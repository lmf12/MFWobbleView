# MFWobbleView

基于 OpenGL ES 模拟物体的晃动效果，通过贝塞尔曲线来确定物体的形状。

## 效果展示

![](https://github.com/lmf12/ImageHost/blob/master/MFWobbleView/exhibition.gif)

## 接口说明

### 一、控制层

控制层负责用户交互，并保存用户的操作数据，在用户确定之后，将数据传递给效果层。

### MFSketchView

`MFSketchView` 负责控制层的 UI 展示。

**1、属性**

```objc
@property (nonatomic, strong, readonly) NSMutableArray<MFSketchModel *> *sketchModels;
```

用于读取当前所有的控制区域。

**2、方法**

```objc
- (void)addSketch;
- (void)clear;
```

 `- addSketch` 可以新增一个控制区域。
 
 `- clear` 可以清除当前所有的控制区域。

### MFSketchModel

`MFSketchModel` 保存了一个控制区域的所有关键信息。

**1、属性**

```objc
@property (nonatomic, assign) CGPoint pointLT; // 左上
@property (nonatomic, assign) CGPoint pointRT; // 右上
@property (nonatomic, assign) CGPoint pointLB; // 左下
@property (nonatomic, assign) CGPoint pointRB; // 右下
@property (nonatomic, assign) CGPoint center; // 中心点
```

保存了 4 个顶点和一个中心点。

**2、方法**

```objc
- (CGPoint)topLineCenter;
- (CGPoint)leftLineCenter;
- (CGPoint)bottomLineCenter;
- (CGPoint)rightLineCenter;
```

用于快速获得每一条边的中点。

### 二、效果层

当用户操作结束后，控制层将保存的数据传给效果层，为实现效果动画做准备。

### MFWobbleModel

`MFWobbleModel` 保存了等待传递给 Shader 的所有数据。

**1、属性**

```objc
@property (nonatomic, assign) CGPoint pointLT; // 左上
@property (nonatomic, assign) CGPoint pointRT; // 右上
@property (nonatomic, assign) CGPoint pointLB; // 左下
@property (nonatomic, assign) CGPoint pointRB; // 右下
@property (nonatomic, assign) CGPoint center; // 中心
@property (nonatomic, assign) CGPoint direction; // 方向的单位向量
@property (nonatomic, assign) CGFloat amplitude; // 振幅 0 ~ 1
@property (nonatomic, assign) CGFloat lastAnimationBeginTime; // 上次动画的开始时间
```

`pointLT` 、 `pointRT` 、 `pointLB` 、 `pointRB` 、 `center` 都是从 `MFSketchModel` 中相应的数据转化过来的纹理坐标。

`direction` 是一个单位方向向量，表示当前晃动周期的方向。

`amplitude` 表示振幅，每次晃动周期会逐步衰减。

`lastAnimationBeginTime` 表示动画开始的时间，用来计算当前时刻动画的进度。

**2、方法**

```objc
- (BOOL)containsPoint:(CGPoint)point;
```

该方法判断某个点是否位于当前区域内，它只提供一个近似计算。用于判断是否应该响应屏幕触摸事件。

### MFWobbleView

`MFWobbleView` 是最终效果的呈现载体。

**1、属性**

```objc
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, copy) NSArray<MFWobbleModel *> *wobbleModels;
```

`image` 是原始图片，需要手动设置 `MFWobbleView` 的 `frame` 大小与 `image` 的 `size` 比例相同，否则会发生形变。 

`wobbleModels` 是 `MFSketchView` 的 `sketchModels` 转化后的结果。

**2、方法**

```objc
- (void)prepare;
- (void)reset;
- (void)enableMotion;
```

`- prepare` 在 `wobbleModels` 设置之后调用，表示当前数据已经应用，可以响应用户的输入事件并产生动画。

`- reset` 表示对所有的数据进行重置， `MFSketchView` 回到初始化状态。

`- enableMotion` 表示开启加速计，则用户通过晃动手机，也能产生动画。

## 更多介绍

[GLSL 与布丁晃动艺术](http://www.lymanli.com/2019/05/09/ios-opengles-wobble/)
