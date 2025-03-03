//
//  ReactBridgeUtils.m
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

#import <objc/runtime.h>
#import "ReactBridgeUtils.h"

#define let __auto_type const
#define var __auto_type


// From RCTBridgeModule.h
typedef struct RCTMethodInfo {
  const char * jsName;
  const char * objcName;
  BOOL isSync;
} RCTMethodInfo;

static void class_performClassSelector(Class class, SEL selector) {
  unsigned int count = 0;
  let methods = class_copyMethodList(object_getClass(class), &count);
  
  for (var i = 0; i < count; i++) {
    let method = methods[i];
    let methodName = method_getName(method);
    if (sel_isEqual(methodName, selector)) {
      let imp = method_getImplementation(method);
      ((void (*)(Class, SEL))imp)(class, selector);
      break;
    }
  }
      
  free(methods);
}

__attribute__((constructor))
static void load() {
  let selector = @selector(_registerModule);
  
  let processName = [NSProcessInfo.processInfo.processName cStringUsingEncoding: NSUTF8StringEncoding];
  let processNameLength = strlen(processName);
  
  var count = objc_getClassList(NULL, 0);
  let classes = (Class *)malloc(sizeof(Class) * count);
  count = objc_getClassList(classes, count);
  
  dispatch_apply(count, DISPATCH_APPLY_AUTO, ^(size_t index) {
    Class class = classes[index];
    let className = class_getName(class);
    if (strncmp(processName, className, processNameLength) == 0) {
      class_performClassSelector(class, selector);
    }
  });
  
  free(classes);
}

@implementation ReactBridgeUtils

+ (const void *)methodInfo:(NSString *)jsName objcName:(NSString *)objcName isSync:(BOOL)isSync {
  RCTMethodInfo* methodInfo = malloc(sizeof(RCTMethodInfo));
  methodInfo->jsName = strdup([jsName cStringUsingEncoding: NSUTF8StringEncoding]);
  methodInfo->objcName = strdup([objcName cStringUsingEncoding: NSUTF8StringEncoding]);
  methodInfo->isSync = isSync;
  return methodInfo;
}

@end
