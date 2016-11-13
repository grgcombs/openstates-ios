//
//  SLFAnalytics.m
//  Created by Greg Combs on 12/4/11.
//
//  OpenStates by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the BSD-3 License included with this source
// distribution.


#import "SLFAnalytics.h"

#define USE_LOCALYTICS 0

#if USE_LOCALYTICS
#import "SLFLocalytics.h"
#endif

@interface SLFAnalytics()
@property (nonatomic,strong) NSMutableSet *adapters;
- (void)configureAdapters;
@end

@implementation SLFAnalytics
@synthesize adapters = _adapters;

+ (id)sharedAnalytics
{
    static dispatch_once_t pred;
    static SLFAnalytics *foo = nil;
    dispatch_once(&pred, ^{ foo = [[self alloc] init]; });
    return foo;
}

- (id)init {
    self = [super init];
    if (self) {
        [self configureAdapters];
    }
    return self;
}


- (void)configureAdapters {
    self.adapters = [NSMutableSet set];

#if USE_LOCALYTICS
    [self.adapters addObject:[[[SLFLocalytics alloc] init] autorelease]];
#endif
}

- (void)beginTracking {
    if (!_adapters.count)
        [self configureAdapters];
    
    for (id<SLFAnalyticsAdapter> adapter in _adapters)
        [adapter beginTracking];
}

- (void)endTracking {
    for (id<SLFAnalyticsAdapter> adapter in _adapters)
        [adapter endTracking];
    self.adapters = nil;
}

- (void)pauseTracking {
    for (id<SLFAnalyticsAdapter> adapter in _adapters)
        [adapter pauseTracking];
}

- (void)resumeTracking {    
    for (id<SLFAnalyticsAdapter> adapter in _adapters)
        [adapter resumeTracking];
}

- (void)tagEnvironmentVariables:(NSDictionary *)variables {
    variables = SLFTypeDictionaryOrNil(variables);
    for (id<SLFAnalyticsAdapter> adapter in _adapters) {
        if (![adapter isOptedIn] || !variables.count)
            continue;
        [adapter tagEnvironmentVariables:variables];
    }
}

- (void)tagEvent:(NSString *)event attributes:(NSDictionary *)attributes {
    event = SLFTypeNonEmptyStringOrNil(event);
    for (id<SLFAnalyticsAdapter> adapter in _adapters) {
        if (![adapter isOptedIn] || !event)
            continue;
        [adapter tagEvent:event attributes:attributes];
    }
}

- (void)tagEvent:(NSString *)event {
    event = SLFTypeNonEmptyStringOrNil(event);
    [self tagEvent:event attributes:nil];
}

- (void)setOptIn:(BOOL)optedIn {
    for (id<SLFAnalyticsAdapter> adapter in _adapters)
        [adapter setOptIn:optedIn];
}

- (BOOL)isOptedIn {
    for (id<SLFAnalyticsAdapter> adapter in _adapters)
        if (![adapter isOptedIn])
            return NO;
    return YES;
}

@end
