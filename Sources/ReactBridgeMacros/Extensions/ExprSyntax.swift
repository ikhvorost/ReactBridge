//
//  ExprSyntax.swift
//
//  Created by Iurii Khvorost <iurii.khvorost@gmail.com> on 2023/08/10.
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


extension ExprSyntax {
  
  func objcType() throws -> String {
    // Decl
    if let decl = self.as(DeclReferenceExprSyntax.self) {
      let swiftType = "\(decl.trimmed)"
      guard let objcType = ObjcType(swiftType: swiftType) else {
        throw SyntaxError(sytax: decl._syntaxNode, message: ErrorMessage.unsupportedType(typeName: swiftType))
      }
      return objcType.name
    }
    // Type: Any
    if let type = self.as(TypeExprSyntax.self) {
      return try type.type.objcType()
    }
    // Optional: ?!
    else if let optional = self.as(OptionalChainingExprSyntax.self) {
      return try optional.expression.objcType()
    }
    // Array: []
    else if let array = self.as(ArrayExprSyntax.self) {
      // Verify element type
      if let element = array.elements.first?.expression {
        _ = try element.objcType()
      }
      return "NSArray"
    }
    // Dictionary
    else if let dictionary = self.as(DictionaryExprSyntax.self) {
      // Verify key and value types
      if let elements = dictionary.content.as(DictionaryElementListSyntax.self), let element = elements.first {
        _ = try element.key.objcType()
        _ = try element.value.objcType()
      }
      return "NSDictionary"
    }
    // Generic: Type<Type>
    else if let generic = self.as(GenericSpecializationExprSyntax.self) {
      let swiftType = "\(generic.expression.trimmed)"
      
      // Verify arguments
      let arguments = generic.genericArgumentClause.arguments
      for item in arguments {
        _ = try item.argument.objcType()
      }
      
      switch swiftType {
        case "Optional":
          if let argument = arguments.first?.argument {
            return try argument.objcType(isRoot: true)
          }
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
    throw SyntaxError(sytax: _syntaxNode, message: ErrorMessage.unsupportedType(typeName: "\(trimmed)"))
  }
}
