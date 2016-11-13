//
//  AppBarController.h
//  Created by Greg Combs on 12/19/11.
//
//  OpenStates by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the BSD-3 License included with this source
// distribution.


#import "StatesPopoverManager.h"
@class SLFStackedViewController;
@interface AppBarController : UIViewController <StatesPopoverDelegate>
@property (nonatomic,strong,readonly) SLFStackedViewController *stackedViewController;
- (IBAction)changeSelectedState:(id)sender;
- (IBAction)browseToAppWebSite:(id)sender;
@end

extern const NSUInteger STACKED_NAVBAR_HEIGHT;
