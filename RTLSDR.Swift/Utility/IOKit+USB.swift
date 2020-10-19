//
//  IOKit+USB.swift
//  RTLSDR.Swift
//
//  Copyright © 2019 Justin England. All rights reserved.
//
//

import CoreFoundation
import IOKit.usb.USB

//------------------------------------------------------------------------------
//
// constants and aliases for IOKit and USB devices not imported into Swift
//
//------------------------------------------------------------------------------

public typealias io_registry_id_t = UInt64

//
// These constants are not imported into Swift from IOUSBLib.h and IOCFPlugin.h
// as they are all #define constants
//

public let kIOUSBDeviceUserClientTypeID     = CFUUIDGetConstantUUIDWithBytes(nil,
                                                            0x9d, 0xc7, 0xb7, 0x80, 0x9e, 0xc0, 0x11, 0xD4,
                                                            0xa5, 0x4f, 0x00, 0x0a, 0x27, 0x05, 0x28, 0x61)
public let kIOUSBDeviceInterfaceID          = CFUUIDGetConstantUUIDWithBytes(nil,
                                                            0x5c, 0x81, 0x87, 0xd0, 0x9e, 0xf3, 0x11, 0xD4,
                                                            0x8b, 0x45, 0x00, 0x0a, 0x27, 0x05, 0x28, 0x61)

public let kIOUSBInterfaceUserClientTypeID  = CFUUIDGetConstantUUIDWithBytes(nil,
                                                            0x2d, 0x97, 0x86, 0xc6, 0x9e, 0xf3, 0x11, 0xD4,
                                                            0xad, 0x51, 0x00, 0x0a, 0x27, 0x05, 0x28, 0x61)
public let kIOUSBInterfaceInterfaceID100    = CFUUIDGetConstantUUIDWithBytes(nil,
                                                            0x73, 0xc9, 0x7a, 0xe8, 0x9e, 0xf3, 0x11, 0xD4,
                                                            0xb1, 0xd0, 0x00, 0x0a, 0x27, 0x05, 0x28, 0x61)
public let kIOUSBInterfaceInterfaceID942    = CFUUIDGetConstantUUIDWithBytes(nil,
                                                            0x87, 0x52, 0x66, 0x3B, 0xC0, 0x7B, 0x4B, 0xAE,
                                                            0x95, 0x84, 0x22, 0x03, 0x2F, 0xAB, 0x9C, 0x5A)
public let kIOUSBInterfaceInterfaceID       = kIOUSBInterfaceInterfaceID100

public let kIOCFPlugInInterfaceID           = CFUUIDGetConstantUUIDWithBytes(nil,
                                                            0xC2, 0x44, 0xE8, 0x58, 0x10, 0x9C, 0x11, 0xD4,
                                                            0x91, 0xD4, 0x00, 0x50, 0xE4, 0xC6, 0x42, 0x6F)

/*!
 @defined USBmakebmRequestType
 @discussion Macro to encode the bRequest field of a Device Request.  It is used when constructing an IOUSBDevRequest.

#define USBmakebmRequestType(direction, type, recipient)        \
(((direction & kUSBRqDirnMask) << kUSBRqDirnShift) |            \
((type & kUSBRqTypeMask) << kUSBRqTypeShift) |            \
(recipient & kUSBRqRecipientMask))
*/

public func USBmakebmRequestType(direction:Int, type:Int, recipient:Int) -> UInt8 {
    return
        UInt8((direction & kUSBRqDirnMask) << kUSBRqDirnShift) |
        UInt8((type      & kUSBRqTypeMask) << kUSBRqTypeShift) |
        UInt8 (recipient & kUSBRqRecipientMask)
}
