//
//  MFWobbleView.m
//  MFWobbleViewDemo
//
//  Created by Lyman Li on 2019/4/18.
//  Copyright © 2019年 Lyman Li. All rights reserved.
//

#import <GLKit/GLKit.h>
#import <CoreMotion/CoreMotion.h>

#import "MFShaderHelper.h"

#import "MFWobbleView.h"

static NSInteger const kMaxWobbleCount = 4;
static CGFloat const kSingleAnimationDuration = 1.2f;  // 单次动画的持续时长

typedef struct {
    GLKVector3 positionCoord; // (X, Y, Z)
    GLKVector2 textureCoord; // (U, V)
} SenceVertex;

@interface MFWobbleView ()

@property (nonatomic, strong) CMMotionManager *motionManager;

@property (nonatomic, assign) SenceVertex *vertices; // 顶点数组
@property (nonatomic, strong) EAGLContext *context;

@property (nonatomic, assign) GLuint frameBuffer; // 帧缓存
@property (nonatomic, assign) GLuint renderBuffer; // 渲染缓存
@property (nonatomic, assign) GLuint vertexBuffer; // 顶点缓存

@property (nonatomic, assign) GLuint program; // 着色器程序

@property (nonatomic, strong) CAEAGLLayer *glLayer;

@property (nonatomic, strong) CADisplayLink *displayLink;

@property (nonatomic, assign) GLuint textureID;

@property (nonatomic, weak) MFWobbleModel *currentTouchModel; // 当前触摸选中的模型
@property (nonatomic, assign) CGPoint startPoint; // 起始触摸点

@end

@implementation MFWobbleView

- (void)dealloc {
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }

    if (_vertices) {
        free(_vertices);
        _vertices = nil;
    }
    if (_program) {
        glUseProgram(0);
        glDeleteProgram(_program);
    }
    if (_textureID > 0) {
        glDeleteTextures(1, &_textureID);
    }
    [self deleteBuffers];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)removeFromSuperview {
    [super removeFromSuperview];
    
    [self stopAnimation];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    
    CGPoint currentPoint = [[touches anyObject] locationInView:self];
    currentPoint = CGPointMake(currentPoint.x / self.bounds.size.width, 1 - (currentPoint.y / self.bounds.size.height)); // 归一化
    for (MFWobbleModel *model in self.wobbleModels) {
        if ([model containsPoint:currentPoint]) {
            self.currentTouchModel = model;
            self.startPoint = currentPoint;
            break;
        }
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];
    
    if (self.currentTouchModel) {
        CGPoint currentPoint = [[touches anyObject] locationInView:self];
        currentPoint = CGPointMake(currentPoint.x / self.bounds.size.width, 1 - (currentPoint.y / self.bounds.size.height)); // 归一化
        CGFloat distance = sqrt(pow(self.startPoint.x - currentPoint.x, 2.0) + pow(self.startPoint.y - currentPoint.y, 2.0));
        CGPoint direction = CGPointMake((currentPoint.x - self.startPoint.x) / distance, ((currentPoint.y - self.startPoint.y) / distance));
        [self startAnimationWithModel:self.currentTouchModel direction:direction amplitude:1.0];
        
        self.currentTouchModel = nil;
    }
}

#pragma mark - Custom Accessor

- (void)setImage:(UIImage *)image {
    _image = image;

    if (_textureID > 0) {
        glDeleteTextures(1, &_textureID);
    }
    self.textureID = [MFShaderHelper createTextureWithImage:image];
    [self display];
}

#pragma mark - Public

- (void)prepare {
    [self prepareAnimation];
}

- (void)reset {
    [self stopAnimation];
    self.wobbleModels = nil;
    [self display];
}

- (void)enableMotion {
    self.motionManager = [[CMMotionManager alloc] init];
    if (![self.motionManager isAccelerometerAvailable]) {
        return;
    }
    self.motionManager.accelerometerUpdateInterval = 0.1;  // 0.1 秒检测一次
    __weak typeof(self) weakSelf = self;
    [self.motionManager startAccelerometerUpdatesToQueue:[[NSOperationQueue alloc] init] withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
        CMAcceleration acceleration = accelerometerData.acceleration;
        CGFloat sensitivity = sqrt(pow(acceleration.x, 2.0) + pow(acceleration.y, 2.0));
        if (sensitivity > 1.0) {
            CGPoint direction = CGPointMake(acceleration.x / sensitivity, acceleration.y / sensitivity);
            for (MFWobbleModel *model in weakSelf.wobbleModels) {
                // 当前的振幅小于某个阈值才会受影响
                if (model.amplitude < 0.3) {
                    [weakSelf startAnimationWithModel:model direction:direction amplitude:1.0];
                }
            }
        }
    }];
}

#pragma mark - Private

- (void)commonInit {
    [self setupGLLayer];
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [EAGLContext setCurrentContext:self.context];
    
    // 创建顶点数组
    self.vertices = malloc(sizeof(SenceVertex) * 4); // 4 个顶点
    
    self.vertices[0] = (SenceVertex){{-1, 1, 0}, {0, 1}}; // 左上角
    self.vertices[1] = (SenceVertex){{-1, -1, 0}, {0, 0}}; // 左下角
    self.vertices[2] = (SenceVertex){{1, 1, 0}, {1, 1}}; // 右上角
    self.vertices[3] = (SenceVertex){{1, -1, 0}, {1, 0}}; // 右下角
    
    // 创建着色器程序
    [self genProgram];
    
    // 创建缓存
    [self genBuffers];
    
    // 绑定纹理输出的层
    [self bindRenderLayer:self.glLayer];
    
    // 指定窗口大小
    glViewport(0, 0, self.drawableWidth, self.drawableHeight);
}

// 创建输出层
- (void)setupGLLayer {
    CAEAGLLayer *layer = [[CAEAGLLayer alloc] init];
    layer.frame = self.bounds;
    layer.contentsScale = [[UIScreen mainScreen] scale];
    self.glLayer = layer;
    
    [self.layer addSublayer:self.glLayer];
}

// 创建 program
- (void)genProgram {
    self.program = [MFShaderHelper programWithShaderName:@"wobble"];
}

// 创建 buffer
- (void)genBuffers {
    glGenFramebuffers(1, &_frameBuffer);
    glGenRenderbuffers(1, &_renderBuffer);
    glGenBuffers(1, &_vertexBuffer);
}

// 清除 buffer
- (void)deleteBuffers {
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    glBindRenderbuffer(GL_RENDERBUFFER, 0);
    if (_frameBuffer != 0) {
        glDeleteFramebuffers(1, &_frameBuffer);
    }
    if (_renderBuffer != 0) {
        glDeleteRenderbuffers(1, &_renderBuffer);
    }
    if (_vertexBuffer != 0) {
        glDeleteBuffers(1, &_vertexBuffer);
    }
}

// 绑定图像要输出的 layer
- (void)bindRenderLayer:(CALayer <EAGLDrawable> *)layer {
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
    [self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:layer];
    
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER,
                              GL_COLOR_ATTACHMENT0,
                              GL_RENDERBUFFER,
                              _renderBuffer);
}

// 获取渲染缓存宽度
- (GLint)drawableWidth {
    GLint backingWidth;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
    
    return backingWidth;
}

// 获取渲染缓存高度
- (GLint)drawableHeight {
    GLint backingHeight;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
    
    return backingHeight;
}

// 开启动画
- (void)prepareAnimation {
    if (self.displayLink) {
        [self.displayLink invalidate];
        self.displayLink = nil;
    }
    
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(timeAction)];
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop]
                           forMode:NSRunLoopCommonModes];
}

// 结束动画
- (void)stopAnimation {
    if (self.displayLink) {
        [self.displayLink invalidate];
        self.displayLink = nil;
    }
}

// 刷新视图
- (void)display {
    glUseProgram(self.program);
    
    GLuint positionSlot = glGetAttribLocation(self.program, "Position");
    GLuint textureSlot = glGetUniformLocation(self.program, "Texture");
    GLuint textureCoordsSlot = glGetAttribLocation(self.program, "TextureCoords");
    
    int wobbleCount = (int)MIN(self.wobbleModels.count, kMaxWobbleCount);
    
    GLuint count = glGetUniformLocation(self.program, "SketchCount");
    glUniform1i(count, wobbleCount);
    
    for (NSInteger index = 0; index < wobbleCount; ++index) {
        MFWobbleModel *model = self.wobbleModels[index];
        char nameLT[30];
        char nameRT[30];
        char nameRB[30];
        char nameLB[30];
        char direction[30];
        char amplitude[30];
        char time[30];
        sprintf(nameLT, "sketchs[%d].PointLT", (int)index);
        sprintf(nameRT, "sketchs[%d].PointRT", (int)index);
        sprintf(nameRB, "sketchs[%d].PointRB", (int)index);
        sprintf(nameLB, "sketchs[%d].PointLB", (int)index);
        sprintf(direction, "sketchs[%d].Direction", (int)index);
        sprintf(amplitude, "sketchs[%d].Amplitude", (int)index);
        sprintf(time, "sketchs[%d].Time", (int)index);
        GLuint PointLT = glGetUniformLocation(self.program, nameLT);
        GLuint PointRT = glGetUniformLocation(self.program, nameRT);
        GLuint PointRB = glGetUniformLocation(self.program, nameRB);
        GLuint PointLB = glGetUniformLocation(self.program, nameLB);
        GLuint Direction = glGetUniformLocation(self.program, direction);
        GLuint Amplitude = glGetUniformLocation(self.program, amplitude);
        GLuint Time = glGetUniformLocation(self.program, time);
        
        glUniform2f(PointLT, model.pointLT.x, model.pointLT.y);
        glUniform2f(PointRT, model.pointRT.x, model.pointRT.y);
        glUniform2f(PointRB, model.pointRB.x, model.pointRB.y);
        glUniform2f(PointLB, model.pointLB.x, model.pointLB.y);
        glUniform2f(Direction, model.direction.x, model.direction.y);
        glUniform1f(Amplitude, model.amplitude);
        glUniform1f(Time, self.displayLink.timestamp - model.lastAnimationBeginTime);
    }
    
    GLuint duration = glGetUniformLocation(self.program, "Duration");
    glUniform1f(duration, kSingleAnimationDuration);
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, self.textureID);
    glUniform1i(textureSlot, 0);
    
    glBindBuffer(GL_ARRAY_BUFFER, self.vertexBuffer);
    GLsizeiptr bufferSizeBytes = sizeof(SenceVertex) * 4;
    glBufferData(GL_ARRAY_BUFFER, bufferSizeBytes, self.vertices, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(positionSlot);
    glVertexAttribPointer(positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(SenceVertex), NULL + offsetof(SenceVertex, positionCoord));
    
    glEnableVertexAttribArray(textureCoordsSlot);
    glVertexAttribPointer(textureCoordsSlot, 2, GL_FLOAT, GL_FALSE, sizeof(SenceVertex), NULL + offsetof(SenceVertex, textureCoord));
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)startAnimationWithModel:(MFWobbleModel *)model
                      direction:(CGPoint)direction
                      amplitude:(CGFloat)amplitude {
    model.direction = direction;
    model.amplitude = amplitude;
    model.lastAnimationBeginTime = 0;
}

#pragma mark - Action

- (void)timeAction {
    for (MFWobbleModel *model in self.wobbleModels) {
        if (model.lastAnimationBeginTime == 0) {
            model.lastAnimationBeginTime = self.displayLink.timestamp;
        } else if (self.displayLink.timestamp - model.lastAnimationBeginTime >= kSingleAnimationDuration) {
            // 每间隔一段周期，振幅衰减
            model.amplitude *= 0.7;
            model.amplitude = model.amplitude < 0.1 ? 0 : model.amplitude;
            model.lastAnimationBeginTime = self.displayLink.timestamp;
        }
    }
    [self display];
}

@end
