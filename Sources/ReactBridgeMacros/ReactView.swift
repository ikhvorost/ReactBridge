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
      ]
      
      // Properties
      if let properties = arguments?["properties"] as? [String : ExprSyntax] {
        for (name, expr) in properties {
          let objcType = try expr.objcType()
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
