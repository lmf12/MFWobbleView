//
//  MFSketchModel.m
//  MFWobbleViewDemo
//
//  Created by Lyman Li on 2019/4/20.
//  Copyright © 2019年 Lyman Li. All rights reserved.
//

#import "MFSketchModel.h"

@implementation MFSketchModel

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

- (CGPoint)center {
    return [self centerPointFromPoint:[self topLineCenter] toPoint:[self bottomLineCenter]];
}

#pragma mark - Private

- (CGPoint)centerPointFromPoint:(CGPoint)fromPoint toPoint:(CGPoint)toPoint {
    return CGPointMake((fromPoint.x + toPoint.x) / 2, (fromPoint.y + toPoint.y) / 2);
}

@end
