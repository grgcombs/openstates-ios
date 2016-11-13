//
//  SLFAppearance.h
//  Created by Greg Combs on 9/22/11.
//
//  OpenStates (iOS) by Sunlight Foundation Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the BSD-3 License included with this source
// distribution.


@interface SLFAppearance : NSObject

+(void)setupAppearance;

+ (UIColor *)navBarTextColor;
+ (UIColor *)primaryTintColor;
+ (UIColor *)barTintColor;
+ (UIColor *)menuTextColor;
+ (UIColor *)menuBackgroundColor;
+ (UIColor *)cellBackgroundDarkColor;
+ (UIColor *)cellBackgroundLightColor;
+ (UIColor *)cellTextColor;
+ (UIColor *)cellSecondaryTextColor;
+ (UIColor *)detailHeaderSeparatorColor;
+ (UIColor *)tableBackgroundLightColor;
+ (UIColor *)tableBackgroundDarkColor;
+ (UIColor *)tableSeparatorColor;
+ (UIColor *)tableSectionColor;
+ (UIColor *)accentGreenColor;
+ (UIColor *)accentBlueColor;
+ (UIColor *)accentOrangeColor;
+ (UIColor *)partyRed;
+ (UIColor *)partyBlue;
+ (UIColor *)partyGreen;
+ (UIColor *)partyWhite;
@end

BOOL SLFColorGetRGBAComponents(UIColor *color, CGFloat *red, CGFloat *green, CGFloat *blue, CGFloat *alpha);
UIColor *SLFColorWithRGBShift(UIColor *color, int offset);
UIColor *SLFColorWithRGBA(int r, int g, int b, CGFloat a);
UIColor *SLFColorWithRGB(int red,  int green, int blue);
UIColor *SLFColorWithHex(char hex);

UIFont *SLFFontWithDescriptorAndSize(UIFontDescriptor *descriptor, CGFloat zeroOrSize);
UIFont *SLFFontWithStyle(NSString *textStyle, UIFontDescriptorSymbolicTraits traits, CGFloat zeroOrSize);
UIFont *SLFFont(CGFloat size);
UIFont *SLFPlainFont(CGFloat size);
UIFont *SLFTitleFont(CGFloat size);
UIFont *SLFItalicFont(CGFloat size);

extern NSString * const SLFAppearanceBoldFontName;
extern NSString * const SLFAppearancePlainFontName;
extern NSString * const SLFAppearanceItalicsFontName;
extern NSString * const SLFAppearanceTitleFontName;
