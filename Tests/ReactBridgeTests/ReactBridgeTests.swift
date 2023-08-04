import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

@testable import ReactBridgeMacros
import ReactBridge


//let macros: [String: Macro.Type] = [
//  "ReactModule": ReactModule.self,
//  "ReactMethod": ReactMethod.self,
//  "ReactViewManager": ReactViewManager.self
//]

@ReactModule
class A: NSObject {
//
//  @ReactMethod(isSync: true)
//  @objc func test(value: String) -> NSNumber {
//    return 200
//  }
}

@ReactViewManager(jsName: "NativeView", properties: ["text" : String.self])
class B: RCTViewManager {
}

final class ReactMethodTests: XCTestCase {
  
  let macros: [String: Macro.Type] = [
    "ReactMethod": ReactMethod.self,
  ]
  
  func test_error_funcOnly() {
    assertMacroExpansion(
      """
      class A {
        @ReactMethod
        @objc func test(text: Dictionary<String, Int>) {
        }
      }
      """,
      expandedSource:
      """
      """,
      macros: macros
    )
  }
}

final class ReactModuleTests: XCTestCase {
  
  let macros: [String: Macro.Type] = [
    "ReactModule": ReactModule.self,
  ]
  
  func test_error_classOnly() {
    let diagnostic = DiagnosticSpec(message: ReactModule.Message.classOnly.message, line: 1, column: 1)
        
    assertMacroExpansion(
      """
      @ReactModule
      struct A {
      }
      """,
      expandedSource:
      """
      struct A {
      }
      """,
      diagnostics: [diagnostic],
      macros: macros
    )
  }
  
  func test_error_inheritNSObject() {
    let diagnostic = DiagnosticSpec(message: ReactModule.Message.inheritNSObject(name: "A").message, line: 1, column: 1)
    
    assertMacroExpansion(
      """
      @ReactModule
      class A {
      }
      """,
      expandedSource:
      """
      class A {
      }
      """,
      diagnostics: [diagnostic],
      macros: macros
    )
  }
  
  func test() {
    assertMacroExpansion(
      """
      @ReactModule(jsName: "A", requiresMainQueueSetup: true)
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


final class ReactViewManagerTests: XCTestCase {
  let macros: [String: Macro.Type] = [
    "ReactViewManager": ReactViewManager.self,
  ]
  
  func test_error_classOnly() {
    assertMacroExpansion(
      """
      @ReactViewManager(jsName: "NativeView", properties: ["test" : String.self])
      class A: RCTViewManager {
      }
      """,
      expandedSource:
      """
      """,
      macros: macros
    )
  }
  
}

