//*
import Foundation
import ReactBridge

// MARK: - React Mock

typealias RCTDirectEventBlock = ([String : Any]) -> Void
typealias RCTBubblingEventBlock = ([String : Any]) -> Void
typealias RCTCapturingEventBlock = ([String : Any]) -> Void
typealias RCTPromiseResolveBlock = (Any) -> Void
typealias RCTPromiseRejectBlock = (String, String, NSError) -> Void

func RCTRegisterModule(_ cls: AnyClass) {
}

@objc
protocol RCTBridgeModule {
  @objc static func moduleName() -> String!
  @objc static optional func requiresMainQueueSetup() -> Bool
  
  @objc optional var methodQueue: DispatchQueue { get }
}

class RCTEventEmitter: RCTBridgeModule {
  class func moduleName() -> String! { "" }
  class func requiresMainQueueSetup() -> Bool { false }
}

class RCTViewManager: NSObject {
  class func moduleName() -> String! { "" }
  class func requiresMainQueueSetup() -> Bool { false }
  var methodQueue: DispatchQueue { .main }
}

class RCTMethodInfo: NSObject {
  let jsName: UnsafePointer<CChar>?
  let objcName: UnsafePointer<CChar>?
  let isSync: Bool
  
  init(jsName: UnsafePointer<CChar>?, objcName: UnsafePointer<CChar>?, isSync: Bool) {
    self.jsName = jsName
    self.objcName = objcName
    self.isSync = isSync
  }
}

// MARK: - Sandbox

@ReactModule(jsName: "Calendar")
class CalendarModule: NSObject, RCTBridgeModule {
  @ReactMethod
  @objc func createEvent(title: String, location: String) {
    print("Create event '\(title)' at '\(location)'")
  }
  
  @ReactMethod
  @objc func createEvent2(title: String, location: String, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
    print("Create event '\(title)' at '\(location)'")
  }
}

@ReactModule
class EventEmitter: RCTEventEmitter {
}

@ReactView
class MapView: RCTViewManager {
  @ReactProperty
  var zoomEnabled: Bool?
  
  @ReactProperty
  var onRegionChange: RCTBubblingEventBlock?
}
// */
