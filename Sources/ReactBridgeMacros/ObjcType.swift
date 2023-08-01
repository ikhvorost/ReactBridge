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


fileprivate let objectMap: [String : [String]] = [
  "id" : ["Any", "AnyObject"],
  "NSString" : ["String"],
  "NSNumber" : [],
  "NSObject" : [],
  "NSDate" : ["Date"],
  "NSData" : ["Data"],
  "NSURL" : ["URL"],
  "NSURLRequest": ["URLRequest"],
  "NSArray": ["NSMutableArray"],
  "NSDictionary": ["NSMutableDictionary"],
  "NSSet": ["NSMutableSet"],
  "UIColor": [],
]

fileprivate let numericMap: [String : [String]] = [
  "BOOL" : ["Bool"],
  "NSInteger" : ["Int", "Int8", "Int16", "Int32", "Int64"],
  "NSUInteger" : ["UInt", "UInt8", "UInt16", "UInt32", "UInt64"],
  "float" : ["Float"],
  "CGFloat" : [],
  "double" : ["Double"],
  "NSTimeInterval" : ["TimeInterval"],
]

fileprivate let otherMap: [String : [String]] = [
  "CGPoint" : [],
  "CGSize" : [],
  "CGRect" : [],
  "RCTResponseSenderBlock" : [],
  "RCTResponseErrorBlock" : [],
  "RCTPromiseResolveBlock" : [],
  "RCTPromiseRejectBlock" : [],
]

struct ObjcType {
  enum Kind {
    case object
    case numeric
    case other
  }
  
  private static let maps: [(Kind, [String : [String]])] = [
    (.object, objectMap),
    (.numeric, numericMap),
    (.other, otherMap)
  ]
  
  let kind: Kind
  let name: String
  
  init?(swiftType: String) {
    for (kind, map) in Self.maps {
      for (key, value) in map {
        if key == swiftType || value.contains(swiftType) {
          self.kind = kind
          self.name = key
          return
        }
      }
    }
    return nil
  }
}
