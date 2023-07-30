//
//  ObjcType.swift
//
//  Created by Iurii Khvorost <iurii.khvorost@gmail.com> on 2023/07/30.
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

import Foundation

struct ObjcType {
  let type: String
  let swiftTypes: [String]
  
  fileprivate func isEqual(swiftType: String) -> Bool {
    return type == swiftType || swiftTypes.contains(swiftType)
  }
  
  fileprivate init(type: String, swiftTypes: [String] = []) {
    self.type = type
    self.swiftTypes = swiftTypes
  }
}

extension ObjcType {
  
  private static let objectTypes: [ObjcType] = [
    // Objects
    ObjcType(type: "id", swiftTypes: ["Any", "AnyObject"]),
    ObjcType(type: "NSString", swiftTypes: ["String"]),
    ObjcType(type: "NSNumber"),
    ObjcType(type: "NSObject"),
    ObjcType(type: "NSDate", swiftTypes: ["Date"]),
    ObjcType(type: "NSData", swiftTypes: ["Data"]),
    ObjcType(type: "NSURL", swiftTypes: ["URL"]),
    ObjcType(type: "NSURLRequest", swiftTypes: ["URLRequest"]),
    ObjcType(type: "NSArray", swiftTypes: ["NSMutableArray"]),
    ObjcType(type: "NSDictionary", swiftTypes: ["NSMutableDictionary"]),
    ObjcType(type: "NSSet", swiftTypes: ["NSMutableSet"]),
  ]
  
  private static let numericTypes: [ObjcType] = [
    ObjcType(type: "BOOL", swiftTypes: ["Bool"]),
    ObjcType(type: "NSInteger", swiftTypes: ["Int", "Int8", "Int16", "Int32", "Int64"]),
    ObjcType(type: "NSUInteger", swiftTypes: ["UInt", "UInt8", "UInt16", "UInt32", "UInt64"]),
    ObjcType(type: "GCFloat", swiftTypes: ["Float"]),
    ObjcType(type: "double", swiftTypes: ["Double"]),
    ObjcType(type: "NSTimeInterval", swiftTypes: ["TimeInterval"]),
  ]
  
  private static let otherTypes: [ObjcType] = [
    ObjcType(type: "CGPoint"),
    ObjcType(type: "RCTResponseSenderBlock"),
    ObjcType(type: "RCTResponseErrorBlock"),
    ObjcType(type: "RCTPromiseResolveBlock"),
    ObjcType(type: "RCTPromiseRejectBlock"),
  ]
  
  enum ObjcTypeKind {
    case object
    case numeric
    case other
  }
  
  static func find(swiftType: String) -> (type: String, kind: ObjcTypeKind)? {
    if let objcType = objectTypes.first(where: { $0.isEqual(swiftType: swiftType) }) {
      let asterisk = objcType.type == "id" ? "" : " *"
      let type = "\(objcType.type)\(asterisk)"
      return (type, .object)
    }
    else if let objcType = numericTypes.first(where: { $0.isEqual(swiftType: swiftType) }) {
      return (objcType.type, .numeric)
    }
    else if let objcType = otherTypes.first(where: { $0.isEqual(swiftType: swiftType) }) {
      return (objcType.type, .other)
    }
    return nil
  }
}
