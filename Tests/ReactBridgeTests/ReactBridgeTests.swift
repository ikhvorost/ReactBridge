import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

import ReactBridgeMacros
import ReactBridge


@ReactModule
class A: NSObject {
  
  @ReactMethod
  @objc func hello(_ t: String, b: Bool) {
    print("Hello!")
  }
  
  @ReactViewProperty
  @objc var name: String?
}

final class ReactBridgeTests: XCTestCase {
  let testMacros: [String: Macro.Type] = [
    "ReactModule": ReactModuleMacro.self,
    "ReactMethod": ReactMethodMacro.self,
    "ReactViewProperty": ReactViewPropertyMacro.self
  ]
  
  func testReactModule() {
    
    assertMacroExpansion(
      """
      @ReactModule
      class A {
          @ReactMethod(jsName: "hello", isSync: true)
          func hello() {}
      
          @ReactViewProperty
          var name: String?
      }
      """,
      expandedSource: """
      """,
      macros: testMacros
    )
  }
}

