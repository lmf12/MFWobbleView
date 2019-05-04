//
//  MFWobbleView.h
//  MFWobbleViewDemo
//
//  Created by Lyman Li on 2019/4/18.
//  Copyright © 2019年 Lyman Li. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MFWobbleModel.h"

@interface MFWobbleView : UIView

@property (nonatomic, strong) UIImage *image;

@property (nonatomic, copy) NSArray<MFWobbleModel *> *wobbleModels;

/**
 配置完成
 */
- (void)prepare;

/**
 重置回初识状态
 */
- (void)reset;

/**
 启用加速计
 */
- (void)enableMotion;

@end
