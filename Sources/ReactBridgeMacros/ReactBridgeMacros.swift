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

import Foundation
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxMacros

extension String {
  private static let quotes = CharacterSet(charactersIn: "\"")
  
  var trimmedQuotes: String {
    trimmingCharacters(in: Self.quotes)
  }
}

extension String: LocalizedError {
  public var errorDescription: String? { self }
}

extension Dictionary {
  func mergingNew(dict: Dictionary) -> Dictionary {
    merging(dict) { _, new in new }
  }
}

extension AttributeSyntax {
  
  func arguments() -> [String : Any]? {
    arguments?.as(LabeledExprListSyntax.self)?
      .compactMap {
        guard let name = $0.label?.text else {
          return nil
        }
        
        if let stringLiteral = $0.expression.as(StringLiteralExprSyntax.self)?.trimmed {
          let value = "\(stringLiteral)".trimmedQuotes
          return [name : value]
        }
        else if let booleanLiteral = $0.expression.as(BooleanLiteralExprSyntax.self) {
          let value = booleanLiteral.literal.tokenKind == .keyword(.true)
          return [name : value]
          //return [name : "\(booleanLiteral)" == "true"]
        }
        else if let dictionary = $0.expression.as(DictionaryExprSyntax.self), let list = dictionary.content.as(DictionaryElementListSyntax.self) {
          let dict: [String : String] = list
            .map {
              let key = "\($0.key.trimmed)".trimmedQuotes
              let value = "\($0.value.trimmed)"
              return [key : value]
            }
            .reduce([:], { $0.mergingNew(dict: $1) })
          return [name : dict]
        }
        return nil
      }
      .reduce([:], { $0.mergingNew(dict: $1) })
  }
}

@main
struct ReactBridgePlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    ReactModule.self,
    ReactMethod.self,
    ReactViewManager.self,
  ]
}
