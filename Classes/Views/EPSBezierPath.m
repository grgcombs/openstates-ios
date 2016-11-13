//
//  EPSBezierPath.m
//  Created by Greg Combs on 11/13/11.
//
//  OpenStates (iOS) by Sunlight Foundation Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the BSD-3 License included with this source
// distribution.


#import "EPSBezierPath.h"

@interface EPSBezierPath()
@property (nonatomic,assign) CGPoint previousPoint;
@end

@implementation EPSBezierPath
@synthesize previousPoint = _previousPoint;
@synthesize fillColor = _fillColor;
@synthesize strokeColor = _strokeColor;

+ (EPSBezierPath *)pathWithFillColor:(UIColor *)fill strokeColor:(UIColor *)stroke {
    EPSBezierPath *path = [[EPSBezierPath alloc] init];
    path.fillColor = fill;
    path.strokeColor = stroke;
    return path;
}


    // EPS:"M"
- (void)moveToPoint:(CGPoint)point {
    [super moveToPoint:point];
    _previousPoint = point;
}

    // EPS:"L"
- (void)addLineToPoint:(CGPoint)point {
    [super addLineToPoint:point];
    _previousPoint = point;
}

    // EPS:"V"
- (void)startCurveWithControlPoint2:(CGPoint)point2 end:(CGPoint)end {
    [super addCurveToPoint:end controlPoint1:_previousPoint controlPoint2:point2];
    _previousPoint = end;
}

    // EPS:"C"
- (void)continueCurveWithControlPoint1:(CGPoint)point1 point2:(CGPoint)point2 end:(CGPoint)end {
    [super addCurveToPoint:end controlPoint1:point1 controlPoint2:point2];
    _previousPoint = end;
}

    // EPS:"Y"
- (void)endCurveWithControlPoint1:(CGPoint)point1 end:(CGPoint)end {
    [super addCurveToPoint:end controlPoint1:point1 controlPoint2:end];
    _previousPoint = end;
}

- (void)fillIfNeeded {
    if (!self.fillColor)
        return;
    [_fillColor setFill];
    [self fill];
}

- (void)strokeIfNeeded {
    if (!self.strokeColor)
        return;
    [_strokeColor setStroke];
    [self stroke];
}

- (void)fillAndStrokeIfNeeded {
    [self fillIfNeeded];
    [self strokeIfNeeded];
}
@end
