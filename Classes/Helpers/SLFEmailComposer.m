//
//  SLFEmailComposer.m
//  Created by Gregory Combs on 8/10/10.
//
//  OpenStates (iOS) by Sunlight Foundation Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the BSD-3 License included with this source
// distribution.


#import "SLFEmailComposer.h"
#import "SLFReachable.h"
#import "SLFAlertView.h"
#import "SLFAnalytics.h"

@interface SLFEmailComposer()
@property (nonatomic, strong) MFMailComposeViewController *composer;
@end

@implementation SLFEmailComposer

@synthesize composer = _composer;
@synthesize isComposingMail = _isComposingMail;

+ (id)sharedComposer
{
	static dispatch_once_t pred;
	static SLFEmailComposer *foo = nil;
	dispatch_once(&pred, ^{ foo = [[self alloc] init]; });
	return foo;
}

- (id) init
{
    if ((self = [super init]))
    {
		_isComposingMail = NO;
    }
    return self;
}


- (BOOL)isNetworkAvailableForURL:(NSURL *)url {
    if (![[SLFReachable sharedReachable] isURLReachable:url])
        return NO;
    if (![[UIApplication sharedApplication] canOpenURL:url])
        return NO;
    return YES;
}

- (void)presentAppSupportComposerFromParent:(UIViewController *)parent {
    NSMutableString *body = [[NSMutableString alloc] init];
    NSString *appVer = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSString *buildVer = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    NSString *stateId = SLFSelectedStateID();
    [body appendString:NSLocalizedString(@"\nDescription of Problem, Concern, or Question:\n", @"")];
    [body appendString:@"\n\n    *** VERY IMPORTANT *** Please tell us any problems you experienced, and how we can reproduce it (if possible).\n\n"];
    [body appendFormat:NSLocalizedString(@"Open States App Version: %@ (Build %@)\n", @""), appVer, buildVer];
    if (stateId) {
        [body appendFormat:NSLocalizedString(@"Current selected state: %@\n", @""), stateId];
    }
    [body appendFormat:NSLocalizedString(@"iOS Version: %@\n", @""), [[UIDevice currentDevice] systemVersion]];
    [body appendFormat:NSLocalizedString(@"iOS Device: %@\n", @""), [[UIDevice currentDevice] model]];
    [self presentMailComposerTo:@"openstates-mobile@sunlightfoundation.com" subject:NSLocalizedString(@"Open States App Support", @"") body:body parent:parent];
    [[SLFAnalytics sharedAnalytics] tagEvent:@"EMAILING_DEV_SUPPORT" attributes:[NSDictionary dictionaryWithObject:@"APP_DEV" forKey:@"category"]];
}

- (void)presentMailComposerTo:(NSString*)recipient subject:(NSString*)subject body:(NSString*)body parent:(UIViewController *)parent {
	if (!parent)
		return;
	if (!body)
		body = @"";
	if ([MFMailComposeViewController canSendMail]) {
		self.isComposingMail = YES;
        self.composer = nil;
		_composer = [[MFMailComposeViewController alloc] init];
		_composer.mailComposeDelegate = self;
        if ([[UIDevice currentDevice] systemMajorVersion] >= 7) {
            _composer.view.tintColor = [SLFAppearance primaryTintColor];
        }
		[_composer setSubject:subject];
		[_composer setToRecipients:[NSArray arrayWithObject:recipient]];
		[_composer setMessageBody:body isHTML:NO];
		[parent presentViewController:_composer animated:YES completion:NULL];
	}
	else {
		NSMutableString *message = [[NSMutableString alloc] initWithFormat:@"mailto:%@", recipient];
		if (SLFTypeNonEmptyStringOrNil(subject))
			[message appendFormat:@"&subject=%@", subject];
		if (SLFTypeNonEmptyStringOrNil(body))
			[message appendFormat:@"&body=%@", body];
        NSCharacterSet *allowedCharacters = [NSCharacterSet URLQueryAllowedCharacterSet];
		NSURL *mailto = [NSURL URLWithString:[message stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacters]];
		if ( ![self isNetworkAvailableForURL:mailto] ) {
			[SLFAlertView showWithTitle:NSLocalizedString(@"Network Unavailable", @"")
								message:NSLocalizedString(@"Cannot send an email at this time.  Please check your network settings and try again.", @"")
							buttonTitle:NSLocalizedString(@"Cancel", @"")];
            return;
		}			
        [[UIApplication sharedApplication] openURL:mailto];
	}
}

#pragma mark -
#pragma mark Mail Composer Delegate

- (void)mailComposeController:(MFMailComposeViewController*)mailController didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
	if (result == MFMailComposeResultFailed) {
		[SLFAlertView showWithTitle:NSLocalizedString(@"Failure, Message Not Sent", @"")
							message:NSLocalizedString(@"An error prevented successful transmission of your message. Check your email and network settings or try emailing manually.", @"")
						buttonTitle:NSLocalizedString(@"Cancel", @"")];
	}
	[self.composer dismissViewControllerAnimated:YES completion:NULL];
	self.isComposingMail = NO;
	self.composer = nil;
}


@end
