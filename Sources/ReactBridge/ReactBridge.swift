//
//  ReactBridge.swift
//
//  Created by Iurii Khvorost <iurii.khvorost@gmail.com> on 2023/07/24.
//  Copyright © 2023 Iurii Khvorost. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation
@_exported import ReactBridgeUtils


/// The macro exports and registers a class as a native module for React Native.
///
/// Attach this macro to your class definition to automatically register your module with the bridge when it loads.
///
///     @ReactModule
///     class Calendar: NSObject, RCTBridgeModule {
///     }
///
/// - Parameters:
///   - jsName: JavaScript module name. If omitted, the JavaScript module name will match the class name.
///   - requiresMainQueueSetup: Let React Native know if your module needs to be initialized on the main queue, before any JavaScript code executes. If value is `false` an class initializer will be called on a global queue. Defaults to `false`.
///   - methodQueue: The queue that will be used to call all exported methods. By default exported methods will call on a global queue.
///
@attached(member, names: named(_registerModule), named(moduleName), named(requiresMainQueueSetup), named(methodQueue))
public macro ReactModule(
  jsName: String? = nil,
  requiresMainQueueSetup: Bool = false,
  methodQueue: DispatchQueue? = nil
) = #externalMacro(module: "ReactBridgeMacros", type: "ReactModule")

/// The macro exposes a method of a native module to JavaScript.
///
/// Attach this macro to your method definition to  expose it explicitly to JavaScript.
///
///     @ReactModule
///     class Calendar: NSObject, RCTBridgeModule {
///
///       @ReactMethod
///       @objc func createEvent(name: String, location: String) {}
///     }
///
/// - Parameters:
///   - jsName: JavaScript method name. If omitted, the JavaScript method name will match the method name.
///   - isSync: Calling the method asynchronously or synchronously. If value is `true` the method is called from JavaScript synchronously on the JavaScript thread. Defaults to `false`.
///
@attached(peer, names: prefixed(__rct_export__))
public macro ReactMethod(jsName: String? = nil, isSync: Bool = false) = #externalMacro(module: "ReactBridgeMacros", type: "ReactMethod")

/// The macro exports and registers a class as a native UI component for React Native.
///
/// Attach this macro to your class definition to automatically register your native UI component with the bridge when it loads.
///
///     @ReactView
///     class MapView: RCTViewManager {
///
///       override func view() -> UIView! {
///         MKMapView()
///       }
///     }
///
/// - Parameters:
///   - jsName: JavaScript UI component name. If omitted, the JavaScript UI component name will match the class name.
///
@attached(member, names: named(_registerModule), named(moduleName), named(requiresMainQueueSetup), named(methodQueue))
public macro ReactView(jsName: String? = nil) = #externalMacro(module: "ReactBridgeMacros", type: "ReactView")

/// The macro exports a property of a native view to JavaScript.
///
/// Attach this macro to your property definition to exports it explicitly to JavaScript.
///
///     @ReactView
///     class MapView: RCTViewManager {
///
///       @ReactProperty
///       var zoomEnabled: Bool?
///
///       override func view() -> UIView! {
///         MKMapView()
///       }
///     }
///
/// - Parameters:
///   - keyPath: An arbitrary key path in the view to set a value.
///   - isCustom: Handling a property with a custom setter `@objc func set_Name(_ value: Type, forView: ViewType?, withDefaultView: ViewType?)` on a native UI component. Defaults to `false`.
///
@attached(peer, names: prefixed(propConfig_))
public macro ReactProperty(keyPath: String? = nil, isCustom: Bool = false) = #externalMacro(module: "ReactBridgeMacros", type: "ReactProperty")
