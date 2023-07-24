import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

import ReactBridgeMacros
import ReactBridge


@ReactModule
class A: NSObject {
  
  @ReactMethod
  func hello(_ text: String, flag: Bool, value: NSObject) {
  }
  
  @ReactViewProperty
  var name: [String : String]?
}

final class ReactBridgeTests: XCTestCase {
  let testMacros: [String: Macro.Type] = [
    "ReactModule": ReactModule.self,
    "ReactMethod": ReactMethod.self,
    "ReactViewProperty": ReactViewProperty.self
  ]
  
  func testReactModule() {
    
    assertMacroExpansion(
      """
      @ReactModule
      class A: NSObject {
      }
      """,
      expandedSource:
      """
      class A: NSObject {
          @objc static func moduleName() -> String! {
            String(describing: self)
          }
          @objc static func _registerModule() {
            RCTRegisterModule(self);
          }
      }
      extension A: RCTBridgeModule {
      }
      """,
      macros: testMacros
    )
  }
}

