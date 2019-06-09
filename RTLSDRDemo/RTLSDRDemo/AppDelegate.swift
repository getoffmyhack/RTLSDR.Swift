//
//  AppDelegate.swift
//  RTLSDRDemo
//
//  Created by Justin England on 6/3/19.
//  Copyright © 2019 GetOffMyHack. All rights reserved.
//

import Cocoa
import RTLSDR_Swift

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, USBManagerDelegate {

    @IBOutlet weak var window: NSWindow!
    
    var usbManager = USBManager()


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        // not really doing anything here, so just do some standard debug stuff
        usbManager.start(delegate: self)
        
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func usbDeviceAdded(_ id: io_registry_id_t) {
        
//        print("did call usbDeviceAdded")
        let _ = RTLSDR.initWithRegistryID(registryID: id)
    
    }
    
    func usbDeviceRemoved(_ id: io_registry_id_t) {
        
    }


}

