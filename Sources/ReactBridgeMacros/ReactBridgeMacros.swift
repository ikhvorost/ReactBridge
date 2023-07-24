//
//  ReactBridgeMacros.swift
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

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxMacros
import Foundation


extension String: LocalizedError {
  public var errorDescription: String? { self }
}

func arguments(node: AttributeSyntax) -> [String : String] {
  var result = [String : String]()
  
  if let list = node.argument?.as(TupleExprElementListSyntax.self) {
    for item in list {
      guard let name = item.label?.text else {
        continue
      }
      let value = item.expression.description.replacingOccurrences(of: "\"", with: "")
      result[name] = value
    }
  }
  return result
}

struct ObjcType {
  let objcType: String
  let swiftTypes: [String]
  let custom: ((String) -> Bool)?
  
  func isEqual(swiftType: String) -> Bool {
    objcType == swiftType || swiftTypes.contains(swiftType) || custom?(swiftType) == true
  }
  
  init(objcType: String, swiftTypes: [String] = [], custom: ((String) -> Bool)? = nil) {
    self.objcType = objcType
    self.swiftTypes = swiftTypes
    self.custom = custom
  }
}

let objcTypes: [ObjcType] = [
  ObjcType(objcType: "NSString", swiftTypes: ["String"]),
  ObjcType(objcType: "BOOL", swiftTypes: ["Bool"]),
  ObjcType(objcType: "NSInteger", swiftTypes: ["Int", "Int8", "Int16", "Int32", "Int64"]),
  ObjcType(objcType: "NSUInteger", swiftTypes: ["UInt", "UInt8", "UInt16", "UInt32", "UInt64"]),
  ObjcType(objcType: "NSNumber"),
  ObjcType(objcType: "GCFloat", swiftTypes: ["Float"]),
  ObjcType(objcType: "double", swiftTypes: ["Double"]),
  ObjcType(objcType: "NSArray", swiftTypes: ["NSMutableArray"], custom: {
    $0.hasPrefix("Array<") || ($0.hasPrefix("[") && !$0.contains(":") && $0.hasSuffix("]"))
  }),
  ObjcType(objcType: "NSDictionary", swiftTypes: ["NSMutableDictionary"], custom: {
    $0.hasPrefix("Dictionary<") || ($0.hasPrefix("[") && $0.contains(":") && $0.hasSuffix("]"))
  }),
  ObjcType(objcType: "RCTResponseSenderBlock"),
  ObjcType(objcType: "RCTResponseErrorBlock"),
  ObjcType(objcType: "RCTPromiseResolveBlock"),
  ObjcType(objcType: "RCTPromiseRejectBlock"),
  ObjcType(objcType: "NSObject"),
  ObjcType(objcType: "id", swiftTypes: ["Any", "AnyObject"]),
]

func convertType(swiftType: String) -> String? {
  let optionalSet = CharacterSet(["?", "!"])
  let type = swiftType.trimmingCharacters(in: optionalSet)
  let first = objcTypes.first { $0.isEqual(swiftType: type) }
  return first?.objcType
}

@main
struct ReactBridgePlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    ReactModule.self,
    ReactMethod.self,
    ReactViewProperty.self,
  ]
}
