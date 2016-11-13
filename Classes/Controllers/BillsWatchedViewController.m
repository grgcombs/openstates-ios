//
//  BillsWatchedViewController.m
//  Created by Greg Combs on 11/25/11.
//
//  OpenStates by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the BSD-3 License included with this source
// distribution.


#import "BillsWatchedViewController.h"
#import "SLFDataModels.h"
#import "BillDetailViewController.h"
#import "SLFPersistenceManager.h"
#import "SLFRestKitManager.h"
#import "NSDate+SLFDateHelper.h"
#import "SLFDrawingExtensions.h"

@interface BillsWatchedViewController()
@property (nonatomic,strong) RKTableController *tableController;
@property (nonatomic,strong) IBOutlet id editButton;
@property (nonatomic,strong) IBOutlet id doneButton;
- (void)watchedBillsChanged:(NSNotification *)notification;
- (void)configureTableItems;
- (void)configureEditingButtons;
- (void)configureEditingButtonsIphone;
- (void)configureEditingButtonsIpad;
- (void)loadStatesForStateIDsFromNetwork:(NSSet *)stateIDs;
- (void)loadBillsForWatchIDsFromNetwork:(NSSet *)watchIDs;
- (NSArray *)actualBillsFromWatchedBills;
- (RKTableViewCellMapping *)billCellMapping;
@end

@implementation BillsWatchedViewController
@synthesize tableController = _tableController;
@synthesize editButton;
@synthesize doneButton;
- (id)init {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.useTitleBar = SLFIsIpad();
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(watchedBillsChanged:) name:SLFWatchedBillsDidChangeNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[RKObjectManager sharedManager].requestQueue cancelRequestsWithDelegate:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidUnload {
    self.editButton = nil;
    self.doneButton = nil;
    self.tableController = nil;
    [[RKObjectManager sharedManager].requestQueue cancelRequestsWithDelegate:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewDidUnload];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableController = [SLFImprovedRKTableController tableControllerForTableViewController:(UITableViewController*)self];
    _tableController.delegate = self;
    _tableController.objectManager = [RKObjectManager sharedManager];
    _tableController.pullToRefreshEnabled = NO;
    _tableController.tableView.rowHeight = 90;
    _tableController.canEditRows = YES;
    [_tableController mapObjectsWithClass:[SLFBill class] toTableCellsWithMapping:[self billCellMapping]];
    RKTableItem *emptyItem = [RKTableItem tableItemWithText:NSLocalizedString(@"No Watched Bills",@"") detailText:NSLocalizedString(@"There are no watched bills, yet. To add one, find a bill and click its star button.",@"")];
    emptyItem.cellMapping = [StyledCellMapping cellMappingWithStyle:UITableViewCellStyleSubtitle alternatingColors:NO largeHeight:YES selectable:NO];
    [emptyItem.cellMapping addDefaultMappings];
    _tableController.emptyItem = emptyItem;
    [self configureEditingButtons];
    [self configureTableItems];
    self.screenName = @"Watched Bills Screen";
}

- (NSString *)actionPath {
    return [[self class] actionPathForObject:nil];
}

- (void)configureEditingButtonsIphone {
    self.editButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Edit", @"") orange:NO width:45 target:self action:@selector(toggleEditing:)];
    self.doneButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", @"") orange:YES width:45 target:self action:@selector(toggleEditing:)];
    [self.navigationItem setRightBarButtonItem:self.editButton animated:YES];
}

- (void)configureEditingButtonsIpad {
    CGPoint origin = CGPointMake(self.titleBarView.size.width - 55, 18);

    SEL toggleEditingSelector = @selector(toggleEditing:);

    NSString *localizedDone = NSLocalizedString(@"Done", @"");
    if ([[UIDevice currentDevice] systemMajorVersion] >= 7) {
        UIButton *dButton = [UIButton buttonWithType:UIButtonTypeSystem];
        dButton.titleLabel.font = SLFTitleFont(14);
        self.doneButton = dButton;
        [self.doneButton setTitle:localizedDone forState:UIControlStateNormal];
        [self.doneButton setTitleColor:[SLFAppearance primaryTintColor] forState:UIControlStateNormal];
        [self.doneButton setTitleColor:[SLFAppearance navBarTextColor] forState:UIControlStateHighlighted];
        [self.doneButton sizeToFit];
        [self.doneButton addTarget:self action:toggleEditingSelector forControlEvents:UIControlEventTouchUpInside];
    } else {
        self.doneButton = [UIButton buttonWithTitle:localizedDone orange:YES width:45 target:self action:toggleEditingSelector];
    }
    [self.doneButton setOrigin:origin];
    [self.doneButton setTag:6616];
    [self.doneButton setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
    [self.doneButton setHidden:YES];
    [self.titleBarView addSubview:self.doneButton];

    NSString *localizedEdit = NSLocalizedString(@"Edit", @"");
    if ([[UIDevice currentDevice] systemMajorVersion] >= 7) {
        UIButton *eButton = [UIButton buttonWithType:UIButtonTypeSystem];
        eButton.titleLabel.font = SLFTitleFont(14);
        self.editButton = eButton;
        [self.editButton setTitle:localizedEdit forState:UIControlStateNormal];
        [self.editButton setTitleColor:[SLFAppearance primaryTintColor] forState:UIControlStateNormal];
        [self.editButton setTitleColor:[SLFAppearance navBarTextColor] forState:UIControlStateHighlighted];
        [self.editButton sizeToFit];
        [self.editButton addTarget:self action:toggleEditingSelector forControlEvents:UIControlEventTouchUpInside];
    } else {
        self.editButton = [UIButton buttonWithTitle:localizedEdit orange:NO width:45 target:self action:toggleEditingSelector];
    }
    [self.editButton setOrigin:origin];
    [self.editButton setTag:6617];
    [self.editButton setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
    [self.titleBarView addSubview:self.editButton];
}

- (void)configureEditingButtons {
    if (SLFIsIpad())
        [self configureEditingButtonsIpad];
    else
        [self configureEditingButtonsIphone];
}

- (IBAction)toggleEditing:(id)sender {
    BOOL wantToEdit = (NO == self.tableController.tableView.editing);
    [self.tableController.tableView setEditing:wantToEdit animated:YES];
    id nextButton = wantToEdit ? self.doneButton : self.editButton;
    id previousButton = wantToEdit ? self.editButton : self.doneButton;
    if (SLFIsIpad()) {
        [previousButton setHidden:YES];
        [nextButton setHidden:NO];
    }
    else
        [self.navigationItem setRightBarButtonItem:nextButton animated:YES];
}

#pragma mark - Section / Row Data

- (NSArray *)filterBills:(NSArray *)bills withStateID:(NSString *)stateID {
    NSParameterAssert(SLFTypeNonEmptyArrayOrNil(bills) && SLFTypeNonEmptyStringOrNil(stateID));
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"stateID == %@", [stateID lowercaseString]];
    return [bills filteredArrayUsingPredicate:pred];
}

- (void)recreateSectionForStateID:(NSString *)stateID usingWatchedBillsOrNil:(NSArray *)bills {
    if (!bills)
        bills = [self actualBillsFromWatchedBills];
    if (!SLFTypeNonEmptyArrayOrNil(bills))
        return;
    NSArray *stateBills = [self filterBills:bills withStateID:stateID];
    NSString *headerTitle = [stateID uppercaseString];
    RKTableSection *section = [_tableController sectionWithHeaderTitle:headerTitle];
    if (!SLFTypeNonEmptyArrayOrNil(stateBills)) {
        if (section)
            [_tableController removeSection:section];
        return;
    }
    if (!section) {
        section = SLFAddTableControllerSectionWithTitle(self.tableController, headerTitle);
    }
    [section setObjects:stateBills];
}

- (void)configureTableItems {
    [self.tableController removeAllSections];
    NSArray *bills = [self actualBillsFromWatchedBills];
    if (!SLFTypeNonEmptyArrayOrNil(bills)) {
        [self.tableController loadEmpty];
        [self.tableView reloadData];
        self.title = NSLocalizedString(@"No Watched Bills", @"");
        [self.editButton setEnabled:NO];
        return;
    }
    NSArray *states = SLFTypeNonEmptyArrayOrNil([bills valueForKeyPath:@"stateID"]);
    NSAssert(states, @"Found watched bills but had an empty list of stateIDs??");
    for (NSString *state in states)
        [self recreateSectionForStateID:state usingWatchedBillsOrNil:bills];
    self.title = [NSString stringWithFormat:NSLocalizedString(@"%d Watched Bills",@""), _tableController.rowCount];
    [self.editButton setEnabled:YES];
    [self.tableView reloadData];
}

- (RKTableViewCellMapping *)billCellMapping {
    StyledCellMapping *cellMap = [StyledCellMapping cellMappingWithStyle:UITableViewCellStyleSubtitle alternatingColors:NO largeHeight:YES selectable:YES];
    [cellMap mapKeyPath:@"name" toAttribute:@"textLabel.text"];
    [cellMap mapKeyPath:@"watchSummaryForDisplay" toAttribute:@"detailTextLabel.text"];

    __weak __typeof__(self) bself = self;
    cellMap.onSelectCellForObjectAtIndexPath = ^(UITableViewCell* cell, id object, NSIndexPath *indexPath) {
        if (!bself)
            return;
        
        SLFBill *bill = object;
        NSString *path = [SLFActionPathNavigator navigationPathForController:[BillDetailViewController class] withResource:bill];
        if (SLFTypeNonEmptyStringOrNil(path))
            [SLFActionPathNavigator navigateToPath:path skipSaving:NO fromBase:bself popToRoot:NO];
    };
    return cellMap;
}

- (void)tableController:(RKAbstractTableController*)tableController didDeleteObject:(id)object atIndexPath:(NSIndexPath*)indexPath {
    if (!object || ![object isKindOfClass:[SLFBill class]])
        return;
    SLFBill *bill = object;
    SLFSaveBillWatchedStatus(bill, NO);
    self.title = [NSString stringWithFormat:NSLocalizedString(@"%d Watched Bills",@""), _tableController.rowCount];
}

- (void)watchedBillsChanged:(NSNotification *)notification {
    if (!notification || !notification.object || NO == [notification.object isKindOfClass:[SLFBill class]]) {
        [self configureTableItems];
        return;
    }
    SLFBill *bill = (SLFBill *)notification.object;
    [self recreateSectionForStateID:bill.stateID usingWatchedBillsOrNil:nil];
    [self.tableView reloadData];
}

- (NSArray *)actualBillsFromWatchedBills {
    NSMutableArray *foundBills = [NSMutableArray array];
    NSDictionary *watchedBills = SLFWatchedBillsCatalog();
    if (!watchedBills.count)
        return foundBills;
    NSArray *watchIDs = [[watchedBills allKeys] sortedArrayUsingSelector:@selector(localizedStandardCompare:)];
    NSMutableSet *billsToLoad = [NSMutableSet set];
    NSMutableSet *statesToLoad = [NSMutableSet set];
    for (NSString *watchID in watchIDs) {
        SLFBill *bill = [SLFBill billForWatchID:watchID];
        if (!bill) {
            [billsToLoad addObject:watchID];
            continue;
        }
        [foundBills addObject:bill];
        SLFState *state = bill.stateObj;
        if (!state)
            [statesToLoad addObject:bill.stateID];
    }
    [self loadBillsForWatchIDsFromNetwork:billsToLoad];
    [self loadStatesForStateIDsFromNetwork:statesToLoad];
    return foundBills;
}

- (void)loadBillsForWatchIDsFromNetwork:(NSSet *)watchIDs {
    if (!SLFTypeNonEmptySetOrNil(watchIDs))
        return;
    for (NSString *watchID in watchIDs)
    {
        NSString *resourcePath = [SLFBill resourcePathForWatchID:watchID];
        [[SLFRestKitManager sharedRestKit] loadObjectsAtResourcePath:resourcePath delegate:self withTimeout:SLF_HOURS_TO_SECONDS(1)];
    }
}

- (void)loadStatesForStateIDsFromNetwork:(NSSet *)stateIDs {
    if (!SLFTypeNonEmptySetOrNil(stateIDs))
         return;
     for (NSString *stateID in stateIDs) {
         NSString *resourcePath = [SLFState resourcePathForStateID:stateID];
         [[SLFRestKitManager sharedRestKit] loadObjectsAtResourcePath:resourcePath delegate:self withTimeout:SLF_HOURS_TO_SECONDS(1)];
     }
}

- (void)objectLoader:(RKObjectLoader*)objectLoader didLoadObject:(id)object {
    if (!object)
        return;
    NSString *stateID = nil;
    if ([object isKindOfClass:[SLFBill class]] || [object isKindOfClass:[SLFState class]])
        stateID = SLFTypeNonEmptyStringOrNil([object valueForKey:@"stateID"]);
    if (!stateID)
        return;
    [self recreateSectionForStateID:stateID usingWatchedBillsOrNil:nil];
    [self.tableView reloadData];
}

- (void)objectLoader:(RKObjectLoader*)objectLoader didFailWithError:(NSError*)error {
    self.title = NSLocalizedString(@"Load Error", @"");
    [SLFRestKitManager showFailureAlertWithRequest:objectLoader error:error];
}
@end
