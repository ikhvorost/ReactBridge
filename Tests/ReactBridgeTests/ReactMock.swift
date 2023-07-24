import Foundation


func RCTRegisterModule(_ cls: AnyClass) {
  print(#function, cls)
}

protocol RCTBridgeModule: NSObjectProtocol {
  static func moduleName() -> String!
}

@objcMembers
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
