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

protocol rtlsdrTuner {
    func initTuner() -> Int
    func exitTuner() -> Int
    func setFrequency() -> Int
    func setBandwidth() -> Int
    func setGain() -> Int
    func setIFGain() -> Int
    func setGainMode() -> Int
}
