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
import SwiftDiagnostics


extension TypeSyntax {
  
  func objcType(isRoot: Bool = false) throws -> String {
    let nonnull = isRoot ? " _Nonnull" : ""
    
    // Simple
    if let identifier = self.as(IdentifierTypeSyntax.self) {
      let swiftType = "\(identifier.name.trimmed)"
      
      // Generic: Type<type>
      if let generic = identifier.genericArgumentClause {
        switch swiftType {
            //case "Optional":
          case "Array":
            if let argument = generic.arguments.first?.argument {
              let elementType = try argument.objcType()
              return "NSArray<\(elementType)> *\(nonnull)"
            }
            break;
            
            // MARK: React Native doesn't support type parameters for NSDictionary e.g.: NSDictionary<NSString *, NSNumber *>
          case "Dictionary":
            // Verify key and value types
            for argument in generic.arguments {
              let _ = try argument.argument.objcType()
            }
            return "NSDictionary *\(nonnull)"
            
            // MARK: React Native doesn't support type parameters for NSSet e.g.: NSSet<NSString *>
          case "Set":
            // Verify type
            for argument in generic.arguments {
              let _ = try argument.argument.objcType()
            }
            return "NSSet *\(nonnull)"
            
          default:
            throw Diagnostic(node: identifier.name._syntaxNode, message: ErrorMessage.unsupportedType(typeName: swiftType))
        }
      }
      // Non generic
      else {
        guard let objcType = ObjcType(swiftType: swiftType) else {
          throw Diagnostic(node: identifier.name._syntaxNode, message: ErrorMessage.unsupportedType(typeName: swiftType))
        }
        
        let type = (isRoot == false && objcType.kind == .numeric) ? "NSNumber *" : objcType.name
        let asterisk = (objcType.kind == .object && objcType.name != "id") ? " *\(nonnull)" : ""
        
        return "\(type)\(asterisk)"
      }
    }
    // Optional: ?!
    else if let optional = self.as(OptionalTypeSyntax.self) {
      let wrappedType = try optional.wrappedType.objcType()
      return "\(wrappedType) _Nullable"
    }
    // Array: []
    else if let array = self.as(ArrayTypeSyntax.self) {
      let objcType = try array.element.objcType()
      return "NSArray<\(objcType)> *\(nonnull)"
    }
    // Dictionary: [:]
    // MARK: React Native doesn't support type parameters for NSDictionary e.g.: NSDictionary<NSString *, NSNumber *>
    else if let dictionary = self.as(DictionaryTypeSyntax.self) {
      // Verify key and value types
      let _ = try dictionary.key.objcType()
      let _ = try dictionary.value.objcType()
      
      return "NSDictionary *\(nonnull)"
    }
    throw Diagnostic(node: self._syntaxNode, message: ErrorMessage.unsupportedType(typeName: "\(trimmed)"))
  }
}
