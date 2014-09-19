//
//  BBUFunctionStatistics.h
//  PuncoverPlugin
//
//  Created by Boris Bügling on 06/09/14.
//  Copyright (c) 2014 Boris Bügling. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface BBUFunctionStatistics : NSObject

@property (nonatomic, readonly) NSColor* backgroundColor;
@property (nonatomic, readonly) NSUInteger lineNumber;
@property (nonatomic, readonly) NSString* longText;
@property (nonatomic, readonly) NSString* shortText;
@property (nonatomic, readonly) NSURL* url;

+(NSArray*)functionStatisticsForFileAtPath:(NSString*)path
                        forWorkspaceAtPath:(NSString*)workspacePath;
+(NSString*)widestShortTextForFileAtPath:(NSString*)path
                      forWorkspaceAtPath:(NSString*)workspacePath;

@end
