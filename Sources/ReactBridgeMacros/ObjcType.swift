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
import SwiftSyntax
import SwiftDiagnostics


fileprivate let objectMap: [String : [String]] = [
  "id": ["Any", "AnyObject"],
  "NSString": ["String"],
  "NSNumber": [],
  "NSObject": [],
  "NSDate": ["Date"],
  "NSData": ["Data"],
  "NSURL": ["URL"],
  "NSURLRequest": ["URLRequest"],
  "NSArray": ["NSMutableArray"],
  "NSDictionary": ["NSMutableDictionary"],
  "NSSet": ["NSMutableSet"],
  "UIColor": [],
  "NSColor": [],
]

fileprivate let numberMap: [String : [String]] = [
  "BOOL": ["Bool"],
  "NSInteger": ["Int", "Int8", "Int16", "Int32", "Int64"],
  "NSUInteger": ["UInt", "UInt8", "UInt16", "UInt32", "UInt64"],
  "float": ["Float"],
  "CGFloat": [],
  "double": ["Double", "TimeInterval"],
]

fileprivate let structMap: [String : [String]] = [
  "CGPoint": [],
  "CGSize": [],
  "CGRect": [],
]

fileprivate let blockMap: [String : [String]] = [
  "RCTResponseSenderBlock": [],
  "RCTResponseErrorBlock": [],
  
  "RCTPromiseResolveBlock": [],
  "RCTPromiseRejectBlock": [],
  
  "RCTDirectEventBlock": [],
  "RCTBubblingEventBlock": [],
  "RCTCapturingEventBlock": [],
]

fileprivate func objcType(swiftType: String, map: [String : [String]]) -> String? {
  for (objcType, swiftTypes) in map {
    if objcType == swiftType || swiftTypes.contains(swiftType) {
      return objcType
    }
  }
  return nil
}

indirect enum ObjcType {
  case object(String)
  case number(String)
  case `struct`(String)
  case block(String)
  
  case array(ObjcType)
  case dictionary(ObjcType, ObjcType)
  case set(ObjcType)
  case optional(ObjcType)
  
  init?(swiftType: String) {
    if let objcType = objcType(swiftType: swiftType, map: objectMap) {
      self = .object(objcType)
    }
    else if let objcType = objcType(swiftType: swiftType, map: numberMap) {
      self = .number(objcType)
    }
    else if let objcType = objcType(swiftType: swiftType, map: structMap) {
      self = .struct(objcType)
    }
    else if let objcType = objcType(swiftType: swiftType, map: blockMap) {
      self = .block(objcType)
    }
    else {
      return nil
    }
  }
  
  func text(root: Bool = false, container: Bool = false) -> String {
    let nonnull = root ? " _Nonnull" : ""
    
    switch self {
      case .object(let name):
        let asterisk = name != "id" ? "*" : ""
        return "\(name) \(asterisk)\(nonnull)"
        
      case .number(let name):
        return container ? "NSNumber *" : name
        
      case .array(let type):
        return "NSArray<\(type.text(container: true))> *\(nonnull)"
        
      case .dictionary(_, _):
        return "NSDictionary *\(nonnull)"
        
      case .set(_):
        return "NSSet *\(nonnull)"
        
      case .optional(let type):
        return "\(type.text(container: true)) _Nullable"
        
      case .struct(let name), .block(let name):
        return name
    }
  }
  
  func type() -> String {
    switch self {
      case .object(let name), .number(let name), .struct(let name), .block(let name):
        return name
        
      case .array:
        return "NSArray"
        
      case .dictionary:
        return "NSDictionary"
        
      case .set:
        return "NSSet"
        
      case .optional(let type):
        return type.type()
    }
  }
}
