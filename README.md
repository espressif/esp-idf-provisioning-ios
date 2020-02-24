# ESP-IDF Provisioning - iOS: AVS

ESP-IDF consists of a provisioning mechanism, which is used to provide network credentials and/or custom data to an ESP32 device.
This repository contains the source code for the companion iOS app for this provisioning mechanism.

This is licensed under Apache 2.0. The complete license for the same can be found in the LICENSE file.

## Setup

To build this app, you will need a macOS development machines, with XCode installed. Make sure you have a developer account with Apple setup. More about the same can be found [here](https://developer.apple.com/support/compare-memberships/)

### Install Dependencies
#### swiftformat
The app depends on `swiftformat`. To install the same, you will need `brew`. Brew can be installed from [brew.sh](https://brew.sh). Once you have `brew` installed and setup, run -

```
brew install swiftformat
```

#### protoc-gen-swift
We use protobuf files across different platforms(C, iOS, Android, Python) to serialize the data to be sent. The source files are the same across all these platforms and can be found in the `proto` directory in the root folder of this repository.

To convert these files to swift, we need `protoc-gen-swift`. We depend on version `1.0.3` of the same. This is part of [swift-protobuf](https://github.com/apple/swift-protobuf) project maintained by Apple Inc. This project consists of two things -
 - a runtime library
 - a command line utility

The runtime library is installed as part of the next section. In this section, we will install the `protoc-gen-swift` command line utility.

To install, run the following command -

```
brew install swift-protobuf
```
Next, confirm that the version that you have installed is `1.1.1`.

```
$ protoc-gen-swift --version
protoc-gen-swift 1.1.1
```

Note that this version need to match the version number of SwiftProtobuf in `EspressifProvision/Podfile`


#### Cocoapods
Make sure you have Cocoapods installed. Installation steps can be found on [cocoapods.org](https://cocoapods.org)  
Now navigate to `EspressifProvision` directory from the root directory, and run -

```
pod install
```

This ensures that you have the following dependencies installed -
- SwiftProtobuf
- Curve25519

### Get Alexa credentials

As we are building a mobile application that will provision network credentials as well AVS credentials, we will need to associate our application with a security profile for LWA (`Login with Amazon`).

`Login with Amazon` is Amazon's OAuth2 provider. It allows third party developers like us to enable the user to use their existing Amazon account to sign in through our ESP32 device.

### Build Settings

- Enter a unique bundle identifier for your application in TARGETS -> General under Identity section.
- Generate API key for this bundle id from LWA console. Put this as value for "APIKey" in Info.plist.

Now your app is ready to build.

# Resources

* Documentation for the latest version: https://docs.espressif.com/projects/esp-idf/. This documentation is built from the [docs directory](docs) of this repository.

* The [esp32.com forum](https://esp32.com/) is a place to ask questions and find community resources.

* [Check the Issues section on github](https://github.com/espressif/esp-idf/issues) if you find a bug or have a feature request. Please check existing Issues before opening a new one.

* Check out the latest release of this version on App Store [iOS Alexa app](https://apps.apple.com/app/esp-alexa/id1464127534) .

