//
//  ReactViewManager.swift
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


public struct ReactViewManager {
  
  enum Message: DiagnosticMessage {
    case classOnly
    case inheritRCTViewManager(name: String)
    
    var severity: DiagnosticSeverity { .error }
    
    var message: String {
      switch self {
        case .classOnly:
          return "@ReactViewManager can only be applied to a class"
        case .inheritRCTViewManager(let name):
          return "'\(name)' must inherit 'RCTViewManager'"
      }
    }
    
    var diagnosticID: MessageID {
      MessageID(domain: "ReactViewManager", id: message)
    }
  }
}

extension ReactViewManager: MemberMacro {
  
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
        throw SyntaxError(sytax: declaration._syntaxNode, message: ReactViewManager.Message.classOnly)
      }
      
      // Error: RCTViewManager
      guard classDecl.inheritanceClause?.description.contains("RCTViewManager") == true else {
        let name = "\(classDecl.name.trimmed)"
        throw SyntaxError(sytax: classDecl.name._syntaxNode, message: Message.inheritRCTViewManager(name: name))
      }
      
      let arguments = node.arguments()
      let jsName = arguments?["jsName"] as? String
      
      var items: [DeclSyntax] = [
        ReactModule.moduleName(name: jsName, override: true),
        ReactModule.registerModule,
        ReactModule.requiresMainQueueSetup(value: true, override: true),
        ReactModule.methodQueue(queue: ".main")
      ]
      
      if let properties = arguments?["properties"] as? [String : String] {
        for (name, type) in properties {
          let swiftType = type.replacingOccurrences(of: ".self", with: "")
          guard let objcType = ObjcType(swiftType: swiftType) else {
            throw "Unsupported variable type: \(swiftType)."
          }
          items.append(propConfig(name: name, objcType: objcType.name))
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
