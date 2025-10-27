//
//  ReactModule.swift
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


struct ReactModule {
}

extension ReactModule: MemberMacro {
  
  static let registerModule: DeclSyntax =
    """
    @objc static func _registerModule() {
      RCTRegisterModule(self);
    }
    """
  
  static func moduleName(name: String, override: Bool = false) -> DeclSyntax {
    """
    @objc \(raw: override ? "override " : "")class func moduleName() -> String! {
      \(raw: name)
    }
    """
  }
  
  static func requiresMainQueueSetup(value: Bool, override: Bool = false) -> DeclSyntax {
    """
    @objc \(raw: override ? "override " : "")class func requiresMainQueueSetup() -> Bool {
      \(raw: value)
    }
    """
  }
  
  static func methodQueue(queue: String, override: Bool = false) -> DeclSyntax {
    """
    @objc \(raw: override ? "override " : "")var methodQueue: DispatchQueue {
      \(raw: queue)
    }
    """
  }
  
  static func expansion(of node: AttributeSyntax, providingMembersOf declaration: some DeclGroupSyntax, conformingTo protocols: [TypeSyntax], in context: some MacroExpansionContext) throws -> [DeclSyntax] {
    do {
      // Error: class
      guard let classDecl = declaration.as(ClassDeclSyntax.self) else {
        throw Diagnostic(node: declaration, message: ErrorMessage.classOnly(macroName: "\(self)"))
      }
      
      let className = "\(classDecl.name.trimmed)"
      
      guard let inheritance = classDecl.inheritanceClause?.description else {
        throw Diagnostic(node: classDecl.name, message: ErrorMessage.mustInherit(className: className, superclassName: "NSObject"))
      }
      
      var override = false
      if inheritance.contains("NSObject") {
        if inheritance.contains("RCTBridgeModule") == false {
          throw Diagnostic(node: classDecl.name, message: ErrorMessage.mustConform(className: className, protocolName: "RCTBridgeModule"))
        }
      }
      else {
        override = true
      }
      
      let arguments = node.arguments()
      
      let jsName = arguments["jsName"]?.stringValue ?? "\"\(className)\""
      let mainQueueSetup = arguments["requiresMainQueueSetup"]?.boolValue == true
      
      var items: [DeclSyntax] = [
        moduleName(name: jsName, override: override),
        requiresMainQueueSetup(value: mainQueueSetup, override: override),
        registerModule
      ]
      
      if let queue = arguments["methodQueue"]?.stringValue {
        items.append(methodQueue(queue: queue, override: override))
      }
      
      return items
    }
    catch let diagnostic as Diagnostic {
      context.diagnose(diagnostic)
    }
    return []
  }
}
