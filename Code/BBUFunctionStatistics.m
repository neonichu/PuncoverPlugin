//
//  BBUFunctionStatistics.m
//  PuncoverPlugin
//
//  Created by Boris Bügling on 06/09/14.
//  Copyright (c) 2014 Boris Bügling. All rights reserved.
//

#import "BBUFunctionStatistics.h"

@interface BBUFunctionStatistics ()

@property (nonatomic) NSUInteger functionSize;
@property (nonatomic) NSUInteger lineNumber;
@property (nonatomic) NSUInteger stackSize;
@property (nonatomic) NSURL* url;

@end

#pragma mark -

@implementation BBUFunctionStatistics

+(NSArray*)functionStatisticsForFileAtPath:(NSString*)path {
    static dispatch_once_t onceToken;
    static NSDictionary* fileStatistics = nil;
    dispatch_once(&onceToken, ^{
        NSString* filePath = [[NSBundle bundleForClass:self.class] pathForResource:@"test" ofType:@"json"];
        NSData* JSONData = [NSData dataWithContentsOfFile:filePath];
        fileStatistics = [NSJSONSerialization JSONObjectWithData:JSONData
                                                         options:0
                                                           error:nil];
    });

    if (!path) {
        return nil;
    }

    NSArray* fileStatistic = fileStatistics[path];
    NSMutableArray* result = [@[] mutableCopy];

    for (NSDictionary* functionStatistic in fileStatistic) {
        [result addObject:[[[self class] alloc] initWithDictionary:functionStatistic]];
    }

    return result;
}

#pragma mark -

-(instancetype)initWithDictionary:(NSDictionary*)dictionary {
    self = [super init];
    if (self) {
        self.functionSize = [dictionary[@"function_size"] unsignedIntegerValue];
        self.lineNumber = [dictionary[@"line_number"] unsignedIntegerValue];
        self.stackSize = [dictionary[@"stack_size"] unsignedIntegerValue];

        NSString* urlString = dictionary[@"url"];
        if (urlString) {
            self.url = [NSURL URLWithString:urlString];
        }
    }
    return self;
}

@end
