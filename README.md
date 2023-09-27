# ReactBridge

[![Swift 5](https://img.shields.io/badge/Swift-5-f48041.svg?style=flat)](https://developer.apple.com/swift)
![Platforms: iOS, macOS, tvOS, watchOS](https://img.shields.io/badge/Platforms-iOS%20|%20macOS%20|%20tvOS%20|%20watchOS%20-blue.svg?style=flat)
[![Swift Package Manager: compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-4BC51D.svg?style=flat)](https://swift.org/package-manager/)
[![Build](https://github.com/ikhvorost/KeyValueCoding/actions/workflows/swift.yml/badge.svg?branch=main)](https://github.com/ikhvorost/KeyValueCoding/actions/workflows/swift.yml)
[![Codecov](https://codecov.io/gh/ikhvorost/KeyValueCoding/branch/main/graph/badge.svg?token=26NymxLQyB)](https://codecov.io/gh/ikhvorost/KeyValueCoding)
[![Swift Doc Coverage](https://img.shields.io/badge/Swift%20Doc%20Coverage-100%25-f39f37)](https://github.com/SwiftDocOrg/swift-doc)

[![Donate](https://www.paypalobjects.com/en_US/i/btn/btn_donate_SM.gif)](https://www.paypal.com/donate/?hosted_button_id=TSPDD3ZAAH24C)

Description

- [Getting Started](#getting-started)
  - [Native Module](#nativemodule)
  - [Native UI Component](#nativeuicomponent)
- [Macros](#macros)
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

## Requirements

- Xcode 15 or later.
- Swift 5.9 or later.

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






