//
//  RTLSDRTuner.swift
//  RTLSDR.Swift
//
//  Copyright © 2019 GetOffMyHack. All rights reserved.
//


/*
typedef struct rtlsdr_tuner_iface {
    /* tuner interface */
    int (*init)(void *);
    int (*exit)(void *);
    int (*set_freq)(void *, uint32_t freq /* Hz */);
    int (*set_bw)(void *, int bw /* Hz */, uint32_t *applied_bw /* configured bw in Hz */, int apply /* 1 == configure it!, 0 == deliver applied_bw */);
    int (*set_gain)(void *, int gain /* tenth dB */);
    int (*set_if_gain)(void *, int stage, int gain /* tenth dB */);
    int (*set_gain_mode)(void *, int manual);
} rtlsdr_tuner_iface_t;
*/

protocol RTLTunerProtocol {
    func initTuner() -> Int
    func exitTuner() -> Int
    func setFrequency() -> Int
    func setBandwidth() -> Int
    func setGain() -> Int
    func setIFGain() -> Int
    func setGainMode() -> Int
}

protocol RTLTunerDelegate {
    
    func enableI2CRepeaterForTuner(on: Bool)
    func writeI2CForTuner()
    func readI2CForTuner(deviceI2CAddress: UInt8, address: UInt8) -> UInt8
    
    // calls to change the Realtek config from tuner
    func disableZeroIFModeForTuner()
    func onlyEnableInPhaseADCInputForTuner()
    func setIFFrequencyForTuner(frequency: UInt32)
    func enableSpectrumInversionForTuner()

}

class RTLTuner: RTLTunerProtocol {
    
    final class func discoverTuner(bootStrap: RTLTunerDelegate) -> RTLTuner? {
    
        var tuner: RTLTuner? = nil
        
        //
        // normally, I would check which tuner is attached by testing
        // each type until a match is found, as in librtlsdr, but since
        // all of my RTLSDR dongles (one from NooElec, one from RTL-SDR.com,
        // and a few generics) have the same Rafael Micro R820T tuner,
        // that is all that I can test, therefore, that is all that I will code
        //
        
        tuner = RTLTunerR820T.isMatchingTuner(bootStrap: bootStrap)
        
        return tuner
    }
    
    func initTuner() -> Int {
        
//        fatalError("Method \(#function) must be overridden!")
        return 0
    }
    
    func exitTuner() -> Int {
        
//        fatalError("Method \(#function) must be overridden!")
        return 0
        
    }
    
    func setFrequency() -> Int {
        
//        fatalError("Method \(#function) must be overridden!")
        return 0
        
    }
    
    func setBandwidth() -> Int {
        
//        fatalError("Method \(#function) must be overridden!")
        return 0
        
    }
    
    func setGain() -> Int {
        
//        fatalError("Method \(#function) must be overridden!")
        return 0
        
    }
    
    func setIFGain() -> Int {
        
//        fatalError("Method \(#function) must be overridden!")
        return 0
        
    }
    
    func setGainMode() -> Int {
        
//        fatalError("Method \(#function) must be overridden!")
        return 0
        
    }

}
