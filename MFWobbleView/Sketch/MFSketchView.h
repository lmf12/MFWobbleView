//
//  MFSketchView.h
//  MFWobbleViewDemo
//
//  Created by Lyman Li on 2019/4/20.
//  Copyright © 2019年 Lyman Li. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MFSketchModel.h"

@interface MFSketchView : UIView

@property (nonatomic, strong, readonly) NSMutableArray<MFSketchModel *> *sketchModels;

/**
 添加一个图形
 */
- (void)addSketch;

/**
 清除数据和视图
 */
- (void)clear;

@end
