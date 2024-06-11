//
//  ReactMethod.swift
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

fileprivate extension String {
  var uppercasedFirst: String {
    prefix(1).uppercased() + dropFirst()
  }
}


struct ReactMethod {
}

extension ReactMethod: PeerMacro {
  
  private static let nonisolatedUnsafe: String = {
#if swift(>=5.10)
    "nonisolated(unsafe) "
#else
    ""
#endif
  }()
  
  static func reactExport(funcName: String, jsName: String, objcName: String, isSync: Bool) -> DeclSyntax {
    """
    @objc static func __rct_export__\(raw: funcName)() -> UnsafePointer<RCTMethodInfo>? {
      struct Static {
        static let jsName = strdup(\(raw: jsName))
        static let objcName = strdup("\(raw: objcName)")
        \(raw: Self.nonisolatedUnsafe)static var methodInfo = RCTMethodInfo(jsName: jsName, objcName: objcName, isSync: \(raw: isSync))
      }
      return withUnsafePointer(to: &Static.methodInfo) { $0 }
    }
    """
  }
  
  private static func objcSelector(funcDecl: FunctionDeclSyntax) throws -> String {
    var selector = "\(funcDecl.name.trimmed)"
    
    let parameterList = funcDecl.signature.parameterClause.parameters
    for param in parameterList {
      let objcType = try param.type.objcType().text(root: true)
      var firstName = "\(param.firstName.trimmed)"
      
      if param == parameterList.first {
        if firstName != "_" {
          if param.secondName == nil {
            selector += "With\(firstName.uppercasedFirst):(\(objcType))\(firstName)"
            continue
          }
          else {
            firstName = firstName.uppercasedFirst
          }
        }
      }
      else {
        selector += " " // Next param
      }
      
      let secondName = param.secondName != nil ? "\(param.secondName!.trimmed)" : firstName
      selector += "\(firstName != "_" ? firstName : ""):(\(objcType))\(secondName)"
    }
    
    return selector
  }

  static func expansion(
    of node: AttributeSyntax,
    providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext)
  throws -> [DeclSyntax]
  {
    do {
      // Error: func
      guard let funcDecl = declaration.as(FunctionDeclSyntax.self) else {
        throw Diagnostic(node: declaration, message: ErrorMessage.funcOnly(macroName: "\(self)"))
      }
      
      // Error: @objc
      guard funcDecl.attributes.isObjc else {
        let funcName = "\(funcDecl.name.trimmed)"
        throw Diagnostic(node: funcDecl, message: ErrorMessage.objcOnly(name: funcName))
      }
    
      let objcName = try objcSelector(funcDecl: funcDecl)
      let funcName = "\(funcDecl.name.trimmed)"
      
      let arguments = node.arguments()
      
      let jsName = arguments["jsName"]?.stringValue ?? "\"\(funcName)\""
      let isSync = arguments["isSync"]?.boolValue == true
      
      // Return type
      if let returnType = funcDecl.signature.returnClause?.type {
        if isSync == false {
          // Warning: isSync
          let diagnostic = Diagnostic(node: node, message: ErrorMessage.nonSync)
          context.diagnose(diagnostic)
        }
        
        let objcType = try returnType.objcType()
        guard case .object = objcType else {
          throw Diagnostic(node: returnType, message: ErrorMessage.mustBeClass)
        }
      }
      
      return [
        reactExport(funcName: funcName, jsName: jsName, objcName: objcName, isSync: isSync)
      ]
    }
    catch let diagnostic as Diagnostic {
      context.diagnose(diagnostic)
    }
    return []
  }
}
