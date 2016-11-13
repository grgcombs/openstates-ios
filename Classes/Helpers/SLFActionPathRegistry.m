//
//  SLFActionPathRegistry.m
//  Created by Greg Combs on 12/5/11.
//
//  OpenStates by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the BSD-3 License included with this source
// distribution.

#ifndef SLFActionPathRegistry_h
#define SLFActionPathRegistry_h "SLFActionPathRegistry.h"

#import "SLFActionPathRegistry.h"
#import "NSString+SLFExtensions.h"
#import "StatesViewController.h"
#import "StackedMenuViewController.h"
#import "StateDetailViewController.h"
#import "LegislatorsViewController.h"
#import "LegislatorDetailViewController.h"
#import "CommitteesViewController.h"
#import "CommitteeDetailViewController.h"
#import "DistrictsViewController.h"
#import "DistrictDetailViewController.h"
#import "EventsViewController.h"
#import "EventDetailViewController.h"
#import "BillsMenuViewController.h"
#import "BillsSearchViewController.h"
#import "BillDetailViewController.h"
#import "BillsWatchedViewController.h"
#import "BillsSubjectsViewController.h"
#import "AssetsViewController.h"
#import "LegislatorsNoFetchViewController.h"
#import "AppDelegate.h"

@interface SLFTableViewController(SLFActionPath)
+ (void)registerActionPathWithPattern:(NSString *)pattern;
@end

@interface SLFActionPathRegistry()
@property (nonatomic,retain) NSMutableDictionary *patternsForClasses;
- (void)registerAllControllers;
- (void)registerPattern:(NSString *)pattern forClass:(Class)controllerClass;
@end

@implementation SLFActionPathRegistry
@synthesize patternsForClasses = _patternsForClasses;

+ (SLFActionPathRegistry *)sharedRegistry
{
    static dispatch_once_t pred;
    static SLFActionPathRegistry *foo = nil;
    dispatch_once(&pred, ^{ foo = [[self alloc] init]; });
    return foo;
}

- (id)init {
    self = [super init];
    if (self) {
        _patternsForClasses = [[NSMutableDictionary alloc] init];
        [self registerAllControllers];
    }
    return self;
}

- (void)registerAllControllers {
    if (SLFIsIpad())
        [self registerPattern:@"slfos://states/detail/:stateID" forClass:[StackedMenuViewController class]];
    else
        [self registerPattern:@"slfos://states/detail/:stateID" forClass:[StateDetailViewController class]];
    [self registerPattern:@"slfos://states" forClass:[StatesViewController class]];
    [self registerPattern:@"slfos://findMyLegislators/:stateID" forClass:[LegislatorsNoFetchViewController class]];
    [self registerPattern:@"slfos://legislators/detail/:legID" forClass:[LegislatorDetailViewController class]];
    [self registerPattern:@"slfos://legislators/:stateID" forClass:[LegislatorsViewController class]];
    [self registerPattern:@"slfos://committees/detail/:committeeID" forClass:[CommitteeDetailViewController class]];
    [self registerPattern:@"slfos://committees/:stateID" forClass:[CommitteesViewController class]];
    [self registerPattern:@"slfos://districts/detail/:boundaryID" forClass:[DistrictDetailViewController class]];
    [self registerPattern:@"slfos://districts/:stateID" forClass:[DistrictsViewController class]];
    [self registerPattern:@"slfos://events/detail/:eventID" forClass:[EventDetailViewController class]];
    [self registerPattern:@"slfos://events/:stateID" forClass:[EventsViewController class]];
    [self registerPattern:@"slfos://bills/detail/:stateID/:session/:billID" forClass:[BillDetailViewController class]];
    [self registerPattern:@"slfos://bills/search/:stateID" forClass:[BillsSearchViewController class]];
    [self registerPattern:@"slfos://bills/subjects/:stateID" forClass:[BillsSubjectsViewController class]];
    [self registerPattern:@"slfos://bills/watch" forClass:[BillsWatchedViewController class]];
    [self registerPattern:@"slfos://bills/:stateID" forClass:[BillsMenuViewController class]];
    [self registerPattern:@"slfos://capitolmaps/:stateID" forClass:[AssetsViewController class]];
}

+ (NSString *)patternForClass:(Class)controllerClass {
    if (!controllerClass)
        return nil;
    return [[SLFActionPathRegistry sharedRegistry].patternsForClasses valueForKey:NSStringFromClass(controllerClass)];
}

- (void)registerPattern:(NSString *)pattern forClass:(Class)controllerClass {
    if (!controllerClass || !pattern)
        return;
    [_patternsForClasses setObject:pattern forKey:NSStringFromClass(controllerClass)];
    NSAssert([controllerClass respondsToSelector:@selector(registerActionPathWithPattern:)], @"Class doesn't answer to registration methods");
    [controllerClass registerActionPathWithPattern:pattern];
}

+ (NSString *)interpolatePathForClass:(Class)controllerClass withResourceID:(NSString *)resourceID {
    NSParameterAssert(controllerClass != NULL);
    NSString *pattern = [self patternForClass:controllerClass];
    if (!SLFTypeNonEmptyStringOrNil(resourceID))
        return pattern;
    NSParameterAssert([pattern hasPrefix:@"slfos://"]);
    NSString *patternContents = [pattern substringFromIndex:8];
    NSArray *components = [patternContents componentsSeparatedByString:@":"];
    if (!SLFTypeNonEmptyArrayOrNil(components))
        return pattern;
    // some initializers require multiple arguments, so assume they've concatenated the resource ID, i.e. @"stateID/session/billID"
    NSString *path = [NSString stringWithFormat:@"slfos://%@%@", components[0], resourceID];
    return path; 
}
@end


@implementation SLFTableViewController(SLFActionPath)
+ (void)registerActionPathWithPattern:(NSString *)pattern {
    if (!pattern)
        return;
    Class controllerClass = [self class];
    [SLFActionPathNavigator registerPattern:pattern withArgumentHandler:^UIViewController *(NSDictionary *arguments, BOOL skipSaving) {
        if (NO == [controllerClass instancesRespondToSelector:@selector(initWithState:)])
            return nil;
        SLFState *state = [SLFState findFirstByAttribute:@"stateID" withValue:[arguments valueForKey:@"stateID"]];
        if (!state)
            return nil;
        SLFTableViewController *vc = [[controllerClass alloc] initWithState:state];
        if (!skipSaving) {
            vc.onSavePersistentActionPath = ^(NSString *actionPath) {
                SLFSaveCurrentActionPath(actionPath);
            };
        }
        return vc;
    }];
}

@end

@implementation StackedMenuViewController(SLFActionPath)
+ (void)registerActionPathWithPattern:(NSString *)pattern {
    if (!pattern)
        return;    
    [SLFActionPathNavigator registerPattern:pattern withArgumentHandler:^UIViewController *(NSDictionary *arguments, BOOL skipSaving) {
        SLFState *state = [SLFState findFirstByAttribute:@"stateID" withValue:[arguments valueForKey:@"stateID"]];
        if (!state)
            return nil;
        [SLFAppBarController statePopover:nil didSelectState:state];
        StackedMenuViewController *vc = (StackedMenuViewController *)SLFAppDelegateStack.rootViewController;
        if (!skipSaving && vc && [vc conformsToProtocol:@protocol(SLFPerstentActionsProtocol)])
            vc.onSavePersistentActionPath = ^(NSString *actionPath) {
                SLFSaveCurrentActionPath(actionPath);
            };
        return nil;
    }];
}
@end

@implementation StatesViewController(SLFActionPath)
+ (void)registerActionPathWithPattern:(NSString *)pattern {
    if (!pattern)
        return;
    [SLFActionPathNavigator registerPattern:pattern withArgumentHandler:^UIViewController *(NSDictionary *arguments, BOOL skipSaving) {
        if (SLFIsIpad()) {
            [SLFAppBarController changeSelectedState:nil];
            return nil;
        }
        UINavigationController *nav = (UINavigationController *)[UIApplication sharedApplication].keyWindow.rootViewController;
        [nav popToRootViewControllerAnimated:YES];
        StatesViewController *vc = (StatesViewController *)[nav.viewControllers objectAtIndex:0];
        if (!skipSaving && vc && [vc conformsToProtocol:@protocol(SLFPerstentActionsProtocol)])
            vc.onSavePersistentActionPath = ^(NSString *actionPath) {
                SLFSaveCurrentActionPath(actionPath);
            };
        return nil;
    }];
}
@end

@implementation LegislatorsNoFetchViewController(SLFActionPath)

+ (void)registerActionPathWithPattern:(NSString *)pattern {
    if (!pattern)
        return;
    [SLFActionPathNavigator registerPattern:pattern withArgumentHandler:^UIViewController *(NSDictionary *arguments, BOOL skipSaving) {
        SLFState *state = [SLFState findFirstByAttribute:@"stateID" withValue:[arguments valueForKey:@"stateID"]];
        if (!state)
            return nil;
        LegislatorsNoFetchViewController *vc = [[LegislatorsNoFetchViewController alloc] initWithState:state usingGeolocation:YES];
        if (!skipSaving) {
            vc.onSavePersistentActionPath = ^(NSString *actionPath) {
                SLFSaveCurrentActionPath(actionPath);
            };
        }
        return vc;
    }];
}

@end

@implementation LegislatorDetailViewController(SLFActionPath)
+ (void)registerActionPathWithPattern:(NSString *)pattern {
    if (!pattern)
        return;
    Class controllerClass = [self class];
    [SLFActionPathNavigator registerPattern:pattern withArgumentHandler:^UIViewController *(NSDictionary *arguments, BOOL skipSaving) {
        NSString *legID = [arguments valueForKey:@"legID"];
        if (!legID)
            return nil;
        LegislatorDetailViewController *vc = [[controllerClass alloc] initWithLegislatorID:legID];
        if (!skipSaving) {
            vc.onSavePersistentActionPath = ^(NSString *actionPath) {
                SLFSaveCurrentActionPath(actionPath);
            };
        }
        return vc;
    }];
}
@end

@implementation CommitteeDetailViewController(SLFActionPath)
+ (void)registerActionPathWithPattern:(NSString *)pattern {
    if (!pattern)
        return;
    Class controllerClass = [self class];
    [SLFActionPathNavigator registerPattern:pattern withArgumentHandler:^UIViewController *(NSDictionary *arguments, BOOL skipSaving) {
        NSString *committeeID = [arguments valueForKey:@"committeeID"];
        if (!committeeID)
            return nil;
        CommitteeDetailViewController *vc = [[controllerClass alloc] initWithCommitteeID:committeeID];
        if (!skipSaving) {
            vc.onSavePersistentActionPath = ^(NSString *actionPath) {
                SLFSaveCurrentActionPath(actionPath);
            };
        }
        return vc;
    }];
}
@end

@implementation DistrictDetailViewController(SLFActionPath)
+ (void)registerActionPathWithPattern:(NSString *)pattern {
    if (!pattern)
        return;
    Class controllerClass = [self class];
    [SLFActionPathNavigator registerPattern:pattern withArgumentHandler:^UIViewController *(NSDictionary *arguments, BOOL skipSaving) {
        NSString *boundaryID = [arguments valueForKey:@"boundaryID"];
        DistrictDetailViewController *vc = [[controllerClass alloc] initWithDistrictMapID:boundaryID];
        if (!skipSaving) {
            vc.onSavePersistentActionPath = ^(NSString *actionPath) {
                SLFSaveCurrentActionPath(actionPath);
            };
        }
        return vc;
    }];
}
@end

@implementation EventDetailViewController(SLFActionPath)
+ (void)registerActionPathWithPattern:(NSString *)pattern {
    if (!pattern)
        return;
    Class controllerClass = [self class];
    [SLFActionPathNavigator registerPattern:pattern withArgumentHandler:^UIViewController *(NSDictionary *arguments, BOOL skipSaving) {
        NSString *eventID = [arguments valueForKey:@"eventID"];
        if (!eventID)
            return nil;
        EventDetailViewController *vc = [[controllerClass alloc] initWithEventID:eventID];
        if (!skipSaving) {
            vc.onSavePersistentActionPath = ^(NSString *actionPath) {
                SLFSaveCurrentActionPath(actionPath);
            };
        }
        return vc;
    }];
}
@end

@implementation BillDetailViewController(SLFActionPath)
+ (void)registerActionPathWithPattern:(NSString *)pattern {
    if (!pattern)
        return;
    Class controllerClass = [self class];
    [SLFActionPathNavigator registerPattern:pattern withArgumentHandler:^UIViewController *(NSDictionary *arguments, BOOL skipSaving) {
        SLFState *state = [SLFState findFirstByAttribute:@"stateID" withValue:[arguments valueForKey:@"stateID"]];
        NSString *session = SLFTypeNonEmptyStringOrNil([arguments valueForKey:@"session"]);
        NSString *billID = SLFTypeNonEmptyStringOrNil([arguments valueForKey:@"billID"]);
        if (!state || !session || !billID)
            return nil;
        BillDetailViewController *vc = [[controllerClass alloc] initWithState:state session:session billID:billID];
        if (!skipSaving) {
            vc.onSavePersistentActionPath = ^(NSString *actionPath) {
                SLFSaveCurrentActionPath(actionPath);
            };
        }
        return vc;
    }];
}
@end

@implementation BillsWatchedViewController(SLFActionPath)
+ (void)registerActionPathWithPattern:(NSString *)pattern {
    if (!pattern)
        return;
    Class controllerClass = [self class];
    [SLFActionPathNavigator registerPattern:pattern withArgumentHandler:^UIViewController *(NSDictionary *arguments, BOOL skipSaving) {
        BillsWatchedViewController *vc = [[controllerClass alloc] init];
        if (!skipSaving) {
            vc.onSavePersistentActionPath = ^(NSString *actionPath) {
                SLFSaveCurrentActionPath(actionPath);
            };
        }
        return vc;
    }];
}
@end

#endif
