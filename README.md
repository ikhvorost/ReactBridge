# ReactBridge

[![Swift 5.9](https://img.shields.io/badge/Swift-5.9-f48041.svg?style=flat&logo=swift)](https://developer.apple.com/swift)
[![React Native 0.60](https://img.shields.io/badge/React%20Native-0.60-61dafb.svg?style=flat&logo=react)](https://reactnative.dev/)
[![SwiftPM compatible](https://img.shields.io/badge/SwiftPM-compatible-4BC51D.svg?style=flat&logo=apple)](https://swift.org/package-manager/)
![Platforms: iOS, macOS, tvOS, watchOS](https://img.shields.io/badge/Platforms-iOS%20|%20macOS%20|%20tvOS%20|%20watchOS%20-blue.svg?style=flat&logo=apple)
[![Build](https://github.com/ikhvorost/ReactBridge/actions/workflows/swift.yml/badge.svg?branch=main)](https://github.com/ikhvorost/ReactBridge/actions/workflows/swift.yml)
[![Codecov](https://codecov.io/gh/ikhvorost/ReactBridge/branch/main/graph/badge.svg?token=26NymxLQyB)](https://codecov.io/gh/ikhvorost/ReactBridge)

[![Donate](https://www.paypalobjects.com/en_US/i/btn/btn_donate_SM.gif)](https://www.paypal.com/donate/?hosted_button_id=TSPDD3ZAAH24C)

`ReactBridge` provides Swift macros to expose Native Modules with their methods and Native UI Components to JavaScript.

- [Getting Started](#getting-started)
  - [Native Module](#native-module)
  - [Native UI Component](#native-ui-component)
- [Documentation](#documentation)
  - [`@ReactModule`](#reactmodule)
  - [`@ReactMethod`](#reactmethod)
  - [`@ReactView`](#reactview)
  - [`@ReactProperty`](#reactproperty)
- [Requirements](#requirements)
- [Installation](#installation)
  - [XCode](#xcode)
  - [Swift Package](#swift-package)
- [Licensing](#licensing)

## Getting Started

### Native Module

Attach `@ReactModule` macro to your class definition and it exports and registers the native module class with React Native and that will allow you to access its code from JavaScript:

``` swift
@ReactModule
class CalendarModule: NSObject, RCTBridgeModule {
}
```

> **Note**
> Swift class must be inherited from `NSObject` and must conform to `RCTBridgeModule` protocol.

The `@ReactModule` macro also takes optional `jsName` argument that specifies the name that the module will be accessible as in your JavaScript code:

``` swift
@ReactModule(jsName: "Calendar")
class CalendarModule: NSObject, RCTBridgeModule {
}
```

> **Note**
> If you do not specify a name, the JavaScript module name will match the Swift class name.

The native module can then be accessed in JavaScript like this:

``` js
import { NativeModules } from 'react-native';
const { Calendar } = NativeModules;
```

**Methods**

React Native will not expose any methods in a native module to JavaScript unless explicitly told to. This can be done using the `@ReactMethod` macro:

``` swift
@ReactModule(jsName: "Calendar")
class CalendarModule: NSObject, RCTBridgeModule {
  
  @ReactMethod
  @objc func createEvent(title: String, location: String) {
    print("Create event '\(title)' at '\(location)'")
  }
}
```

> **Note**
> The exported method must be marked with `@objc` attribute.

Now that you have the `CalendarModule` native module available, you can invoke your native method `createEvent()`:

``` js
Calendar.createEvent('Wedding', 'Las Vegas');
```

**Callbacks**

Methods marked with `@ReactMethod` macro are asynchronous by default but if it's needed to to pass data from Swift to JavaScript you can use the callback parameter with type `RCTResponseSenderBlock`: 

``` swift
@ReactMethod
@objc func createEvent(title: String, location: String, callback: RCTResponseSenderBlock) {
  print("Create event '\(title)' at '\(location)'")
  let eventId = 10;
  callback([eventId])
}
```

This method could then be accessed in JavaScript using the following:

``` js
Calendar.createEvent('Wedding', 'Las Vegas', eventId => {
  console.log(`Created a new event with id ${eventId}`);
});
```

**Promises**

Native modules can also fulfill a promise, which can simplify your JavaScript, especially when using async/await syntax:

``` swift
@ReactMethod
@objc func createEvent(title: String, location: String, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
  do {
    let eventId = try createEvent(title: title, location: location)
    resolve(eventId)
  }
  catch let error as NSError {
    reject("\(error.code)", error.localizedDescription, error)
  }
}
```

The JavaScript counterpart of this method returns a Promise:

``` js
Calendar.createEvent('Wedding', 'Las Vegas')
  .then(eventId => {
    console.log(`Created a new event with id ${eventId}`);
  })
  .catch(error => {
    console.error(`Error: ${error}`);
  });
```

For more details about Native Modules, see: https://reactnative.dev/docs/native-modules-ios.

### Native UI Component

## Documentation

### @ReactModule

### @ReactMethod

### @ReactView

### @ReactProperty

## Requirements

- Xcode 15 or later.
- Swift 5.9 or later.
- React Native 0.60 or later.

## Installation

### XCode

1. Select `File > Add Package Dependencies...`. (Note: The menu options may vary depending on the version of Xcode being used.)
2. Enter the URL for the the package repository: `https://github.com/ikhvorost/ReactBridge.git`
3. Input a specific version or a range of versions for `Dependency Rule` and a need target for `Add to Project`.
4. Import the package in your source files: `import ReactBridge`.

### Swift Package

For a swift package you can add `ReactBridge` directly to your dependencies in your `Package.swift` file:

```swift
let package = Package(
    ...
    dependencies: [
        .package(url: "https://github.com/ikhvorost/ReactBridge.git", from: "1.0.0")
    ],
    targets: [
        .target(name: "YourPackage",
            dependencies: [
                .product(name: "ReactBridge", package: "ReactBridge")
            ]
        ),
        ...
    ...
)
```

## Licensing

This project is licensed under the MIT License. See [LICENSE](LICENSE) for more information.

[![Donate](https://www.paypalobjects.com/en_US/i/btn/btn_donate_SM.gif)](https://www.paypal.com/donate/?hosted_button_id=TSPDD3ZAAH24C)
