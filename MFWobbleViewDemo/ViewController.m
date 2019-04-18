//
//  ViewController.m
//  MFWobbleViewDemo
//
//  Created by Lyman Li on 2019/4/18.
//  Copyright © 2019年 Lyman Li. All rights reserved.
//

#import "MFWobbleView.h"

#import "ViewController.h"

@interface ViewController ()

@property (nonatomic, strong) MFWobbleView *wobbleView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
}

- (void)setupUI {
    UIImage *image = [UIImage imageNamed:@"sample.jpg"];
    CGFloat width = self.view.frame.size.width;
    CGFloat height = self.view.frame.size.width / image.size.width * image.size.height;
    self.wobbleView = [[MFWobbleView alloc] initWithFrame:CGRectMake(0, 100, width, height)];
    self.wobbleView.image = image;
    [self.view addSubview:self.wobbleView];
}

@end
