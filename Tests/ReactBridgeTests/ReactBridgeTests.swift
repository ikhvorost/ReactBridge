import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

@testable import ReactBridgeMacros

//*
import ReactBridge

@ReactModule
class Calendar: NSObject, RCTBridgeModule {

  @ReactMethod
  @objc func createCalendarEvent(name: String, location: String) {
  }
}

@ReactView()
class MapManager: RCTViewManager {
  
  @ReactProperty()
  var zoomEnabled: Bool?
}

// */

final class ReactMethodTests: XCTestCase {
  
  let macros: [String: Macro.Type] = [
    "ReactMethod": ReactMethod.self,
  ]
  
  func rct_export(name: String, selector: String, isSync: Bool = false, jsName: String? = nil) -> String {
    """
    @objc static func __rct_export__\(name)() -> UnsafePointer<RCTMethodInfo>? {
        struct Static {
          static var methodInfo = RCTMethodInfo(
            jsName: NSString(string: "\(jsName ?? name)").utf8String,
            objcName: NSString(string: "\(selector)").utf8String,
            isSync: \(isSync)
          )
        }
        return withUnsafePointer(to: &Static.methodInfo) {
            $0
        }
      }
    """
  }
  
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
    let diagnostic = DiagnosticSpec(message: ErrorMessage.objcOnly(name: "test").message, line: 2, column: 3)
    
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
        func test1(count: Int) {}
      
        @ReactMethod
        @objc
        func test2(_ count: Int) {}
      
        @ReactMethod
        @objc
        func test3(in count: Int) {}
      
        @ReactMethod
        @objc
        func test4(in _: Int) {}
      
        @ReactMethod
        @objc
        func test5(_: Int) {}
      
        @ReactMethod
        @objc
        func test6(_: Int, text: String) {}
      
        @ReactMethod
        @objc
        func test7(_: Int, _ text: String) {}
      
        @ReactMethod
        @objc
        func test8(_: Int, text _: String) {}
      
        @ReactMethod
        @objc
        func test9(_: Int, _: String) {}
      
        @ReactMethod
        @objc
        func test10(_ text: String?) {}
      
        @ReactMethod
        @objc
        func test11(point: CGPoint, array: [Int], dict: [String : Int], set: Set<Int>) {}
      }
      """,
      expandedSource:
      """
      class A {
        @objc
        func test1(count: Int) {}
      
        \(rct_export(name: "test1", selector: "test1WithCount:(NSInteger)count"))
        @objc
        func test2(_ count: Int) {}
      
        \(rct_export(name: "test2", selector: "test2:(NSInteger)count"))
        @objc
        func test3(in count: Int) {}
      
        \(rct_export(name: "test3", selector: "test3In:(NSInteger)count"))
        @objc
        func test4(in _: Int) {}
      
        \(rct_export(name: "test4", selector: "test4In:(NSInteger)_"))
        @objc
        func test5(_: Int) {}
      
        \(rct_export(name: "test5", selector: "test5:(NSInteger)_"))
        @objc
        func test6(_: Int, text: String) {}
      
        \(rct_export(name: "test6", selector: "test6:(NSInteger)_ text:(NSString * _Nonnull)text"))
        @objc
        func test7(_: Int, _ text: String) {}
      
        \(rct_export(name: "test7", selector: "test7:(NSInteger)_ :(NSString * _Nonnull)text"))
        @objc
        func test8(_: Int, text _: String) {}
      
        \(rct_export(name: "test8", selector: "test8:(NSInteger)_ text:(NSString * _Nonnull)_"))
        @objc
        func test9(_: Int, _: String) {}
      
        \(rct_export(name: "test9", selector: "test9:(NSInteger)_ :(NSString * _Nonnull)_"))
        @objc
        func test10(_ text: String?) {}
      
        \(rct_export(name: "test10", selector: "test10:(NSString * _Nullable)text"))
        @objc
        func test11(point: CGPoint, array: [Int], dict: [String : Int], set: Set<Int>) {}
      
        \(rct_export(name: "test11", selector: "test11WithPoint:(CGPoint)point array:(NSArray<NSNumber *> * _Nonnull)array dict:(NSDictionary * _Nonnull)dict set:(NSSet * _Nonnull)set"))
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
      
        \(rct_export(name: "test", selector: "testWithCount:(NSInteger)count", isSync: true, jsName: "add"))
      }
      """,
      macros: macros
    )
  }
  
  func test_nonSync() {
    let nonSync = DiagnosticSpec(message: ErrorMessage.nonSync.message, line: 2, column: 3, severity: .warning)
    
    assertMacroExpansion(
      """
      class A {
        @ReactMethod
        @objc
        func test() -> String {}
      }
      """,
      expandedSource:
      """
      class A {
        @objc
        func test() -> String {}
      
        \(rct_export(name: "test", selector: "test"))
      }
      """,
      diagnostics: [nonSync],
      macros: macros
    )
  }
  
  func test_mustBeClass() {
    let mustBeClass = DiagnosticSpec(message: ErrorMessage.mustBeClass.message, line: 4, column: 18, severity: .error)
    
    assertMacroExpansion(
      """
      class A {
        @ReactMethod(isSync: true)
        @objc
        func test() -> Int {}
      }
      """,
      expandedSource:
      """
      class A {
        @objc
        func test() -> Int {}
      }
      """,
      diagnostics: [mustBeClass],
      macros: macros
    )
  }

  func test_unsupportedType() {
    let diagnostic = DiagnosticSpec(message: ErrorMessage.unsupportedType(typeName: "CGColor").message, line: 4, column: 20)
    
    assertMacroExpansion(
      """
      class A {
        @ReactMethod
        @objc
        func test(color: CGColor) {}
      }
      """,
      expandedSource:
      """
      class A {
        @objc
        func test(color: CGColor) {}
      }
      """,
      diagnostics: [diagnostic],
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

final class ReactPropertyTests: XCTestCase {
  let macros: [String: Macro.Type] = [
    "ReactProperty": ReactProperty.self,
  ]
  
  func propConfig(name: String, objcType: String) -> String {
    """
    @objc static func propConfig_\(name)() -> [String] {
        ["\(objcType)"]
      }
    """
  }
  
  func test_func() {
    let diagnostic = DiagnosticSpec(message: ErrorMessage.varOnly(macroName: "ReactProperty").message, line: 2, column: 3)
    
    assertMacroExpansion(
      """
      class View {
        @ReactProperty
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
  
  func test_multiple() {
    let diagnostic = DiagnosticSpec(message: ErrorMessage.varSingleOnly(macroName: "ReactProperty").message, line: 3, column: 7)
    
    assertMacroExpansion(
      """
      class View {
        @ReactProperty
        var a, b: Int?
      }
      """,
      expandedSource:
      """
      class View {
        var a, b: Int?
      }
      """,
      diagnostics: [diagnostic],
      macros: macros
    )
  }
  
  func test_unsupported() {
    let unsupported1 = DiagnosticSpec(message: ErrorMessage.unsupportedType(typeName: "MyType").message, line: 3, column: 10)
    let unsupported2 = DiagnosticSpec(message: ErrorMessage.unsupportedType(typeName: "CGColor").message, line: 6, column: 14)
    let unsupported3 = DiagnosticSpec(message: ErrorMessage.unsupportedType(typeName: "(Int, String)").message, line: 9, column: 14)
    let unsupported4 = DiagnosticSpec(message: ErrorMessage.unsupportedType(typeName: "((Int) -> Void)").message, line: 12, column: 10)
    
    assertMacroExpansion(
      """
      class View {
        @ReactProperty
        var a: MyType<Int>?
      
        @ReactProperty
        var color: CGColor?
      
        @ReactProperty
        var tuple: (Int, String)?
      
        @ReactProperty
        var f: ((Int) -> Void)?
      }
      """,
      expandedSource:
      """
      class View {
        var a: MyType<Int>?
        var color: CGColor?
        var tuple: (Int, String)?
        var f: ((Int) -> Void)?
      }
      """,
      diagnostics: [unsupported1, unsupported2, unsupported3, unsupported4],
      macros: macros
    )
  }
  
  func test_default() {
    assertMacroExpansion(
      """
      class View {
        @ReactProperty
        var id: Int?
      
        @ReactProperty
        var name: String = ""
      
        @ReactProperty
        var title: String?
      
        @ReactProperty
        var array: [String]?
      
        @ReactProperty
        var dict: [String : Int]?
      
        @ReactProperty
        var title: Optional<String>
      
        @ReactProperty
        var array: Array<String>?
      
        @ReactProperty
        var dict: Dictionary<String, Int>?
      
        @ReactProperty
        var set: Set<String>?
      
        @ReactProperty
        var onData: RCTBubblingEventBlock?
      }
      """,
      expandedSource:
      """
      class View {
        var id: Int?
      
        \(propConfig(name: "id", objcType: "NSInteger"))
        var name: String = ""
      
        \(propConfig(name: "name", objcType: "NSString"))
        var title: String?
      
        \(propConfig(name: "title", objcType: "NSString"))
        var array: [String]?
      
        \(propConfig(name: "array", objcType: "NSArray"))
        var dict: [String : Int]?
      
        \(propConfig(name: "dict", objcType: "NSDictionary"))
        var title: Optional<String>
      
        \(propConfig(name: "title", objcType: "NSString"))
        var array: Array<String>?
      
        \(propConfig(name: "array", objcType: "NSArray"))
        var dict: Dictionary<String, Int>?
      
        \(propConfig(name: "dict", objcType: "NSDictionary"))
        var set: Set<String>?
      
        \(propConfig(name: "set", objcType: "NSSet"))
        var onData: RCTBubblingEventBlock?
      
        \(propConfig(name: "onData", objcType: "RCTBubblingEventBlock"))
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

