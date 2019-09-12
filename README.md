# ESP-IDF Provisioning - iOS

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
Next, confirm that the version that you have installed is greater than `1.1.1`.

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

## Build

There are multiple app variants that you can build using this repository. You will need to select the right variant from the following available ones -


|XCode Project Scheme|Transport|Security Scheme|ESP-IDF Example| ESP-IDF Example menuconfig|
|:----:|:-------:|:------------:|:-------------:|:-------------------------:|
|WifiSec0 Debug|Wi-Fi|0|`examples/provisioning/softap_prov`|`Example Configuration` -> Deselect `Use Security Version 1`|
|WifiSec1 Debug|Wi-Fi|1|`examples/provisioning/softap_prov`|`Example Configuration` -> Select `Use Security Version 1`|
|BLESec0 Debug|BLE|0|`examples/provisioning/ble_prov`|`Example Configuration` -> Deselect `Use Security Version 1`|
|BLESec1 Debug|BLE|1|`examples/provisioning/ble_prov`|`Example Configuration` -> Select `Use Security Version 1`|
|BLESec1 Release|BLE|1|`examples/provisioning/ble_prov`|`Example Configuration` -> Select `Use Security Version 1`|
|WifiSec1 Release|Wi-Fi|1|`examples/provisioning/softap_prov`|`Example Configuration` -> Select `Use Security Version 1`|


For Security 1, for BLE or Wi-Fi, you can set an optional `Proof of Possession` key. Make sure that the key present in `Example Configuration` -> `Proof-of-possession` under ESP-IDF example menuconfig is the same as the one set in `Info.plist` file in the `./EspressifProvision/EspressifProvision/` folder


# Resources

* Documentation for the latest version: https://docs.espressif.com/projects/esp-idf/. This documentation is built from the [docs directory](docs) of this repository.

* The [esp32.com forum](https://esp32.com/) is a place to ask questions and find community resources.

* [Check the Issues section on github](https://github.com/espressif/esp-idf/issues) if you find a bug or have a feature request. Please check existing Issues before opening a new one.

* If you're interested in contributing to ESP-IDF, please check the [Contributions Guide](https://docs.espressif.com/projects/esp-idf/en/latest/contribute/index.html).
