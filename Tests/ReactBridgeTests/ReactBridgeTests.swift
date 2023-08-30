import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

@testable import ReactBridgeMacros

//*
import ReactBridge

@ReactModule()
class A: NSObject, RCTBridgeModule {

  @ReactMethod(isSync: true)
  @objc func test(value: Int) -> Any {
    return 200
  }
}

@ReactView(
  properties: [
    "title": String,
    "count" : Int,
    "onData": RCTBubblingEventBlock,
    "config": [String: Any]
  ]
)
class NativeView: RCTViewManager {
}

// */

final class ReactMethodTests: XCTestCase {
  
  let macros: [String: Macro.Type] = [
    "ReactMethod": ReactMethod.self,
  ]
  
  func test_error_funcOnly() {
    assertMacroExpansion(
      """
      class A {
        @ReactMethod(isSync: true)
        @objc func test(text: String) -> CGColor? {
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
  
  private let macros: [String: Macro.Type] = [
    "ReactModule": ReactModule.self
  ]
  
  func test_struct() {
    let diagnostic = DiagnosticSpec(message: ErrorMessage.classOnly(macroName: "ReactModule").message, line: 1, column: 1)
        
    assertMacroExpansion(
      """
      @ReactModule
      struct A {}
      """,
      expandedSource:
      """
      struct A {}
      """,
      diagnostics: [diagnostic],
      macros: macros
    )
  }
  
  func test_NSObject() {
    let diagnostic = DiagnosticSpec(message: ErrorMessage.mustInherit(className: "A", superclassName: "NSObject").message, line: 2, column: 7)
    
    assertMacroExpansion(
      """
      @ReactModule
      class A {}
      """,
      expandedSource:
      """
      class A {}
      """,
      diagnostics: [diagnostic],
      macros: macros
    )
  }
  
  func test_RCTBridgeModule() {
    let diagnostic = DiagnosticSpec(message: ErrorMessage.mustConform(className: "A", protocolName: "RCTBridgeModule").message, line: 2, column: 7)
    
    assertMacroExpansion(
      """
      @ReactModule
      class A: NSObject {}
      """,
      expandedSource:
      """
      class A: NSObject {}
      """,
      diagnostics: [diagnostic],
      macros: macros
    )
  }
  
  func test_default() {
    assertMacroExpansion(
      """
      @ReactModule
      class A: NSObject, RCTBridgeModule {
      }
      """,
      expandedSource:
      """
      class A: NSObject, RCTBridgeModule {
      
          @objc static func _registerModule() {
            RCTRegisterModule(self);
          }
      }
      
      extension A { // RCTBridgeModule
        @objc class func moduleName() -> String! {
          "A"
        }
      
        @objc class func requiresMainQueueSetup() -> Bool {
          false
        }
      }
      """,
      macros: macros
    )
  }
  
  func test_params() {
    assertMacroExpansion(
      """
      @ReactModule(jsName: "ModuleA", requiresMainQueueSetup: true, methodQueue: .main)
      class A: NSObject, RCTBridgeModule {
      }
      """,
      expandedSource:
      """
      class A: NSObject, RCTBridgeModule {
      
          @objc static func _registerModule() {
            RCTRegisterModule(self);
          }
      }
      
      extension A { // RCTBridgeModule
        @objc class func moduleName() -> String! {
          "ModuleA"
        }

        @objc class func requiresMainQueueSetup() -> Bool {
          true
        }

        @objc var methodQueue: DispatchQueue {
          .main
        }
      }
      """,
      macros: macros
    )
  }
}


final class ReactViewTests: XCTestCase {
  let macros: [String: Macro.Type] = [
    "ReactView": ReactView.self,
  ]
  
  func test_struct() {
    let diagnostic = DiagnosticSpec(message: ErrorMessage.classOnly(macroName: "ReactView").message, line: 1, column: 1)
    
    assertMacroExpansion(
      """
      @ReactView
      struct View {}
      """,
      expandedSource:
      """
      struct View {}
      """,
      diagnostics: [diagnostic],
      macros: macros
    )
  }
  
  func test_RCTViewManager() {
    let diagnostic = DiagnosticSpec(message: ErrorMessage.mustInherit(className: "View", superclassName: "RCTViewManager").message, line: 2, column: 7)
    
    assertMacroExpansion(
      """
      @ReactView
      class View {}
      """,
      expandedSource:
      """
      class View {}
      """,
      diagnostics: [diagnostic],
      macros: macros
    )
  }
  
  func test_default() {
    assertMacroExpansion(
      """
      @ReactView
      class View: RCTViewManager {
      }
      """,
      expandedSource:
      """
      class View: RCTViewManager {
      
          @objc static func _registerModule() {
            RCTRegisterModule(self);
          }
      
          @objc override class func moduleName() -> String! {
              "View"
          }
      
          @objc override class func requiresMainQueueSetup() -> Bool {
            true
          }
      }
      """,
      macros: macros
    )
  }
  
  func test_params() {
    assertMacroExpansion(
      """
      @ReactView(jsName: "MyView", properties: ["title": String, "count": Int])
      class View: RCTViewManager {
      }
      """,
      expandedSource:
      """
      class View: RCTViewManager {
      
          @objc static func _registerModule() {
            RCTRegisterModule(self);
          }
      
          @objc override class func moduleName() -> String! {
              "MyView"
          }
      
          @objc override class func requiresMainQueueSetup() -> Bool {
            true
          }
      
          @objc static func propConfig_title() -> [String] {
            ["NSString"]
          }
      
          @objc static func propConfig_count() -> [String] {
            ["NSInteger"]
          }
      }
      """,
      macros: macros
    )
  }
  
}

