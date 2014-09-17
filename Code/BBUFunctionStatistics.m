//
//  BBUFunctionStatistics.m
//  PuncoverPlugin
//
//  Created by Boris Bügling on 06/09/14.
//  Copyright (c) 2014 Boris Bügling. All rights reserved.
//

#import "BBUFunctionStatistics.h"

static NSString* const kLastModified    = @"LastModifiedKey";
static NSString* const kJSONData        = @"JSONDataKey";

static NSMutableDictionary* JSONLastModified;

@interface BBUFunctionStatistics ()

@property (nonatomic) NSUInteger lineNumber;
@property (nonatomic) NSString* longText;
@property (nonatomic) NSString* shortText;
@property (nonatomic) NSURL* url;

@end

#pragma mark -

@implementation BBUFunctionStatistics

+(void)load {
    JSONLastModified = [@{} mutableCopy];
}

+(NSDictionary*)fileStatisticsForWorkspaceAtPath:(NSString*)workspacePath {
    NSString* filePath = [workspacePath stringByAppendingPathComponent:@".gutter.json"];
    NSDictionary* attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
    NSDate* currentModified = attrs[NSFileModificationDate];

    if (!attrs) {
        return nil;
    }

    NSDictionary* cachedData = JSONLastModified[filePath];

    if (cachedData) {
        NSDate* lastModified = cachedData[kLastModified];
        if ([lastModified compare:currentModified] != NSOrderedAscending) {
            return cachedData[kJSONData];
        }
    }

    NSData* JSONData = [NSData dataWithContentsOfFile:filePath];

    if (!JSONData) {
        return nil;
    }

    NSDictionary* JSONDict = [NSJSONSerialization JSONObjectWithData:JSONData options:0 error:nil];
    JSONLastModified[filePath] = @{ kLastModified: currentModified, kJSONData: JSONDict };
    return JSONDict;
}

+(NSArray*)functionStatisticsForFileAtPath:(NSString*)path
                        forWorkspaceAtPath:(NSString*)workspacePath {
    if (!path || !workspacePath) {
        return nil;
    }

    path = [path stringByReplacingOccurrencesOfString:workspacePath withString:@""];

    if (path.length < 1) {
        return @[];
    }

    path = [path substringFromIndex:1];

    NSDictionary* fileStatistics = [self fileStatisticsForWorkspaceAtPath:workspacePath];
    NSArray* fileStatistic = fileStatistics[@"symbols_by_file"][path];
    NSMutableArray* result = [@[] mutableCopy];

    for (NSDictionary* functionStatistic in fileStatistic) {
        [result addObject:[[[self class] alloc] initWithDictionary:functionStatistic]];
    }

    return result;
}

+(NSString*)widestShortTextForFileAtPath:(NSString*)path
                      forWorkspaceAtPath:(NSString*)workspacePath {
    NSArray* functionStatistics = [self functionStatisticsForFileAtPath:path
                                                     forWorkspaceAtPath:workspacePath];
    NSString* widestShortText = @"";

    for (BBUFunctionStatistics* functionStatistic in functionStatistics) {
        if (functionStatistic.shortText.length > widestShortText.length) {
            widestShortText = functionStatistic.shortText;
        }
    }

    return widestShortText;
}

#pragma mark -

-(instancetype)initWithDictionary:(NSDictionary*)dictionary {
    self = [super init];
    if (self) {
        self.lineNumber = [dictionary[@"line"] unsignedIntegerValue];
        self.longText = dictionary[@"long_text"];
        self.shortText = dictionary[@"short_text"];

        NSString* urlString = dictionary[@"url"];
        if (urlString) {
            self.url = [NSURL URLWithString:urlString];
        }
    }
    return self;
}

@end
