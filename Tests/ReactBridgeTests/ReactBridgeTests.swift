import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

import ReactBridgeMacros
import ReactBridge

let macros: [String: Macro.Type] = [
  "ReactModule": ReactModule.self,
  "ReactMethod": ReactMethod.self,
  "ReactViewProperty": ReactViewProperty.self
]

@ReactModule()
class A: NSObject {
}

final class ReactModuleTests: XCTestCase {
  
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
            "\\(self)"
          }
          @objc static func _registerModule() {
            RCTRegisterModule(self);
          }
      }
      extension A: RCTBridgeModule {
      }
      """,
      macros: macros
    )
  }
}

