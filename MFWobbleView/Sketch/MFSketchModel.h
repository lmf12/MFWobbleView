//
//  MFSketchModel.h
//  MFWobbleViewDemo
//
//  Created by Lyman Li on 2019/4/20.
//  Copyright © 2019年 Lyman Li. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MFSketchModel : NSObject

@property (nonatomic, assign) CGPoint pointLT; // 左上
@property (nonatomic, assign) CGPoint pointRT; // 右上
@property (nonatomic, assign) CGPoint pointLB; // 左下
@property (nonatomic, assign) CGPoint pointRB; // 右下

/**
 上边中点
 */
- (CGPoint)topLineCenter;

/**
 左边中点
 */
- (CGPoint)leftLineCenter;

/**
 底边中点
 */
- (CGPoint)bottomLineCenter;

/**
 右边中点
 */
- (CGPoint)rightLineCenter;

/**
 中心点
 */
- (CGPoint)center;

@end
