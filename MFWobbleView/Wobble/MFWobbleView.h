//
//  MFWobbleView.h
//  MFWobbleViewDemo
//
//  Created by Lyman Li on 2019/4/18.
//  Copyright © 2019年 Lyman Li. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MFWobbleView : UIView

@property (nonatomic, strong) UIImage *image;

@property (nonatomic, assign) CGPoint pointLT;
@property (nonatomic, assign) CGPoint pointRT;
@property (nonatomic, assign) CGPoint pointRB;
@property (nonatomic, assign) CGPoint pointLB;

/**
 配置完成
 */
- (void)prepare;

/**
 重置回初识状态
 */
- (void)reset;

@end
