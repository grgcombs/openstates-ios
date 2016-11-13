//
//  WatchedBillNotificationManager.m
//  Created by Greg Combs on 12/3/11.
//
//  OpenStates by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the BSD-3 License included with this source
// distribution.


#import "WatchedBillNotificationManager.h"
#import "SLFPersistenceManager.h"
#import "SLFDataModels.h"
#import "SLFRestKitManager.h"
#import "NSDate+SLFDateHelper.h"
#import "BillDetailViewController.h"
#import "SLFAlertView.h"

@interface WatchedBillNotificationManager()
@property (nonatomic,weak) NSTimer *scheduleTimer;
@property (nonatomic,strong) RKRequestQueue *billRequestQueue;
- (IBAction)resetStatusNotifications:(id)sender;
- (IBAction)loadWatchedBillsFromNetwork:(id)sender;
- (BOOL)isBillStatusUpdated:(SLFBill *)foundBill;
@property (nonatomic,strong) NSMutableSet *updatedBills;
@end

@implementation WatchedBillNotificationManager
@synthesize billRequestQueue = _billRequestQueue;
@synthesize updatedBills = _updatedBills;
@synthesize scheduleTimer = _scheduleTimer;

+ (WatchedBillNotificationManager *)manager {
    static WatchedBillNotificationManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[WatchedBillNotificationManager alloc] init];
    });
    return manager;
}

- (id)init {
    self = [super init];
    if (self) {
        _billRequestQueue = [RKRequestQueue newRequestQueueWithName:NSStringFromClass([self class])];
        _billRequestQueue.delegate = self;
        _billRequestQueue.concurrentRequestsLimit = 2;
        _billRequestQueue.showsNetworkActivityIndicatorWhenBusy = NO;
        _updatedBills = [[NSMutableSet alloc] init];
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
        [self performSelectorInBackground:@selector(checkBillsStatus:) withObject:self]; // check now
        self.scheduleTimer = [NSTimer scheduledTimerWithTimeInterval:SLF_HOURS_TO_SECONDS(2) target:self selector:@selector(checkBillsStatus:) userInfo:nil repeats:YES]; 
    }
    return self;
}

- (void)dealloc {
    [self.scheduleTimer invalidate];
    self.scheduleTimer = nil;
    [self.billRequestQueue cancelAllRequests];
}

- (IBAction)checkBillsStatus:(id)sender {
    @autoreleasepool {
        [self loadWatchedBillsFromNetwork:sender];
    }
}

- (IBAction)loadWatchedBillsFromNetwork:(id)sender {
    NSDictionary *watchedBills = SLFWatchedBillsCatalog();
    if (!watchedBills.count)
        return;
    [self resetStatusNotifications:sender];
    SLFRestKitManager *restKit = [SLFRestKitManager sharedRestKit];
    for (NSString *watchID in [watchedBills allKeys]) {
        NSString *resourcePath = [SLFBill resourcePathForWatchID:watchID];
        RKObjectLoader *loader = [restKit objectLoaderForResourcePath:resourcePath delegate:self withTimeout:SLF_HOURS_TO_SECONDS(1)];
        [_billRequestQueue addRequest:loader];
    }
    if ([_billRequestQueue count])
        [_billRequestQueue start];
}

- (BOOL)isBillStatusUpdated:(SLFBill *)foundBill {
    if (!SLFBillIsWatched(foundBill))
        return NO;
    NSDictionary *watchedBills = SLFWatchedBillsCatalog();
    NSDate *previousUpdated = [watchedBills objectForKey:[foundBill watchID]];
    if (!previousUpdated || [[NSNull null] isEqual:previousUpdated])
        return NO;
    NSDate *currentUpdated = foundBill.dateUpdated;
    if (!currentUpdated || [[NSNull null] isEqual:currentUpdated])
        return NO;
    return [previousUpdated isEarlierThanDate:currentUpdated];
}

- (NSString *)alertMessageForUpdatedBill:(SLFBill *)updatedBill {
    if (!updatedBill)
        return nil;
    return [NSString stringWithFormat:NSLocalizedString(@"%@ (%@) has recently changed.  Select 'View Bill' to see the bill's current status.", @""), updatedBill.billID, updatedBill.state.name];
}

- (void)issueNotificationForBill:(SLFBill *)updatedBill {
    NSParameterAssert(updatedBill != NULL);
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.applicationIconBadgeNumber = [self.updatedBills count];
    notification.alertAction = NSLocalizedString(@"View Bill", @"");
    notification.alertBody = [self alertMessageForUpdatedBill:updatedBill];
    NSString *actionPath = [BillDetailViewController actionPathForObject:updatedBill];
    notification.userInfo = [NSDictionary dictionaryWithObject:actionPath forKey:@"ActionPath"];
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
}

- (IBAction)resetStatusNotifications:(id)sender {
    [self.updatedBills removeAllObjects];
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
}

- (void)objectLoader:(RKObjectLoader*)objectLoader didLoadObject:(id)object {
    if (![object isKindOfClass:[SLFBill class]])
        return;
    SLFBill *foundBill = object;
    if ([self isBillStatusUpdated:foundBill]) {
        [self.updatedBills addObject:foundBill];
        SLFTouchBillWatchedStatus(foundBill);
        [self issueNotificationForBill:foundBill];
    }
}

- (void)pruneInvalidResultIfNessesaryWithResourcePath:(NSString *)resourcePath {
    NSString *watchID = [SLFBill watchIDForResourcePath:resourcePath];
    if (!SLFTypeNonEmptyStringOrNil(watchID))
        return;
    if (!SLFBillIsWatchedWithID(watchID))
        return;
    NSString *watchIDForDisplay = [[watchID stringByReplacingOccurrencesOfString:@"||" withString:@" "] uppercaseString];
    NSString *title = [NSString stringWithFormat:NSLocalizedString(@"Error for %@", @""), watchIDForDisplay];
    NSString *message = [NSString stringWithFormat:NSLocalizedString(@"An error occurred while checking for updates to a watched bill, %@.  You may choose to ignore this error and keep the bill in your watch list for now, or you can opt to remove this bill in the event this error is not a temporary problem.", @""), watchIDForDisplay];
    [SLFAlertView showWithTitle:title message:message cancelTitle:NSLocalizedString(@"Keep", @"") cancelBlock:nil otherTitle:NSLocalizedString(@"Delete",@"") otherBlock:^{
        SLFRemoveWatchedBillWithWatchID(watchID);
    }];
}

- (void)objectLoader:(RKObjectLoader*)objectLoader didFailWithError:(NSError*)error {
    [SLFRestKitManager logFailureMessageForRequest:objectLoader error:error];
    [self pruneInvalidResultIfNessesaryWithResourcePath:objectLoader.resourcePath];
}

- (void)objectLoaderDidLoadUnexpectedResponse:(RKObjectLoader*)objectLoader {
    [self pruneInvalidResultIfNessesaryWithResourcePath:objectLoader.resourcePath];
}

@end
