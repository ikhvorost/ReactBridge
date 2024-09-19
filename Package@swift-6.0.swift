// swift-tools-version: 6.0
//
//  Package.swift
//
//  Created by Iurii Khvorost <iurii.khvorost@gmail.com> on 2024/07/25.
//  Copyright © 2024 Iurii Khvorost. All rights reserved.
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

import PackageDescription
import CompilerPluginSupport

let package = Package(
  name: "ReactBridge",
  platforms: [
    .iOS(.v13),
    .macOS(.v10_15),
    .tvOS(.v13),
    .visionOS(.v1),
    .watchOS(.v6)
  ],
  products: [
    .library(name: "ReactBridge", targets: ["ReactBridge"])
  ],
  dependencies: [
    .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0")
  ],
  targets: [
    .macro(
      name: "ReactBridgeMacros",
      dependencies: [
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
      ]
    ),
    .target(
      name: "ReactBridge",
      dependencies: ["ReactBridgeMacros", "ReactBridgeUtils"]
    ),
    .target(
      name: "ReactBridgeUtils",
      cSettings: [.define("SymbolLinkageMarkers")]
    ),
    .testTarget(
      name: "ReactBridgeTests",
      dependencies: [
        "ReactBridgeMacros",
        .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax")
      ]
    ),
  ],
  swiftLanguageModes: [.v6]
)
