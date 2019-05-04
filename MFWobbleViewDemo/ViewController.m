//
//  ViewController.m
//  MFWobbleViewDemo
//
//  Created by Lyman Li on 2019/4/18.
//  Copyright © 2019年 Lyman Li. All rights reserved.
//

#import "MFSketchView.h"
#import "MFWobbleView.h"

#import "ViewController.h"

@interface ViewController ()

@property (nonatomic, strong) MFWobbleView *wobbleView;
@property (nonatomic, strong) MFSketchView *sketchView;

@property (weak, nonatomic) IBOutlet UIButton *addButton;
@property (weak, nonatomic) IBOutlet UIButton *confirmButton;
@property (weak, nonatomic) IBOutlet UIButton *resetButton;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
}

#pragma mark - Private

- (void)setupUI {
    UIImage *image = [UIImage imageNamed:@"sample.jpg"];
    CGFloat width = self.view.frame.size.width;
    CGFloat height = self.view.frame.size.width / image.size.width * image.size.height;
    self.wobbleView = [[MFWobbleView alloc] initWithFrame:CGRectMake(0, 100, width, height)];
    self.wobbleView.image = image;
    [self.wobbleView enableMotion];
    [self.view addSubview:self.wobbleView];
    
    self.sketchView = [[MFSketchView alloc] initWithFrame:self.wobbleView.frame];
    [self.view addSubview:self.sketchView];
    
    self.addButton.layer.cornerRadius = 10;
    self.addButton.backgroundColor = [UIColor blackColor];
    [self.addButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.addButton setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
    
    self.confirmButton.layer.cornerRadius = 10;
    self.confirmButton.backgroundColor = [UIColor blackColor];
    [self.confirmButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.confirmButton setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
    self.confirmButton.enabled = NO;
    
    self.resetButton.layer.cornerRadius = 10;
    self.resetButton.backgroundColor = [UIColor blackColor];
    [self.resetButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.resetButton setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
}

- (void)updateButtonState {
    self.addButton.enabled = !self.sketchView.hidden;
    self.confirmButton.enabled = [self.sketchView.sketchModels count] > 0;
}

#pragma mark - Action

- (IBAction)addAction:(id)sender {
    [self.sketchView addSketch];
    [self updateButtonState];
}

- (IBAction)confirmAction:(id)sender {
    CGFloat width = self.sketchView.frame.size.width;
    CGFloat height = self.sketchView.frame.size.height;

    NSMutableArray *mutArr = [[NSMutableArray alloc] init];
    for (MFSketchModel *model in self.sketchView.sketchModels) {
        MFWobbleModel *wobbleModel = [[MFWobbleModel alloc] init];
        wobbleModel.pointLT = CGPointMake(model.pointLT.x / width, 1 - (model.pointLT.y / height));
        wobbleModel.pointRT = CGPointMake(model.pointRT.x / width, 1 - (model.pointRT.y / height));
        wobbleModel.pointRB = CGPointMake(model.pointRB.x / width, 1 - (model.pointRB.y / height));
        wobbleModel.pointLB = CGPointMake(model.pointLB.x / width, 1 - (model.pointLB.y / height));
        wobbleModel.center = CGPointMake(model.center.x / width, 1 - (model.center.y / height));
        
        [mutArr addObject:wobbleModel];
    }
    self.wobbleView.wobbleModels = [mutArr copy];
    [self.wobbleView prepare];
    
    [self.sketchView clear];
    self.sketchView.hidden = YES;
    [self updateButtonState];
}

- (IBAction)resetAction:(id)sender {
    [self.sketchView clear];
    self.sketchView.hidden = NO;
    [self updateButtonState];
    [self.wobbleView reset];
}

@end










