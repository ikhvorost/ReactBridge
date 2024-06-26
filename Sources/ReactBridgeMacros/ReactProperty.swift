//
//  ReactProperty.swift
//
//  Created by Iurii Khvorost <iurii.khvorost@gmail.com> on 2023/09/06.
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


struct ReactProperty {
}

extension ReactProperty: PeerMacro {
  
  private static func propConfig(name: String, objcType: String, keyPath: String) -> DeclSyntax {
    """
    @objc static func propConfig_\(raw: name)() -> [String] {
      ["\(raw: objcType)", \(raw: keyPath)]
    }
    """
  }
  
  static func expansion(
    of node: AttributeSyntax,
    providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext) 
  throws -> [DeclSyntax] {
    do {
      // Error: var
      guard let varDecl = declaration.as(VariableDeclSyntax.self) else {
        throw Diagnostic(node: declaration, message: ErrorMessage.varOnly(macroName: "\(self)"))
      }
      
      // Error: single var
      guard varDecl.bindings.count == 1, let item = varDecl.bindings.first else {
        throw Diagnostic(node: varDecl.bindings, message: ErrorMessage.varSingleOnly(macroName: "\(self)"))
      }
      
      let name = "\(item.pattern.trimmed)"
      
      // Error: no type
      guard let type = item.typeAnnotation?.type else {
        throw Diagnostic(node: item, message: ErrorMessage.varNoType(name: name))
      }
      let objcType = try type.objcType()
      
      let arguments = node.arguments()
      let isCustom = arguments["isCustom"]?.boolValue == true
      let keyPath = isCustom
        ? #""__custom__""#
        : arguments["keyPath"]?.stringValue ?? #""\#(name)""#
      
      return [
        propConfig(name: name, objcType: objcType.type(), keyPath: keyPath)
      ]
    }
    catch let diagnostic as Diagnostic {
      context.diagnose(diagnostic)
    }
    return []
  }
}
