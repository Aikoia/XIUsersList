//
//  ViewController.m
//  XIUsersList
//
//  Created by xi on 16/3/24.
//  Copyright © 2016年 xi. All rights reserved.
//

#import "ViewController.h"
#import "XIUsersListVC.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.title = @"ME";
    
    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithString:@"Users"];
    text.font = [UIFont boldSystemFontOfSize:30];
    text.color = [UIColor redColor];
    
    YYTextBorder *border = [YYTextBorder new];
    border.strokeColor = [UIColor redColor];
    border.strokeWidth = 1;
    border.cornerRadius = 100;
    border.insets = UIEdgeInsetsMake(1, -10, 0, -10);
    text.textBackgroundBorder = border;
    
    YYTextBorder *linkBorder = [YYTextBorder new];
    linkBorder.strokeWidth = 0;
    linkBorder.fillColor = [UIColor redColor];
    linkBorder.cornerRadius = 100;
    linkBorder.insets = border.insets;
    
    YYTextHighlight *highlight = [YYTextHighlight new];
    [highlight setColor:[UIColor blackColor]];
    [highlight setBackgroundBorder:linkBorder];
    
    [text setTextHighlight:highlight range:text.rangeOfAll];
    
    YYLabel *label = [YYLabel new];
    label.attributedText = text;
    label.width = kScreenWidth;
    label.height = kScreenHeight;
    label.centerX = kScreenWidth/2.0;
    label.centerY = label.height/2.0;
    label.textAlignment = NSTextAlignmentCenter;
    label.textVerticalAlignment = YYTextVerticalAlignmentCenter;
    label.backgroundColor = [UIColor colorWithHexString:@"eeeeee"];
    [self.view addSubview:label];
    label.highlightTapAction = ^(UIView *containerView, NSAttributedString *text, NSRange range, CGRect rect) {
        [self.navigationController pushViewController:[XIUsersListVC new] animated:YES];
    };
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
