//
//  QuestionViewController.m
//  hw3
//
//  Created by student14 on 2021/10/27.
//  Copyright © 2021 SDCS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QuestionViewController.h"
#import "../../Pods/Masonry/Masonry/Masonry.h"

// 网络访问（get）的同步信号量
dispatch_semaphore_t sem_get_;
// 网络访问（post）的同步信号量
dispatch_semaphore_t sem_post_;

@interface QuestionViewController ()<UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout,UINavigationControllerDelegate>

@property (strong, nonatomic)UICollectionView *collectionView;
@property (strong, nonatomic)UIButton *ConfirmBtn;
@property (strong, nonatomic)UIButton *GoOnBtn;
@property (strong, nonatomic)UIImageView *imageview;
@property (strong, nonatomic)__block NSMutableArray *image_url;
@property (strong, nonatomic)__block NSMutableArray *choices;
@property (strong, nonatomic)__block NSString *correct;
@property (strong, nonatomic)NSString* answer;
@property (strong, nonatomic)UIView *display;
@property (nonatomic, strong) UILabel *displayAnswer;
@property BOOL isConfirm;
@property NSMutableArray *id_;
@property(strong, nonatomic) NSIndexPath* select;
@property(strong, nonatomic) FinishingViewController *FVC;
@end

@implementation QuestionViewController

- (void)viewDidLoad {
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    _isConfirm = NO;
    
    _FVC = [[FinishingViewController alloc]init];
    _FVC.totalRight = [[NSMutableArray alloc]initWithCapacity:3];
    
    self->_image_url = [[NSMutableArray alloc] initWithCapacity:0];
    self->_choices = [[NSMutableArray alloc] initWithCapacity:0];
    self->_id_ = [[NSMutableArray alloc] initWithCapacity:0];
    [self GetAllData];
    [self initImage];
    [self CreateCol];
    
    self.collectionView.delegate=self;
    self.collectionView.dataSource=self;
    [self.view addSubview:self.collectionView];
    [_collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.view);
        make.centerY.mas_equalTo(self.view).mas_offset(70);
        make.size.mas_equalTo(CGSizeMake(350, 350));
    }];
    
    //初始化显示答案的view
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    _display = [[UIView alloc]initWithFrame:CGRectMake(0, screenBounds.size.height, screenBounds.size.width, screenBounds.size.height * 0.3)];
    _displayAnswer = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 30)];
    [_displayAnswer setTextColor:[UIColor whiteColor]];
    _displayAnswer.font = [UIFont fontWithName:@"Helvetica-Bold" size:20];
    [_display addSubview:_displayAnswer];
    [_displayAnswer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self->_display.mas_top).with.offset(10);
        make.left.mas_equalTo(self->_display.mas_left).with.offset(10);
    }];
    [self.view addSubview: _display];
    
    //初始化按钮
    [self CreateBtn];
    
    self.navigationController.delegate = self;
}


//从服务器GET数据
-(void) GetAllData{
    // 信号量确保切换页面前，能从网上获取到数据
    sem_get_ = dispatch_semaphore_create(0);
    // 创建一个网络路径
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://172.18.178.56:8360/hw3/get_question"]];
    // 创建一个网络请求
    NSURLRequest *request =[NSURLRequest requestWithURL:url];
    // 获得会话对象
    NSURLSession *session = [NSURLSession sharedSession];
    // 4.根据会话对象，创建一个Task任务：
    NSURLSessionDataTask *sessionDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if(error == nil)
        {
            NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            NSDictionary *dataDic = [dic objectForKey:@"data"];
            NSMutableArray *infoList = [dataDic objectForKey:@"info"];
            // 将info中的内容保存到dataInfo中
            [self->_image_url removeAllObjects];
            [self->_choices removeAllObjects];
            [self->_id_ removeAllObjects];
            for (NSMutableDictionary *member in infoList) {
                [self->_image_url addObject:[[member objectForKey:@"image"]description]];
                [self->_choices addObject:[[member objectForKey:@"choice1"]description]];
                [self->_choices addObject:[[member objectForKey:@"choice2"]description]];
                [self->_choices addObject:[[member objectForKey:@"choice3"]description]];
                [self->_id_ addObject:[[member objectForKey:@"id"]description]];
            }
        }
        // 异步获取题目的任务完成，发出信号量
        dispatch_semaphore_signal(sem_get_);
    }];
    // 执行任务（resume也是继续执行）:
    [sessionDataTask resume];
    // 等待同步信号量的到来
    dispatch_semaphore_wait(sem_get_, DISPATCH_TIME_FOREVER);
}

//将答案POST到服务器
-(BOOL)PostData:(NSString *)answer{
    __block BOOL res = NO;
    // 信号量确保页面刷新前，能从网上获取到数据
    sem_post_ = dispatch_semaphore_create(0);
    // 创建一个网络路径
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://172.18.178.56:8360/hw3/query"]];
    // 创建一个网络请求，分别设置请求方法、请求参数
    NSMutableURLRequest *request =[NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    NSDictionary *dic = @{@"number": [NSString stringWithFormat: @"%d", [_id_[_currentQuestion] intValue]],
                          @"choice": answer};
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&error];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    request.HTTPBody = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    // 获得会话对象
    NSURLSession *session = [NSURLSession sharedSession];
    // 根据会话对象，创建一个Task任务
    NSURLSessionDataTask *sessionDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if(error == nil)
        {
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            NSDictionary *datadict = [dict objectForKey:@"data"];
            NSString *res_str = [[datadict objectForKey:@"res"]description];
            if ([res_str isEqualToString:@"true"]) {
                res = YES;
            }
            else {
                res = NO;
            }
            
        }
        dispatch_semaphore_signal(sem_post_);
    }];
    // 执行任务，(resume也是继续执行)。
    [sessionDataTask resume];
    dispatch_semaphore_wait(sem_post_, DISPATCH_TIME_FOREVER);
    return res;
}

// 更新正确答案label
- (void)updateCorrectAnswer {
    NSString *choice=self->_choices[_currentQuestion*3];
    // 遍历向服务器发送所有选项，得到正确的结果
    if ([self PostData:choice]) {
        _correct = choice;
    }
    else {
        choice=self->_choices[_currentQuestion*3+1];
        if ([self PostData:choice]) {
            _correct = choice;
        }
        else {
            _correct=self->_choices[_currentQuestion*3+2];
        }
    }
}

//初始化图片视图组件
- (void)initImage {
    _imageview = [[UIImageView alloc]init];
    NSString *string=self->_image_url[_currentQuestion];
    NSURL *url = [NSURL URLWithString:string];
    NSData *data=[NSData dataWithContentsOfURL:url];
    _imageview.image = [UIImage imageWithData:data];
    [self.view addSubview:_imageview];
    [_imageview mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(200);
        make.height.mas_equalTo(200);
        make.centerY.equalTo(self.view).offset(-200);
        make.centerX.equalTo(self.view);
    }];
}

-(void)CreateCol{
    //创建一个layout布局类
    UICollectionViewFlowLayout * layout = [[UICollectionViewFlowLayout alloc]init];
    //设置布局方向为垂直流布局
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    //设置每个item的大小
    layout.itemSize = CGSizeMake(285, 55);
    //创建collectionView 通过一个布局策略layout来创建
    self.collectionView = [[UICollectionView alloc]initWithFrame:self.view.frame collectionViewLayout:layout];
    //注册collectionViewCell
    //注意，此处的ReuseIdentifier 必须和 cellForItemAtIndexPath 方法中 一致 均为 cellId
    [self.collectionView registerClass:[ChoiceCell class] forCellWithReuseIdentifier:@"cellId"];
    self.collectionView.backgroundColor = [UIColor clearColor];
}

//创建“确定”和“继续”按钮
-(void)CreateBtn{
    _ConfirmBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 285, 45)];
    //0:不响应事件 1:响应事件
    _ConfirmBtn.tag = 0;
    [_ConfirmBtn setTitle:@"确认" forState:UIControlStateNormal];
    _ConfirmBtn.contentHorizontalAlignment=UIControlContentHorizontalAlignmentCenter;
    [_ConfirmBtn.layer setMasksToBounds:YES];
    [_ConfirmBtn.layer setCornerRadius:15];
    [_ConfirmBtn setBackgroundColor:[UIColor grayColor]];
    [_ConfirmBtn addTarget:self action:@selector(Confirm) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_ConfirmBtn];
    [_ConfirmBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(285, 45));
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.view.mas_bottom).with.offset(-40);
    }];
    
    _GoOnBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 285, 45)];
    [_GoOnBtn setTitle:@"继续" forState:UIControlStateNormal];
    _GoOnBtn.contentHorizontalAlignment=UIControlContentHorizontalAlignmentCenter;
    [_GoOnBtn.layer setMasksToBounds:YES];
    [_GoOnBtn.layer setCornerRadius:15];
    [_GoOnBtn setBackgroundColor:[UIColor colorWithRed:103.0/255.0 green:200.0/255.0 blue:90.0/255.0 alpha:1.0]];
    [_GoOnBtn addTarget:self action:@selector(GoOn) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_GoOnBtn];
    [_GoOnBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(285, 45));
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.view.mas_bottom).with.offset(-40);
    }];
    [_GoOnBtn setHidden:YES];
}

//点击“确定”按钮的事件
-(void)Confirm{
    if(_ConfirmBtn.tag == 1){
        _isConfirm = YES;
        [_ConfirmBtn setHidden:YES];
        [_GoOnBtn setHidden:NO];
        [self updateCorrectAnswer];
        _displayAnswer.text = [NSString stringWithFormat:@"正确答案: %@", _correct];
        if([self PostData:_answer]){
            [_display setBackgroundColor:[UIColor colorWithRed:144.0/255.0 green:238.0/255.0 blue:144.0/255.0 alpha:1.0]];
            _FVC.totalRight[_currentQuestion]=@"right";
        }
        else{
            [_GoOnBtn setBackgroundColor:[UIColor colorWithRed:233.0/255.0 green:63.0/255.0 blue:51.0/255.0 alpha:1.0]];
            [_display setBackgroundColor:[UIColor colorWithRed:237.0/255.0 green:127.0/255.0 blue:128.0/255.0 alpha:1.0]];
            _FVC.totalRight[_currentQuestion]=@"wrong";
            
        }
        [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^ {
            CGRect screenBounds = [[UIScreen mainScreen] bounds];
            self->_display.transform = CGAffineTransformTranslate(self->_display.transform, 0, -screenBounds.size.height * 0.3);
        } completion:^(BOOL finished) {
            
        }];
    }
}

//点击“继续”按钮的事件
-(void)GoOn{
    if(_currentQuestion < 3){
        _isConfirm = NO;
        _ConfirmBtn.tag = 0;
        [_ConfirmBtn setBackgroundColor:[UIColor grayColor]];
        [_ConfirmBtn setHidden:NO];
        [_GoOnBtn setHidden:YES];
        [_GoOnBtn setBackgroundColor:[UIColor colorWithRed:103.0/255.0 green:200.0/255.0 blue:90.0/255.0 alpha:1.0]];
        //刷新数据
        _currentQuestion ++;
        NSString *string=self->_image_url[_currentQuestion];
        NSURL *url = [NSURL URLWithString:string];
        NSData *data=[NSData dataWithContentsOfURL:url];
        _imageview.image = [UIImage imageWithData:data];
        [_collectionView reloadData];
    }
    else{
        //TODO: finish
        [self.navigationController pushViewController: _FVC animated:YES];
    }
    [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^ {
        CGRect screenBounds = [[UIScreen mainScreen] bounds];
        self->_display.transform = CGAffineTransformTranslate(self->_display.transform, 0, screenBounds.size.height * 0.3);
    } completion:^(BOOL finished) {
        
    }];
}

//返回分区个数
-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 3;
}
//返回每个分区的item个数
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return 1;
}
//返回每个item
- (ChoiceCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ChoiceCell *cell = (ChoiceCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"cellId" forIndexPath:indexPath];
    //将得到的choicef赋值给对应的cell
    [cell.choice setText: [NSString stringWithFormat:@"%@",_choices[_currentQuestion*3+indexPath.section]]];
    [cell.choice setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    cell.layer.borderWidth = 0;
    cell.choice.textColor = [UIColor blackColor];
    return cell;
}


//每个cell的距离
-(UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(15, 0, 15, 0);//分别为上、左、下、右
}

//UICollectionView被选中时调用的方法
-( void )collectionView:( UICollectionView *)collectionView didSelectItemAtIndexPath:( NSIndexPath *)indexPath{
    //TODO
    self.navigationController.navigationBar.translucent = NO;
    ChoiceCell *cell = (ChoiceCell *)[collectionView cellForItemAtIndexPath:indexPath];
    _select = indexPath;
    cell.layer.borderWidth = 0.5;
    cell.layer.borderColor = [UIColor colorWithRed:103.0/255.0 green:200.0/255.0 blue:90.0/255.0 alpha:1.0].CGColor;
    cell.choice.textColor = [UIColor colorWithRed:103.0/255.0 green:200.0/255.0 blue:90.0/255.0 alpha:1.0];
    [_ConfirmBtn setBackgroundColor:[UIColor colorWithRed:103.0/255.0 green:200.0/255.0 blue:90.0/255.0 alpha:1.0]];
    _ConfirmBtn.tag = 1;
    _answer = cell.choice.text;
}

//UICollectionView取消选中时调用的方法
-(void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath{
    ChoiceCell *cell = (ChoiceCell *)[collectionView cellForItemAtIndexPath:indexPath];
    cell.layer.borderWidth = 0;
    cell.choice.textColor = [UIColor blackColor];
}


//返回这个UICollectionViewCell是否可以被选择
-( BOOL )collectionView:( UICollectionView *)collectionView shouldSelectItemAtIndexPath:( NSIndexPath *)indexPath{
    if(_isConfirm == NO){
        return YES ;
    }
    else{
        return NO;
    }
}

@end
