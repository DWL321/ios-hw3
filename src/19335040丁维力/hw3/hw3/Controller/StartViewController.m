//
//  StartViewController.m
//  hw3
//
//  Created by student14 on 2021/10/27.
//  Copyright © 2021 SDCS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "StartViewController.h"
#import "QuestionViewController.h"
#import "../../Pods/Masonry/Masonry/Masonry.h"

@interface StartViewController ()<UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout,UINavigationControllerDelegate>

// “识别”按钮
@property (strong,nonatomic) UIButton *button;
@property (strong, nonatomic)UICollectionView *collectionView;
@property (strong, nonatomic)QuestionViewController *questionVC;
@end

@implementation StartViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    [self setupButton];
    self.navigationController.delegate = self;
}

// 设置开始识别的按钮
- (void)setupButton {
    //懒加载
    if(self.button == nil){
        // 创建按钮
        self.button = [[UIButton alloc]init];
        self.button.frame = CGRectMake(0, 0, 0, 0);
        self.button.layer.cornerRadius = 100.0;
        // 设置按钮渐变背景（从左上角到右下角）
        CAGradientLayer *gl = [CAGradientLayer layer];
        gl.frame = CGRectMake(0,0,200,200);
        gl.startPoint = CGPointMake(0, 0);
        gl.endPoint = CGPointMake(1, 1);
        gl.cornerRadius = 100;
        gl.locations = @[@0.0, @1.0];
        gl.colors = [NSArray arrayWithObjects:
                     (id)[UIColor redColor].CGColor,
                     (id)[UIColor blueColor].CGColor,
                     nil];
        [self.button.layer addSublayer:gl];
        // 设置内容
        [self.button setTitle:@"识别" forState:UIControlStateNormal];
        [self.button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.button.titleLabel.font = [UIFont systemFontOfSize:40.0];
        // 添加到视图
        [self.view addSubview:self.button];
        [_button mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.view);
            make.centerY.equalTo(self.view);
            make.size.mas_equalTo(CGSizeMake(200, 200));
        }];
        // 点击后响应事件
        [self.button addTarget:self action:@selector(ButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    }
}

//点击识别按钮时调用的方法
-( void )ButtonClick:(id)sender{
    //TODO
    _questionVC = [[QuestionViewController alloc]init];
    _questionVC.currentQuestion = 0;
    [self.navigationController pushViewController: _questionVC animated:YES];
    self.navigationController.navigationBar.translucent = YES;
    
}

@end
