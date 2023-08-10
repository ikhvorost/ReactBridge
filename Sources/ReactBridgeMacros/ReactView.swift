//
//  ReactView.swift
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


public struct ReactView {
}

extension ReactView: MemberMacro {
  
  private static func propConfig(name: String, objcType: String) -> DeclSyntax {
    """
    @objc static func propConfig_\(raw: name)() -> [String] {
      ["\(raw: objcType)"]
    }
    """
  }
  
  private static func objcType(expr: ExprSyntax) throws -> String {
    // Decl
    if let decl = expr.as(DeclReferenceExprSyntax.self) {
      let swiftType = "\(decl.trimmed)"
      guard let objcType = ObjcType(swiftType: swiftType) else {
        throw SyntaxError(sytax: decl._syntaxNode, message: ErrorMessage.unsupportedType(typeName: swiftType))
      }
      return objcType.name
    }
    // Type
    if let type = expr.as(TypeExprSyntax.self) {
      let swiftType = "\(type.trimmed)"
      guard let objcType = ObjcType(swiftType: swiftType) else {
        throw SyntaxError(sytax: type._syntaxNode, message: ErrorMessage.unsupportedType(typeName: swiftType))
      }
      return objcType.name
    }
    // Optional
    else if let optional = expr.as(OptionalChainingExprSyntax.self) {
      return try objcType(expr: optional.expression)
    }
    // Dictionary
    else if let dictionary = expr.as(DictionaryExprSyntax.self) {
      // Verify key and value types
      if let elements = dictionary.content.as(DictionaryElementListSyntax.self), let element = elements.first {
        _ = try objcType(expr: element.key)
        _ = try objcType(expr: element.value)
      }
      return "NSDictionary"
    }
    // Array
    else if let array = expr.as(ArrayExprSyntax.self) {
      // Verify element type
      if let element = array.elements.first?.expression {
        _ = try objcType(expr: element)
      }
      return "NSArray"
    }
    // Generic
    else if let generic = expr.as(GenericSpecializationExprSyntax.self) {
      let swiftType = "\(generic.expression.trimmed)"
      
      switch swiftType {
//        case "Optional":
//          if let argument = generic.genericArgumentClause.arguments.first?.argument {
//            return try objcType(expr: argument)
//          }
        case "Array":
          return "NSArray"
        case "Dictionary":
          return "NSDictionary"
        case "Set":
          return "NSSet"
        default:
          throw SyntaxError(sytax: generic._syntaxNode, message: ErrorMessage.unsupportedType(typeName: swiftType))
      }
    }
    throw SyntaxError(sytax: expr._syntaxNode, message: ErrorMessage.unsupportedType(typeName: "\(expr.trimmed)"))
  }
  
  public static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    in context: some MacroExpansionContext)
  throws -> [DeclSyntax] {
    do {
      // Error: class
      guard let classDecl = declaration.as(ClassDeclSyntax.self) else {
        throw SyntaxError(sytax: declaration._syntaxNode, message: ErrorMessage.classOnly(macroName: "\(self)"))
      }
      
      // Error: RCTViewManager
      guard classDecl.inheritanceClause?.description.contains("RCTViewManager") == true else {
        let className = "\(classDecl.name.trimmed)"
        throw SyntaxError(sytax: classDecl.name._syntaxNode, message: ErrorMessage.mustInherit(className: className, parentName: "RCTViewManager"))
      }
      
      let arguments = node.arguments()
      let jsName = arguments?["jsName"] as? String
      
      var items: [DeclSyntax] = [
        ReactModule.moduleName(name: jsName ?? "\(classDecl.name.trimmed)", override: true),
        ReactModule.registerModule,
        ReactModule.requiresMainQueueSetup(value: true, override: true),
        ReactModule.methodQueue(queue: ".main")
      ]
      
      // Properties
      if let properties = arguments?["properties"] as? [String : ExprSyntax] {
        for (name, expr) in properties {
          let objcType = try objcType(expr: expr)
          items.append(propConfig(name: name, objcType: objcType))
        }
      }
      
      return items
    }
    catch let error as SyntaxError {
      let diagnostic = Diagnostic(node: error.sytax, message: error.message)
      context.diagnose(diagnostic)
      
      return []
    }
  }
}
