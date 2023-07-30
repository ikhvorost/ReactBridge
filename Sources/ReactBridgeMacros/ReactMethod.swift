//
//  ReactMethod.swift
//
//  Created by Iurii Khvorost <iurii.khvorost@gmail.com> on 2023/07/24.
//  Copyright © 2023 Iurii Khvorost. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics


public struct ReactMethod {
  
  enum Error: DiagnosticMessage {
    case funcOnly
    case objcOnly(name: String)
    case unsupportedType(name: String)
    
    var severity: DiagnosticSeverity { .error }
    
    var message: String {
      switch self {
        case .funcOnly:
          return "@ReactMethod can only be applied to a func"
        case .objcOnly(let name):
          return "'\(name)' must be marked with '@objc'"
        case .unsupportedType(let name):
          return "'\(name)' type is not supported"
      }
    }
    
    var diagnosticID: MessageID {
      MessageID(domain: "ReactModule", id: message)
    }
  }
}

extension ReactMethod: PeerMacro {
  
  private static func reactExport(funcName: String, jsName: String, objcName: String, isSync: Bool) -> DeclSyntax {
    """
    @objc static func __rct_export__\(raw: funcName)() -> UnsafePointer<RCTMethodInfo>? {
      struct Static {
        static var methodInfo = RCTMethodInfo(
          jsName: NSString(string:"\(raw: jsName)").utf8String,
          objcName: NSString(string:"\(raw: objcName)").utf8String,
          isSync: \(raw: isSync)
        )
      }
      return withUnsafePointer(to: &Static.methodInfo) { $0 }
    }
    """
  }
  
  private static func objcType(type: TypeSyntax, isRoot: Bool = false) -> String? {
    let nonnull = isRoot ? " _Nonnull" : ""
    
    if let simpleType = type.as(SimpleTypeIdentifierSyntax.self) {
      // TODO: Generic Set, Array, Dictionary
//      SimpleTypeIdentifierSyntax
//      ├─name: identifier("Array")
//      ╰─genericArgumentClause: GenericArgumentClauseSyntax
//        ├─leftAngleBracket: leftAngle
//        ├─arguments: GenericArgumentListSyntax
//        │ ╰─[0]: GenericArgumentSyntax
//        │   ╰─argumentType: SimpleTypeIdentifierSyntax
//        │     ╰─name: identifier("Int")
//        ╰─rightAngleBracket: rightAngle
      
      guard let (objcType, kind) = ObjcType.find(swiftType: simpleType.description.trimmed) else {
        return nil
      }
      
      let type = isRoot == false && kind == .numeric
        ? "NSNumber *"
        : objcType
      
      return "\(type)\(kind == .object ? nonnull : "")"
    }
    else if let optionalType = type.as(OptionalTypeSyntax.self), let wrappedType = objcType(type: optionalType.wrappedType) {
      return "\(wrappedType) _Nullable"
    }
    else if let arrayType = type.as(ArrayTypeSyntax.self), let elementType = objcType(type: arrayType.elementType) {
      return "NSArray<\(elementType)> *\(nonnull)"
    }
    else if let dictType = type.as(DictionaryTypeSyntax.self), let keyType = objcType(type: dictType.keyType), let valueType = objcType(type: dictType.valueType) {
      return "NSDictionary<\(keyType), \(valueType)> *\(nonnull)"
    }
    return nil
  }
  
  private static func objcSelector(funcDecl: FunctionDeclSyntax, node: Syntax, context: MacroExpansionContext) -> String? {
    var selector = funcDecl.identifier.text.trimmed
    let parameterList = funcDecl.signature.input.parameterList
    for param in parameterList {
      
      guard let objcType = objcType(type: param.type, isRoot: true) else {
        let swiftType = param.type.description.trimmed
        let diagnostic = Diagnostic(node: node, message: Error.unsupportedType(name: swiftType))
        context.diagnose(diagnostic)
        return nil
      }
      
      var firstName = param.firstName.description.trimmed
      
      if param == parameterList.first {
        if firstName != "_" {
          if param.secondName == nil {
            selector += "With\(firstName.capitalized):(\(objcType))\(firstName)"
            continue
          }
          else {
            firstName = firstName.capitalized
          }
        }
      }
      else {
        selector += " "
      }
      
      firstName = firstName == "_" ? "" : firstName
      let secondName = param.secondName?.description.trimmed ?? firstName
      selector += "\(firstName):(\(objcType))\(secondName)"
    }
    return selector
  }
  
  public static func expansion(
    of node: AttributeSyntax,
    providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext)
  throws -> [DeclSyntax]
  {
    // func
    guard let funcDecl = declaration.as(FunctionDeclSyntax.self) else {
      let diagnostic = Diagnostic(node: node._syntaxNode, message: Error.funcOnly)
      context.diagnose(diagnostic)
      return []
    }
    
    // @objc
    guard let attributes = funcDecl.attributes?.as(AttributeListSyntax.self),
          attributes.first(where: { $0.description.contains("@objc") }) != nil
    else {
      let name = funcDecl.identifier.description.trimmed
      let diagnostic = Diagnostic(node: node._syntaxNode, message: Error.objcOnly(name: name))
      context.diagnose(diagnostic)
      return []
    }
    
    guard let objcName = objcSelector(funcDecl: funcDecl, node: node._syntaxNode, context: context) else {
      return []
    }
    
    let funcName = funcDecl.identifier.text.trimmed
    
    let arguments = node.arguments()
    let jsName = arguments?["jsName"] ?? funcName
    let isSync = arguments?["isSync"] == "true"
    
    return [
      reactExport(funcName: funcName, jsName: jsName, objcName: objcName, isSync: isSync)
    ]
  }
}
