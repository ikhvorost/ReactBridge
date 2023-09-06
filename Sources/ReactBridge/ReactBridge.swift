//
//  ReactBridge.swift
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


@attached(extension, /*conformances: RCTBridgeModule, */names: named(moduleName), named(requiresMainQueueSetup), named(methodQueue))
@attached(member, names: named(_registerModule))
public macro ReactModule(
  jsName: String? = nil,
  requiresMainQueueSetup: Bool = false,
  methodQueue: DispatchQueue? = nil
) = #externalMacro(module: "ReactBridgeMacros", type: "ReactModule")

@attached(peer, names: prefixed(__rct_export__))
public macro ReactMethod(jsName: String? = nil, isSync: Bool = false) = #externalMacro(module: "ReactBridgeMacros", type: "ReactMethod")

@attached(member, names: named(_registerModule), named(moduleName), named(requiresMainQueueSetup))
public macro ReactView(jsName: String? = nil) = #externalMacro(module: "ReactBridgeMacros", type: "ReactView")

@attached(peer, names: prefixed(propConfig_))
public macro ReactProperty() = #externalMacro(module: "ReactBridgeMacros", type: "ReactProperty")
