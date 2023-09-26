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


struct ReactView {
}

extension ReactView: MemberMacro {
  
  static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    in context: some MacroExpansionContext)
  throws -> [DeclSyntax] 
  {
    do {
      // Error: class
      guard let classDecl = declaration.as(ClassDeclSyntax.self) else {
        throw Diagnostic(node: declaration, message: ErrorMessage.classOnly(macroName: "\(self)"))
      }
      
      let className = "\(classDecl.name.trimmed)"
      
      // Error: RCTViewManager
      guard classDecl.inheritanceClause?.description.contains("RCTViewManager") == true else {
        throw Diagnostic(node: classDecl.name, message: ErrorMessage.mustInherit(className: className, superclassName: "RCTViewManager"))
      }
      
      let jsName = node.arguments()["jsName"]?.stringValue ?? "\"\(className)\""
      
      return [
        ReactModule.registerModule,
        ReactModule.moduleName(name: jsName, override: true),
        ReactModule.requiresMainQueueSetup(value: true, override: true),
      ]
    }
    catch let diagnostic as Diagnostic {
      context.diagnose(diagnostic)
    }
    return []
  }
}
