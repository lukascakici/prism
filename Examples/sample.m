// Prism Objective-C sample.
//
// Exercises:
//   - @-keywords (@interface, @implementation, @property, @end, @selector, ...)
//   - NSString literals (@"...")
//   - properties, instance variables
//   - method declarations (- and +) and message sends ([obj msg:arg])
//   - blocks (^void(...))
//   - YES/NO/nil/Nil constants

#import <Foundation/Foundation.h>

#define PRISM_VERSION 1
#define PRISM_NAME    @"Prism Quick Look"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, PRSMLanguage) {
    PRSMLanguageJSON,
    PRSMLanguagePython,
    PRSMLanguageSwift,
    PRSMLanguageObjectiveC,
};

@protocol PRSMTokenizer <NSObject>
@required
- (NSArray<NSString *> *)tokenize:(NSString *)source;
@optional
@property (readonly) NSString *displayName;
@end

@interface PRSMGreeter : NSObject

@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, nullable) NSString *salutation;

+ (instancetype)greeterWithName:(NSString *)name;
- (instancetype)initWithName:(NSString *)name NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (NSString *)greet;
- (void)enumerateLanguages:(void (^)(PRSMLanguage lang, BOOL *stop))block;

@end

@implementation PRSMGreeter {
    NSDate *_createdAt;
}

+ (instancetype)greeterWithName:(NSString *)name {
    return [[self alloc] initWithName:name];
}

- (instancetype)initWithName:(NSString *)name {
    self = [super init];
    if (self) {
        _name = [name copy];
        _salutation = @"Hello";
        _createdAt = [NSDate date];
    }
    return self;
}

- (NSString *)greet {
    return [NSString stringWithFormat:@"%@, %@! (v%d, mask=0x%08lx)",
            self.salutation ?: @"Hi",
            self.name,
            PRISM_VERSION,
            (unsigned long) 0xDEADBEEF];
}

- (void)enumerateLanguages:(void (^)(PRSMLanguage lang, BOOL *stop))block {
    NSArray<NSNumber *> *all = @[ @(PRSMLanguageJSON),
                                  @(PRSMLanguagePython),
                                  @(PRSMLanguageSwift),
                                  @(PRSMLanguageObjectiveC) ];

    BOOL stop = NO;
    for (NSNumber *n in all) {
        if (stop) break;
        block((PRSMLanguage) n.integerValue, &stop);
    }
}

@end

NS_ASSUME_NONNULL_END

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        PRSMGreeter *g = [PRSMGreeter greeterWithName:@"World"];
        NSLog(@"%@", [g greet]);

        [g enumerateLanguages:^(PRSMLanguage lang, BOOL *stop) {
            NSLog(@"language code: %ld", (long) lang);
            if (lang == PRSMLanguageObjectiveC) *stop = YES;
        }];

        SEL selector = @selector(greet);
        if ([g respondsToSelector:selector]) {
            NSString *msg = [g performSelector:selector];
            NSLog(@"via selector: %@", msg);
        }
    }
    return 0;
}
