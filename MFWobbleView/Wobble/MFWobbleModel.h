//
//  MFWobbleModel.h
//  MFWobbleViewDemo
//
//  Created by Lyman Li on 2019/4/27.
//  Copyright © 2019年 Lyman Li. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MFWobbleModel : NSObject

@property (nonatomic, assign) CGPoint pointLT; // 左上
@property (nonatomic, assign) CGPoint pointRT; // 右上
@property (nonatomic, assign) CGPoint pointLB; // 左下
@property (nonatomic, assign) CGPoint pointRB; // 右下
@property (nonatomic, assign) CGPoint direction; // 方向的单位向量
@property (nonatomic, assign) CGFloat amplitude; // 振幅 0 ~ 1

@property (nonatomic, assign) CGFloat lastAnimationBeginTime; // 上次动画的开始时间

- (BOOL)containsPoint:(CGPoint)point;

@end
