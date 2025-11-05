# ReactBridge

[![Swift 6.2, 6.1, 6.0](https://img.shields.io/badge/Swift-6.2%20|%206.1%20|%206.0-f48041.svg?style=flat&logo=swift)](https://developer.apple.com/swift)
![Platforms: iOS, macOS, tvOS, visionOS, watchOS](https://img.shields.io/badge/Platforms-iOS%20|%20macOS%20|%20tvOS%20|%20visionOS%20|%20watchOS%20-blue.svg?style=flat&logo=apple)
[![Swift Package Manager: compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-4BC51D.svg?style=flat&logo=apple)](https://swift.org/package-manager/)
[![React Native: 0.60](https://img.shields.io/badge/React%20Native-0.60-61dafb.svg?style=flat&logo=react)](https://reactnative.dev/)
[![Build](https://github.com/ikhvorost/ReactBridge/actions/workflows/swift.yml/badge.svg)](https://github.com/ikhvorost/ReactBridge/actions/workflows/swift.yml)
[![codecov](https://codecov.io/gh/ikhvorost/ReactBridge/graph/badge.svg?token=0MNGNA5W90)](https://codecov.io/gh/ikhvorost/ReactBridge)
[![Swift Doc Coverage](https://img.shields.io/badge/Swift%20Doc%20Coverage-100%25-f39f37?logo=google-docs&logoColor=white)](https://github.com/ikhvorost/swift-doc-coverage)

[![Donate](https://www.paypalobjects.com/en_US/i/btn/btn_donate_SM.gif)](https://www.paypal.com/donate/?hosted_button_id=TSPDD3ZAAH24C)

`ReactBridge` provides Swift macros for React Native to expose Native Modules and UI Components to JavaScript.

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
> `ReactBridge` requires to import `React` library.
> Swift class must be inherited from `NSObject` and must conform to `RCTBridgeModule` protocol.

The `@ReactModule` macro also takes optional `jsName` argument that specifies the name that will be accessible as in your JavaScript code:

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

Now that you have the native module available, you can invoke your native method `createEvent()`:

``` js
Calendar.createEvent('Wedding', 'Las Vegas');
```

**Callbacks**

Methods marked with `@ReactMethod` macro are asynchronous by default but if it's needed to pass data from Swift to JavaScript you can use the callback parameter with `RCTResponseSenderBlock` type:

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

Native modules can also fulfill promises, which can simplify your JavaScript, especially when using async/await syntax:

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

The JavaScript counterpart of this method returns a promise:

``` js
Calendar.createEvent('Wedding', 'Las Vegas')
  .then(eventId => {
    console.log(`Created a new event with id ${eventId}`);
  })
  .catch(error => {
    console.error(`Error: ${error}`);
  });
```

**Inheritance**

It's possible to inherit an other native module (which implements `RCTBridgeModule` protocol) and override existing or append additional functionality. For instance, to signal events to JavaScript you can subclass `RCTEventEmitter`:

``` swift
@ReactModule
class EventEmitter: RCTEventEmitter {
  
  static private(set) var shared: EventEmitter?
  
  override init() {
    super.init()
    Self.shared = self
  }
  
  override func supportedEvents() -> [String]! {
    ["EventReminder"]
  }
  
  func sendReminderEvent(title: String) {
    sendEvent(withName: "EventReminder", body: ["title" : title])
  }
}

...

EventEmitter.shared?.sendReminderEvent(title: "Dinner Party")
```

Then in JavaScript you can create `NativeEventEmitter` with your module and subscribe to a particular event:

``` js
const { EventEmitter } = NativeModules;

this.eventEmitter = new NativeEventEmitter(EventEmitter);
this.emitterSubscription = this.eventEmitter.addListener('EventReminder', event => {
  console.log(event); // Prints: { title: 'Dinner Party' }
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

For more complex properties you can pass `json` from JavaScript directly to native properties of your view (if they are implemented) or use `isCustom` argument to inform React Native that a custom setter is implemented on your view manager:

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
> The custom setter must have the following signature: `@objc func set_Name(_ value: Type, forView: ViewType?, withDefaultView: ViewType?)`

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
class NativeMapView: MKMapView {
  @objc var onRegionChange: RCTBubblingEventBlock?
}

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

### `@ReactModule`

The macro exports and registers a class as a native module for React Native.

``` swift
@ReactModule(jsName: String? = nil, requiresMainQueueSetup: Bool = false, methodQueue: DispatchQueue? = nil)
```

**Parameters**

- **jsName**: JavaScript module name. If omitted, the JavaScript module name will match the class name.
- **requiresMainQueueSetup**: Let React Native know if your module needs to be initialized on the main queue, before any JavaScript code executes. If value is `false` an class initializer will be called on a global queue. Defaults to `false`.
- **methodQueue**: The queue that will be used to call all exported methods. By default exported methods will call on a global queue.

### `@ReactMethod`

The macro exposes a method of a native module to JavaScript.

``` swift
@ReactMethod(jsName: String? = nil, isSync: Bool = false)
```

**Parameters**
- **jsName**: JavaScript method name. If omitted, the JavaScript method name will match the method name.
- **isSync**: Calling the method asynchronously or synchronously. If value is `true` the method is called from JavaScript synchronously on the JavaScript thread. Defaults to `false`.

> **Note**
> If you choose to use a method synchronously, your app can no longer use the Google Chrome debugger. This is because synchronous methods require the JS VM to share memory with the app. For the Google Chrome debugger, React Native runs inside the JS VM in Google Chrome, and communicates asynchronously with the mobile devices via WebSockets.

### `@ReactView`

The macro exports and registers a class as a native UI component for React Native.

``` swift
@ReactView(jsName: String? = nil)
```

**Parameters**
- **jsName**: JavaScript UI component name. If omitted, the JavaScript UI component name will match the class name.

### `@ReactProperty`

The macro exports a property of a native view to JavaScript.

``` swift
@ReactProperty(keyPath: String? = nil, isCustom: Bool = false)
```

**Parameters**
- **keyPath**: An arbitrary key path in the view to set a value.
- **isCustom**: Handling a property with a custom setter `@objc func set_Name(_ value: Type, forView: ViewType?, withDefaultView: ViewType?)` on a native UI component. Defaults to `false`.

## Requirements

- Xcode 15 or later.
- Swift 5.9 or later.
- React Native 0.60 or later.

## Installation

### XCode

1. Select `File > Add Package Dependencies...`. (Note: The menu options may vary depending on the version of Xcode being used.)
2. Enter the URL for the the package repository: `https://github.com/ikhvorost/ReactBridge.git`
3. Input a specific version or a range of versions for `Dependency Rule` and a need target for `Add to Project`.
4. Import the package in your source files: 
```
import React
import ReactBridge
...
```

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
