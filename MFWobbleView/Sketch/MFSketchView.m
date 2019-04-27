//
//  MFSketchView.m
//  MFWobbleViewDemo
//
//  Created by Lyman Li on 2019/4/20.
//  Copyright © 2019年 Lyman Li. All rights reserved.
//

#import "MFSketchView.h"

static NSInteger const kMaxSketchCount = 4;

typedef NS_ENUM(NSUInteger, MFSketchPointType) {
    MFSketchPointTypeLT = 0,
    MFSketchPointTypeRT,
    MFSketchPointTypeRB,
    MFSketchPointTypeLB
};

@interface MFSketchView ()

@property (nonatomic, strong) NSMutableArray<MFSketchModel *> *sketchModels;

// 画线
@property (nonatomic, strong) CAShapeLayer *lineLayer;
@property (nonatomic, strong) UIBezierPath *linePath;

// 画顶点
@property (nonatomic, strong) CAShapeLayer *pointLayer;
@property (nonatomic, strong) UIBezierPath *pointPath;

// 画路径
@property (nonatomic, strong) CAShapeLayer *pathLayer;
@property (nonatomic, strong) UIBezierPath *pathsPath;

// 当前控制的点
@property (nonatomic, weak) MFSketchModel *currentControlModel;
@property (nonatomic, assign) MFSketchPointType currentControlPointType;

@end

@implementation MFSketchView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.lineLayer.frame = self.bounds;
    self.pointLayer.frame = self.bounds;
    self.pathLayer.frame = self.bounds;
}

#pragma mark - Touches

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    
    CGPoint currentPoint = [[touches anyObject] locationInView:self];
    
    CGFloat maxDistance = 20;  // 判定选中的最大距离
    for (MFSketchModel *model in self.sketchModels) {
        NSArray *points = @[@(model.pointLT),
                            @(model.pointRT),
                            @(model.pointRB),
                            @(model.pointLB)];
        for (NSValue *value in points) {
            CGPoint point = [value CGPointValue];
            CGFloat distance = sqrt(pow(point.x - currentPoint.x, 2.0) + pow(point.y - currentPoint.y, 2.0));
            if (distance <= maxDistance) {
                self.currentControlModel = model;
                NSInteger pointIndex = [points indexOfObject:value];
                self.currentControlPointType = (MFSketchPointType)pointIndex;
                break;
            }
        }
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];
    
    if (self.currentControlModel) {
        CGPoint point = [[touches anyObject] locationInView:self];
        if (!CGRectContainsPoint(self.bounds, point)) {
            return;
        }
        switch (self.currentControlPointType) {
            case MFSketchPointTypeLT:
                self.currentControlModel.pointLT = point;
                break;
            case MFSketchPointTypeRT:
                self.currentControlModel.pointRT = point;
                break;
            case MFSketchPointTypeRB:
                self.currentControlModel.pointRB = point;
                break;
            case MFSketchPointTypeLB:
                self.currentControlModel.pointLB = point;
                break;
            default:
                break;
        }
        [self reloadData];
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    
    self.currentControlModel = nil;
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
    
    self.currentControlModel = nil;
}

#pragma mark - Public

- (void)addSketch {
    // 超过最大数量，直接忽略
    if (self.sketchModels.count >= kMaxSketchCount) {
        return;
    }
    
    [self.sketchModels addObject:[self defaultModel]];
    [self reloadData];
}

- (void)clear {
    [self.sketchModels removeAllObjects];
    [self reloadData];
}

#pragma mark - Private

- (void)commonInit {
    [self setupSketchLayer];
    self.sketchModels = [[NSMutableArray alloc] init];
}

- (void)setupSketchLayer {
    self.lineLayer = [[CAShapeLayer alloc] init];
    self.lineLayer.fillColor = [[UIColor clearColor] CGColor];
    self.lineLayer.strokeColor = [[UIColor blackColor] CGColor];
    [self.layer addSublayer:self.lineLayer];
    
    self.pointLayer = [[CAShapeLayer alloc] init];
    self.pointLayer.fillColor = [[UIColor redColor] CGColor];
    self.pointLayer.strokeColor = [[UIColor clearColor] CGColor];
    [self.layer addSublayer:self.pointLayer];
    
    self.pathLayer = [[CAShapeLayer alloc] init];
    self.pathLayer.fillColor = [[UIColor clearColor] CGColor];
    self.pathLayer.strokeColor = [[UIColor blueColor] CGColor];
    [self.layer addSublayer:self.pathLayer];
    
    self.linePath = [[UIBezierPath alloc] init];
    self.linePath.lineWidth = 2;
    
    self.pointPath = [[UIBezierPath alloc] init];
    self.pointPath.lineWidth = 2;
    
    self.pathsPath = [[UIBezierPath alloc] init];
    self.pathsPath.lineWidth = 2;
}

/**
 刷新数据
 */
- (void)reloadData {
    [self.linePath removeAllPoints];
    [self.pointPath removeAllPoints];
    [self.pathsPath removeAllPoints];
    for (MFSketchModel *sketchModel in self.sketchModels) {
        [self drawSketchModel:sketchModel];
    }
    self.lineLayer.path = [self.linePath CGPath];
    self.pointLayer.path = [self.pointPath CGPath];
    self.pathLayer.path = [self.pathsPath CGPath];
}

/**
 绘制单个图形
 */
- (void)drawSketchModel:(MFSketchModel *)sketchModel {
    [self drawLinesWithSketchModel:sketchModel];
    [self drawPointsWithSketchModel:sketchModel];
    [self drawPathsWithSketchModel:sketchModel];
}

/**
 绘制四条边
 */
- (void)drawLinesWithSketchModel:(MFSketchModel *)sketchModel {
    [self.linePath moveToPoint:sketchModel.pointLT];
    [self.linePath addLineToPoint:sketchModel.pointRT];
    [self.linePath addLineToPoint:sketchModel.pointRB];
    [self.linePath addLineToPoint:sketchModel.pointLB];
    [self.linePath addLineToPoint:sketchModel.pointLT];
}

/**
 绘制四个顶点
 */
- (void)drawPointsWithSketchModel:(MFSketchModel *)sketchModel {
    CGFloat radius = 8;
    [self.pointPath moveToPoint:sketchModel.pointLT];
    [self.pointPath addArcWithCenter:sketchModel.pointLT
                              radius:radius
                          startAngle:0
                            endAngle:M_PI * 2
                           clockwise:YES];
    [self.pointPath moveToPoint:sketchModel.pointRT];
    [self.pointPath addArcWithCenter:sketchModel.pointRT
                              radius:radius
                          startAngle:0
                            endAngle:M_PI * 2
                           clockwise:YES];
    [self.pointPath moveToPoint:sketchModel.pointRB];
    [self.pointPath addArcWithCenter:sketchModel.pointRB
                              radius:radius
                          startAngle:0
                            endAngle:M_PI * 2
                           clockwise:YES];
    [self.pointPath moveToPoint:sketchModel.pointLB];
    [self.pointPath addArcWithCenter:sketchModel.pointLB
                              radius:radius
                          startAngle:0
                            endAngle:M_PI * 2
                           clockwise:YES];
}

/**
 绘制四条路径
 */
- (void)drawPathsWithSketchModel:(MFSketchModel *)sketchModel {
    [self.pathsPath moveToPoint:sketchModel.leftLineCenter];
    [self.pathsPath addQuadCurveToPoint:sketchModel.topLineCenter
                           controlPoint:sketchModel.pointLT];
    [self.pathsPath addQuadCurveToPoint:sketchModel.rightLineCenter
                           controlPoint:sketchModel.pointRT];
    [self.pathsPath addQuadCurveToPoint:sketchModel.bottomLineCenter
                           controlPoint:sketchModel.pointRB];
    [self.pathsPath addQuadCurveToPoint:sketchModel.leftLineCenter
                           controlPoint:sketchModel.pointLB];
}

/**
 获取一个默认的 model
 */
- (MFSketchModel *)defaultModel {
    MFSketchModel *model = [[MFSketchModel alloc] init];
    model.pointLT = CGPointMake(10, 10);
    model.pointRT = CGPointMake(100, 10);
    model.pointRB = CGPointMake(100, 100);
    model.pointLB = CGPointMake(10, 100);
    
    return model;
}

@end









