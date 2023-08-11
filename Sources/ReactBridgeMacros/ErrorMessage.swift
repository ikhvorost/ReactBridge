//
//  ObjcType.swift
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


enum ErrorMessage: DiagnosticMessage, Equatable {
  // Error
  case funcOnly(macroName: String)
  case classOnly(macroName: String)
  case objcOnly(funcName: String)
  case mustInherit(className: String, parentName: String)
  case unsupportedType(typeName: String)
  
  // Warning
  case nonSync
  case nonClassReturnType
  
  var severity: DiagnosticSeverity {
    switch self {
      case .funcOnly, .classOnly, .objcOnly, .unsupportedType, .mustInherit:
        return .error
      case .nonSync, .nonClassReturnType:
        return .warning
    }
  }
  
  var message: String {
    switch self {
      case .funcOnly(let macroName):
        return "@\(macroName) can only be applied to a func"
      case .classOnly(let macroName):
        return "@\(macroName) can only be applied to a class"
      case .objcOnly(let funcName):
        return "'\(funcName)' must be marked with '@objc'"
      case .mustInherit(let className, let parentName):
        return "'\(className)' must inherit '\(parentName)'"
      case .unsupportedType(let typeName):
        return "'\(typeName)' type is not supported"
        
      case .nonClassReturnType:
        return "Return type must be a class type or 'Any'"
      case .nonSync:
        return "Functions with a defined return type should be synchronous"
    }
  }
  
  var diagnosticID: MessageID {
    MessageID(domain: "ReactBridge", id: message)
  }
}
