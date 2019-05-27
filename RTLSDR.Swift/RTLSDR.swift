//
//  RTLSDR.swift
//  RTLSDR.Swift
//
//  Copyright © 2019 GetOffMyHack
//

import Foundation
import IOKit
import IOKit.usb

class RTLSDR: NSObject {

    private override init(/* device: USBDevice */) {
        
        // the init method will require a USBDevice struct that is a
        // known RTLSDR device.  This will be a private method and only
        // callable from a class factory method that determines if the
        // USBDevice is an RTL device, and if so, will call init.
        
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



