//
//  SLFDrawingExtensions.h
//  Created by Greg Combs on 11/18/11.
//
//  OpenStates by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the BSD-3 License included with this source
// distribution.


@interface SLFDrawing : NSObject
    // Used to determine gradient direction
+ (void)getStartPoint:(CGPoint*)startRef endPoint:(CGPoint *)endRef withAngle:(CGFloat)angle inRect:(CGRect)rect;
+ (UIBezierPath *)tableHeaderBorderPathWithFrame:(CGRect)frame;
+ (void)drawInsetBeveledRoundedRect:(CGRect)rect radius:(CGFloat)radius fillColor:(UIColor *)fillColor context:(CGContextRef)context;
@end

@interface UIImage (SLFExtensions)
+ (UIImage *)imageFromView:(UIView *)view;
- (UIImage *)glossyImageOverlay;
@end

@interface UIButton (SLFExtensions)
+ (UIButton *)buttonForImage:(UIImage *)iconImage withFrame:(CGRect)rect glossy:(BOOL)glossy shadow:(BOOL)shadow;
+ (UIButton *)buttonForImage:(UIImage *)iconImage withFrame:(CGRect)rect glossy:(BOOL)glossy;
@end

