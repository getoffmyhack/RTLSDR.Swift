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

    private let defaults: Dictionary<String, Any> =
            ["tunerClock" : UInt(28000000)]
    
    
    private var tunerClock:         UInt
    
    private let ioRegistryID:       io_registry_id_t
    private let ioRegistryName:     String
    private let usbVendorID:        Int
    private let usbProductID:       Int
    private let usbVendorName:      String
    private let usbProductName:     String
    private let usbSerialString:    String
    

    private typealias IOUSBDeviceInterfaceUMPtrUMPtr    = UnsafeMutablePointer<UnsafeMutablePointer<IOUSBDeviceInterface>?>?
    private typealias IOUSBInterfaceInterfaceUMPtrUMPtr = UnsafeMutablePointer<UnsafeMutablePointer<IOUSBInterfaceInterface>?>?
    
    
    private var deviceInterfaceUMPtrUMPtr:      IOUSBDeviceInterfaceUMPtrUMPtr      = nil
    private var deviceInterface:                IOUSBDeviceInterface                = IOUSBDeviceInterface()
    
    private var interfaceInterfaceUMPtrUMPtr:   IOUSBInterfaceInterfaceUMPtrUMPtr   = nil
    private var interfaceInterface:             IOUSBInterfaceInterface             = IOUSBInterfaceInterface()
    
    private var usbDeviceConfiguration:         IOUSBConfigurationDescriptor        = IOUSBConfigurationDescriptor()
    private var usbInterfaceConfiguration:      IOUSBInterfaceDescriptor            = IOUSBInterfaceDescriptor()
    
    private static var rtlDeviceList: Dictionary<io_registry_id_t, RTLSDR> = [:]
    
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

    private init(deviceToInit: io_object_t) {
        
        // init instance properties to defaults
        self.tunerClock = defaults["tunerClock"] as! UInt
        
        // retreive identifing info from IORegistry using the device object
        self.ioRegistryID       = deviceToInit.ioRegistryID()
        self.ioRegistryName     = deviceToInit.ioRegistryName()!
        self.usbVendorID        = deviceToInit.usbVendorID()!
        self.usbProductID       = deviceToInit.usbProductID()!
        self.usbVendorName      = deviceToInit.usbVendorName()!
        self.usbProductName     = deviceToInit.usbProductName()!
        self.usbSerialString    = deviceToInit.usbSerialNumber()!
        
        super.init()
        
        for(key, value) in deviceToInit.getProperties()! {
            print("Key: \(key)\t\(value)")
        }
        
        // get the device's USB device interface from IOKit
        self.getDeviceInterface(device: deviceToInit)

        // open the device and proceed to set its USB Configuration
        let deviceOpenResult = deviceInterface.USBDeviceOpen(deviceInterfaceUMPtrUMPtr)
        if(deviceOpenResult == kIOReturnSuccess) {
            print("Device OPENED!!")
        }
        
        // set the USB Configuration
        self.configureUSBDeviceConfiguration()
        
        // find the interfaceInterface that is bulk-in as that is what is used
        // to get the IQ samples from the device
        self.findInterfaceInterface()
        
        _ = deviceInterface.USBDeviceClose(deviceInterfaceUMPtrUMPtr)

//        super.init()
        
    }
    
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
        while case let interface = IOIteratorNext(interfaceIterator), interface != IO_OBJECT_NULL {
            
            if interfaceFound == true {
                // even though we found the interface, finish iterating interfaces
                continue
            }
            var score: Int32 = 0
            
            // create plugin interface to get the interfaceInterface
            let interfaceForSeriveResult = IOCreatePlugInInterfaceForService(
                interface,
                kIOUSBInterfaceUserClientTypeID,
                kIOCFPlugInInterfaceID,
                &plugInInterfaceUMPtrUMPtr,
                &score)
            
            // check for success
            if interfaceForSeriveResult != kIOReturnSuccess {
                fatalError("Unable to IOCreatePlugInInterfaceForService: \(interfaceForSeriveResult)")
            }
            
            // release interface object as no longer needed
            _ = IOObjectRelease(interface)
            
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
    
    
    //
    //
    // Private internal functions
    //
    //
    
    private func rtlsdr_init_baseband() {
        
        /* initialize USB */

        /* poweron demod */
        
        /* reset demod (bit 3, soft_rst) */

        /* disable spectrum inversion and adjacent channel rejection */

        /* clear both DDC shift and IF frequency registers    */

        /* set fir */
        
        /* enable SDR mode, disable DAGC (bit 5) */
        
        /* init FSM state-holding register */

        /* disable AGC (en_dagc, bit 0) (this seems to have no effect) */

        /* disable RF and IF AGC loop */

        /* disable PID filter (enable_PID = 0) */

        /* opt_adc_iq = 0, default ADC_I/ADC_Q datapath */

        /* Enable Zero-IF mode (en_bbin bit), DC cancellation (en_dc_est),
         * IQ estimation/compensation (en_iq_comp, en_iq_est) */
        
        /* disable 4.096 MHz clock output on pin TP_CK0 */

    }
    
    private func rtlsdr_write_reg(
        block: UInt8, address: UInt16, value: UInt16, length: UInt8
        ) {
        
        // manage data to write
        
        // fill IOUSBDevRequest struct
        
        // send IOUSBDevRequest to device interface
    
    }
    
}



