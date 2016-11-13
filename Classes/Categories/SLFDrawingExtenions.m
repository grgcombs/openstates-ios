//
//  SLFDrawingExtensions.m
//  Created by Greg Combs on 11/18/11.
//
//  OpenStates by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the BSD-3 License included with this source
// distribution.


#import "SLFDrawingExtensions.h"
#import <QuartzCore/QuartzCore.h>

static void addRoundedRectToPath(CGContextRef context, CGRect rect, float ovalWidth, float ovalHeight);
static void addGlossPath(CGContextRef context, CGRect rect);

@implementation UIImage (SLFExtensions)
+ (UIImage *)imageFromView:(UIView *)view
{
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.opaque, 0.0);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage * img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

- (UIImage *)glossyImageOverlay {
    UIImage *newImage;
    CGContextRef context;
    CGGradientRef glossGradient;
    CGColorSpaceRef rgbColorspace;
    CGRect currentBounds = CGRectMake(0, 0, self.size.width, self.size.height);
    CGPoint topCenter = CGPointMake(CGRectGetMidX(currentBounds), 0.0f);
    CGPoint midCenter = CGPointMake(CGRectGetMidX(currentBounds), CGRectGetMidY(currentBounds));
    
    CGFloat locations[2] = {0.0, 1.0};
    CGFloat components[8] = {
        1.0, 1.0, 1.0, 0.75, 
        1.0, 1.0, 1.0, 0.2
    };
    
    UIGraphicsBeginImageContext(self.size);
    context = UIGraphicsGetCurrentContext();
    UIGraphicsPushContext(context);
    
    addRoundedRectToPath(context, currentBounds, 10, 10);
    CGContextClosePath(context);
    CGContextClip(context);
    [self drawInRect:currentBounds];
    
    addGlossPath(context, currentBounds);
    CGContextClip(context);
    
    rgbColorspace = CGColorSpaceCreateDeviceRGB();
    glossGradient = CGGradientCreateWithColorComponents(rgbColorspace, components, locations, 2);
    
    CGContextDrawLinearGradient(context, glossGradient, topCenter, midCenter, 0);
    UIGraphicsPopContext();
    
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    CGGradientRelease(glossGradient);
    CGColorSpaceRelease(rgbColorspace);
    UIGraphicsEndImageContext();
    
    return newImage;
}
@end

@implementation UIButton (SLFExtensions)
+ (UIButton *)buttonForImage:(UIImage *)iconImage withFrame:(CGRect)rect glossy:(BOOL)glossy shadow:(BOOL)shadow {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = rect;
    if (glossy)
        iconImage = [iconImage glossyImageOverlay];
    [button setImage:iconImage forState:UIControlStateNormal];
    button.layer.shouldRasterize = YES;
    if (shadow) {
        button.layer.shadowColor = [[UIColor blackColor] CGColor];
        button.layer.shadowOffset = CGSizeMake(0, 1);
        button.layer.shadowRadius = 2.f;
        button.layer.shadowOpacity = 1;
    }
    return button;
}

+ (UIButton *)buttonForImage:(UIImage *)iconImage withFrame:(CGRect)rect glossy:(BOOL)glossy {
    return [UIButton buttonForImage:iconImage withFrame:rect glossy:glossy shadow:YES];
}
@end

@implementation SLFDrawing

#if !defined(DegreesToRadians)
#define DegreesToRadians(x) (x * (CGFloat)M_PI / 180.0f)
#endif

#if !defined(RadiansToDegrees)
#define RadiansToDegrees(x) (x * 180.0f / (CGFloat)M_PI)
#endif

+ (void)getStartPoint:(CGPoint*)startRef endPoint:(CGPoint *)endRef withAngle:(CGFloat)angle inRect:(CGRect)rect {
    NSParameterAssert(startRef != NULL && endRef != NULL);
	CGPoint startPoint;
    CGPoint endPoint;
	if(angle == 0)
  	{
		startPoint = CGPointMake(CGRectGetMinX(rect), CGRectGetMinY(rect));
		endPoint   = CGPointMake(CGRectGetMaxX(rect), CGRectGetMinY(rect));
  	} else if(angle == 90) {
		startPoint = CGPointMake(CGRectGetMinX(rect), CGRectGetMinY(rect));
		endPoint   = CGPointMake(CGRectGetMinX(rect), CGRectGetMaxY(rect));
  	} else {
		double_t x, y;
		double_t sina, cosa, tana;
		double_t length;
		double_t deltax, deltay;
        
		double_t radians = DegreesToRadians(angle);
        
		if(fabs(tan(radians)) <= 1.0f)
		{
			x = CGRectGetWidth(rect);
			y = CGRectGetHeight(rect);
            
			sina = sin(radians);
			cosa = cos(radians);
			tana = tan(radians);
            
			length = x/fabs(cosa) + (y - x * fabs(tana)) * fabs(sina);
            
			deltax = length * cosa/2;
			deltay = length * sina/2;
		} else	{
			x = CGRectGetHeight(rect);
			y = CGRectGetWidth(rect);
            
			sina = sin(radians - DegreesToRadians(90));
			cosa = cos(radians - DegreesToRadians(90));
			tana = tan(radians - DegreesToRadians(90));
            
			length = x/fabs(cosa) + (y - x * fabs(tana)) * fabs(sina);
            
			deltax = -length * sina/2;
			deltay = length * cosa/2;
		}
        
		startPoint = CGPointMake(CGRectGetMidX(rect) - (CGFloat)deltax, CGRectGetMidY(rect) - (CGFloat)deltay);
		endPoint   = CGPointMake(CGRectGetMidX(rect) + (CGFloat)deltax, CGRectGetMidY(rect) + (CGFloat)deltay);
	}
    *startRef = startPoint;
    *endRef = endPoint;
}

+ (UIBezierPath *)tableHeaderBorderPathWithFrame:(CGRect)frame {
    CGRect rect = frame;
    rect.size.height -= 26;
    if (SLFIsIpad()) {
        rect.size.width -= 26;
        rect.origin.x += (CGRectGetMidX(frame) - CGRectGetMidX(rect));
    }
    rect = CGRectIntegral(rect);
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:rect.origin];
    [path addLineToPoint:CGPointMake(rect.origin.x+rect.size.width, rect.origin.y)];
    [path addLineToPoint:CGPointMake(rect.origin.x+rect.size.width, rect.origin.y+rect.size.height)];
    [path addLineToPoint:CGPointMake(rect.origin.x+52, rect.origin.y+rect.size.height)];
    [path addLineToPoint:CGPointMake(rect.origin.x+38, rect.origin.y+rect.size.height + 15)];
    [path addLineToPoint:CGPointMake(rect.origin.x+24, rect.origin.y+rect.size.height)];
    [path addLineToPoint:CGPointMake(rect.origin.x, rect.origin.y+rect.size.height)];
    [path addLineToPoint:CGPointMake(rect.origin.x, rect.origin.y)];
    [path closePath];
    path.lineWidth = 1;
    path.lineJoinStyle = kCGLineJoinMiter;
    path.lineCapStyle = kCGLineCapButt;
    return path;
}

+ (void)drawInsetBeveledRoundedRect:(CGRect)rect radius:(CGFloat)radius fillColor:(UIColor *)fillColor context:(CGContextRef)context {
    CGRect drawRect = CGRectInset(rect, 1.0f, 1.0f);
    drawRect.size.height -= 1.0f;
	CGContextSaveGState(context);
    CGPathRef boxPath = [[UIBezierPath bezierPathWithRoundedRect: drawRect cornerRadius: radius] CGPath];
        //offset by half a pixel to ensure proper drawing
    CGPathRef strokePath = [[UIBezierPath bezierPathWithRoundedRect: CGRectInset(drawRect, -0.5f, -0.5f) cornerRadius: radius] CGPath];
    
    /* Draw the bevel effect*/
    CGContextSaveGState(context);
    CGContextSetFillColorWithColor(context, [[UIColor colorWithWhite: 1.0f alpha: 0.8f] CGColor]);
    CGContextClipToRect(context, CGRectMake(rect.origin.x, rect.origin.y+rect.size.height-radius, rect.size.width, radius));
    CGRect corner = CGRectMake(rect.origin.x, (rect.origin.y+rect.size.height)-(2*radius)-1, (radius*2)+1, (radius*2)+1);
    CGContextFillEllipseInRect(context, corner);
    corner.origin.x = rect.origin.x + rect.size.width - (radius*2)-1;
    CGContextFillEllipseInRect(context, corner);
    CGContextSetBlendMode(context, kCGBlendModeCopy);
    CGContextFillRect(context, CGRectMake(rect.origin.x+radius, rect.origin.y+rect.size.height-radius, rect.size.width-(2*radius),radius+1));
    CGContextRestoreGState(context);
    
    /* Draw the main region */
    CGContextSaveGState(context);
    CGContextSetFillColorWithColor(context, [fillColor CGColor]);
    CGContextAddPath(context, strokePath);
    CGContextFillPath(context);
    CGContextRestoreGState(context);
    
    /* Main fill region inner drop shadow
     This is done by duplicating the path, offsetting the duplicate by 1 pixel, and using the EO winding fill rule to fill the gap between the two */
    CGContextSaveGState(context);
    CGContextSetFillColorWithColor(context, [[UIColor colorWithWhite: 0.0f alpha: 0.08f] CGColor]);
    CGContextClipToRect(context, CGRectMake( drawRect.origin.x, drawRect.origin.y, drawRect.size.width, radius ));
    CGContextAddPath(context, boxPath);
    CGContextTranslateCTM(context, 0.0f, 1.0f);
    CGContextAddPath(context, boxPath);
    CGContextEOFillPath(context);
    CGContextRestoreGState(context);
    
    /* Outer Stroke
     This is drawn outside of the fill region to prevent the fill region bleeding over in some cases */
    CGContextSaveGState(context);
    CGContextSetLineWidth(context, 1.0f);
    CGContextSetStrokeColorWithColor(context, [[UIColor colorWithWhite: 0.0f alpha: 0.18f] CGColor]);
    CGContextAddPath(context, strokePath);
    CGContextSetBlendMode(context, kCGBlendModeCopy);
    CGContextStrokePath(context);
    CGContextRestoreGState( 
                           context );
    
	CGContextRestoreGState( context );
}
@end

static void addRoundedRectToPath(CGContextRef context, CGRect rect, float ovalWidth, float ovalHeight) {
    float fw, fh;
    if (ovalWidth == 0 || ovalHeight == 0) {
        CGContextAddRect(context, rect);
        return;
    }
    CGContextSaveGState(context);
    CGContextTranslateCTM (context, CGRectGetMinX(rect), CGRectGetMinY(rect));
    CGContextScaleCTM (context, ovalWidth, ovalHeight);
    fw = CGRectGetWidth (rect) / ovalWidth;
    fh = CGRectGetHeight (rect) / ovalHeight;
    CGContextMoveToPoint(context, fw, fh/2);
    CGContextAddArcToPoint(context, fw, fh, fw/2, fh, 1);
    CGContextAddArcToPoint(context, 0, fh, 0, fh/2, 1);
    CGContextAddArcToPoint(context, 0, 0, fw/2, 0, 1);
    CGContextAddArcToPoint(context, fw, 0, fw, fh/2, 1);
    CGContextClosePath(context);
    CGContextRestoreGState(context);
}

static void addGlossPath(CGContextRef context, CGRect rect) {
    CGFloat quarterHeight = CGRectGetMidY(rect) / 2;
    CGContextSaveGState(context);
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, -20, 0);
    
    CGContextAddLineToPoint(context, -20, quarterHeight);
    CGContextAddQuadCurveToPoint(context, CGRectGetMidX(rect), quarterHeight * 3, CGRectGetMaxX(rect) + 20, quarterHeight);
    CGContextAddLineToPoint(context, CGRectGetMaxX(rect) + 20, 0);
    
    CGContextClosePath(context);
    CGContextRestoreGState(context);
}


