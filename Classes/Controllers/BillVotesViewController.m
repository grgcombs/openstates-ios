//
//  BillVotesViewController.m
//  Created by Greg Combs on 11/21/11.
//
//  OpenStates by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the BSD-3 License included with this source
// distribution.


#import "BillVotesViewController.h"
#import "SLFDataModels.h"
#import "TableSectionHeaderView.h"
#import "NSString+SLFExtensions.h"
#import "NSDate+SLFDateHelper.h"
#import "LegislatorDetailViewController.h"
#import "UIImageView+AFNetworking.h"
#import "UIImageView+RoundedCorners.h"
#import "LegislatorCell.h"
#import "SLFImprovedRKTableController.h"

enum SECTIONS {
    SectionVoteInfo = 1,
    SectionYes,
    SectionNo,
    SectionOther,
    kNumSections
};

@interface BillVotesViewController()

@property (nonatomic, strong) SLFImprovedRKTableController *tableController;

- (RKTableViewCellMapping *)voterCellMap;
- (NSString *)headerForSectionIndex:(NSInteger)sectionIndex;
- (void)configureTableItems;
- (void)configureVoteInfo;
- (void)configureVoters;

@end

@implementation BillVotesViewController
@synthesize vote = _vote;
@synthesize tableController = _tableController;

- (id)initWithVote:(BillRecordVote *)vote {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.stackWidth = 500;
        self.vote = vote;
    }
    return self;
}


- (void)viewDidUnload {
    self.tableController = nil;
    [super viewDidUnload];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView registerClass:[LegislatorCell class] forCellReuseIdentifier:NSStringFromClass([LegislatorCell class])];
    self.tableController = [SLFImprovedRKTableController tableControllerForTableViewController:(UITableViewController*)self];
    _tableController.delegate = self;
    _tableController.variableHeightRows = YES;
    _tableController.objectManager = [RKObjectManager sharedManager];
    _tableController.pullToRefreshEnabled = NO;
    [_tableController mapObjectsWithClass:[BillVoter class] toTableCellsWithMapping:[self voterCellMap]];
    NSInteger sectionIndex;
    CGFloat headerHeight = [TableSectionHeaderView heightForTableViewStyle:self.tableViewStyle];

    __weak __typeof__(self) bself = self;
    for (sectionIndex = SectionVoteInfo;sectionIndex < kNumSections; sectionIndex++)
    {
        [_tableController addSectionUsingBlock:^(RKTableSection *section) {
            if (!bself)
                return;

            NSString *headerTitle = [bself headerForSectionIndex:sectionIndex];
            TableSectionHeaderView *headerView = [[TableSectionHeaderView alloc] initWithTitle:headerTitle width:bself.tableView.width style:bself.tableViewStyle];
            section.headerTitle = headerTitle;
            section.headerHeight = headerHeight;
            section.headerView = headerView;
        }];
    }
    [self configureTableItems];
    self.screenName = @"Bill Votes Screen";
}

- (void)configureTableItems {
    if (!self.vote)
        return;
    self.title = _vote.title;
    [self configureVoteInfo];     
    [self configureVoters];
}

#pragma mark - Table Item Creation and Mapping

- (void)configureVoteInfo {
    NSMutableArray* tableItems  = [[NSMutableArray alloc] init];    
    __weak __typeof__(self) bself = self;
    [tableItems addObject:[RKTableItem tableItemUsingBlock:^(RKTableItem *tableItem) {
        tableItem.cellMapping = [StyledCellMapping staticSubtitleMapping];
        tableItem.text = NSLocalizedString(@"Chamber", @"");
        tableItem.detailText = bself.vote.chamberObj.formalName;
    }]];
    [tableItems addObject:[RKTableItem tableItemUsingBlock:^(RKTableItem *tableItem) {
        NSString *caption = [bself.vote.date stringForDisplay];
        if (SLFTypeNonEmptyStringOrNil(bself.vote.session))
            caption = [NSString stringWithFormat:@"%@ (%@)", [bself.vote.date stringForDisplay], bself.vote.session];
        tableItem.cellMapping = [StyledCellMapping staticSubtitleMapping];
        tableItem.text = NSLocalizedString(@"Date", @"");
        tableItem.detailText = caption;
    }]];
    if (SLFTypeNonEmptyStringOrNil(bself.vote.motion)) {
        [tableItems addObject:[RKTableItem tableItemUsingBlock:^(RKTableItem *tableItem) {
            NSString *caption = [bself.vote.motion capitalizedString];
            if (SLFTypeNonEmptyStringOrNil(bself.vote.record))
                caption = [NSString stringWithFormat:@"%@ (%@)", caption, bself.vote.record];
            tableItem.cellMapping = [StyledCellMapping staticSubtitleMapping];
            tableItem.text = NSLocalizedString(@"Motion", @"");
            tableItem.detailText = caption;
        }]];
    }
    [tableItems addObject:[RKTableItem tableItemUsingBlock:^(RKTableItem *tableItem) {
        tableItem.cellMapping = [StyledCellMapping staticSubtitleMapping];
        tableItem.text = NSLocalizedString(@"Status", @"");
        tableItem.detailText = bself.vote.subtitle;
    }]];
    [self.tableController loadTableItems:tableItems inSection:SectionVoteInfo];     
}

- (void)configureVoters {
    [_tableController loadObjects:_vote.sortedYesVotes inSection:SectionYes];    
    [_tableController loadObjects:_vote.sortedNoVotes inSection:SectionNo];    
    [_tableController loadObjects:_vote.sortedOtherVotes inSection:SectionOther];    
}

- (RKTableViewCellMapping *)voterCellMap {
    FoundLegislatorCellMapping *cellMapping = [FoundLegislatorCellMapping cellMapping];
    [cellMapping mapKeyPath:@"foundLegislator" toAttribute:@"legislator"];
    [cellMapping mapKeyPath:@"type" toAttribute:@"role"];
    [cellMapping mapKeyPath:@"name" toAttribute:@"genericName"];
    __weak __typeof__(self) wSelf = self;
    __weak __typeof__(cellMapping) wCellMapping = cellMapping;
    cellMapping.onCellWillAppearForObjectAtIndexPath = ^(UITableViewCell* cell, id object, NSIndexPath* indexPath) {
        if (wCellMapping.roundImageCorners) {
            NSInteger numRows = [wSelf.tableController tableView:wSelf.tableView numberOfRowsInSection:indexPath.section];
            if (numRows == 1)
                [cell.imageView roundTopAndBottomLeftCorners];
            else if (indexPath.row == 0)
                [cell.imageView roundTopLeftCorner];
            else if (indexPath.row == (numRows-1))
                [cell.imageView roundBottomLeftCorner];
        }
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.f, 0.f, 50.f, 50.f)];
		cell.accessoryView = imageView;
        BillVoter *voter = object;
        if ([voter yesVoteInverse])
            imageView.image = [UIImage imageNamed:@"VoteYea"];
        else if ([voter noVoteInverse])
            imageView.image = [UIImage imageNamed:@"VoteNay"];
        else if ([voter otherVoteInverse])
            imageView.image = [UIImage imageNamed:@"VotePNV"];
        [(LegislatorCell *)cell setUseDarkBackground:NO];
    };
    cellMapping.onSelectCellForObjectAtIndexPath = ^(UITableViewCell* cell, id object, NSIndexPath *indexPath) {
        NSString *legID = SLFTypeNonEmptyStringOrNil([object valueForKey:@"legID"]);
        NSString *path = [SLFActionPathNavigator navigationPathForController:[LegislatorDetailViewController class] withResourceID:legID];
        if (SLFTypeNonEmptyStringOrNil(path)) {
            [SLFActionPathNavigator navigateToPath:path skipSaving:NO fromBase:wSelf popToRoot:NO];
        }
    };
    return cellMapping;
}

- (NSString *)headerForSectionIndex:(NSInteger)sectionIndex {
    switch (sectionIndex) {
        case SectionVoteInfo:
            return NSLocalizedString(@"Vote Details", @"");
        case SectionYes:
            return NSLocalizedString(@"Yeas",@"");
        case SectionNo:
            return NSLocalizedString(@"Nays",@"");
        case SectionOther:
            return NSLocalizedString(@"Others (PNV, Absent, etc)", @"");
        default:
            return @"";
    }
}
@end
