//
//  TypeSyntax.swift
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
import SwiftDiagnostics


extension TypeSyntax {
  
  func objcType() throws -> ObjcType {
    if let attributed = self.as(AttributedTypeSyntax.self) {
      return try attributed.baseType.objcType()
    }
    else if let identifier = self.as(IdentifierTypeSyntax.self) {
      let swiftType = "\(identifier.name.trimmed)"
      
      // Generic
      if let generic = identifier.genericArgumentClause {
        switch swiftType {
          case "Array":
            if case .type(let type) = generic.arguments.first?.argument {
              return .array(try type.objcType())
            }
            
          case "Dictionary":
            if case .type(let keyType) = generic.arguments.first?.argument,
               case .type(let valueType) = generic.arguments.last?.argument
            {
              return .dictionary(try keyType.objcType(), try valueType.objcType())
            }
            
          case "Set":
            if case .type(let type) = generic.arguments.first?.argument {
              return .set(try type.objcType())
            }
            
          case "Optional":
            if case .type(let type) = generic.arguments.first?.argument {
              return .optional(try type.objcType())
            }
            
          default:
            throw Diagnostic(node: identifier.name, message: ErrorMessage.unsupportedType(typeName: swiftType))
        }
      }
      // Regular
      else {
        guard let objcType = ObjcType(swiftType: swiftType) else {
          throw Diagnostic(node: identifier.name, message: ErrorMessage.unsupportedType(typeName: swiftType))
        }
        return objcType
      }
    }
    // Optional
    else if let optional = self.as(OptionalTypeSyntax.self) {
      let type = try optional.wrappedType.objcType()
      return .optional(type)
    }
    // Array
    else if let array = self.as(ArrayTypeSyntax.self) {
      let type = try array.element.objcType()
      return .array(type)
    }
    // Dictionary
    else if let dictionary = self.as(DictionaryTypeSyntax.self) {
      let keyType = try dictionary.key.objcType()
      let valueType = try dictionary.value.objcType()
      return .dictionary(keyType, valueType)
    }
    
    throw Diagnostic(node: self, message: ErrorMessage.unsupportedType(typeName: "\(trimmed)"))
  }
}
