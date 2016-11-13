//
//  BillDetailViewController.m
//  Created by Gregory Combs on 2/20/11.
//
//  OpenStates (iOS) by Sunlight Foundation Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the BSD-3 License included with this source
// distribution.


#import "BillDetailViewController.h"
#import "SLFDataModels.h"
#import "BillsViewController.h"
#import "BillSearchParameters.h"
#import "LegislatorDetailViewController.h"
#import "BillVotesViewController.h"
#import "SLFMappingsManager.h"
#import "SLFRestKitManager.h"
#import "SLFReachable.h"
#import "NSDate+SLFDateHelper.h"
#import "LegislatorCell.h"
#import "SLFDrawingExtensions.h"
#import "SLFPersistenceManager.h"
#import "AppendingFlowCell.h"
#import "BillActionTableViewCell.h"

@interface BillDetailViewController()

@property (nonatomic,strong) IBOutlet UIButton *watchButton;

- (id)initWithResourcePath:(NSString *)resourcePath;
- (RKTableViewCellMapping *)actionCellMap;
- (RKTableViewCellMapping *)sponsorCellMap;
- (RKTableViewCellMapping *)votesCellMap;
- (RKTableViewCellMapping *)subjectCellMap;
- (void)reconfigureForBill:(SLFBill *)bill;
- (void)configureActionBarForBill:(SLFBill *)bill;
- (UIButton *)configureWatchButton;
- (void)reconfigureWatchButtonForBill:(SLFBill *)bill;
- (void)configureTableItems;
- (void)configureBillInfoItems;
- (void)configureStages;
- (void)configureResources;
- (void)configureSubjects;
- (void)configureVotes;
- (void)configureSponsors;
- (void)configureActions;
- (void)addTableItems:(NSMutableArray *)tableItems fromWebAssets:(NSSet *)assets withType:(NSString *)type;

@end

@implementation BillDetailViewController
@synthesize bill = _bill;
@synthesize tableController = _tableController;
@synthesize watchButton = _watchButton;

- (id)initWithResourcePath:(NSString *)resourcePath {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.useTitleBar = YES;
        self.stackWidth = 500;
        RKLogDebug(@"Loading resource path for bill: %@", resourcePath);
        [[SLFRestKitManager sharedRestKit] loadObjectsAtResourcePath:resourcePath delegate:self withTimeout:SLF_HOURS_TO_SECONDS(1)];
    }
    return self;
}

- (id)initWithState:(SLFState *)aState session:(NSString *)aSession billID:(NSString *)billID {
    NSString *resourcePath = [BillSearchParameters pathForBill:billID state:aState.stateID session:aSession];
    self = [self initWithResourcePath:resourcePath];
    return self;
}

- (id)initWithBill:(SLFBill *)aBill {
    NSString *resourcePath = [BillSearchParameters pathForBill:aBill];
    self = [self initWithResourcePath:resourcePath];
    if (self) {
        self.bill = aBill;
    }
    return self;
}

- (void)dealloc {
    [[RKObjectManager sharedManager].requestQueue cancelRequestsWithDelegate:self];
}

- (void)viewDidUnload {
    [[RKObjectManager sharedManager].requestQueue cancelRequestsWithDelegate:self];
    self.tableController = nil;
    self.watchButton = nil;
    [super viewDidUnload];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableController = [RKTableController tableControllerForTableViewController:(UITableViewController*)self];
    _tableController.delegate = self;
    _tableController.variableHeightRows = YES;
    _tableController.objectManager = [RKObjectManager sharedManager];
    _tableController.pullToRefreshEnabled = NO;
    [_tableController mapObjectsWithClass:[BillRecordVote class] toTableCellsWithMapping:[self votesCellMap]];
    [_tableController mapObjectsWithClass:[BillAction class] toTableCellsWithMapping:[self actionCellMap]];
    [_tableController mapObjectsWithClass:[BillSponsor class] toTableCellsWithMapping:[self sponsorCellMap]];
    [_tableController mapObjectsWithClass:[GenericWord class] toTableCellsWithMapping:[self subjectCellMap]];
    RKTableViewCellMapping *flowMapping = [AppendingFlowCellMapping cellMapping];
    [self.tableView registerClass:flowMapping.cellClass forCellReuseIdentifier:flowMapping.reuseIdentifier];

    [self configureActionBarForBill:self.bill];
	self.title = NSLocalizedString(@"Loading...", @"");
    self.screenName = @"Bill Detail Screen";
}

- (NSString *)actionPath {
    return [[self class] actionPathForObject:self.bill];
}

- (void)reconfigureForBill:(SLFBill *)bill {
    if (bill) {
        self.bill = bill;
        self.title = bill.name;
    }
    if (!self.isViewLoaded)
        return;
    [self reconfigureWatchButtonForBill:bill];
    [self configureTableItems];
}

#pragma mark - Action Bar Header

- (void)setState:(BOOL)isOn forWatchButton:(UIButton *)button {
    static UIImage *buttonOff;
    if (!buttonOff)
        buttonOff = [UIImage imageNamed:@"StarButtonOff"];
    static UIImage *buttonOn;
    if (!buttonOn)
        buttonOn = [UIImage imageNamed:@"StarButtonOn"];
    button.tag = isOn;
    UIImage *normal = isOn ? buttonOn : buttonOff;
    [button setImage:normal forState:UIControlStateNormal];
    UIImage *highlighted = isOn ? buttonOff : buttonOn;;
    [button setImage:highlighted forState:UIControlStateHighlighted];
    [button setNeedsDisplay];
}

- (IBAction)toggleWatchButton:(id)sender {
    NSParameterAssert(sender != NULL && [sender isKindOfClass:[UIButton class]]);
    BOOL isFavorite = SLFBillIsWatched(_bill);
    [self setState:!isFavorite forWatchButton:sender];
    SLFSaveBillWatchedStatus(_bill, !isFavorite);
}

- (UIButton *)configureWatchButton {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    button.frame = CGRectMake(self.titleBarView.size.width - 50, 12, 43, 43);
    [button addTarget:self action:@selector(toggleWatchButton:) forControlEvents:UIControlEventTouchDown]; 
    return button;
}

- (void)reconfigureWatchButtonForBill:(SLFBill *)bill {
    _watchButton.enabled = (bill != NULL);
    [self setState:SLFBillIsWatched(bill) forWatchButton:_watchButton];
    if (!bill)
        return;
    SLFTouchBillWatchedStatus(_bill);
}

- (void)configureActionBarForBill:(SLFBill *)bill {
    self.watchButton = [self configureWatchButton];
    [self reconfigureWatchButtonForBill:bill];
    [self.titleBarView addSubview:_watchButton];
}

#pragma mark - Table Item Creation and Mapping

- (void)configureTableItems {
    [_tableController removeAllSections:NO];
    [self configureBillInfoItems];     
    [self configureStages];
    [self configureResources];
    [self configureSubjects];
    [self configureVotes];
    [self configureSponsors];
    [self configureActions];
}

- (void)configureBillInfoItems {
    NSMutableArray* tableItems  = [[NSMutableArray alloc] init];
    __weak SLFBill * aBill = self.bill;
    [tableItems addObject:[RKTableItem tableItemUsingBlock:^(RKTableItem *tableItem) {
        tableItem.cellMapping = [StyledCellMapping cellMappingWithStyle:UITableViewCellStyleSubtitle alternatingColors:NO largeHeight:YES selectable:NO];
        tableItem.text = aBill.billID;
        tableItem.detailText = aBill.title;
    }]];
    [tableItems addObject:[RKTableItem tableItemUsingBlock:^(RKTableItem *tableItem) {
        tableItem.cellMapping = [StyledCellMapping staticSubtitleMapping];
        tableItem.text = NSLocalizedString(@"Originating Chamber", @"");
        tableItem.detailText = aBill.chamberObj.formalName;
    }]];
    [tableItems addObject:[RKTableItem tableItemUsingBlock:^(RKTableItem *tableItem) {
        tableItem.cellMapping = [StyledCellMapping staticSubtitleMapping];
        tableItem.text = NSLocalizedString(@"Last Updated", @"");
        tableItem.detailText = [NSString stringWithFormat:NSLocalizedString(@"Bill info was updated %@",@""), [aBill.dateUpdated stringForDisplayWithPrefix:YES]];
    }]];
    NSArray *sortedActions = aBill.sortedActions;
    if (SLFTypeNonEmptyArrayOrNil(sortedActions)) {
        [tableItems addObject:[RKTableItem tableItemUsingBlock:^(RKTableItem *tableItem) {
            tableItem.cellMapping = [StyledCellMapping staticSubtitleMapping];
            tableItem.text = NSLocalizedString(@"Latest Activity",@"");
            BillAction *latest = sortedActions[0];
            tableItem.detailText = [NSString stringWithFormat:@"%@ - %@", latest.title, latest.subtitle];
        }]];
    }
    SLFAddTableControllerSectionWithTitle(self.tableController, NSLocalizedString(@"Bill Details", @""));
    NSUInteger sectionIndex = _tableController.sectionCount-1;
    [self.tableController loadTableItems:tableItems inSection:sectionIndex];
}

- (void)configureStages {
    NSArray *stages = _bill.stages;
    if (!SLFTypeNonEmptyArrayOrNil(stages))
        return;
    RKTableItem *stageItemCell = [RKTableItem tableItemUsingBlock:^(RKTableItem* tableItem) {
        AppendingFlowCellMapping *cellMap = [AppendingFlowCellMapping cellMapping];
        cellMap.stages = stages;
        tableItem.cellMapping = cellMap;
    }];
    NSArray *tableItems = [[NSArray alloc] initWithObjects:stageItemCell, nil];
    SLFAddTableControllerSectionWithTitle(self.tableController, NSLocalizedString(@"Legislative Status (Beta)",@""));
    NSUInteger sectionIndex = self.tableController.sectionCount-1;
    [self.tableController loadTableItems:tableItems inSection:sectionIndex];
}

- (void)configureSubjects {
    NSArray *tableItems = _bill.sortedSubjects;
    if (!SLFTypeNonEmptyArrayOrNil(tableItems))
        return;
    SLFAddTableControllerSectionWithTitle(self.tableController, NSLocalizedString(@"Subjects", @""));
    NSUInteger sectionIndex = self.tableController.sectionCount-1;
    [self.tableController loadObjects:tableItems inSection:sectionIndex];
}

- (void)configureResources {
    NSMutableArray* tableItems  = [[NSMutableArray alloc] init];
    [self addTableItems:tableItems fromWebAssets:_bill.versions withType:NSLocalizedString(@"Version",@"")];
    [self addTableItems:tableItems fromWebAssets:_bill.documents withType:NSLocalizedString(@"Document",@"")];
    [self addTableItems:tableItems fromWebAssets:_bill.sources withType:NSLocalizedString(@"Resource",@"")];
    if (tableItems.count) {
        SLFAddTableControllerSectionWithTitle(_tableController, NSLocalizedString(@"Resources", @""));
        NSUInteger sectionIndex = _tableController.sectionCount-1;
        [_tableController loadTableItems:tableItems inSection:sectionIndex];
    }
}

- (void)configureSponsors {
    NSArray *tableItems = _bill.sortedSponsors;
    if (!SLFTypeNonEmptyArrayOrNil(tableItems))
        return;
    SLFAddTableControllerSectionWithTitle(_tableController, NSLocalizedString(@"Sponsors", @""));
    NSUInteger sectionIndex = _tableController.sectionCount-1;
    [_tableController loadObjects:tableItems inSection:sectionIndex];
}

- (void)configureVotes {
    NSArray *tableItems = _bill.sortedVotes;
    if (!SLFTypeNonEmptyArrayOrNil(tableItems))
        return;
    SLFAddTableControllerSectionWithTitle(_tableController, NSLocalizedString(@"Votes", @""));
    NSUInteger sectionIndex = _tableController.sectionCount-1;
    [_tableController loadObjects:tableItems inSection:sectionIndex];
}

- (void)configureActions {
    NSArray *tableItems = _bill.sortedActions;
    if (!SLFTypeNonEmptyArrayOrNil(tableItems))
        return;
    SLFAddTableControllerSectionWithTitle(_tableController, NSLocalizedString(@"Actions", @""));
    NSUInteger sectionIndex = _tableController.sectionCount-1;
    [_tableController loadObjects:tableItems inSection:sectionIndex];
}

- (RKTableViewCellMapping *)subjectCellMap {
    StyledCellMapping *cellMap = [StyledCellMapping cellMapping];
    [cellMap mapKeyPath:@"word" toAttribute:@"textLabel.text"];
    cellMap.reuseIdentifier = @"SUBJECT_CELL";
    __weak __typeof__(self) bself = self;
    cellMap.onSelectCellForObjectAtIndexPath = ^(UITableViewCell *cell, id object, NSIndexPath *indexPath) {
        if (!object || ![object valueForKey:@"word"])
            return;
        NSString *word = [object valueForKey:@"word"];
        NSString *subjectPath = [BillSearchParameters pathForSubject:word state:bself.bill.stateID session:bself.bill.session chamber:nil];
        BillsViewController *vc = [[BillsViewController alloc] initWithState:bself.bill.stateObj resourcePath:subjectPath];
        vc.title = [NSString stringWithFormat:@"%@: %@", [bself.bill.stateID uppercaseString], word];
        [bself stackOrPushViewController:vc];
    };
    return cellMap;
}

- (RKTableViewCellMapping *)actionCellMap {
    BillActionCellMapping *cellMap = [BillActionCellMapping cellMapping];
    [cellMap mapKeyPath:@"title" toAttribute:@"textLabel.text"];
    [cellMap mapKeyPath:@"subtitle" toAttribute:@"detailTextLabel.text"];
    return cellMap;
}

- (RKTableViewCellMapping *)sponsorCellMap {
    __weak __typeof__(self) bself = self;
    FoundLegislatorCellMapping *cellMap = [FoundLegislatorCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
        [cellMapping mapKeyPath:@"foundLegislator" toAttribute:@"legislator"];
        [cellMapping mapKeyPath:@"type" toAttribute:@"role"];
        [cellMapping mapKeyPath:@"name" toAttribute:@"genericName"];
        cellMapping.onSelectCellForObjectAtIndexPath = ^(UITableViewCell* cell, id object, NSIndexPath *indexPath) {
            NSString *legID = [object valueForKey:@"legID"];
            NSString *path = [SLFActionPathNavigator navigationPathForController:[LegislatorDetailViewController class] withResourceID:legID];
            if (SLFTypeNonEmptyStringOrNil(path))
                [SLFActionPathNavigator navigateToPath:path skipSaving:NO fromBase:bself popToRoot:NO];
        };
    }];
    return cellMap;
}

- (RKTableViewCellMapping *)votesCellMap {
    StyledCellMapping *cellMap = [StyledCellMapping subtitleMapping];
    [cellMap mapKeyPath:@"title" toAttribute:@"textLabel.text"];
    [cellMap mapKeyPath:@"subtitle" toAttribute:@"detailTextLabel.text"];
    __weak __typeof__(self) bself = self;
    cellMap.onSelectCellForObjectAtIndexPath = ^(UITableViewCell* cell, id object, NSIndexPath *indexPath) {
        BillRecordVote *vote = object;
        BillVotesViewController *vc = [[BillVotesViewController alloc] initWithVote:vote];
        [bself stackOrPushViewController:vc];
    };
    return cellMap;
}

- (void)addTableItems:(NSMutableArray *)tableItems fromWebAssets:(NSSet *)assets withType:(NSString *)type {
    if (!SLFTypeNonEmptySetOrNil(assets))
        return;
    NSArray *sorted = [assets sortedArrayUsingDescriptors:[GenericAsset sortDescriptors]];
    for (GenericAsset *source in sorted) {
        if (!SLFTypeURLOrNil(source.url))
            continue;
        NSString *subtitle = source.name;
        if (!SLFTypeNonEmptyStringOrNil(subtitle))
            subtitle = source.url;
        [tableItems addObject:[self webPageItemWithTitle:type subtitle:subtitle url:source.url]];
    }
}

#pragma mark - Object Loader

- (void)objectLoader:(RKObjectLoader*)objectLoader didFailWithError:(NSError*)error {
    self.title = NSLocalizedString(@"Load Error", @"");
    [SLFRestKitManager showFailureAlertWithRequest:objectLoader error:error];
}

- (void)objectLoader:(RKObjectLoader*)objectLoader didLoadObject:(id)object {
    SLFBill *bill = nil;
    if (object && [object isKindOfClass:[SLFBill class]]) {
        bill = object;
    }
    [self reconfigureForBill:bill];
    [self.tableView reloadData];
}

@end
