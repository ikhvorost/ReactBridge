//
//  ErrorMessage.swift
//
//  Created by Iurii Khvorost <iurii.khvorost@gmail.com> on 2023/08/10.
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

import SwiftDiagnostics
import SwiftSyntax


extension Diagnostic: Error {}

enum ErrorMessage: DiagnosticMessage {
  // Errors
  case funcOnly(macroName: String)
  case classOnly(macroName: String)
  case varOnly(macroName: String)
  case varSingleOnly(macroName: String)
  case objcOnly(name: String)
  
  case mustInherit(className: String, superclassName: String)
  case mustConform(className: String, protocolName: String)
  case mustBeClass
  
  case unsupportedType(typeName: String)
  
  // Warnings
  case nonSync
  
  var severity: DiagnosticSeverity {
    switch self {
      case .funcOnly, .classOnly, .varOnly, .varSingleOnly, .objcOnly, .unsupportedType, .mustInherit, .mustConform, .mustBeClass:
        return .error
      case .nonSync:
        return .warning
    }
  }
  
  var message: String {
    switch self {
      case .funcOnly(let macroName):
        return "@\(macroName) can only be applied to a func"
      case .classOnly(let macroName):
        return "@\(macroName) can only be applied to a class"
      case .varOnly(let macroName):
        return "@\(macroName) can only be applied to a var"
      case .varSingleOnly(let macroName):
        return "@\(macroName) can only be applied to a single var"
      case .objcOnly(let name):
        return "'\(name)' must be marked with '@objc'"
      case .mustInherit(let className, let superclassName):
        return "'\(className)' must inherit '\(superclassName)'"
      case .mustConform(let className, let protocolName):
        return "'\(className)' must conform '\(protocolName)'"
      case .mustBeClass:
        return "Return type must be any class type or 'Any'"
      case .unsupportedType(let typeName):
        return "'\(typeName)' type is not supported"
        
      case .nonSync:
        return "Functions with a defined return type should be synchronous"
    }
  }
  
  var diagnosticID: MessageID {
    MessageID(domain: "ReactBridge", id: message)
  }
}
