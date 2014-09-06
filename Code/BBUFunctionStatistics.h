//
//  BBUFunctionStatistics.h
//  PuncoverPlugin
//
//  Created by Boris Bügling on 06/09/14.
//  Copyright (c) 2014 Boris Bügling. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BBUFunctionStatistics : NSObject

@property (nonatomic, readonly) NSUInteger functionSize;
@property (nonatomic, readonly) NSUInteger lineNumber;
@property (nonatomic, readonly) NSUInteger stackSize;
@property (nonatomic, readonly) NSURL* url;

+(NSArray*)functionStatisticsForFileAtPath:(NSString*)path;

@end
