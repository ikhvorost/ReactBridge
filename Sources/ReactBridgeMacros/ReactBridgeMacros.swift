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
  private static let whitespacesAndQuotes = CharacterSet(charactersIn: " \"")
  
  var trimmed: String {
    trimmingCharacters(in: Self.whitespacesAndQuotes)
  }
}

extension String: LocalizedError {
  public var errorDescription: String? { self }
}

extension AttributeSyntax {
  
  func arguments() -> [String : String]? {
    argument?.as(TupleExprElementListSyntax.self)?
      .compactMap {
        guard let name = $0.label?.text else {
          return nil
        }
        let value = $0.expression.description.trimmed
        return [name : value]
      }
      .reduce([String : String](), { $0.merging($1) { _, new in new } })
  }
}

@main
struct ReactBridgePlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    ReactModule.self,
    ReactMethod.self,
    ReactViewProperty.self,
  ]
}
