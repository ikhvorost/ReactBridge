//
//  ReactViewProperty.swift
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


public struct ReactViewProperty {
}

extension ReactViewProperty: PeerMacro {
  
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
