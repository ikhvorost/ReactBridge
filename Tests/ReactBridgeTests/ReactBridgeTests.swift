import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

@testable import ReactBridgeMacros

//*
import ReactBridge

let name = "Name"

@ReactModule(jsName: "ModuleA")
class A: NSObject, RCTBridgeModule {

  @ReactMethod(jsName: "t", isSync: true)
  @objc func test(count: Int) {}
}

@ReactView()
class ViewManager: RCTViewManager {
  
  @ReactViewProperty()
  var title: String?
  
  @ReactViewProperty()
  var onData: RCTBubblingEventBlock?
}

// */

final class ReactMethodTests: XCTestCase {
  
  let macros: [String: Macro.Type] = [
    "ReactMethod": ReactMethod.self,
  ]
  
  func test_var() {
    let diagnostic = DiagnosticSpec(message: ErrorMessage.funcOnly(macroName: "ReactMethod").message, line: 2, column: 3)
    
    assertMacroExpansion(
      """
      class A {
        @ReactMethod
        var name: String
      }
      """,
      expandedSource:
      """
      class A {
        var name: String
      }
      """,
      diagnostics: [diagnostic],
      macros: macros
    )
  }
  
  func test_objc() {
    let diagnostic = DiagnosticSpec(message: ErrorMessage.objcOnly(funcName: "test").message, line: 2, column: 3)
    
    assertMacroExpansion(
      """
      class A {
        @ReactMethod
        func test() {}
      }
      """,
      expandedSource:
      """
      class A {
        func test() {}
      }
      """,
      diagnostics: [diagnostic],
      macros: macros
    )
  }
  
  func test_default() {
    assertMacroExpansion(
      """
      class A {
        @ReactMethod
        @objc
        func test(count: Int) {}
      }
      """,
      expandedSource:
      """
      class A {
        @objc
        func test(count: Int) {}
      
        @objc static func __rct_export__test() -> UnsafePointer<RCTMethodInfo>? {
          struct Static {
            static var methodInfo = RCTMethodInfo(
              jsName: NSString(string: "test").utf8String,
              objcName: NSString(string: "testWithCount:(NSInteger)count").utf8String,
              isSync: false
            )
          }
          return withUnsafePointer(to: &Static.methodInfo) {
              $0
          }
        }
      }
      """,
      macros: macros
    )
  }
  
  func test_params() {
    assertMacroExpansion(
      """
      class A {
        @ReactMethod(jsName: "add", isSync: true)
        @objc
        func test(count: Int) {}
      }
      """,
      expandedSource:
      """
      class A {
        @objc
        func test(count: Int) {}
      
        @objc static func __rct_export__test() -> UnsafePointer<RCTMethodInfo>? {
          struct Static {
            static var methodInfo = RCTMethodInfo(
              jsName: NSString(string: "add").utf8String,
              objcName: NSString(string: "testWithCount:(NSInteger)count").utf8String,
              isSync: true
            )
          }
          return withUnsafePointer(to: &Static.methodInfo) {
              $0
          }
        }
      }
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
      
          @objc class func moduleName() -> String! {
            "A"
          }
      
          @objc class func requiresMainQueueSetup() -> Bool {
            false
          }
      
          @objc static func _registerModule() {
            RCTRegisterModule(self);
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
      
          @objc class func moduleName() -> String! {
            "ModuleA"
          }
      
          @objc class func requiresMainQueueSetup() -> Bool {
            true
          }
      
          @objc static func _registerModule() {
            RCTRegisterModule(self);
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

final class ReactViewPropertyTests: XCTestCase {
  let macros: [String: Macro.Type] = [
    "ReactViewProperty": ReactViewProperty.self,
  ]
  
  func test_func() {
    let diagnostic = DiagnosticSpec(message: ErrorMessage.varOnly(macroName: "ReactViewProperty").message, line: 2, column: 3)
    
    assertMacroExpansion(
      """
      class View {
        @ReactViewProperty
        func hide() {}
      }
      """,
      expandedSource:
      """
      class View {
        func hide() {}
      }
      """,
      diagnostics: [diagnostic],
      macros: macros
    )
  }
  
  func test_badType() {
    let diagnostic = DiagnosticSpec(message: ErrorMessage.unsupportedType(typeName: "CGColor").message, line: 3, column: 14)
    
    assertMacroExpansion(
      """
      class View {
        @ReactViewProperty
        var color: CGColor?
      }
      """,
      expandedSource:
      """
      class View {
        var color: CGColor?
      }
      """,
      diagnostics: [diagnostic],
      macros: macros
    )
  }
  
  func test_default() {
    assertMacroExpansion(
      """
      class View {
        @ReactViewProperty
        var title: String?
      }
      """,
      expandedSource:
      """
      class View {
        var title: String?
      
        @objc static func propConfig_title() -> [String] {
          ["NSString"]
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
      @ReactView(jsName: "MyView")
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
      }
      """,
      macros: macros
    )
  }
}

