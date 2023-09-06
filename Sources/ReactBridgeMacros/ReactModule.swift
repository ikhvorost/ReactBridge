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


public struct ReactModule {
  
  private static func diagnostic(declaration: DeclGroupSyntax) -> Diagnostic? {
    // Error: class
    guard let classDecl = declaration.as(ClassDeclSyntax.self) else {
      return Diagnostic(node: declaration._syntaxNode, message: ErrorMessage.classOnly(macroName: "\(self)"))
    }
    
    let className = "\(classDecl.name.trimmed)"
    
    // Error: NSObject
    guard classDecl.inheritanceClause?.description.contains("NSObject") == true else {
      return Diagnostic(node: classDecl.name._syntaxNode, message: ErrorMessage.mustInherit(className: className, superclassName: "NSObject"))
    }
    
    // Error: RCTBridgeModule
    guard classDecl.inheritanceClause?.description.contains("RCTBridgeModule") == true else {
      return Diagnostic(node: classDecl.name._syntaxNode, message: ErrorMessage.mustConform(className: className, protocolName: "RCTBridgeModule"))
    }
    
    return nil
  }
}

extension ReactModule: ExtensionMacro {
  
  static func moduleName(name: String, override: Bool = false) -> String {
    """
    @objc \(override ? "override " : "")class func moduleName() -> String! {
      "\(name)"
    }
    """
  }
  
  static func requiresMainQueueSetup(value: Bool, override: Bool = false) -> String {
    """
    @objc \(override ? "override " : "")class func requiresMainQueueSetup() -> Bool {
      \(value)
    }
    """
  }
  
  private static func methodQueue(queue: String) -> String {
    """
    @objc var methodQueue: DispatchQueue {
      \(queue)
    }
    """
  }
  
  public static func expansion(
    of node: AttributeSyntax, 
    attachedTo declaration: some DeclGroupSyntax,
    providingExtensionsOf type: some TypeSyntaxProtocol,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext)
  throws -> [ExtensionDeclSyntax] 
  {
    if let _ = diagnostic(declaration: declaration) {
      return []
    }
    
    guard let classDecl = declaration.as(ClassDeclSyntax.self) else {
      return []
    }
    
    let className = "\(classDecl.name.trimmed)"
    
    let arguments = node.arguments()
    let jsName = arguments?["jsName"]?.stringValue ?? className
    let mainQueueSetup = arguments?["requiresMainQueueSetup"]?.boolValue == true
      
    var items: [String] = [
      moduleName(name: jsName),
      requiresMainQueueSetup(value: mainQueueSetup)
    ]
    
    if let queue = arguments?["methodQueue"]?.stringValue {
      items.append(methodQueue(queue: queue))
    }
    
    let ext: DeclSyntax =
    """
    extension \(type.trimmed) { // RCTBridgeModule
      \(raw: items.joined(separator: "\n\n"))
    }
    """
    
    return [ext.cast(ExtensionDeclSyntax.self)]
  }
}

extension ReactModule: MemberMacro {
  
  static let registerModule: DeclSyntax =
    """
    @objc static func _registerModule() {
      RCTRegisterModule(self);
    }
    """
  
  public static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    in context: some MacroExpansionContext)
  throws -> [DeclSyntax]
  {
    if let diagnostic = diagnostic(declaration: declaration) {
      context.diagnose(diagnostic)
      return []
    }
    
    return [registerModule]
  }
}
