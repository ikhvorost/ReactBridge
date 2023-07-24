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

public struct ReactModule {
}

extension ReactModule: ConformanceMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingConformancesOf declaration: some DeclGroupSyntax,
    in context: some MacroExpansionContext)
  throws -> [(TypeSyntax, GenericWhereClauseSyntax?)] {
    let syntax = TypeSyntax(stringLiteral: "RCTBridgeModule")
    return [( syntax, nil )]
  }
}

extension ReactModule: MemberMacro {
  
  private static func moduleName(name: String?) -> String {
    """
    @objc static func moduleName() -> String! {
      \(name != nil ? "\(name!)" : "String(describing: self)")
    }
    """
  }
  
  private static let registerModule =
    """
    @objc static func _registerModule() {
      RCTRegisterModule(self);
    }
    """
  
  private static let requiresMainQueueSetup =
    """
    @objc static func requiresMainQueueSetup() -> Bool {
      return true
    }
    """
  
  public static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    in context: some MacroExpansionContext)
  throws -> [DeclSyntax] {
    guard let _ = declaration.as(ClassDeclSyntax.self) else {
      throw "@\(self) only works on classes."
    }
    
    let arguments = arguments(node: node)
    
    var items = [
      moduleName(name: arguments["jsName"]),
      registerModule,
    ]
    
    if arguments["isMainQueue"] == "true" {
      items.append(requiresMainQueueSetup)
    }
    
    return items.map { DeclSyntax(stringLiteral: $0) }
  }
}
