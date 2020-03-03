//
//  RTLTunerR820T.swift
//  RTLSDR.Swift
//
//  Created by Justin England on 6/9/19.
//  Copyright © 2019 Justin England. All rights reserved.
//

import Foundation

class RTLTunerR820T: RTLTuner {
    
    private static let i2cAddress:      UInt8   = 0x34
    private static let checkAddress:    UInt8   = 0x00
    private static let checkValue:      UInt8   = 0x69
    private static let ifFrequency:     UInt32  = 3570000
    private static let maxI2CLength:    UInt8   = 8
    
    private var capSelect:       xtalCapValue   = .highCap0P

    enum xtalCapValue: UInt8 {
        case lowCap30P = 0
        case lowCap20P
        case lowCap10P
        case lowCap0P
        case highCap0P
    }
        
    private static let initRegisters: [UInt8] = [
        
        0x83, 0x32, 0x75,               /* 05 to 07 */
        0xc0, 0x40, 0xd6, 0x6c,         /* 08 to 0b */
        0xf5, 0x63, 0x75, 0x68,         /* 0c to 0f */
        0x6c, 0x83, 0x80, 0x00,         /* 10 to 13 */
        0x0f, 0x00, 0xc0, 0x30,         /* 14 to 17 */
        0x48, 0xcc, 0x60, 0x00,         /* 18 to 1b */
        0x54, 0xae, 0x4a, 0xc0          /* 1c to 1f */
        
    ]
    private static let registerStart            = 5
    private        var registerFile: [UInt8]    = []
        
    private var delegate:               RTLTunerDelegate
    
    class func isMatchingTuner(bootStrap: RTLTunerDelegate) -> RTLTuner? {

        var tuner: RTLTunerR820T? = nil
        
        bootStrap.enableI2CRepeaterForTuner(on: true)
        
        if(bootStrap.readI2CForTuner(deviceI2CAddress: i2cAddress, address: checkAddress) == checkValue) {
            tuner = RTLTunerR820T(delegate: bootStrap)
            print("Found Rafael Micro R828D tuner")
        }
        
        bootStrap.enableI2CRepeaterForTuner(on: false)
        
        return tuner
        
    }
    
    init(delegate: RTLTunerDelegate) {
        
        self.delegate = delegate
        super.init()
        
        //----------------------------------------------------------------------
        //
        // The following is the R820T init code from librtlsdr.  The original
        // C code is spread across librtlsdr.c and tuner_r82xx.c with calls
        // going back and forth.  This is my attempt at abstracting all of the
        // tuner code from the main rtlsdr code.
        //
        //----------------------------------------------------------------------
        
        /*
         
         dev->tun_xtal = dev->rtl_xtal;
         dev->tuner = &tuners[dev->tuner_type];
         
         */
         
         
         /* disable Zero-IF mode */
//         rtlsdr_demod_write_reg(dev, 1, 0xb1, 0x1a, 1);
        self.delegate.disableZeroIFModeForTuner()
         
         /* only enable In-phase ADC input */
//         rtlsdr_demod_write_reg(dev, 0, 0x08, 0x4d, 1);
        self.delegate.onlyEnableInPhaseADCInputForTuner()
         
         /* the R82XX use 3.57 MHz IF for the DVB-T 6 MHz mode, and
         * 4.57 MHz for the 8 MHz mode */
        self.delegate.setIFFrequencyForTuner(frequency: RTLTunerR820T.ifFrequency)
//         rtlsdr_set_if_freq(dev, R82XX_IF_FREQ);
         
         /* enable spectrum inversion */
        self.delegate.enableSpectrumInversionForTuner()
//         rtlsdr_demod_write_reg(dev, 1, 0x15, 0x01, 1);
        
        // initalize registers
        self.registerFile = RTLTunerR820T.initRegisters
        
        
         
        /*

         
         int r82xx_init(struct r82xx_priv *priv) {
            int rc;
         

         
            /* Initialize registers */
            rc = r82xx_write(priv, 0x05,
            r82xx_init_array, sizeof(r82xx_init_array));
         
            rc = r82xx_set_tv_standard(priv, 3, TUNER_DIGITAL_TV, 0);
            if (rc < 0)
                goto err;
         
            rc = r82xx_sysfreq_sel(priv, 0, TUNER_DIGITAL_TV, SYS_DVBT);
         
            priv->init_done = 1;
         
            err:
                if (rc < 0)
                    fprintf(stderr, "%s: failed=%d\n", __FUNCTION__, rc);
                return rc;
         }
         
                 int r820t_init(void *dev) {
                 
                    rtlsdr_dev_t* devt = (rtlsdr_dev_t*)dev;
                    devt->r82xx_p.rtl_dev = dev;
                 
                    if (devt->tuner_type == RTLSDR_TUNER_R828D) {
                        devt->r82xx_c.i2c_addr = R828D_I2C_ADDR;
                        devt->r82xx_c.rafael_chip = CHIP_R828D;
                    } else {
                        devt->r82xx_c.i2c_addr = R820T_I2C_ADDR;
                        devt->r82xx_c.rafael_chip = CHIP_R820T;
                    }

                    rtlsdr_get_xtal_freq(devt, NULL, &devt->r82xx_c.xtal);
         
                    devt->r82xx_c.max_i2c_msg_len = 8;
                    devt->r82xx_c.use_predetect = 0;
                    devt->r82xx_p.cfg = &devt->r82xx_c;
         
                    return r82xx_init(&devt->r82xx_p);
                 }

*/
        
    }
    
    func writeRegisters(startRegister: UInt8, registers: [UInt8], length: Int8) {
        
        
        
    }

}
