//
//  LegislatorCell.m
//  Created by Gregory Combs on 8/9/10.
//
//  OpenStates (iOS) by Sunlight Foundation Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the BSD-3 License included with this source
// distribution.


#import "LegislatorCell.h"
#import "LegislatorCellView.h"
#import "SLFAppearance.h"
#import "SLFLegislator.h"
#import "UIImageView+AFNetworking.h"
#import "UIImageView+RoundedCorners.h"
#import "SLFTheme.h"
#import "UIImageView+SLFLegislator.h"

static CGFloat LegImageWidth = 53.f;

@interface LegislatorCell()

@property (nonatomic, strong) UIImage *placeholderImage;

@end

@implementation LegislatorCell
@synthesize legislator = _legislator;
@synthesize cellContentView = _cellContentView;
@synthesize placeholderImage;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.opaque = YES;
        self.backgroundColor = [SLFAppearance cellBackgroundLightColor];
        CGRect tzvFrame = CGRectMake(LegImageWidth, 0, CGRectGetWidth(self.contentView.bounds) - LegImageWidth, CGRectGetHeight(self.contentView.bounds));
        _cellContentView = [[LegislatorCellView alloc] initWithFrame:CGRectInset(tzvFrame, 0, 1.0)];
        _cellContentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _cellContentView.contentMode = UIViewContentModeRedraw;
        self.placeholderImage = [UIImage imageNamed:@"placeholder"];
        self.imageView.width = LegImageWidth;
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        self.imageView.autoresizingMask = UIViewAutoresizingNone;
        self.imageView.clipsToBounds = YES;
        self.imageView.backgroundColor = [UIColor whiteColor];
        self.imageView.image = self.placeholderImage;
        [self.contentView addSubview:_cellContentView];
    }
    return self;
}

- (void)dealloc
{
    self.legislator = nil;
}

- (void)prepareForReuse
{
    [super prepareForReuse];

    self.imageView.image = nil;
    self.legislator = nil;
    [self.cellContentView setLegislator:nil];
    self.imageView.image = self.placeholderImage;
}

- (CGSize)cellSize {
	return _cellContentView.cellSize;
}

- (NSString*)role {
	return _cellContentView.role;
}

- (void)setRole:(NSString *)value {
	_cellContentView.role = value;
}

- (void)setGenericName:(NSString *)genericName {
    _cellContentView.genericName = [genericName capitalizedString];
}

- (NSString *)genericName {
    return _cellContentView.genericName;
}

- (void)setHighlighted:(BOOL)val animated:(BOOL)animated {
	[super setHighlighted:val animated:animated];
	_cellContentView.highlighted = val;
}

- (void)setSelected:(BOOL)val animated:(BOOL)animated {
	[super setHighlighted:val animated:animated];
	_cellContentView.highlighted = val;
}

- (void)setLegislator:(SLFLegislator *)value {
    SLFRelease(_legislator);
    _legislator = value; // shouldn't really retain, we don't need to keep it around except mapping fails.
    [self.imageView setImageWithLegislator:value];
	[_cellContentView setLegislator:value];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.imageView.frame = CGRectMake(0, 0, LegImageWidth, 73);
    [_cellContentView setNeedsDisplay];
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    [super setBackgroundColor:backgroundColor];
    self.imageView.backgroundColor = backgroundColor;
    [self.imageView setNeedsDisplay];
    if (_cellContentView.highlighted)
        return;
    _cellContentView.backgroundColor = backgroundColor;
    [_cellContentView setNeedsDisplay];
}

- (void)setUseDarkBackground:(BOOL)useDarkBackground {
    _cellContentView.useDarkBackground = useDarkBackground;
}

- (BOOL)useDarkBackground {
    return _cellContentView.useDarkBackground;
}

@end

@implementation LegislatorCellMapping
@synthesize roundImageCorners = _roundImageCorners;
@synthesize useAlternatingRowColors = _useAlternatingRowColors;

+ (id)cellMapping {
    return [self mappingForClass:[LegislatorCell class]];
}

- (id)init {
    self = [super init];
    if (self) {
        self.cellClass = [LegislatorCell class];
        self.reuseIdentifier = NSStringFromClass([LegislatorCell class]);
        self.rowHeight = 73;
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        self.roundImageCorners = NO;
        self.useAlternatingRowColors = YES;

		__weak __typeof__(self) wSelf = self;
        self.onCellWillAppearForObjectAtIndexPath = ^(UITableViewCell* cell, id object, NSIndexPath* indexPath) {
            LegislatorCell *legCell = (LegislatorCell *)cell;
            BOOL useDarkBG = NO;
            if (wSelf.useAlternatingRowColors) {
                useDarkBG = SLFAlternateCellForIndexPath(cell, indexPath);
            }
            [legCell setUseDarkBackground:useDarkBG];
        };
    }
    return self;
}

- (void)addDefaultMappings {
    [self mapKeyPath:@"self" toAttribute:@"legislator"];
}

@end

@implementation FoundLegislatorCellMapping

- (id)init {
    self = [super init];
    if (self) {
        self.useAlternatingRowColors = NO;
    }
    return self;
}

- (void)addDefaultMappings {
    [self mapKeyPath:@"foundLegislator" toAttribute:@"legislator"];
    [self mapKeyPath:@"type" toAttribute:@"role"];
    [self mapKeyPath:@"name" toAttribute:@"genericName"];
}

@end
