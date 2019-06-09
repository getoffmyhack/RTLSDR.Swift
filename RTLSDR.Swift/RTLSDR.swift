//
//  RTLSDR.swift
//  RTLSDR.Swift
//
//  Copyright © 2019 GetOffMyHack
//

import Foundation
import IOKit
import IOKit.usb

public class RTLSDR: NSObject {

    // defaults for librtlsdr vars
    private static let defaults: Dictionary<String, Any> =
        [
            "tunerClock"        : UInt(28000000),
            "rtlXtal"           : UInt(28800000),
            "firCoefficients"   : [Int16]([
                -54, -36, -41, -40, -32, -14, 14, 53,       // 8 bit signed
                101, 156, 215, 273, 327, 372, 404, 421])    // 12 bit signed
        ]
    
    // librtlsdr vars
    private var tunerClock:         UInt
    private var rtlXtal:            UInt
    
    // librtlsdr constants
    
    // pseudo Device Descriptor
    private let ioRegistryID:       io_registry_id_t
    private let ioRegistryName:     String
    private let usbVendorID:        Int
    private let usbProductID:       Int
    private let usbVendorName:      String
    private let usbProductName:     String
    private let usbSerialString:    String
    
    // IOKit.usb typealiases, just because they are so long
    private typealias IOUSBDeviceInterfaceUMPtrUMPtr    = UnsafeMutablePointer<UnsafeMutablePointer<IOUSBDeviceInterface>?>?
    private typealias IOUSBInterfaceInterfaceUMPtrUMPtr = UnsafeMutablePointer<UnsafeMutablePointer<IOUSBInterfaceInterface>?>?
    
    // DeviceInterface for communication to the Realtek USB chip
    private var deviceInterfaceUMPtrUMPtr:      IOUSBDeviceInterfaceUMPtrUMPtr      = nil
    private var deviceInterface:                IOUSBDeviceInterface                = IOUSBDeviceInterface()
    
    // InterfaceInterface for the Bulk-in interface for IQ samples
    private var interfaceInterfaceUMPtrUMPtr:   IOUSBInterfaceInterfaceUMPtrUMPtr   = nil
    private var interfaceInterface:             IOUSBInterfaceInterface             = IOUSBInterfaceInterface()
    
    // Not necessarily needed, but standard USB descriptors
    private var usbDeviceConfiguration:         IOUSBConfigurationDescriptor        = IOUSBConfigurationDescriptor()
    private var usbInterfaceConfiguration:      IOUSBInterfaceDescriptor            = IOUSBInterfaceDescriptor()
    
    // master assoc array of each RTLSDR device currently instaniated
    private static var rtlDeviceList: Dictionary<io_registry_id_t, RTLSDR> = [:]
    
    //
    // Realtek Register Blocks
    //
    enum rtlRegisterBlock: UInt16 {
        case demod  = 0x0000
        case usb    = 0x0100
        case system = 0x0200
        case tuner  = 0x0300
        case rom    = 0x0400
        case ir     = 0x0500
        case i2c    = 0x0600
    }
    
    enum rtlRegisterAddress: UInt16 {
        case USB_SYSCTL         = 0x2000
        case USB_CTRL           = 0x2010
        case USB_STAT           = 0x2014
        case USB_EPA_CFG        = 0x2144
        case USB_EPA_CTL        = 0x2148
        case USB_EPA_MAXPKT     = 0x2158
        case USB_EPA_MAXPKT_2   = 0x215a
        case USB_EPA_FIFO_CFG   = 0x2160
        
        case DEMOD_CTL          = 0x3000
        case GPO                = 0x3001
        case GPI                = 0x3002
        case GPOE               = 0x3003
        case GPD                = 0x3004
        case SYSINTE            = 0x3005
        case SYSINTS            = 0x3006
        case GP_CFG0            = 0x3007
        case GP_CFG1            = 0x3008
        case SYSINTE_1          = 0x3009
        case SYSINTS_1          = 0x300a
        case DEMOD_CTL_1        = 0x300b
        case IR_SUSPEND         = 0x300c
    }
    

    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------
    
    public class func initWithRegistryID(registryID: io_registry_id_t) -> RTLSDR? {
        
        var rtlsdrDevice: RTLSDR? = nil
        
        // check if RTLSDR device is already init'd
        if let device = rtlDeviceList[registryID] {
            rtlsdrDevice = device
        } else {
            
            //
            // check if passed in registry ID is an RTLSDR
            //
            
            // get mach master port
            var masterPort: mach_port_t = 0
            
            // make sure the IOMasterPort call succeeds
            guard IOMasterPort(mach_port_t(MACH_PORT_NULL), &masterPort) == kIOReturnSuccess else {
                fatalError("Unable to get master mach port!")
            }
            
            // set up matching dictionary
            let matchingDictionary: NSMutableDictionary = IORegistryEntryIDMatching(registryID)
            
            // get io object for this registry ID and make sure it exists
            let device = IOServiceGetMatchingService(masterPort, matchingDictionary)
            guard device != IO_OBJECT_NULL else {
                fatalError("Unable to get device object!")
            }

            // with the device object, get the VID / PID and check if
            // known RTLSDR devive (list found in librtlsdr.c)
            if(RTLKnownDevices.isKnownRTLDevice(vid: device.usbVendorID()!, pid: device.usbProductID()!)) {
                rtlsdrDevice = RTLSDR(deviceToInit: device)
                rtlDeviceList[registryID] = rtlsdrDevice
            }
            
            IOObjectRelease(device)
            
        }
        
        return rtlsdrDevice
        
    }
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------

    private init?(deviceToInit: io_object_t) {
        
        // init librtlsdr properties to defaults
        self.tunerClock = RTLSDR.defaults["tunerClock"]    as! UInt
        self.rtlXtal    = RTLSDR.defaults["rtlXtal"]       as! UInt
        
        // retreive identifing info from IORegistry using the device object
        self.ioRegistryID       = deviceToInit.ioRegistryID()
        self.ioRegistryName     = deviceToInit.ioRegistryName()!
        self.usbVendorID        = deviceToInit.usbVendorID()!
        self.usbProductID       = deviceToInit.usbProductID()!
        self.usbVendorName      = deviceToInit.usbVendorName()!
        self.usbProductName     = deviceToInit.usbProductName()!
        self.usbSerialString    = deviceToInit.usbSerialNumber()!
        
        super.init()
        
//        for(key, value) in deviceToInit.getProperties()! {
//            print("Key: \(key)\t\(value)")
//        }
        
        // get the device's USB device interface from IOKit
        self.getDeviceInterface(device: deviceToInit)

        // open the device
        let deviceOpenResult = deviceInterface.USBDeviceOpen(deviceInterfaceUMPtrUMPtr)
        if(deviceOpenResult == kIOReturnSuccess) {
            print("Device OPENED!!")
        }
        
        // set the USB Configuration
        self.configureUSBDeviceConfiguration()
        
        // find the interfaceInterface that is bulk-in as that is what is used
        // to get the IQ samples from the device
        self.findInterfaceInterface()
        
        // this is straight from librtlsdr
        self.initBaseband()
        
        _ = deviceInterface.USBDeviceClose(deviceInterfaceUMPtrUMPtr)

        // TODO: register this ioRegistryID to be notified when removed
        
        
    }
    
    // MARK: USB Init Methods
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------
    
    private func getDeviceInterface(device: io_object_t) {
        
        var interfaceUMPtrUMPtr:  IOUSBDeviceInterfaceUMPtrUMPtr  = nil
        
        //
        // use a plugin interface to find the device interface
        //
        var plugInInterfaceUMPtrUMPtr:UnsafeMutablePointer<UnsafeMutablePointer<IOCFPlugInInterface>?>?
        var score: Int32 = 0
        
        // Get plugInInterface for current USB device
        let plugInInterfaceResult = IOCreatePlugInInterfaceForService(
            device,
            kIOUSBDeviceUserClientTypeID,
            kIOCFPlugInInterfaceID,
            &plugInInterfaceUMPtrUMPtr,
            &score)
        
        IOObjectRelease(device)
        
        // check if IOCreatePlugInInterfaceForService was successful
        if ( (plugInInterfaceResult != kIOReturnSuccess)) {
            fatalError("Unable to get Plug-In Interface")
        }
        
        // Dereference pointer for the plug-in interface
        guard let plugInInterface = plugInInterfaceUMPtrUMPtr?.pointee?.pointee else {
            fatalError("Unable to dereference plugInInterface")
        }
        
        // use plug in interface to get a device interface
        let queryInterfaceResult = withUnsafeMutablePointer(to: &interfaceUMPtrUMPtr) {
            $0.withMemoryRebound(to: (LPVOID?).self, capacity: 1) {
                plugInInterface.QueryInterface(
                    plugInInterfaceUMPtrUMPtr,
                    CFUUIDGetUUIDBytes(kIOUSBDeviceInterfaceID),
                    $0)
            }
        }
        
        // check if QueryInterface was successful
        if ( (interfaceUMPtrUMPtr == nil)  || (queryInterfaceResult != kIOReturnSuccess)) {
            fatalError("Unable to get device Interface")
        }
        
        // dereference device interface and save the pointer -> pointer and
        // the dereferened to this instance
        guard let interfaceDereferenced = interfaceUMPtrUMPtr?.pointee?.pointee else {
            fatalError("Unable to dereference deviceInterface")
        }
        
        // plugInInterface is no longer needed
        _ = plugInInterface.Release(plugInInterfaceUMPtrUMPtr)
        plugInInterfaceUMPtrUMPtr = nil
        
        self.deviceInterface            = interfaceDereferenced
        self.deviceInterfaceUMPtrUMPtr  = interfaceUMPtrUMPtr
        
    }
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------
    
    private func configureUSBDeviceConfiguration() {
        
        //
        // the following code which gets the number of configs, sets config to
        // the first (and only) configuration is probably not really needed as
        // I do not see this happening with librtlsdr.
        //
        
        //
        // This code is basically out of the "USB Device Interface Guide" from
        // Apple but re-written in Swift
        //
        
        // get number of configurations
        var numberOfConfigurations: UInt8 = 0
        _ = self.deviceInterface.GetNumberOfConfigurations(self.deviceInterfaceUMPtrUMPtr, &numberOfConfigurations)
        print("Number of Configurations: \(numberOfConfigurations)")
        
        // get configuration descriptor
        var usbConfigurationDescriptorPtr: IOUSBConfigurationDescriptorPtr? = nil
        _ = self.deviceInterface.GetConfigurationDescriptorPtr(self.deviceInterfaceUMPtrUMPtr, 0, &usbConfigurationDescriptorPtr)
        let usbConfigurationDescriptor = usbConfigurationDescriptorPtr!.pointee
        print(usbConfigurationDescriptor)
        
        // set to first configuration found in the bConfigurationValue field
        let setConfigurationResult = self.deviceInterface.SetConfiguration(
            self.deviceInterfaceUMPtrUMPtr, usbConfigurationDescriptor.bConfigurationValue)
        
        if setConfigurationResult != kIOReturnSuccess {
            fatalError("Unable to setConfiguration: \(setConfigurationResult)")
        }
        
        usbDeviceConfiguration = usbConfigurationDescriptor
        
    }
    
    //--------------------------------------------------------------------------
    //
    // 
    //
    //--------------------------------------------------------------------------
    
    private func findInterfaceInterface() {
        
        //
        // More code from Appple:  iterate over the interfaces found
        // in this device.
        //
        
        // create interface request structure
        var interfaceRequest: IOUSBFindInterfaceRequest = IOUSBFindInterfaceRequest(
            bInterfaceClass:    UInt16(kIOUSBFindInterfaceDontCare),
            bInterfaceSubClass: UInt16(kIOUSBFindInterfaceDontCare),
            bInterfaceProtocol: UInt16(kIOUSBFindInterfaceDontCare),
            bAlternateSetting:  UInt16(kIOUSBFindInterfaceDontCare))
        
        // get interface iterator from usb device interface
        var interfaceIterator: io_iterator_t = 0
        let interfaceIteratorResult = deviceInterface.CreateInterfaceIterator(
            deviceInterfaceUMPtrUMPtr,
            &interfaceRequest,
            &interfaceIterator)
        
        // check for success
        if interfaceIteratorResult != kIOReturnSuccess {
            fatalError("Unable to CreateInterfaceIterator: \(interfaceIteratorResult)")
        }
        
        var plugInInterfaceUMPtrUMPtr:UnsafeMutablePointer<UnsafeMutablePointer<IOCFPlugInInterface>?>?
        
        var interfaceFound: Bool = false
        
        // iterate over the interfaceIterface(s) available with this device
        while case let interfaceObject = IOIteratorNext(interfaceIterator), interfaceObject != IO_OBJECT_NULL {
            
            defer { _ = IOObjectRelease(interfaceObject) }
            
            if interfaceFound == true {
                // even though we found the interface, finish iterating interfaces
                continue
            }
            var score: Int32 = 0
            
            // create plugin interface to get the interfaceInterface
            let interfaceForSeriveResult = IOCreatePlugInInterfaceForService(
                interfaceObject,
                kIOUSBInterfaceUserClientTypeID,
                kIOCFPlugInInterfaceID,
                &plugInInterfaceUMPtrUMPtr,
                &score)
            
            // check for success
            if interfaceForSeriveResult != kIOReturnSuccess {
                fatalError("Unable to IOCreatePlugInInterfaceForService: \(interfaceForSeriveResult)")
            }
            
            // Dereference pointer for the plug-in interface
            guard let plugInInterface = plugInInterfaceUMPtrUMPtr?.pointee?.pointee else {
                fatalError("Unable to dereference plugInInterface for Interface")
            }
            
            var interfaceUMPtrUMPtr: UnsafeMutablePointer<UnsafeMutablePointer<IOUSBInterfaceInterface>?>?
            var interface: IOUSBInterfaceInterface
            
            // use plug in interface to get an interfaceInterface
            let queryInterfaceResult = withUnsafeMutablePointer(to: &interfaceUMPtrUMPtr) {
                $0.withMemoryRebound(to: (LPVOID?).self, capacity: 1) {
                    plugInInterface.QueryInterface(
                        plugInInterfaceUMPtrUMPtr,
                        CFUUIDGetUUIDBytes(kIOUSBInterfaceInterfaceID),
                        $0)
                }
            }
            
            // check if QueryInterface was successful
            if ( (interfaceUMPtrUMPtr == nil)  || (queryInterfaceResult != kIOReturnSuccess)) {
                fatalError("Unable to get Interface Interface")
            }
            
            // dereference interface interface and save the pointer -> pointer and
            // the dereferened to this instance
            guard let interfaceDereferenced = interfaceUMPtrUMPtr?.pointee?.pointee else {
                fatalError("Unable to dereference deviceInterface")
            }
            
            interface = interfaceDereferenced
            
            // query the inteface for it's properties
            var interfaceClass:     UInt8 = 0
            var interfaceSubClass:  UInt8 = 0
            
            let interfaceClassResult = interface.GetInterfaceClass(interfaceUMPtrUMPtr, &interfaceClass)
            if interfaceClassResult != kIOReturnSuccess {
                fatalError("Unable to GetInterfaceCLass: \(interfaceClassResult)")
            }
            
            print("InterfaceClass: \(interfaceClass)")
            
            let interfaceSubClassResult = interface.GetInterfaceSubClass(interfaceUMPtrUMPtr, &interfaceSubClass)
            if interfaceSubClassResult != kIOReturnSuccess {
                fatalError("Unable to GetInterfaceCLass: \(interfaceSubClassResult)")
            }
            
            print("InterfaceSubClass: \(interfaceSubClass)")
            
            //Now open the interface. This will cause the pipes associated with
            //the endpoints in the interface descriptor to be instantiated
            let interfaceOpenResult = interface.USBInterfaceOpen(interfaceUMPtrUMPtr)
            if interfaceOpenResult != kIOReturnSuccess {
                fatalError("Unable to USBInterfaceOpen: \(interfaceOpenResult)")
            }
            
            print("Opened interfaceInterface")
            
            var interfaceNumberOfEndpoints: UInt8 = 0
            let endpointsResult = interface.GetNumEndpoints(interfaceUMPtrUMPtr,
                                                                     &interfaceNumberOfEndpoints);
            if endpointsResult != kIOReturnSuccess {
                fatalError("Unable to GetNumEndpoints: \(endpointsResult)")
            }
            
            print("Number of Endpoints: \(interfaceNumberOfEndpoints)")
            
            //Access each pipe in turn, starting with the pipe at index 1
            //The pipe at index 0 is the default control pipe and should be
            //accessed using (*usbDevice)->DeviceRequest() instead
            var pipeIndex: UInt8 = 1
            while (pipeIndex <= interfaceNumberOfEndpoints) {
                
                var direction:      UInt8  = 0
                var number:         UInt8  = 0
                var transferType:   UInt8  = 0
                var maxPacketSize:  UInt16 = 0
                var interval:       UInt8  = 0
                
                // get properties for this pipe
                let pipePropertiesResult =  interface.GetPipeProperties(
                    interfaceUMPtrUMPtr,
                    pipeIndex,
                    &direction,
                    &number,
                    &transferType,
                    &maxPacketSize,
                    &interval)
                
                if pipePropertiesResult != kIOReturnSuccess {
                    fatalError("Unable to GetPipeProperties: \(pipePropertiesResult)")
                }
                
                
                // although we can already "guess" which endpoint is needed,
                // just double check here
                if(number == 1) && (direction == kUSBIn) && (transferType == kUSBBulk) {
                    print("Found Bulk-in Interface: \(number)")
                    self.interfaceInterfaceUMPtrUMPtr   = interfaceUMPtrUMPtr
                    self.interfaceInterface             = interface
                    interfaceFound                      = true
                }
    
                // get next pipe details
                pipeIndex += 1
                
            }
            
            _ = interface.USBInterfaceClose(interfaceUMPtrUMPtr)
            
        }
        
    }
    
    // MARK: Read / Write Realtek Registers USB Control
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------

    
    private func writeRegister( block: rtlRegisterBlock, address: rtlRegisterAddress, value: UInt16, length: UInt16) {
    
        var data: [UInt8] = [UInt8](repeating: 0, count: 2)
        
        // create index value from registerBlock
        let index: UInt16 = ( block.rawValue | 0x10 )
        
        // put value to write into data[UInt8] array as separate bytes
        if (length == 1) {
            data[0] = UInt8(value & 0xff)
        } else {
            data[0] = UInt8(value >> 8)
        }
        data[1] = UInt8(value & 0xff)
        
        // Creating request type
        let requestType = USBmakebmRequestType(direction: kUSBOut, type: kUSBVendor, recipient: kUSBDevice)

        // create Device Request struct
        var request = IOUSBDevRequest(bmRequestType: requestType,
                                      bRequest: 0,
                                      wValue: address.rawValue,
                                      wIndex: index,
                                      wLength: UInt16(length),
                                      pData: &data,
                                      wLenDone: 0)
        // send IOUSBDevRequest to device interface
        let requestResponse = self.deviceInterface.DeviceRequest(self.deviceInterfaceUMPtrUMPtr, &request)

        if requestResponse != kIOReturnSuccess {
            fatalError("Unable to send Device Request: writeRegister: \(request)")
        }
        
    }
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------
    
    func writeDemodRegister(page: UInt8, address: UInt16, value: UInt16, length: UInt8) -> IOUSBDevRequest {
        //        writeDemodRegister(page: 1, address: 0x01, value: 0x14, length: 1)

        var data: [UInt8] = [UInt8]( repeating: 0, count: 2 )
        let index: UInt16 = UInt16( page | 0x10 )
        
        let address = ( (address << 8) | 0x20 )
        
        // put value to write into data[UInt8] array as separate bytes
        if (length == 1) {
            data[0] = UInt8(value & 0xff)
        } else {
            data[0] = UInt8(value >> 8)
        }
        data[1] = UInt8(value & 0xff)

        // Creating request type
        let requestType = USBmakebmRequestType(direction: kUSBOut, type: kUSBVendor, recipient: kUSBDevice)
        
        // create Device Request struct
        var request = IOUSBDevRequest(bmRequestType: requestType,
                                      bRequest: 0,
                                      wValue: address,
                                      wIndex: index,
                                      wLength: UInt16(length),
                                      pData: &data,
                                      wLenDone: 0)
        
        // send IOUSBDevRequest to device interface
        let requestResponse = self.deviceInterface.DeviceRequest(self.deviceInterfaceUMPtrUMPtr, &request)
        
        if requestResponse != kIOReturnSuccess {
            fatalError("Unable to send Device Request: writeDemodRegister:  \(request)")
        }

        _ = readDemodRegister(page: 0x0A, address: 0x01, length: 1)
        
        return request
        
    }
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------

    private func readDemodRegister(page: UInt8, address: UInt16, length: UInt8) -> UInt16{

        var data:       [UInt8] = [UInt8](repeating: 0, count: 2)
        let index:      UInt16  = UInt16(page)
        let address:    UInt16  = ( (address << 8) | 0x20 )
        
        // Creating request type
        let requestType = USBmakebmRequestType(direction: kUSBIn, type: kUSBVendor, recipient: kUSBDevice)
        
        // create Device Request struct
        var request = IOUSBDevRequest(bmRequestType: requestType,
                                      bRequest: 0,
                                      wValue: address,
                                      wIndex: index,
                                      wLength: UInt16(length),
                                      pData: &data,
                                      wLenDone: 0)
        
        // send IOUSBDevRequest to device interface
        let requestResponse = self.deviceInterface.DeviceRequest(self.deviceInterfaceUMPtrUMPtr, &request)
        
        if requestResponse != kIOReturnSuccess {
            fatalError("Unable to send Device Request: readDemodRegister:  \(request)")
        }
        
        return UInt16( (data[1] << 8) | data[0] )
    }
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------
    
    private func initBaseband() {
        
        /* initialize USB */
        writeRegister(block: .usb, address: .USB_SYSCTL,     value: 0x09,   length: 1)
        writeRegister(block: .usb, address: .USB_EPA_MAXPKT, value: 0x0002, length: 2)
        writeRegister(block: .usb, address: .USB_EPA_CTL,    value: 0x1002, length: 2)
        
        /* poweron demod */
        writeRegister(block: .system, address: .DEMOD_CTL_1, value: 0x22,   length: 1)
        writeRegister(block: .system, address: .DEMOD_CTL,   value: 0xE8,   length: 1)

        /* reset demod (bit 3, soft_rst) */
        _ = writeDemodRegister(page: 1, address: 0x01, value: 0x14, length: 1)
        _ = writeDemodRegister(page: 1, address: 0x01, value: 0x10, length: 1)

        /* disable spectrum inversion and adjacent channel rejection */
        _ = writeDemodRegister(page: 1, address: 0x15, value: 0x00, length: 1)
        _ = writeDemodRegister(page: 1, address: 0x16, value: 0x0000, length: 2)
        
        
        /* clear both DDC shift and IF frequency registers    */
        for counter in 0..<6 {
            _ = writeDemodRegister(page: 1, address: (UInt16(0x16 + counter)), value: 0x00, length: 1)
        }
        
        setFirCoefficients()
        
        /* set fir */
//        rtlsdr_set_fir(dev);
        
        /* enable SDR mode, disable DAGC (bit 5) */
        _ = writeDemodRegister(page: 0, address: 0x19, value: 0x05, length: 1)

        /* init FSM state-holding register */
        _ = writeDemodRegister(page: 1, address: 0x93, value: 0xf0, length: 1)
        _ = writeDemodRegister(page: 1, address: 0x94, value: 0x0f, length: 1)
        
        /* disable AGC (en_dagc, bit 0) (this seems to have no effect) */
        _ = writeDemodRegister(page: 1, address: 0x11, value: 0x00, length: 1)
//        rtlsdr_demod_write_reg(dev, 1, 0x11, 0x00, 1);

        /* disable RF and IF AGC loop */
        _ = writeDemodRegister(page: 1, address: 0x04, value: 0x00, length: 1)
//        rtlsdr_demod_write_reg(dev, 1, 0x04, 0x00, 1);
        
        /* disable PID filter (enable_PID = 0) */
        _ = writeDemodRegister(page: 0, address: 0x61, value: 0x60, length: 1)
//        rtlsdr_demod_write_reg(dev, 0, 0x61, 0x60, 1);
        
        /* opt_adc_iq = 0, default ADC_I/ADC_Q datapath */
        _ = writeDemodRegister(page: 0, address: 0x06, value: 0x80, length: 1)
//        rtlsdr_demod_write_reg(dev, 0, 0x06, 0x80, 1);
        
        /* Enable Zero-IF mode (en_bbin bit), DC cancellation (en_dc_est),
         * IQ estimation/compensation (en_iq_comp, en_iq_est) */
        _ = writeDemodRegister(page: 1, address: 0xb1, value: 0x1b, length: 1)
//        rtlsdr_demod_write_reg(dev, 1, 0xb1, 0x1b, 1);
        
        /* disable 4.096 MHz clock output on pin TP_CK0 */
        _ = writeDemodRegister(page: 0, address: 0x0d, value: 0x83, length: 1)
//        rtlsdr_demod_write_reg(dev, 0, 0x0d, 0x83, 1);
    }
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------
    
    private func setFirCoefficients() {
       
        var firToSend:  [UInt8] = []
        var firDefault: [Int16] = RTLSDR.defaults["firCoefficients"] as! [Int16]
        
        //
        // The original librtlsdr code uses plenty of C compiler "tricks" in
        // order to represent an int16_t number as an uint8_t bit pattern
        //
        // Swift is much more strict about converting between signed and
        // unsinged and between bit depths.  In order to keep the exact
        // bit pattern, several conversions need to take place.
        //
        // TODO: Replace RTLSDR.defaults["firCoefficients"]
        // with the computed values from this method
        //
        
        // process first 8 coefficients as they are all 8 bits
        for _ in 0..<8 {
            
            //
            // the first 8 default coefficients are only Int8's, but
            // stored as Int16's.
            //
            // The original librtlsdr returned an (unused) error and did not
            // send the filter to the demodulator if there was a value outside
            // of an Int8 (-128 to 127); no need to deal with that here as Swift
            // with throw a runtime error if the signed value is too large to
            // fit in an Int8
            //
            
            // convert Int16 to Int8 while keeping the same value; swift will
            // throw a runtime error if value to large for an Int8
            let int8Value   = Int8(firDefault.removeFirst())
            
            // convert Int8 to UInt8 without sacrificing the bit pattern
            let uint8value  = UInt8(bitPattern: int8Value)
            
            // append to byte array to send to rtl
            firToSend.append(uint8value)
            
        }
        
        
        //
        // the second 8 coefficients are 12 bits and will take 12 bytes total.
        // this code bit twiddles two 12bit coefficients into three bytes
        //
        
        while firDefault.count != 0 {
            
            // convert Int16's into UInt16's and keeping the same bit pattern
            let uint16Coeff_1 = UInt16(bitPattern: firDefault.removeFirst())
            let uint16Coeff_2 = UInt16(bitPattern: firDefault.removeFirst())
            
            // twiddle the two 12 bit coeff's into 3 UInt8's
            let byte1: UInt8 = UInt8(  uint16Coeff_1 >> 4 )
            let byte2: UInt8 = UInt8(((uint16Coeff_1 << 4) & 0xff) | (uint16Coeff_2 >> 8) & 0x0f )
            let byte3: UInt8 = UInt8(  uint16Coeff_2       & 0xff )
        
            // append the bytes to the rtl filter
            firToSend.append( byte1 )
            firToSend.append( byte2 )
            firToSend.append( byte3 )

        }

        for index in 0..<firToSend.count {

            let address:UInt16 = 0x1c + UInt16(index)
            _ = writeDemodRegister(page: 1, address: address, value: UInt16(firToSend[index]), length: 1)
            
        }

    }
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------
    
    
    //
    //
    // Public interface
    //
    //
    
    func rtlsdr_open() {
        
        
    }
    
    func rtlsdr_close() {
        
    }
    
    /*!
     * Set crystal oscillator frequencies used for the RTL2832 and the tuner IC.
     *
     * Usually both ICs use the same clock. Changing the clock may make sense if
     * you are applying an external clock to the tuner or to compensate the
     * frequency (and samplerate) error caused by the original (cheap) crystal.
     *
     * NOTE: Call this function only if you fully understand the implications.
     *
     * \param dev the device handle given by rtlsdr_open()
     * \param rtl_freq frequency value used to clock the RTL2832 in Hz
     * \param tuner_freq frequency value used to clock the tuner IC in Hz
     * \return 0 on success
     */
    
    func rtlsdr_set_xtal_freq() {
        
    }
    
    /*!
     * Get crystal oscillator frequencies used for the RTL2832 and the tuner IC.
     *
     * Usually both ICs use the same clock.
     *
     * \param dev the device handle given by rtlsdr_open()
     * \param rtl_freq frequency value used to clock the RTL2832 in Hz
     * \param tuner_freq frequency value used to clock the tuner IC in Hz
     * \return 0 on success
     */
    
    func rtlsdr_get_xtal_freq() {
        
    }
    
    /*!
     * Write the device EEPROM
     *
     * \param dev the device handle given by rtlsdr_open()
     * \param data buffer of data to be written
     * \param offset address where the data should be written
     * \param len length of the data
     * \return 0 on success
     * \return -1 if device handle is invalid
     * \return -2 if EEPROM size is exceeded
     * \return -3 if no EEPROM was found
     */
    
    func rtlsdr_write_eeprom() {
        
    }
    
    /*!
     * Read the device EEPROM
     *
     * \param dev the device handle given by rtlsdr_open()
     * \param data buffer where the data should be written
     * \param offset address where the data should be read from
     * \param len length of the data
     * \return 0 on success
     * \return -1 if device handle is invalid
     * \return -2 if EEPROM size is exceeded
     * \return -3 if no EEPROM was found
     */
    
    func rtlsdr_read_eeprom() {
        
    }
    
    /*!
     * Set the frequency the device is tuned to.
     *
     * \param dev the device handle given by rtlsdr_open()
     * \param frequency in Hz
     * \return 0 on error, frequency in Hz otherwise
     */
    
    func rtlsdr_set_center_freq() {
        
    }
    
    /*!
     * Get actual frequency the device is tuned to.
     *
     * \param dev the device handle given by rtlsdr_open()
     * \return 0 on error, frequency in Hz otherwise
     */
    
    func rtlsdr_get_center_freq() {
        
    }
    
    /*!
     * Set the frequency correction value for the device.
     *
     * \param dev the device handle given by rtlsdr_open()
     * \param ppm correction value in parts per million (ppm)
     * \return 0 on success
     */
    
    func rtlsdr_set_freq_correction() {
        
    }
    
    /*!
     * Get actual frequency correction value of the device.
     *
     * \param dev the device handle given by rtlsdr_open()
     * \return correction value in parts per million (ppm)
     */
    
    func rtlsdr_get_freq_correction() {
        
    }
    
    /*!
     * Get the tuner type.
     *
     * \param dev the device handle given by rtlsdr_open()
     * \return RTLSDR_TUNER_UNKNOWN on error, tuner type otherwise
     */
    
    func rtlsdr_get_tuner_type() {
        
    }
    
    /*!
     * Get a list of gains supported by the tuner.
     *
     * NOTE: The gains argument must be preallocated by the caller. If NULL is
     * being given instead, the number of available gain values will be returned.
     *
     * \param dev the device handle given by rtlsdr_open()
     * \param gains array of gain values. In tenths of a dB, 115 means 11.5 dB.
     * \return <= 0 on error, number of available (returned) gain values otherwise
     */
    
    func rtlsdr_get_tuner_gains() {
        
    }
    
    /*!
     * Set the gain for the device.
     * Manual gain mode must be enabled for this to work.
     *
     * Valid gain values (in tenths of a dB) for the E4000 tuner:
     * -10, 15, 40, 65, 90, 115, 140, 165, 190,
     * 215, 240, 290, 340, 420, 430, 450, 470, 490
     *
     * Valid gain values may be queried with \ref rtlsdr_get_tuner_gains function.
     *
     * \param dev the device handle given by rtlsdr_open()
     * \param gain in tenths of a dB, 115 means 11.5 dB.
     * \return 0 on success
     */
    func rtlsdr_set_tuner_gain() {
        
    }
    
    /*!
     * Set the bandwidth for the device.
     *
     * \param dev the device handle given by rtlsdr_open()
     * \param bw bandwidth in Hz. Zero means automatic BW selection.
     * \param applied_bw is applied bandwidth in Hz, or 0 if unknown
     * \param apply_bw: 1 to really apply configure the tuner chip; 0 for just returning applied_bw
     * \return 0 on success
     */
    
    func rtlsdr_set_and_get_tuner_bandwidth() {
        
    }
    
    func rtlsdr_set_tuner_bandwidth() {
        
    }
    
    /*!
     * Get actual gain the device is configured to.
     *
     * \param dev the device handle given by rtlsdr_open()
     * \return 0 on error, gain in tenths of a dB, 115 means 11.5 dB.
     */
    
    func rtlsdr_get_tuner_gain() {
        
    }
    
    /*!
     * Set LNA / Mixer / VGA Device Gain for R820T device is configured to.
     *
     * \param dev the device handle given by rtlsdr_open()
     * \param lna_gain in tenths of a dB, -30 means -3.0 dB.
     * \param mixer_gain in tenths of a dB, -30 means -3.0 dB.
     * \param vga_gain in tenths of a dB, -30 means -3.0 dB.
     * \return 0 on success
     */
    
    func rtlsdr_set_tuner_gain_ext() {
        
    }
    
    /*!
     * Set the intermediate frequency gain for the device.
     *
     * \param dev the device handle given by rtlsdr_open()
     * \param stage intermediate frequency gain stage number (1 to 6 for E4000)
     * \param gain in tenths of a dB, -30 means -3.0 dB.
     * \return 0 on success
     */
    
    func rtlsdr_set_tuner_if_gain() {
        
    }
    
    /*!
     * Set the gain mode (automatic/manual) for the device.
     * Manual gain mode must be enabled for the gain setter function to work.
     *
     * \param dev the device handle given by rtlsdr_open()
     * \param manual gain mode, 1 means manual gain mode shall be enabled.
     * \return 0 on success
     */
    
    func rtlsdr_set_tuner_gain_mode() {
        
    }
    
    /*!
     * Set the sample rate for the device, also selects the baseband filters
     * according to the requested sample rate for tuners where this is possible.
     *
     * \param dev the device handle given by rtlsdr_open()
     * \param samp_rate the sample rate to be set, possible values are:
     *             225001 - 300000 Hz
     *             900001 - 3200000 Hz
     *             sample loss is to be expected for rates > 2400000
     * \return 0 on success, -EINVAL on invalid rate
     */
    
    func rtlsdr_set_sample_rate() {
        
    }
    
    /*!
     * Get actual sample rate the device is configured to.
     *
     * \param dev the device handle given by rtlsdr_open()
     * \return 0 on error, sample rate in Hz otherwise
     */
    
    func rtlsdr_get_sample_rate() {
        
    }
    
    /*!
     * Enable test mode that returns an 8 bit counter instead of the samples.
     * The counter is generated inside the RTL2832.
     *
     * \param dev the device handle given by rtlsdr_open()
     * \param test mode, 1 means enabled, 0 disabled
     * \return 0 on success
     */
    
    func rtlsdr_set_testmode() {
        
    }
    
    /*!
     * Enable or disable the internal digital AGC of the RTL2832.
     *
     * \param dev the device handle given by rtlsdr_open()
     * \param digital AGC mode, 1 means enabled, 0 disabled
     * \return 0 on success
     */
    
    func rtlsdr_set_agc_mode() {
        
    }
    
    /*!
     * Enable or disable the direct sampling mode. When enabled, the IF mode
     * of the RTL2832 is activated, and rtlsdr_set_center_freq() will control
     * the IF-frequency of the DDC, which can be used to tune from 0 to 28.8 MHz
     * (xtal frequency of the RTL2832).
     *
     * \param dev the device handle given by rtlsdr_open()
     * \param on 0 means disabled, 1 I-ADC input enabled, 2 Q-ADC input enabled
     * \return 0 on success
     */
    
    func rtlsdr_set_direct_sampling() {
        
    }
    
    /*!
     * Get state of the direct sampling mode
     *
     * \param dev the device handle given by rtlsdr_open()
     * \return -1 on error, 0 means disabled, 1 I-ADC input enabled
     *        2 Q-ADC input enabled
     */
    
    func rtlsdr_get_direct_sampling() {
        
    }
    
    /*!
     * Set direct sampling mode with threshold
     *
     * \param dev the device handle given by rtlsdr_open()
     * \param mode static modes 0 .. 2 as in rtlsdr_set_direct_sampling(). other modes do automatic switching
     * \param freq_threshold direct sampling is used below this frequency, else quadrature mode through tuner
     *   set 0 for using default setting per tuner - not fully implemented yet!
     * \return negative on error, 0 on success
     */
    
    func rtlsdr_set_ds_mode() {
        
    }
    
    /*!
     * Enable or disable offset tuning for zero-IF tuners, which allows to avoid
     * problems caused by the DC offset of the ADCs and 1/f noise.
     *
     * \param dev the device handle given by rtlsdr_open()
     * \param on 0 means disabled, 1 enabled
     * \return 0 on success
     */
    
    func rtlsdr_set_offset_tuning() {
        
    }
    
    /*!
     * Get state of the offset tuning mode
     *
     * \param dev the device handle given by rtlsdr_open()
     * \return -1 on error, 0 means disabled, 1 enabled
     */
    
    func rtlsdr_get_offset_tuning() {
        
    }
    
    /* streaming functions */
    
    func rtlsdr_reset_buffer() {
        
    }
    
    func rtlsdr_read_sync() {
        
    }
    
    /*!
     * Read samples from the device asynchronously. This function will block until
     * it is being canceled using rtlsdr_cancel_async()
     *
     * \param dev the device handle given by rtlsdr_open()
     * \param cb callback function to return received samples
     * \param ctx user specific context to pass via the callback function
     * \param buf_num optional buffer count, buf_num * buf_len = overall buffer size
     *          set to 0 for default buffer count (15)
     * \param buf_len optional buffer length, must be multiple of 512,
     *          should be a multiple of 16384 (URB size), set to 0
     *          for default buffer length (16 * 32 * 512)
     * \return 0 on success
     */
    
    func rtlsdr_read_async() {
        
    }
    
    /*!
     * Cancel all pending asynchronous operations on the device.
     *
     * \param dev the device handle given by rtlsdr_open()
     * \return 0 on success
     */
    
    func rtlsdr_cancel_async() {
        
    }
    
    /*!
     * Read from the remote control (RC) infrared (IR) sensor
     *
     * \param dev the device handle given by rtlsdr_open()
     * \param buf buffer to write IR signal (MSB=pulse/space, 7LSB=duration*20usec), recommended 128-bytes
     * \param buf_len size of buf
     * \return 0 if no signal, >0 number of bytes written into buf, <0 for error
     */
    
    func rtlsdr_ir_query() {
        
    }
    
    /*!
     * Enable or disable the bias tee on GPIO PIN 0. (Works for rtl-sdr.com v3 dongles)
     * See: http://www.rtl-sdr.com/rtl-sdr-blog-v-3-dongles-user-guide/
     *
     * \param dev the device handle given by rtlsdr_open()
     * \param on  1 for Bias T on. 0 for Bias T off.
     * \return -1 if device is not initialized. 1 otherwise.
     */
    
    func rtlsdr_set_bias_tee() {
        
    }
    
    
    
    
    
}



//
