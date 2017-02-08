//
//  ViewController.m
//  YQDownloadButton
//
//  Created by yingqiu huang on 2017/2/7.
//  Copyright © 2017年 yingqiu huang. All rights reserved.
//

#import "ViewController.h"
#import "YQDownloadButton.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    YQDownloadButton *button = [[YQDownloadButton alloc] initWithFrame:CGRectMake(0, 0, 160, 160)];
    button.center = self.view.center;
    [self.view addSubview:button];
}



@end
