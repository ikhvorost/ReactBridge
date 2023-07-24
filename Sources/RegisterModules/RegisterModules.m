//
//  RegisterModules.m
//  
//
//  Created by Iurii Khvorost on 20.07.2023.
//

#import <objc/runtime.h>

__attribute__((constructor))
static void registerModules(void) {
    SEL selector = @selector(_registerModule);
    
    int numClasses = objc_getClassList(NULL, 0);
    Class* classes = (Class *)malloc(sizeof(Class) * numClasses);
    numClasses = objc_getClassList(classes, numClasses);
    
    for (int i = 0; i < numClasses; i++) {
        Class class = classes[i];
        @try {
            Method method = class_getClassMethod(class, selector);
            if (method != NULL) {
                IMP imp = method_getImplementation(method);
                ((id (*)(Class, SEL))imp)(class, selector);
            }
        }
        @catch(id exception) {
        }
    }
    free(classes);
}
