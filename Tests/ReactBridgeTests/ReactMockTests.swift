import Foundation

typealias RCTBubblingEventBlock = ([String : Any]) -> Void

func RCTRegisterModule(_ cls: AnyClass) {
  print(#function, cls)
}

protocol RCTBridgeModule {
}

class RCTViewManager: NSObject {
  class func moduleName() -> String! { "" }
  class func requiresMainQueueSetup() -> Bool { false }
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
