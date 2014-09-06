//
//  BBUPuncoverPlugin.m
//  BBUPuncoverPlugin
//
//  Created by Boris Bügling on 06/09/14.
//    Copyright (c) 2014 Boris Bügling. All rights reserved.
//

#import <objc/runtime.h>

#import "BBUPuncoverPlugin.h"

static BBUPuncoverPlugin *sharedPlugin;

@interface BBUPuncoverPlugin()

@property (nonatomic, strong) NSBundle *bundle;

@end

#pragma mark -

@implementation BBUPuncoverPlugin

+ (void)pluginDidLoad:(NSBundle *)plugin
{
    static dispatch_once_t onceToken;
    NSString *currentApplicationName = [[NSBundle mainBundle] infoDictionary][@"CFBundleName"];
    if ([currentApplicationName isEqual:@"Xcode"]) {
        dispatch_once(&onceToken, ^{
            sharedPlugin = [[self alloc] initWithBundle:plugin];

            Class aClass = NSClassFromString(@"DVTTextSidebarView");
            [self swizzleClass:aClass
                      exchange:@selector(_drawLineNumbersInSidebarRect:foldedIndexes:count:linesToInvert:linesToReplace:getParaRectBlock:)
                          with:@selector(puncover_drawLineNumbersInSidebarRect:foldedIndexes:count:linesToInvert:linesToReplace:getParaRectBlock:)];
            [self swizzleClass:aClass
                      exchange:@selector(sidebarWidth)
                          with:@selector(puncover_sidebarWidth)];
        });
    }
}

+ (void)swizzleClass:(Class)aClass exchange:(SEL)origMethod with:(SEL)altMethod
{
    method_exchangeImplementations(class_getInstanceMethod(aClass, origMethod),
                                   class_getInstanceMethod(aClass, altMethod));
}

#pragma mark -

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithBundle:(NSBundle *)plugin
{
    if (self = [super init]) {
        self.bundle = plugin;
    }
    return self;
}

@end

#pragma mark -

@interface NSRulerView (Puncover)

@property(retain, nonatomic) NSFont *lineNumberFont;
@property(copy, nonatomic) NSColor *lineNumberTextColor;

- (void)getParagraphRect:(CGRect *)a0 firstLineRect:(CGRect *)a1 forLineNumber:(NSUInteger)a2;

@end

#pragma mark -

@implementation NSRulerView (Puncover)

@dynamic lineNumberFont;
@dynamic lineNumberTextColor;

#pragma mark -

- (void)puncover_drawLineNumbersInSidebarRect:(CGRect)rect
                               foldedIndexes:(NSUInteger *)indexes
                                       count:(NSUInteger)indexCount
                               linesToInvert:(id)a3
                              linesToReplace:(id)a4
                            getParaRectBlock:rectBlock
{
    CGRect a0, a1;
    [self getParagraphRect:&a0 firstLineRect:&a1 forLineNumber:20];

    NSDictionary* attributes = @{ NSFontAttributeName: self.lineNumberFont,
                                  NSForegroundColorAttributeName: self.lineNumberTextColor };
    NSAttributedString * currentText =[[NSAttributedString alloc] initWithString:@"Cat" attributes: attributes];
    [currentText drawAtPoint:a0.origin];

    [self puncover_drawLineNumbersInSidebarRect:rect
                                 foldedIndexes:indexes
                                         count:indexCount
                                 linesToInvert:a3
                                linesToReplace:a4
                              getParaRectBlock:rectBlock];
}

- (double)puncover_sidebarWidth {
    return 80.0;
}

@end
