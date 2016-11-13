//
//  SLFTableViewController.m
//  Created by Greg Combs on 9/26/11.
//
//  OpenStates (iOS) by Sunlight Foundation Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the BSD-3 License included with this source
// distribution.


#import "SLFTableViewController.h"
#import "SLFAppearance.h"
#import "GradientBackgroundView.h"
#import "SLFReachable.h"
#import "SLFDataModels.h"
#import "SLFActionPathRegistry.h"
#import "OpenStatesTableViewCell.h"
#import "AppDelegate.h"

@import SafariServices;

@implementation SLFTableViewController
@synthesize useGradientBackground;
@synthesize useTitleBar;
@synthesize titleBarView = _titleBarView;
@synthesize onSavePersistentActionPath = _onSavePersistentActionPath;
@synthesize searchBar;

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        self.stackWidth = 450;
        self.useGradientBackground = (style == UITableViewStyleGrouped);
        self.useTitleBar = NO;
        if ([self respondsToSelector:@selector(extendedLayoutIncludesOpaqueBars)]) {
            self.extendedLayoutIncludesOpaqueBars = YES;
            self.edgesForExtendedLayout = UIRectEdgeNone;
        }
    }
    return self;
}

- (void)dealloc {
    self.titleBarView = nil;
    self.onSavePersistentActionPath = nil;
    self.searchBar = nil;
}

- (void)viewDidUnload {
    self.titleBarView = nil;
    self.searchBar = nil;
    [super viewDidUnload];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView registerClass:[OpenStatesTableViewCell class] forCellReuseIdentifier:NSStringFromClass([OpenStatesTableViewCell class])];
    [self.tableView registerClass:[OpenStatesSubtitleTableViewCell class] forCellReuseIdentifier:NSStringFromClass([OpenStatesSubtitleTableViewCell class])];
    UIColor *background = [SLFAppearance tableBackgroundLightColor];
    self.tableView.backgroundColor = background;
    if (self.tableView.style == UITableViewStylePlain)
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    if (self.useTitleBar) {
        _titleBarView = [[TitleBarView alloc] initWithFrame:self.view.bounds title:self.title];
        CGRect tableRect = self.tableView.frame;
        tableRect.size.height -= _titleBarView.opticalHeight;
        self.tableView.frame = CGRectOffset(tableRect, 0, _titleBarView.opticalHeight);
        if (!SLFIsIOS5OrGreater()) {
            UIColor *gradientTop = SLFColorWithRGBShift([SLFAppearance menuBackgroundColor], +20);
            UIColor *gradientBottom = SLFColorWithRGBShift([SLFAppearance menuBackgroundColor], -20);
            [_titleBarView setGradientTopColor:gradientTop];
            [_titleBarView setGradientBottomColor:gradientBottom];
            _titleBarView.titleFont = SLFTitleFont(14);
            _titleBarView.titleColor = [SLFAppearance navBarTextColor];
            [_titleBarView setStrokeTopColor:gradientTop];
        }
        [self.view addSubview:_titleBarView];
    }
    if (self.useGradientBackground) {
        GradientBackgroundView *gradient = [[GradientBackgroundView alloc] initWithFrame:self.tableView.bounds];
        gradient.backgroundColor = [SLFAppearance tableBackgroundLightColor];
        self.tableView.backgroundView = gradient;
    }
}

- (NSString *)actionPath {
    return [[self class] actionPathForObject:nil];
}

+ (NSString *)actionPathForObject:(id)object {
    NSString *pattern = [SLFActionPathRegistry patternForClass:[self class]];
    if (!pattern)
        return nil;
    if (!object)
        return pattern;
    return RKMakePathWithObjectAddingEscapes(pattern, object, NO);
}

- (void)setOnSavePersistentActionPath:(SLFPersistentActionsSaveBlock)onSavePersistentActionPath {
    if (_onSavePersistentActionPath) {
        _onSavePersistentActionPath = nil;
        return;
    }
    _onSavePersistentActionPath = [onSavePersistentActionPath copy];
}

- (void)setTitle:(NSString *)title {
    [super setTitle:title];
    if (self.useTitleBar && self.isViewLoaded)
        self.titleBarView.title = title;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}

- (void)tableController:(RKAbstractTableController*)tableController willLoadTableWithObjectLoader:(RKObjectLoader *)objectLoader {
    objectLoader.URLRequest.timeoutInterval = 30; // something reasonable;
}

- (void)tableController:(RKAbstractTableController*)tableController didFailLoadWithError:(NSError*)error {
    self.onSavePersistentActionPath = nil;
    self.title = NSLocalizedString(@"Server Error",@"");
    RKLogError(@"Error loading table: %@", error);
    if ([tableController respondsToSelector:@selector(resourcePath)])
        RKLogError(@"-------- from resource path: %@", [tableController performSelector:@selector(resourcePath)]);
}

- (void)tableControllerDidFinishFinalLoad:(RKAbstractTableController*)tableController {
    RKLogTrace(@"%@: Table controller finished loading.", NSStringFromClass([self class]));
    if (self.isViewLoaded)
        [self.tableView reloadData];
    if (self.onSavePersistentActionPath) {
        self.onSavePersistentActionPath(self.actionPath);
        self.onSavePersistentActionPath = nil;
    }
}

- (void)stackOrPushViewController:(UIViewController *)viewController {
    if (!SLFIsIpad())
        [self.navigationController pushViewController:viewController animated:YES];
    else
        [self.stackController pushViewController:viewController fromViewController:self animated:YES];
}

- (void)popToThisViewController {
    if (!SLFIsIpad())
        [SLFAppDelegateNav popToViewController:self animated:YES];
    else
        [SLFAppDelegateStack popToViewController:self animated:YES];
}

- (RKTableItem *)webPageItemWithTitle:(NSString *)itemTitle subtitle:(NSString *)itemSubtitle url:(NSString *)url {
    url = SLFTypeNonEmptyStringOrNil(url);
    if (!url)
        return nil;
    NSURL *URL = [NSURL URLWithString:url];
    if (!URL)
        return nil;

    BOOL useAlternatingRowColors = NO;
    if (self.isViewLoaded)
        useAlternatingRowColors =  (self.tableView.style == UITableViewStylePlain); 
    StyledCellMapping *cellMapping = [StyledCellMapping cellMapping];
    cellMapping.style = UITableViewCellStyleSubtitle;
    cellMapping.useAlternatingRowColors = useAlternatingRowColors;

    __weak __typeof__(self) wSelf = self;
    cellMapping.onSelectCell = ^(void) {
        if (!URL.scheme || ![@[@"https",@"http"] containsObject:URL.scheme])
        {
            return;
        }

        SLFReachabilityCompletionHandler completion = ^(NSURL *url, BOOL isReachable){
            __strong __typeof__(wSelf) sSelf = wSelf;

            if (!isReachable)
                return;

            SFSafariViewController *webViewController = [[SFSafariViewController alloc] initWithURL:url entersReaderIfAvailable:NO];
            webViewController.modalPresentationStyle = UIModalPresentationPageSheet;
            [sSelf presentViewController:webViewController animated:YES completion:nil];
        };

        SLFIsReachableAddressAsync(URL,completion);
    };

    RKTableItem *webItem = [RKTableItem tableItemWithCellMapping:cellMapping];
    webItem.text = itemTitle;
    webItem.detailText = itemSubtitle;
    webItem.URL = url;
    return webItem;
}

#pragma mark - Search Bar Scope

- (void)configureSearchBarWithPlaceholder:(NSString *)placeholder withConfigurationBlock:(SearchBarConfigurationBlock)block {
    CGFloat tableWidth = self.tableView.bounds.size.width;
    CGRect searchRect = CGRectMake(0, self.titleBarView.opticalHeight, tableWidth, 44);
    self.searchBar = [[UISearchBar alloc] initWithFrame:searchRect];
    self.searchBar.delegate = self;
    self.searchBar.placeholder = placeholder;
    self.searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    if (!SLFIsIOS5OrGreater())
        self.searchBar.tintColor = [SLFAppearance cellSecondaryTextColor];
    if (block)
        block(self.searchBar);
    [self.searchBar sizeToFit];
    self.searchBar.width = tableWidth;
    CGRect tableRect = self.tableView.frame;
    tableRect.size.height -= searchBar.height;
    self.tableView.frame = CGRectOffset(tableRect, 0, searchBar.height);
    [self.view addSubview:self.searchBar];
}

- (void)configureChamberScopeTitlesForSearchBar:(UISearchBar *)bar withState:(SLFState *)state {
    NSParameterAssert(bar != NULL);
    NSArray *buttonTitles = [SLFChamber chamberSearchScopeTitlesWithState:state];
    if (!buttonTitles)
        return;
    bar.showsScopeBar = YES;
    bar.scopeButtonTitles = buttonTitles;
    bar.selectedScopeButtonIndex = SLFSelectedScopeIndexForKey(NSStringFromClass([self class]));
}

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope {
    SLFSaveSelectedScopeIndexForKey(selectedScope, NSStringFromClass([self class]));
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)bar {
    bar.showsCancelButton = YES;
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)bar {
    [bar resignFirstResponder];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)bar {
    [bar resignFirstResponder];
}

- (void)searchBar:(UISearchBar *)bar textDidChange:(NSString *)searchText {
    if (!bar.text.length) {
        bar.showsCancelButton = NO;
        [bar resignFirstResponder];
        return;
    }
    bar.showsCancelButton = YES;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)bar {
    bar.text = nil;
    bar.showsCancelButton = NO;
    [bar resignFirstResponder];
}

@end
