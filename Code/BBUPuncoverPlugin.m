//
//  BBUPuncoverPlugin.m
//  BBUPuncoverPlugin
//
//  Created by Boris Bügling on 06/09/14.
//    Copyright (c) 2014 Boris Bügling. All rights reserved.
//

#import <objc/runtime.h>

#import "BBUFunctionStatistics.h"
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

            __block Class aClass = NSClassFromString(@"DVTTextSidebarView");
            [self swizzleClass:aClass
                      exchange:@selector(_drawLineNumbersInSidebarRect:foldedIndexes:count:linesToInvert:linesToReplace:getParaRectBlock:)
                          with:@selector(puncover_drawLineNumbersInSidebarRect:foldedIndexes:count:linesToInvert:linesToReplace:getParaRectBlock:)];
            [self swizzleClass:aClass
                      exchange:@selector(sidebarWidth)
                          with:@selector(puncover_sidebarWidth)];

#if 0
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                for (NSWindowController* controller in [objc_getClass("IDEWorkspaceWindowController") performSelector:@selector(workspaceWindowControllers)]) {
                    id tabController = [controller performSelector:@selector(activeWorkspaceTabController)];
                    [tabController performSelector:@selector(showUtilities)];
                    //[tabController performSelector:@selector(addAssistantEditor:) withObject:nil];
                    //[tabController performSelector:@selector(changeToAssistantLayout_BH:) withObject:nil];
                    [tabController performSelector:@selector(assistantEditorsLayout)];
                }
            });
#endif
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

@property(nonatomic, readonly) NSURL* currentDocumentURL;
@property(retain, nonatomic) NSFont *lineNumberFont;
@property(copy, nonatomic) NSColor *lineNumberTextColor;

- (void)getParagraphRect:(CGRect *)a0 firstLineRect:(CGRect *)a1 forLineNumber:(NSUInteger)a2;

@end

#pragma mark -

@implementation NSRulerView (Puncover)

@dynamic lineNumberFont;
@dynamic lineNumberTextColor;

#pragma mark -

- (NSAttributedString*)puncover_attributedStringFromString:(NSString*)string {
    if (!self.lineNumberFont || !self.lineNumberTextColor) {
        return nil;
    }

    NSDictionary* attributes = @{ NSFontAttributeName: self.lineNumberFont,
                                  NSForegroundColorAttributeName: self.lineNumberTextColor };
    return [[NSAttributedString alloc] initWithString:string attributes:attributes];
}

- (void)puncover_drawString:(NSString*)string atLine:(NSUInteger)lineNumber {
    NSRect a0, a1;
    [self getParagraphRect:&a0 firstLineRect:&a1 forLineNumber:lineNumber];

    NSAttributedString* currentText = [self puncover_attributedStringFromString:string];

    a0.origin.x += 8.0;
    a0.origin.y -= 1.0;
    [currentText drawAtPoint:a0.origin];
}

- (void)puncover_drawLineNumbersInSidebarRect:(CGRect)rect
                               foldedIndexes:(NSUInteger *)indexes
                                       count:(NSUInteger)indexCount
                               linesToInvert:(id)a3
                              linesToReplace:(id)a4
                            getParaRectBlock:rectBlock
{
    NSString* path = self.currentDocumentURL.path;
    NSArray* stats = [BBUFunctionStatistics functionStatisticsForFileAtPath:path
                                                         forWorkspaceAtPath:[self workspacePath]];

    for (BBUFunctionStatistics* stat in stats) {
        NSUInteger lineNumber = stat.lineNumber;
        for (NSString* line in [stat.shortText componentsSeparatedByString:@"\n"]) {
            [self puncover_drawString:line atLine:lineNumber++];
        }
    }

    [self puncover_drawLineNumbersInSidebarRect:rect
                                 foldedIndexes:indexes
                                         count:indexCount
                                 linesToInvert:a3
                                linesToReplace:a4
                              getParaRectBlock:rectBlock];
}

- (double)puncover_sidebarWidth {
    double originalWidth = [self puncover_sidebarWidth];

    NSAttributedString* widestAttributedString = [self puncover_attributedStringFromString:[BBUFunctionStatistics widestShortTextForFileAtPath:self.currentDocumentURL.path forWorkspaceAtPath:[self workspacePath]]];

    return MIN(100.0, [widestAttributedString size].width + originalWidth);
}

- (NSURL*)currentDocumentURL {
    id workspaceWindowController = [self keyWorkspaceWindowController];
    NSAssert(workspaceWindowController, @"No open window found.");

    id editorArea = [workspaceWindowController performSelector:@selector(editorArea)];
    id document = [editorArea performSelector:@selector(primaryEditorDocument)];

    return [document fileURL];
}

-(NSString*)workspacePath {
    id workspaceWindowController = [self keyWorkspaceWindowController];
    id workspace = [workspaceWindowController valueForKey:@"_workspace"];

    NSString* path = [[workspace valueForKey:@"representingFilePath"] valueForKey:@"_pathString"];
    return [path stringByDeletingLastPathComponent];
}

- (id)keyWorkspaceWindowController {
    NSArray* workspaceWindowControllers = [objc_getClass("IDEWorkspaceWindowController")
                                           performSelector:@selector(workspaceWindowControllers)];

    for (NSWindowController* controller in workspaceWindowControllers) {
        if ([controller.window isKeyWindow]) {
            return controller;
        }
    }

    return workspaceWindowControllers[0];
}

@end
