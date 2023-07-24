import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import Foundation


extension String: LocalizedError {
  public var errorDescription: String? { self }
}


fileprivate func arguments(node: AttributeSyntax) -> [String : String] {
  var result = [String : String]()
  
  if let list = node.argument?.as(TupleExprElementListSyntax.self) {
    for item in list {
      guard let name = item.label?.text else {
        continue
      }
      let value = item.expression.description.replacingOccurrences(of: "\"", with: "")
      result[name] = value
    }
  }
  return result
}

public struct ReactModuleMacro {
}

extension ReactModuleMacro: ConformanceMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingConformancesOf declaration: some DeclGroupSyntax,
    in context: some MacroExpansionContext)
  throws -> [(TypeSyntax, GenericWhereClauseSyntax?)] {
    let syntax = TypeSyntax(stringLiteral: "RCTBridgeModule")
    return [( syntax, nil )]
  }
}

extension ReactModuleMacro: MemberMacro {
  
  private static func moduleName(name: String?) -> String {
    """
    @objc static func moduleName() -> String! {
      \(name != nil ? "\(name!)" : "String(describing: self)")
    }
    """
  }
  
  private static let registerModule =
    """
    @objc static func _registerModule() {
      RCTRegisterModule(self);
    }
    """
  
  private static let requiresMainQueueSetup =
    """
    @objc static func requiresMainQueueSetup() -> Bool {
      return true
    }
    """
  
  public static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    in context: some MacroExpansionContext)
  throws -> [DeclSyntax] {
    guard let _ = declaration.as(ClassDeclSyntax.self) else {
      throw "@\(self) only works on classes."
    }
    
    let arguments = arguments(node: node)
    
    var items = [
      moduleName(name: arguments["jsName"]),
      registerModule,
    ]
    
    if arguments["isMainQueue"] == "true" {
      items.append(requiresMainQueueSetup)
    }
    
    return items.map { DeclSyntax(stringLiteral: $0) }
  }
}

public struct ReactMethodMacro {
}

extension ReactMethodMacro: PeerMacro {
  private static func methodInfo(varName: String, jsName: String, objcName: String, isSync: Bool) -> String {
    """
    private static var \(varName) = RCTMethodInfo(
      jsName: NSString(string:"\(jsName)").utf8String,
      objcName: NSString(string:"\(objcName)").utf8String,
      isSync: \(isSync)
    )
    """
  }
  
  private static func reactExport(varName: String) -> String {
    """
    @objc static func __rct_export__\(varName)() -> UnsafePointer<RCTMethodInfo>? {
      withUnsafePointer(to: &\(varName)) { $0 }
    }
    """
  }
  
  public static func expansion(
    of node: AttributeSyntax,
    providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext)
  throws -> [DeclSyntax] {
    guard let funcDecl = declaration.as(FunctionDeclSyntax.self) else {
      throw "@\(self) only works on functions."
    }
    
    var objcName = funcDecl.identifier.text
    // Parameter list
    let parameterList = funcDecl.signature.input.parameterList
    if parameterList.count > 0 {
      objcName += ":"
      for item in parameterList {
        guard item != parameterList.first else {
          continue
        }
        let firstName = item.firstName.description.trimmingCharacters(in: .whitespaces)
        objcName += "\(firstName):"
      }
    }
    
    let varName = "_" + objcName.replacingOccurrences(of: ":", with: "_")
    
    let arguments = arguments(node: node)
    let jsName = arguments["jsName"] ?? ""
    let isSync = arguments["isSync"] == "true"
    
    let items = [
      methodInfo(varName: varName, jsName: jsName, objcName: objcName, isSync: isSync),
      reactExport(varName: varName),
    ]
    return items.map { DeclSyntax(stringLiteral: $0) }
  }
}


public struct ReactViewPropertyMacro {
}

extension ReactViewPropertyMacro: PeerMacro {
  
  private static func objcType(type: String) -> String {
    if type.contains("String") {
      return "NSString"
    }
    else if type.contains("Bool") {
      return "BOOL"
    }
    else if type.contains("Int") || type.contains("Float") || type.contains("Double") {
      return "NSNumber"
    }
    else if type.contains("[") {
      return type.contains(":") ? "NSDictionary" : "NSArray"
    }
    return type
  }
  
  private static func propConfig(name: String, type: String) -> String {
    """
    @objc static func propConfig_\(name)() -> [String] {
      ["\(objcType(type: type))"]
    }
    """
  }
  
  public static func expansion(
    of node: AttributeSyntax,
    providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext)
  throws -> [DeclSyntax] {
    guard let varDecl = declaration.as(VariableDeclSyntax.self) else {
      throw "@\(self) only works on variables."
    }
    
    guard let pattern = varDecl.bindings.first?.as(PatternBindingSyntax.self),
          let name = pattern.pattern.as(IdentifierPatternSyntax.self)?.identifier.description,
          let type = pattern.typeAnnotation?.type.description
    else {
      throw "@\(self) only works on variables."
    }
    
    return [DeclSyntax(stringLiteral: propConfig(name: name, type: type))]
  }
}

@main
struct ReactBridgePlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    ReactModuleMacro.self,
    ReactMethodMacro.self,
    ReactViewPropertyMacro.self,
  ]
}
