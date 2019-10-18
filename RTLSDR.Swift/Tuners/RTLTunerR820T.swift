//
//  RTLTunerR820T.swift
//  RTLSDR.Swift
//
//  Created by Justin England on 6/9/19.
//  Copyright © 2019 Justin England. All rights reserved.
//

import Foundation

class RTLTunerR820T: RTLTuner {
    
    private static let i2cAddress:     UInt8 = 0x34
    private static let checkAddress:   UInt8 = 0x00
    private static let checkValue:     UInt8 = 0x69
    
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
         
         case RTLSDR_TUNER_R820T:
         /* disable Zero-IF mode */
         rtlsdr_demod_write_reg(dev, 1, 0xb1, 0x1a, 1);
         
         /* only enable In-phase ADC input */
         rtlsdr_demod_write_reg(dev, 0, 0x08, 0x4d, 1);
         
         /* the R82XX use 3.57 MHz IF for the DVB-T 6 MHz mode, and
         * 4.57 MHz for the 8 MHz mode */
         rtlsdr_set_if_freq(dev, R82XX_IF_FREQ);
         
         /* enable spectrum inversion */
         rtlsdr_demod_write_reg(dev, 1, 0x15, 0x01, 1);
         break;
         
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
         
         int r82xx_init(struct r82xx_priv *priv) {
            int rc;
         
            priv->xtal_cap_sel = XTAL_HIGH_CAP_0P;
         
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
        
*/
        
    }

}
