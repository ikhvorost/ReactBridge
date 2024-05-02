import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest


// Macro implementations build for the host, so the corresponding module is not available when cross-compiling.
// Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if DEBUG && canImport(ReactBridgeMacros)

@testable import ReactBridgeMacros

final class ReactMethodTests: XCTestCase {
  
  let macros: [String: Macro.Type] = [
    "ReactMethod": ReactMethod.self,
  ]
  
  private static var nonisolatedUnsafe: String = {
#if swift(>=5.10)
    "nonisolated (unsafe) "
#else
    ""
#endif
  }()
  
  func rct_export(name: String, selector: String, isSync: Bool = false, jsName: String? = nil) -> String {
    """
    @objc static func __rct_export__\(name)() -> UnsafePointer<RCTMethodInfo>? {
        struct Static {
          static let jsName = strdup("\(jsName ?? name)")
          static let objcName = strdup("\(selector)")
          \(Self.nonisolatedUnsafe)static var methodInfo = RCTMethodInfo(jsName: jsName, objcName: objcName, isSync: \(isSync))
        }
        return withUnsafePointer(to: &Static.methodInfo) {
            $0
        }
      }
    """
  }
  
  func test_diagnosticID() {
    let diagnosticID = ErrorMessage.funcOnly(macroName: "ReactMethod").diagnosticID
    XCTAssert("\(diagnosticID)" == #"MessageID(domain: "ReactBridge", id: "ReactBridge: @ReactMethod can only be applied to a func")"#)
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
        func test(count: Int) {}
      
        @ReactMethod
        @objc
        func test(_ count: Int) {}
      
        @ReactMethod
        @objc
        func test(in count: Int) {}
      
        @ReactMethod
        @objc
        func test(in _: Int) {}
      
        @ReactMethod
        @objc
        func test(_: Int) {}
      
        @ReactMethod
        @objc
        func test(_: Int, text: String) {}
      
        @ReactMethod
        @objc
        func test(_: Int, _ text: String) {}
      
        @ReactMethod
        @objc
        func test(_: Int, text _: String) {}
      
        @ReactMethod
        @objc
        func test(_: Int, _: String) {}
      
        @ReactMethod
        @objc
        func test(_ text: String?) {}
      
        @ReactMethod
        @objc
        func test(point: CGPoint, array: [Int], dict: [String : Int], set: Set<Int>) {}
      
        @ReactMethod
        @objc
        func test(resolve: @escaping RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {}
      
        @ReactMethod
        @objc
        func test(countOfItems: Int) {}
      }
      """,
      expandedSource:
      """
      class A {
        @objc
        func test(count: Int) {}
      
        \(rct_export(name: "test", selector: "testWithCount:(NSInteger)count"))
        @objc
        func test(_ count: Int) {}
      
        \(rct_export(name: "test", selector: "test:(NSInteger)count"))
        @objc
        func test(in count: Int) {}
      
        \(rct_export(name: "test", selector: "testIn:(NSInteger)count"))
        @objc
        func test(in _: Int) {}
      
        \(rct_export(name: "test", selector: "testIn:(NSInteger)_"))
        @objc
        func test(_: Int) {}
      
        \(rct_export(name: "test", selector: "test:(NSInteger)_"))
        @objc
        func test(_: Int, text: String) {}
      
        \(rct_export(name: "test", selector: "test:(NSInteger)_ text:(NSString * _Nonnull)text"))
        @objc
        func test(_: Int, _ text: String) {}
      
        \(rct_export(name: "test", selector: "test:(NSInteger)_ :(NSString * _Nonnull)text"))
        @objc
        func test(_: Int, text _: String) {}
      
        \(rct_export(name: "test", selector: "test:(NSInteger)_ text:(NSString * _Nonnull)_"))
        @objc
        func test(_: Int, _: String) {}
      
        \(rct_export(name: "test", selector: "test:(NSInteger)_ :(NSString * _Nonnull)_"))
        @objc
        func test(_ text: String?) {}
      
        \(rct_export(name: "test", selector: "test:(NSString * _Nullable)text"))
        @objc
        func test(point: CGPoint, array: [Int], dict: [String : Int], set: Set<Int>) {}
      
        \(rct_export(name: "test", selector: "testWithPoint:(CGPoint)point array:(NSArray<NSNumber *> * _Nonnull)array dict:(NSDictionary * _Nonnull)dict set:(NSSet * _Nonnull)set"))
        @objc
        func test(resolve: @escaping RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {}
      
        \(rct_export(name: "test", selector: "testWithResolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject"))
        @objc
        func test(countOfItems: Int) {}
      
        \(rct_export(name: "test", selector: "testWithCountOfItems:(NSInteger)countOfItems"))
      }
      """,
      macros: macros
    )
  }
  
  func test_timeInterval() {
    assertMacroExpansion(
      """
      class A {
        @ReactMethod
        @objc
        func test(start: TimeInterval) {}
      }
      """,
      expandedSource:
      """
      class A {
        @objc
        func test(start: TimeInterval) {}
      
        \(rct_export(name: "test", selector: "testWithStart:(double)start"))
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
  
  func methods(name: String, requiresMainQueueSetup: Bool = false, override: Bool = false) -> String {
    """
    
        @objc \(override ? "override " : "")class func moduleName() -> String! {
          "\(name)"
        }

        @objc \(override ? "override " : "")class func requiresMainQueueSetup() -> Bool {
          \(requiresMainQueueSetup)
        }

        @objc static func _registerModule() {
          RCTRegisterModule(self);
        }
    """
  }
  
  func test_struct() {
    let diagnostic = DiagnosticSpec(message: ErrorMessage.classOnly(macroName: "ReactModule").message, line: 1, column: 1)
        
    assertMacroExpansion(
      """
      @ReactModule
      struct Module {}
      """,
      expandedSource:
      """
      struct Module {}
      """,
      diagnostics: [diagnostic],
      macros: macros
    )
  }
  
  func test_NSObject() {
    let diagnostic = DiagnosticSpec(message: ErrorMessage.mustInherit(className: "Module", superclassName: "NSObject").message, line: 2, column: 7)
    
    assertMacroExpansion(
      """
      @ReactModule
      class Module {}
      """,
      expandedSource:
      """
      class Module {}
      """,
      diagnostics: [diagnostic],
      macros: macros
    )
  }
  
  func test_RCTBridgeModule() {
    let diagnostic = DiagnosticSpec(message: ErrorMessage.mustConform(className: "Module", protocolName: "RCTBridgeModule").message, line: 2, column: 7)
    
    assertMacroExpansion(
      """
      @ReactModule
      class Module: NSObject {}
      """,
      expandedSource:
      """
      class Module: NSObject {}
      """,
      diagnostics: [diagnostic],
      macros: macros
    )
  }
  
  func test_default() {
    assertMacroExpansion(
      """
      @ReactModule
      class Module: NSObject, RCTBridgeModule {
      }
      """,
      expandedSource:
      """
      class Module: NSObject, RCTBridgeModule {
      \(methods(name: "Module"))
      }
      """,
      macros: macros
    )
  }
  
  func test_RCTEventEmitter() {
    assertMacroExpansion(
      """
      @ReactModule
      class Module: RCTEventEmitter {
      }
      """,
      expandedSource:
      """
      class Module: RCTEventEmitter {
      \(methods(name: "Module", override: true))
      }
      """,
      macros: macros
    )
  }
  
  func test_params() {
    assertMacroExpansion(
      """
      @ReactModule(jsName: "Module2", requiresMainQueueSetup: true, methodQueue: .main)
      class A: NSObject, RCTBridgeModule {
      }
      """,
      expandedSource:
      """
      class A: NSObject, RCTBridgeModule {
      \(methods(name: "Module2", requiresMainQueueSetup: true))
      
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
  
  func propConfig(name: String, objcType: String, keyPath: String? = nil, isCustom: Bool = false) -> String {
    """
    @objc static func propConfig_\(name)() -> [String] {
        ["\(objcType)", "\(isCustom ? "__custom__" : (keyPath ?? name))"]
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
  
  func test_no_type() {
    let diagnostic = DiagnosticSpec(message: ErrorMessage.varNoType(name: "a").message, line: 3, column: 7)
    
    assertMacroExpansion(
      """
      class View {
        @ReactProperty
        let a = 10
      }
      """,
      expandedSource:
      """
      class View {
        let a = 10
      }
      """,
      diagnostics: [diagnostic],
      macros: macros
    )
  }
  
  func test_multiple() {
    // SwiftSyntaxMacroExpansion
    enum MacroApplicationError: String {
      //case accessorMacroOnVariableWithMultipleBindings = "accessor macro can only be applied to a single variable"
      case peerMacroOnVariableWithMultipleBindings = "peer macro can only be applied to a single variable"
      //case malformedAccessor = "macro returned a malformed accessor. Accessors should start with an introducer like 'get' or 'set'."
    }
    
    let diagnostic = DiagnosticSpec(message: MacroApplicationError.peerMacroOnVariableWithMultipleBindings.rawValue, line: 2, column: 3)
    
    assertMacroExpansion(
      """
      class View {
        @ReactProperty
        let a: Int = 10, b: Int = 20
      }
      """,
      expandedSource:
      """
      class View {
        let a: Int = 10, b: Int = 20
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
        var onDirect: RCTDirectEventBlock?
      
        @ReactProperty
        var onBubbling: RCTBubblingEventBlock?
      
        @ReactProperty
        var onCapturing: RCTCapturingEventBlock?
      
        @ReactProperty(keyPath: "muted")
        var isMute: Bool?
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
        var onDirect: RCTDirectEventBlock?
      
        \(propConfig(name: "onDirect", objcType: "RCTDirectEventBlock"))
        var onBubbling: RCTBubblingEventBlock?
      
        \(propConfig(name: "onBubbling", objcType: "RCTBubblingEventBlock"))
        var onCapturing: RCTCapturingEventBlock?
      
        \(propConfig(name: "onCapturing", objcType: "RCTCapturingEventBlock"))
        var isMute: Bool?
      
        \(propConfig(name: "isMute", objcType: "BOOL", keyPath: "muted"))
      }
      """,
      macros: macros
    )
  }
  
  func test_custom() {
    assertMacroExpansion(
      """
      class View {
        @ReactProperty(isCustom: true)
        var alpha: Double?
      }
      """,
      expandedSource:
      """
      class View {
        var alpha: Double?
      
        \(propConfig(name: "alpha", objcType: "double", isCustom: true))
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
  
  func methods(name: String) -> String {
    """
    
        @objc static func _registerModule() {
          RCTRegisterModule(self);
        }

        @objc override class func moduleName() -> String! {
          "\(name)"
        }

        @objc override class func requiresMainQueueSetup() -> Bool {
          true
        }

        @objc override var methodQueue: DispatchQueue {
          .main
        }
    """
  }
  
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
    let diagnostic = DiagnosticSpec(message: ErrorMessage.mustInherit(className: "View", superclassName: "RCTViewManager").message, line: 2, column: 7, severity: .error)
    
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
      \(methods(name: "View"))
      }
      """,
      macros: macros
    )
  }
  
  func test_RNCWebViewManager() {
    assertMacroExpansion(
      """
      @ReactView
      class View: RNCWebViewManager {
      }
      """,
      expandedSource:
      """
      class View: RNCWebViewManager {
      \(methods(name: "View"))
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
      \(methods(name: "MyView"))
      }
      """,
      macros: macros
    )
  }
}

#endif
