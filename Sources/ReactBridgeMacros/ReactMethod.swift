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

public struct ReactMethod {
}

extension ReactMethod: PeerMacro {
  private static func methodInfo(varName: String, jsName: String, objcName: String, isSync: Bool) -> String {
    """
    private static var \(varName) = RCTMethodInfo(
      jsName: NSString(string:"\(jsName)").utf8String,
      objcName: NSString(string:"\(objcName)").utf8String,
      isSync: \(isSync)
    )
    """
  }
  
  private static func reactExport(varName: String) -> String {
    """
    @objc static func __rct_export__\(varName)() -> UnsafePointer<RCTMethodInfo>? {
      withUnsafePointer(to: &\(varName)) { $0 }
    }
    """
  }
  
  public static func expansion(
    of node: AttributeSyntax,
    providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext)
  throws -> [DeclSyntax] {
    guard let funcDecl = declaration.as(FunctionDeclSyntax.self) else {
      throw "@\(self) only works on functions."
    }
    
    var objcName = funcDecl.identifier.text
    // Parameter list
    let parameterList = funcDecl.signature.input.parameterList
    if parameterList.count > 0 {
      objcName += ":"
      for item in parameterList {
        guard item != parameterList.first else {
          continue
        }
        let firstName = item.firstName.description.trimmingCharacters(in: .whitespaces)
        objcName += "\(firstName):"
      }
    }
    
    let varName = "_" + objcName.replacingOccurrences(of: ":", with: "_")
    
    let arguments = arguments(node: node)
    let jsName = arguments["jsName"] ?? ""
    let isSync = arguments["isSync"] == "true"
    
    let items = [
      methodInfo(varName: varName, jsName: jsName, objcName: objcName, isSync: isSync),
      reactExport(varName: varName),
    ]
    return items.map { DeclSyntax(stringLiteral: $0) }
  }
}
