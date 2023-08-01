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


struct SyntaxError: Error {
  let sytax: Syntax
  let message: DiagnosticMessage
}

public struct ReactModule {
  
  enum Message: DiagnosticMessage {
    case classOnly
    case inheritNSObject(name: String)
    
    var severity: DiagnosticSeverity { .error }
    
    var message: String {
      switch self {
        case .classOnly:
          return "@ReactModule can only be applied to a class"
        case .inheritNSObject(let name):
          return String(format: "'%@' must inherit 'NSObject'", name)
      }
    }
    
    var diagnosticID: MessageID {
      MessageID(domain: "ReactModule", id: message)
    }
  }
}

extension ReactModule: ConformanceMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingConformancesOf declaration: some DeclGroupSyntax,
    in context: some MacroExpansionContext)
  throws -> [(TypeSyntax, GenericWhereClauseSyntax?)]
  {
    return [("RCTBridgeModule", nil)]
  }
}

extension ReactModule: MemberMacro {
  
  private static func moduleName(name: String?) -> DeclSyntax {
    """
    @objc static func moduleName() -> String! {
      "\(raw: name ?? "\\(self)")"
    }
    """
  }
  
  private static let registerModule: DeclSyntax =
    """
    @objc static func _registerModule() {
      RCTRegisterModule(self);
    }
    """
  
  private static func requiresMainQueueSetup(value: Bool) -> DeclSyntax {
    """
    @objc static func requiresMainQueueSetup() -> Bool {
      \(raw: value)
    }
    """
  }
  
  private static func methodQueue(queue: String) -> DeclSyntax {
    """
    @objc func methodQueue() -> DispatchQueue {
      \(raw: queue)
    }
    """
  }
  
  public static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    in context: some MacroExpansionContext)
  throws -> [DeclSyntax]
  {
    do {
      // Error: class
      guard let classDecl = declaration.as(ClassDeclSyntax.self) else {
        throw SyntaxError(sytax: declaration._syntaxNode, message: Message.classOnly)
      }
      
      // Error: NSObject
      guard classDecl.inheritanceClause?.description.contains("NSObject") == true else {
        let name = classDecl.identifier.description.trimmed
        throw SyntaxError(sytax: classDecl._syntaxNode, message: Message.inheritNSObject(name: name))
      }
      
      let arguments = node.arguments()
      
      var items: [DeclSyntax] = [
        moduleName(name: arguments?["jsName"]),
        registerModule,
        requiresMainQueueSetup(value: arguments?["requiresMainQueueSetup"] == "true")
      ]
      
      if let queue = arguments?["methodQueue"] {
        items.append(methodQueue(queue: queue))
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
