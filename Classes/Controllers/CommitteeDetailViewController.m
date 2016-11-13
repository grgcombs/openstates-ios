//
//  CommitteeDetailViewController.m
//  Created by Gregory Combs on 7/31/11.
//
//  OpenStates (iOS) by Sunlight Foundation Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the BSD-3 License included with this source
// distribution.


#import "CommitteeDetailViewController.h"
#import "LegislatorDetailViewController.h"
#import "SLFDataModels.h"
#import "SLFMappingsManager.h"
#import "SLFRestKitManager.h"
#import "SLFReachable.h"
#import "LegislatorCell.h"
#import "GenericDetailHeader.h"
#import "SLFImprovedRKTableController.h"

#define SectionHeaderCommitteeInfo NSLocalizedString(@"Committee Details", @"")
#define SectionHeaderMembers NSLocalizedString(@"Members", @"")

@interface CommitteeDetailViewController()

@property (nonatomic, strong) SLFImprovedRKTableController *tableController;

- (void)configureTableController;
- (void)configureTableItems;
- (void)configureResourceItems;
- (void)configureMemberItems;
- (void)configureTableHeader;
- (void)loadDataFromNetworkWithID:(NSString *)resourceID;
- (RKTableViewCellMapping *)committeeMemberCellMap;

@end

@implementation CommitteeDetailViewController
@synthesize committee = _committee;
@synthesize tableController = _tableController;

- (id)initWithCommitteeID:(NSString *)committeeID {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        [self loadDataFromNetworkWithID:committeeID];
    }
    return self;
}

- (void)dealloc {
    [[RKObjectManager sharedManager].requestQueue cancelRequestsWithDelegate:self];
}

- (void)viewDidUnload {
    [[RKObjectManager sharedManager].requestQueue cancelRequestsWithDelegate:self];
    self.tableController = nil;
    [super viewDidUnload];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureTableController];
	self.title = NSLocalizedString(@"Loading...", @"");
    self.screenName = @"Committee Detail Screen";
}

- (NSString *)actionPath {
    return [[self class] actionPathForObject:self.committee];
}

- (void)reconfigureForCommittee:(SLFCommittee *)committee {
    if (committee) {
        self.committee = committee;
        self.title = committee.committeeName;
    }
    [self configureTableItems];
}

- (void)loadDataFromNetworkWithID:(NSString *)resourceID {
    NSDictionary *queryParams = [NSDictionary dictionaryWithObjectsAndKeys:SUNLIGHT_APIKEY,@"apikey", resourceID, @"committeeID", nil];
    NSString *resourcePath = RKMakePathWithObject(@"/committees/:committeeID?apikey=:apikey", queryParams);
    [[SLFRestKitManager sharedRestKit] loadObjectsAtResourcePath:resourcePath delegate:self withTimeout:SLF_HOURS_TO_SECONDS(24)];
}

- (void)configureTableController {
    self.tableController = [SLFImprovedRKTableController tableControllerForTableViewController:(UITableViewController*)self];
    _tableController.delegate = self;
    _tableController.objectManager = [RKObjectManager sharedManager];
    _tableController.pullToRefreshEnabled = NO;
    _tableController.variableHeightRows = YES;
    [_tableController mapObjectsWithClass:[CommitteeMember class] toTableCellsWithMapping:[self committeeMemberCellMap]];
}

- (void)configureTableItems {
    [_tableController removeAllSections:NO];
    [self configureTableHeader];
    [self configureResourceItems];
    [self configureMemberItems];
}

- (void)configureTableHeader {
    __weak __typeof__(self) bself = self;
    RKTableSection *headerSection = [RKTableSection sectionUsingBlock:^(RKTableSection *section) {
        GenericDetailHeader *header = [[GenericDetailHeader alloc] initWithFrame:CGRectMake(0, 0, bself.tableView.width, 100)];
        header.defaultSize = CGSizeMake(bself.tableView.width, 100);
        section.headerTitle = @"";
        header.title = bself.committee.committeeName;
        header.subtitle = bself.committee.chamberObj.name;
        header.detail = bself.committee.subcommittee;
        [header configure];
        section.headerHeight = header.height;
        section.headerView = header;
    }];
    [_tableController addSection:headerSection];
}

- (void)configureResourceItems {
    if (!SLFTypeNonEmptySetOrNil(_committee.sources))
        return;
    NSMutableArray* tableItems  = [[NSMutableArray alloc] init];
    for (GenericAsset *source in _committee.sources) {
        NSString *subtitle = source.name;
        if (!SLFTypeNonEmptyStringOrNil(subtitle))
            subtitle = source.url;
        [tableItems addObject:[self webPageItemWithTitle:NSLocalizedString(@"Website", @"") subtitle:subtitle url:source.url]];
    }
    SLFAddTableControllerSectionWithTitle(_tableController, NSLocalizedString(@"Resources", @""));
    NSUInteger sectionIndex = _tableController.sectionCount-1;
    [_tableController loadTableItems:tableItems inSection:sectionIndex];
}

- (void)configureMemberItems {
    if (!SLFTypeNonEmptySetOrNil(_committee.members))
        return;
    SLFAddTableControllerSectionWithTitle(_tableController, NSLocalizedString(@"Members", @""));
    NSUInteger sectionIndex = _tableController.sectionCount-1;
    [_tableController loadObjects:_committee.sortedMembers inSection:sectionIndex];
}

- (RKTableViewCellMapping *)committeeMemberCellMap {
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

- (void)objectLoader:(RKObjectLoader*)objectLoader didLoadObject:(id)object {
    SLFCommittee *committee = nil;
    if (object && [object isKindOfClass:[SLFCommittee class]])
        committee = object;
    [self reconfigureForCommittee:committee];
}

- (void)objectLoader:(RKObjectLoader*)objectLoader didFailWithError:(NSError*)error {
    self.title = NSLocalizedString(@"Load Error",@"");
    [SLFRestKitManager showFailureAlertWithRequest:objectLoader error:error];
}

@end
