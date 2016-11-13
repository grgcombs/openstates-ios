//
//  SLFiCloudSync.m
//  Created by Greg Combs on 12/5/11.
//
//  OpenStates by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the BSD-3 License included with this source
// distribution.


#import "SLFiCloudSync.h"
#import "SLFPersistenceManager.h"
#import <SLFRestKit/RestKit.h>

NSString * const kSLFiCloudSyncNotification = @"SLFiCloudSyncDidUpdate";

@implementation SLFiCloudSync

+(void)updateToiCloud:(NSNotification*) notificationObject {
    RKLogInfo(@"Updating to iCloud");
    SLFPersistenceManager *persist = [SLFPersistenceManager sharedPersistence];
    NSDictionary *local = [persist exportSettings];
    [local enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [[NSUbiquitousKeyValueStore defaultStore] setObject:obj forKey:key];
    }];
    [[NSUbiquitousKeyValueStore defaultStore] synchronize];
}

+(void)updateFromiCloud:(NSNotification*) notificationObject {
    RKLogInfo(@"Updating from iCloud");
    NSUbiquitousKeyValueStore *iCloudStore = [NSUbiquitousKeyValueStore defaultStore];
    NSDictionary *remote = [iCloudStore dictionaryRepresentation];
    SLFPersistenceManager *persist = [SLFPersistenceManager sharedPersistence];
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];    
        // prevent user defaults change notification trigger while we update
    [defaultCenter removeObserver:self name:NSUserDefaultsDidChangeNotification object:nil];
    [persist importSettings:remote];
        // enable notification trigger again
    [defaultCenter addObserver:self selector:@selector(updateToiCloud:) name:NSUserDefaultsDidChangeNotification object:nil];
    [defaultCenter postNotificationName:kSLFiCloudSyncNotification object:nil];
}

+(void)start {
    if(NO == NSClassFromString(@"NSUbiquitousKeyValueStore")) {
        RKLogInfo(@"Not an iOS 5 device");  
        return;
    }
    if(NO == [NSUbiquitousKeyValueStore defaultStore]) {
        RKLogInfo(@"iCloud not enabled");
        return;
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateFromiCloud:) name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateToiCloud:) name:NSUserDefaultsDidChangeNotification object:nil];
}

+ (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSUserDefaultsDidChangeNotification object:nil];
}
@end
