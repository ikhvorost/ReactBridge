#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ReactBridgeUtils: NSObject

+ (const void *)methodInfo:(NSString *)jsName objcName:(NSString *)objcName isSync:(BOOL)isSync;

@end

NS_ASSUME_NONNULL_END
