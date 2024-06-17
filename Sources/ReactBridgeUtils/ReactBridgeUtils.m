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
#import <Foundation/Foundation.h>
#import "ReactBridgeUtils.h"


// From RCTBridgeModule.h
typedef struct RCTMethodInfo {
  const char * jsName;
  const char * objcName;
  BOOL isSync;
} RCTMethodInfo;

@implementation ReactBridgeUtils

+ (void)load {
  SEL selector = @selector(_registerModule);
  
  int numClasses = objc_getClassList(NULL, 0);
  Class* classes = (Class *)malloc(sizeof(Class) * numClasses);
  numClasses = objc_getClassList(classes, numClasses);
  
  for (int i = 0; i < numClasses; i++) {
    Class class = classes[i];
    
    unsigned int numMethods = 0;
    Method *methods = class_copyMethodList(object_getClass(class), &numMethods);
    for (int j = 0; j < numMethods; j++) {
      Method method = methods[j];
      if (sel_isEqual(method_getName(method), selector)) {
        IMP imp = method_getImplementation(method);
        ((void (*)(Class, SEL))imp)(class, selector);
        continue;
      }
    }
    free(methods);
  }
  free(classes);
}

+ (const void *)methodInfo:(NSString *)jsName objcName:(NSString *)objcName isSync:(BOOL)isSync {
  RCTMethodInfo* methodInfo = malloc(sizeof(RCTMethodInfo));
  methodInfo->jsName = strdup([jsName cStringUsingEncoding: NSUTF8StringEncoding]);
  methodInfo->objcName = strdup([objcName cStringUsingEncoding: NSUTF8StringEncoding]);
  methodInfo->isSync = isSync;
  return methodInfo;
}

@end
