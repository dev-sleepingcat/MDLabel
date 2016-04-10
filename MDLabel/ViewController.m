//
//  ViewController.m
//  MDLabel
//
//  Created by iNuoXia on 16/4/5.
//  Copyright © 2016年 taobao. All rights reserved.
//

#import "ViewController.h"
#import "MDHeaderView.h"
#import "MDLabel.h"

@interface ViewController ()

@property (nonatomic, strong) MDHeaderView *headerView;

@property (nonatomic, strong) MDLabel *label;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view, typically from a nib.
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.headerView = [[MDHeaderView alloc] init];
    [self.view addSubview:self.headerView];
    
    self.label = [[MDLabel alloc] initWithFrame:CGRectMake(0, self.headerView.frame.origin.y + self.headerView.bounds.size.height + 10.f, self.view.bounds.size.width, 100.f)];
    self.label.backgroundColor = [UIColor clearColor];
    self.label.text = @"MDLabel ![image](http://h5.m.taobao.com width=15 height=12) is wonderful label![image](http://m.taobao.com.cn!";
    self.label.textColor = [UIColor lightGrayColor];
    self.label.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.label];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
