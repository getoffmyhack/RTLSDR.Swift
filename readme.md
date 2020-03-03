# RTLSDR.Swift

## Update Mar 2020

Back from a hiatus of not working on RTLSDR.Swift and [waveSDR](https://github.com/getoffmyhack/waveSDR).  Will start to finish my port of librtlsdr in the coming days - weeks.  Check build log for updates as I make progress.

## Intro

This is my attempt to port librtlsdr to Swift + IOKit to make it macOS native (and possibly iOS, but I am not an iOS programmer. (yet?))

From my first commit, until it is actually usable, almost everything may change, up to and including the name and this repository.  This is purely a learning exercise as I have written very little low-level USB code before, nor have I written much code that uses IOKit.  I will be using librtlsdr as my roadmap, and considering that it uses libusb for communication, I should be able to understand what is being done at the USB level as libusb is very well documented and example code is easy to find.

In my brief survey of the libusb code as used in librtlsdr, IOKit's IOUSBDevice structure (and related structures and objects) has many of the same functions and data structures as found in libusb, which match what I am finding within the USB 2.0 specs. Therefore, I should be able to map the same structures and function calls from libusb into their IOKit counterparts without too many issues.

The major point of difficulty will be in attempting to understand the internals of the RTLSDR dongles themselves.  I can easily port over the commands and data that is sent to the RTL device, but fully understanding what is happening at the chip side of my code will require some reverse engineering.  As I understand, and I could very well be wrong,  the data sheet is only available to companies who sign an NDA and order a truck ton of the RTL chips for use in their own product.

As I work on this project, I will try to document most of my findings in my build log directory, but as much as I will try to make it as readable as possible, it will also be my area where I put as many notes to myself as I can in order to understand what I am doing when I revisit the code later on.  Eventually, I will be migrating my build log entries to a Wordpress site as blog entries.

## macOS

I am building this as a macOS Framework such that it can be easily integrated into any Swift or Objective-C project.  It will use all native IOKit calls and will attempt to use the data structures and constants as defined in the IOKit.usb framework.

This is being developed in parallel with my macOS SDR application [waveSDR](https://github.com/getoffmyhack/waveSDR) and once I am able to receive a data stream of IQ samples from the device, I will start the process to migrate my waveSDR code from librtlsdr to this new RTLSDR.Swift framework.

## Contact

If you would like to drop a message to me, use my [Wordpress contact page ](https://getoffmyhack.wordpress.com/contact/) until I have a site more fully put together.

## Links

Here are the links to the resources that I am using to aid in my adventure:

* [librtlsdr](https://osmocom.org/projects/rtl-sdr/wiki/Rtl-sdr) -- The starting point for all things librtlsdr.
* [librtlsdr fork](https://github.com/librtlsdr/librtlsdr) -- The development branch has all the latest contributed updates to librtlsdr.
* [USB 2.0 Spec](https://www.usb.org/document-library/usb-20-specification) -- The specifications, all 650 pages of them.
* [USB in a Nutshell](https://www.beyondlogic.org/usbnutshell/usb1.shtml) -- A great detailed introduction to the USB 2.0 spec.
* [Softshell](https://github.com/hpux735/Softshell) -- An abandoned Objective-C / IOKit port of librtlsdr.  Helpful with IOKit.


## Apple Docs

Although the documents state that they are no longer being updated by Apple, these are the only documents available that describe the needed parts of the IOKit:
(The links may also change, so just google the title.)

* [IOKit Fundamentals](https://developer.apple.com/library/archive/documentation/DeviceDrivers/Conceptual/IOKitFundamentals/Introduction/Introduction.html)
* [Accessing Hardware from Applications](https://developer.apple.com/library/archive/documentation/DeviceDrivers/Conceptual/AccessingHardware/AH_Intro/AH_Intro.html)
* [USB Device Interface Guide](https://developer.apple.com/library/archive/documentation/DeviceDrivers/Conceptual/USBBook/USBIntro/USBIntro.html)

