//
//  MFWobbleModel.m
//  MFWobbleViewDemo
//
//  Created by Lyman Li on 2019/4/27.
//  Copyright © 2019年 Lyman Li. All rights reserved.
//

#import "MFWobbleModel.h"

@implementation MFWobbleModel

- (CGFloat)distanceFromPoint:(CGPoint)fromPoint toPoint:(CGPoint)toPoint {
    return sqrt(pow(fromPoint.x - toPoint.x, 2.0) + pow(fromPoint.y - toPoint.y, 2.0));
}

- (BOOL)containsPoint:(CGPoint)point {
    CGPoint center = self.center;
    CGFloat distanceLT = [self distanceFromPoint:self.pointLT toPoint:center];
    CGFloat distanceRT = [self distanceFromPoint:self.pointRT toPoint:center];
    CGFloat distanceRB = [self distanceFromPoint:self.pointRB toPoint:center];
    CGFloat distanceLB = [self distanceFromPoint:self.pointLB toPoint:center];
    CGFloat maxDistance = MAX(MAX(distanceLT, distanceRT), MAX(distanceRB, distanceLB));
    
    CGFloat pointDistance = [self distanceFromPoint:point toPoint:center];
    return pointDistance <= maxDistance;
}

@end
