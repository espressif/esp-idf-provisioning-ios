
# ESPProvision

ESPProvision is a provisioning library written in Swift. It provides mechanism to provide network credentials and/or custom data to an ESP32, ESP32-S2 or ESP8266 devices.

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#using-ESPProvision)
    - [****Introduction****](#introduction)
    - [****Getting ESPDevice****](#getting-ESPDevice)
    - [****Provisioning****](#provisioning)
- [License](#license)
- [API Documentation](https://espressif.github.io/esp-idf-provisioning-ios/)

## Features

- [x] Search for available BLE devices.
- [x] Scan device QR code to provide reference to ESP device.
- [x] Create reference of ESPDevice manually.
- [x] Data Encryption
- [x] Data transmission through BLE and SoftAP.
- [x] Provision device.
- [x] Scan for available Wi-Fi networks.
- [x] Console logs
- [x] Support for security version 2.


## Requirements

- iOS 13.0+ / macOS 10.12+
- Xcode 13+
- Swift 5.1+
- Enable Hotspot Configuration capability in Xcode.
- Enable Access WiFI Information capability in Xcode.

## Installation

### CocoaPods

[CocoaPods](https://cocoapods.org) is a dependency manager for Cocoa projects. For usage and installation instructions, visit their website. To integrate ESPProvision into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby

pod 'ESPProvision'

```

### Swift Package Manager

The [Swift Package Manager](https://swift.org/package-manager/) is a tool for automating the distribution of Swift code and is integrated into the `swift` compiler. 

Once you have your Swift package set up, adding ESPProvision as a dependency is as easy as adding it to the `dependencies` value of your `Package.swift`.

```swift
dependencies: [
    .package(url: "https://github.com/espressif/esp-idf-provisioning-ios.git", from: "2.1.1")
]
```

### ...using Xcode

If you are using Xcode, then you should add this SwiftPM package as dependency of your xcode project:
  [Apple Docs](https://developer.apple.com/documentation/swift_packages/adding_package_dependencies_to_your_app)


## Using ESPProvision

## Introduction

ESPProvision provides a simpler mechanism to communicate with an ESP-32, ESP32-S2 and ESP8266 devices. It gives an efficient search and scan model to listen and return devices which are in provisioning mode. ESProvision embeds security protocol and allow for safe transmission of data by doing end to end encryption. It supports BLE and SoftAP as mode of transmission which are configurable at runtime. Its primarily use is to provide home network credentials to a device and ensure device connectivity status is returned to the application.


## Getting ESPDevice

`ESPDevice` object is virtual representation of ESP-32/ESP32-S2/ESP8266 devices. It provides interface to interact with devices directly in a simpler manner. `ESPProvisionManager` is a singleton class that encompasses APIs for managing these objects. `ESPDevice` instances can be obtained from any of the following techniques : 


### Search

ESPProvision supports searching of BLE devices which are currently in provisioning mode. It returns list of devices that are discoverable and matches the parameter criteria.

```swift

ESPProvisionManager.shared.searchESPDevices(devicePrefix:"Prefix",    transport:.ble, security:.secure) { deviceList, _ in
}

```

> Transport parameter is medium of data transmission, ESPProvision support .softAP and .ble transport.
> Security parameter describe if connection needed to be secure or unsecure.
> SoftAP search is not supported in iOS currently.


### Scan

Device information can be extracted from scanning valid QR code. User of this API decides the camera preview layer frame by providing `UIView` as parameter. It return single `ESPDevice` instance on success. Supports both SoftAP and BLE.

```swift

ESPProvisionManager.shared.scanQRCode(scanView: scannerView) { espDevice, _ in
}

```


### Create

`ESPDevice` can be also created by passing necessary parameters as argument of below function.

```swift

ESPProvisionManager.shared.createESPDevice(deviceName: deviceName, transport: transport, security: security){ espDevice, _ in
}

```



## Provisioning

The main feature of ESPProvision library is to provision ESP devices. Once we get instance of `ESPDevice` from above APIs we need to establish session with the device before we can transmit/receive data from it. This can be achieved by calling `connect` as shown below :

```swift

espDevice.connect(delegate: self) { status in
}

```
> Delegate is required to get Proof of Possession from user, if device has pop capability.

Return proof of possession for the device as shown below from delegate class :

```swift

func getProofOfPossesion(forDevice: ESPDevice, completionHandler: @escaping (String) -> Void) {
    completionHandler(proofOfPossession)
}

```

For security version 2, provide username as shown below from delegate class :

```swift

func getUsername(forDevice: ESPProvision.ESPDevice, completionHandler: @escaping (String?) -> Void) {
    completionHandler(username)
}

```


If status is connected then application can proceed to scan list of available networks visible to device. This list can be used to give option to the user to choose network of their own choice.

```swift

espDevice.scanWifiList { wifiList, _ in 
}

```

User can choose to apply Wi-Fi settings from the above list or choose other Wi-Fi network to provision the device.

```swift

espDevice.provision(ssid: ssid, passPhrase: passphrase) { status in
}

```

## Permissions

- Since iOS 13, apps that want to access SSID (Wi-Fi network name) are required to have the location permission. Add key `NSLocationWhenInUseUsageDescription` in Info.plist with proper description. This permission is required to verify iOS device is currently connected with the SoftAP. 

- Since iOS 14, apps that communicate over local network are required to have the local network permission. Add key `NSLocalNetworkUsageDescription` in Info.plist with proper description. This permission is required to send/receive provisioning data with the SoftAP devices.



## License

ESPProvision is released under the Apache License Version 2.0.
