//
//  MFSketchModel.m
//  MFWobbleViewDemo
//
//  Created by Lyman Li on 2019/4/20.
//  Copyright © 2019年 Lyman Li. All rights reserved.
//

#import "MFSketchModel.h"

@implementation MFSketchModel

#pragma mark - Custom Accessor

- (void)setPointLT:(CGPoint)pointLT {
    _pointLT = pointLT;
    
    [self resetCenter];
}

- (void)setPointRT:(CGPoint)pointRT {
    _pointRT = pointRT;
    
    [self resetCenter];
}

- (void)setPointRB:(CGPoint)pointRB {
    _pointRB = pointRB;
    
    [self resetCenter];
}

- (void)setPointLB:(CGPoint)pointLB {
    _pointLB = pointLB;
    
    [self resetCenter];
}

#pragma mark - Public

- (CGPoint)topLineCenter {
    return [self centerPointFromPoint:self.pointLT toPoint:self.pointRT];
}

- (CGPoint)leftLineCenter {
    return [self centerPointFromPoint:self.pointLT toPoint:self.pointLB];
}

- (CGPoint)bottomLineCenter {
    return [self centerPointFromPoint:self.pointLB toPoint:self.pointRB];
}

- (CGPoint)rightLineCenter {
    return [self centerPointFromPoint:self.pointRT toPoint:self.pointRB];
}

#pragma mark - Private

- (CGPoint)centerPointFromPoint:(CGPoint)fromPoint toPoint:(CGPoint)toPoint {
    return CGPointMake((fromPoint.x + toPoint.x) / 2, (fromPoint.y + toPoint.y) / 2);
}

- (void)resetCenter {
    self.center = [self centerPointFromPoint:[self topLineCenter] toPoint:[self bottomLineCenter]];
}

@end
