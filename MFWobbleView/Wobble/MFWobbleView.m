//
//  MFWobbleView.m
//  MFWobbleViewDemo
//
//  Created by Lyman Li on 2019/4/18.
//  Copyright © 2019年 Lyman Li. All rights reserved.
//

#import <GLKit/GLKit.h>

#import "MFShaderHelper.h"

#import "MFWobbleView.h"

typedef struct {
    GLKVector3 positionCoord; // (X, Y, Z)
    GLKVector2 textureCoord; // (U, V)
} SenceVertex;

@interface MFWobbleView ()

@property (nonatomic, assign) SenceVertex *vertices; // 顶点数组
@property (nonatomic, strong) EAGLContext *context;

@property (nonatomic, assign) GLuint frameBuffer; // 帧缓存
@property (nonatomic, assign) GLuint renderBuffer; // 渲染缓存
@property (nonatomic, assign) GLuint vertexBuffer; // 顶点缓存

@property (nonatomic, assign) GLuint program; // 着色器程序

@property (nonatomic, strong) CAEAGLLayer *glLayer;

@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, assign) NSTimeInterval startTimeInterval;

@property (nonatomic, assign) GLuint textureID;

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
    
    // 移除 displayLink
    if (self.displayLink) {
        [self.displayLink invalidate];
        self.displayLink = nil;
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
    
    // 开启动画
    [self startAnimation];
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
- (void)startAnimation {
    if (self.displayLink) {
        [self.displayLink invalidate];
        self.displayLink = nil;
    }
    
    self.startTimeInterval = 0;
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(timeAction)];
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop]
                           forMode:NSRunLoopCommonModes];
}

// 刷新视图
- (void)display {
    glUseProgram(self.program);
    
    GLuint positionSlot = glGetAttribLocation(self.program, "Position");
    GLuint textureSlot = glGetUniformLocation(self.program, "Texture");
    GLuint textureCoordsSlot = glGetAttribLocation(self.program, "TextureCoords");
    
    GLuint PointLT = glGetUniformLocation(self.program, "PointLT");
    GLuint PointRT = glGetUniformLocation(self.program, "PointRT");
    GLuint PointRB = glGetUniformLocation(self.program, "PointRB");
    GLuint PointLB = glGetUniformLocation(self.program, "PointLB");
    
    glUniform2f(PointLT, 0.0, 0.0);
    glUniform2f(PointRT, 1.0, 0.0);
    glUniform2f(PointRB, 1.0, 1.0);
    glUniform2f(PointLB, 0.0, 1.0);
    
    CGFloat currentTime = self.displayLink.timestamp - self.startTimeInterval;
    GLuint time = glGetUniformLocation(self.program, "Time");
    glUniform1f(time, currentTime);
    
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

#pragma mark - Action

- (void)timeAction {
    if (self.startTimeInterval == 0) {
        self.startTimeInterval = self.displayLink.timestamp;
    }
    [self display];
}

@end
