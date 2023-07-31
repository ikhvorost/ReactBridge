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
  
  private static func objcType(type: TypeSyntax, isRoot: Bool = false) throws -> String {
    let nonnull = isRoot ? " _Nonnull" : ""
    
    // Simple
    if let simpleType = type.as(SimpleTypeIdentifierSyntax.self) {
      let swiftType = simpleType.name.description.trimmed
      
      // Generic: Type<type>
      if let generic = simpleType.genericArgumentClause {
        switch swiftType {
          case "Array":
            if let argumentType = generic.arguments.first?.argumentType {
              let elementType = try objcType(type: argumentType)
              return "NSArray<\(elementType)> *\(nonnull)"
            }
            break;
            
          // MARK: React Native doesn't support type parameters for NSDictionary e.g.: NSDictionary<NSString *, NSNumber *>
          case "Dictionary":
            return "NSDictionary *\(nonnull)"

          // MARK: React Native doesn't support type parameters for NSSet e.g.: NSSet<NSString *>
          case "Set":
            return "NSSet *\(nonnull)"
            
          default:
            throw swiftType
        }
      }
      else {
        guard let (objcType, kind) = ObjcType.find(swiftType: swiftType) else {
          throw swiftType
        }
        
        let type = isRoot == false && kind == .numeric
          ? "NSNumber *"
          : objcType
        
        return "\(type)\(kind == .object ? nonnull : "")"
      }
    }
    // Optional: ?!
    else if let optionalType = type.as(OptionalTypeSyntax.self) {
      let wrappedType = try objcType(type: optionalType.wrappedType)
      return "\(wrappedType) _Nullable"
    }
    // Array: []
    else if let arrayType = type.as(ArrayTypeSyntax.self) {
      let elementType = try objcType(type: arrayType.elementType)
      return "NSArray<\(elementType)> *\(nonnull)"
    }
    // Dictionary: [:]
    // MARK: React Native doesn't support type parameters for NSDictionary e.g.: NSDictionary<NSString *, NSNumber *>
    else if let _ = type.as(DictionaryTypeSyntax.self) {
      return "NSDictionary *\(nonnull)"
    }
    
    throw type.description.trimmed
  }
  
  private static func objcSelector(funcDecl: FunctionDeclSyntax) throws -> String {
    var selector = funcDecl.identifier.text.trimmed
    
    let parameterList = funcDecl.signature.input.parameterList
    for param in parameterList {
      let objcType = try objcType(type: param.type, isRoot: true)
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
    
    do {
      let objcName = try objcSelector(funcDecl: funcDecl)
      let funcName = funcDecl.identifier.text.trimmed
      
      let arguments = node.arguments()
      let jsName = arguments?["jsName"] ?? funcName
      let isSync = arguments?["isSync"] == "true"
      
      return [
        reactExport(funcName: funcName, jsName: jsName, objcName: objcName, isSync: isSync)
      ]
    }
    catch {
      let swiftType = error.localizedDescription
      let diagnostic = Diagnostic(node: node._syntaxNode, message: Error.unsupportedType(name: swiftType))
      context.diagnose(diagnostic)
    }
    
    return []
  }
}
