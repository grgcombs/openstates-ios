//
//  LegislatorDetailHeader.m
//  Created by Greg Combs on 12/12/11.
//
//  OpenStates by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "LegislatorDetailHeader.h"
#import <QuartzCore/QuartzCore.h>
#import "SLFDataModels.h"
#import "UIImageView+AFNetworking.h"
#import "SLFDrawingExtensions.h"

@interface LegislatorDetailHeader()
@property (nonatomic,retain) UIBezierPath *borderOutlinePath;
@property (nonatomic,retain) IBOutlet UIImageView *imageView;
- (void)configure;
@end

static UIFont *nameFont;
static UIFont *plainFont;
static UIFont *titleFont;
static UIColor *strokeColor;

@implementation LegislatorDetailHeader
@synthesize borderOutlinePath = _borderOutlinePath;
@synthesize imageView = _imageView;
@synthesize legislator = _legislator;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        _imageView = [[UIImageView alloc] initWithFrame:CGRectMake(28, 10, 52, 73)];
        [self addSubview:_imageView];
        if (!nameFont)
            nameFont = [SLFFont(18) retain];
        if (!plainFont)
            plainFont = [[UIFont fontWithName:@"HelveticaNeue" size:13] retain];
        if (!titleFont)
            titleFont = [SLFItalicFont(13) retain];
        if (!strokeColor)
            strokeColor = [SLFColorWithRGB(189, 189, 176) retain];
        [self configure];
    }
    return self;
}

- (void)dealloc {
    self.borderOutlinePath = nil;
    self.imageView = nil;
    self.legislator = nil;
    [super dealloc];
}

- (CGSize)sizeThatFits:(CGSize)size {
    size.width = roundf(MAX(size.width, 320));
    size.height = roundf(MAX(size.height, 120));
    return size;
}

- (void)configure {
    [self sizeToFit];
    [self setNeedsDisplay];
}

- (NSString *)validString:(NSString *)string {
    if (IsEmpty(string))
        return @"";
    return string;
}

- (void)drawRect:(CGRect)rect
{
    self.borderOutlinePath = [SLFDrawing tableHeaderBorderPathWithFrame:rect];
    [[SLFAppearance cellBackgroundLightColor] setFill];
    [_borderOutlinePath fill];
    [strokeColor setStroke];
    [_borderOutlinePath stroke];
    if (!_legislator)
        return;
    UIColor *darkColor = [SLFAppearance cellTextColor];
    UIColor *lightColor = [SLFAppearance cellSecondaryTextColor];
    UIColor *partyColor = [_legislator partyObj].color;
    CGFloat offsetX = _imageView.origin.x + _imageView.size.width + 15;
    CGFloat offsetY = _imageView.origin.y-2;
    CGFloat maxWidth = _borderOutlinePath.bounds.size.width - offsetX;
    CGFloat actualFontSize;
    CGSize renderedSize;
    
    NSString *title = [self validString:_legislator.title];
    NSString *name = [self validString:_legislator.fullName];
    NSString *party = [self validString:_legislator.partyObj.name];
    NSString *district = [self validString:_legislator.districtShortName];
    NSString *term = [self validString:_legislator.term];
    
    [lightColor set];
    renderedSize = [title drawAtPoint:CGPointMake(offsetX, offsetY) forWidth:maxWidth withFont:titleFont minFontSize:11 actualFontSize:&actualFontSize lineBreakMode:UILineBreakModeTailTruncation baselineAdjustment:UIBaselineAdjustmentAlignBaselines];
    offsetY += roundf(2+renderedSize.height);

    [darkColor set];
    renderedSize = [name drawAtPoint:CGPointMake(offsetX, offsetY) forWidth:maxWidth withFont:nameFont minFontSize:14 actualFontSize:&actualFontSize lineBreakMode:UILineBreakModeTailTruncation baselineAdjustment:UIBaselineAdjustmentAlignBaselines];
    offsetY += roundf(2+renderedSize.height);

    [partyColor set];
    renderedSize = [party drawAtPoint:CGPointMake(offsetX, offsetY) forWidth:maxWidth withFont:plainFont minFontSize:11 actualFontSize:&actualFontSize lineBreakMode:UILineBreakModeTailTruncation baselineAdjustment:UIBaselineAdjustmentAlignBaselines];
    CGFloat shiftX = roundf(renderedSize.width + 6);
    
    [lightColor set];
    renderedSize = [district drawAtPoint:CGPointMake(offsetX+shiftX, offsetY) forWidth:maxWidth-shiftX withFont:plainFont minFontSize:11 actualFontSize:&actualFontSize lineBreakMode:UILineBreakModeTailTruncation baselineAdjustment:UIBaselineAdjustmentAlignBaselines];

    offsetY += roundf(2+renderedSize.height);

    [lightColor set];
    [term drawAtPoint:CGPointMake(offsetX, offsetY) forWidth:maxWidth withFont:titleFont minFontSize:11 actualFontSize:&actualFontSize lineBreakMode:UILineBreakModeTailTruncation baselineAdjustment:UIBaselineAdjustmentAlignBaselines];
}

- (void)setLegislator:(SLFLegislator *)legislator {
    SLFRelease(_legislator);
    _legislator = [legislator retain];
    [self configure];
    if (!legislator)
        return;
    if (legislator.photoURL)
        [_imageView setImageWithURL:[NSURL URLWithString:legislator.photoURL] placeholderImage:[UIImage imageNamed:@"placeholder"]];
    else
        [self.imageView setImage:[UIImage imageNamed:@"placeholder"]];
    [self setNeedsDisplay];
}


@end