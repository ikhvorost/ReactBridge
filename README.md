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
import React
import ReactBridge

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

Now the native module can then be accessed in JavaScript like this:

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

To expose a native view you should attach `@ReactView` macro to a subclass of `RCTViewManager` that is also typically the delegate for the view, sending events back to JavaScript via the bridge.

``` swift
import React
import ReactBridge
import MapKit

@ReactView
class MapView: RCTViewManager {

  override func view() -> UIView {
    MKMapView()
  }
}
```

Then you need a little bit of JavaScript to make this a usable React component:

``` js
import {requireNativeComponent} from 'react-native';

const MapView = requireNativeComponent('MapView');

... 
render() {
  return <MapView style={{flex: 1}} />;
}
```

**Properties**

To bridge over some native properties of a native view we can declare properties with the same name on our view manager class and mark them with `@ReactProperty` macro. Let's say we want to be able to disable zooming:

``` swift
@ReactView
class MapView: RCTViewManager {

  @ReactProperty
  var zoomEnabled: Bool?

  override func view() -> UIView {
    MKMapView()
  }
}
```

> **Note**
> The target properties of a view must be visible for Objective-C.

Now to actually disable zooming, we set the property in JavaScript:

``` js
<MapView style={{flex: 1}} zoomEnabled={false} />
```

For more complex properties you can pass `json` from JavaScript directly to native properties of your view (if they are implemented) or use `isCustom` argument to inform React Native that a custom setter is on your view manager:

``` swift
@ReactView
class MapView: RCTViewManager {

  @ReactProperty
  var zoomEnabled: Bool?
  
  @ReactProperty(isCustom: true)
  var region: [String : Double]?
  
  @objc 
  func set_region(_ json: [String : Double]?, forView: MKMapView?, withDefaultView: MKMapView?) {
    guard let latitude = json?["latitude"],
          let latitudeDelta = json?["latitudeDelta"],
          let longitude = json?["longitude"],
          let longitudeDelta = json?["longitudeDelta"]
    else {
      return
    }
    
    let region = MKCoordinateRegion(
      center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), 
      span: MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
    )
    forView?.setRegion(region, animated: true)
  }
  
  override func view() -> UIView {
    MKMapView()
  }
}
```

> **Note**
> The custom setter must have the following signature: `@objc func set_NAME(_ json: TYPE?, forView: VIEW_TYPE?, withDefaultView: VIEW_TYPE?)`

JavaScript code with `region` property:

``` js
<MapView
  style={{flex: 1}}
  zoomEnabled={false}
  region={{
    latitude: 37.48,
    longitude: -122.1,
    latitudeDelta: 0.1,
    longitudeDelta: 0.1,
  }}
/>
```

**Events**

To deal with events from the user like changing the visible region we can map input event handlers from JavaScript to native view properties with `RCTBubblingEventBlock` type.

Lets add new `onRegionChange` property to a subclass of MKMapView:

``` swift
@ReactView
class MapView: RCTViewManager {
  
  @ReactProperty
  var onRegionChange: RCTBubblingEventBlock?
  
  override func view() -> UIView {
    let mapView = NativeMapView()
    mapView.delegate = self
    return mapView
  }
}

extension MapView: MKMapViewDelegate {
  
  func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
    guard let mapView = mapView as? NativeMapView else {
      return
    }
    
    let region = mapView.region
    mapView.onRegionChange?([
      "latitude": region.center.latitude,
      "longitude": region.center.longitude,
      "latitudeDelta": region.span.latitudeDelta,
      "longitudeDelta": region.span.longitudeDelta,
    ])
  }
}

class NativeMapView: MKMapView {
  @objc var onRegionChange: RCTBubblingEventBlock?
}
```

> **Note**
> All properties with `RCTBubblingEventBlock` must be prefixed with `on` and marked with `@objc`.

Calling the `onRegionChange` event handler property results in calling the same callback property in JavaScript:

``` js
function App(): JSX.Element {
  ...

  this.onRegionChange = event => {
    const region = event.nativeEvent;
    console.log(region.latitude)
  };

  return (
    <MapView
      style={{flex: 1}}
      onRegionChange={this.onRegionChange}
    />
  );
}
```



For more details about Native UI Components, see: https://reactnative.dev/docs/native-components-ios.

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
