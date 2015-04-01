//
//  ViewController.m
//  DDViewSlidePager
//
//  Created by Ddread Li on 3/19/15.
//  Copyright (c) 2015 ddread. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIView *contentBGView;
@property (nonatomic, strong) DDViewSlidePager *viewSlidePager;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.slideType == DDSlideBaseViewTypeView) {
        [self showWithViews];
    } else {
        [self showWithViewControllers];
    }
}

- (IBAction)btn:(id)sender {
    [self.viewSlidePager cleanUp];
}


- (void)showWithViews {
    NSInteger count = 8;
    NSMutableArray *titleArray = [NSMutableArray new];
    NSMutableArray *contentArray = [NSMutableArray new];
    for (NSInteger i = 0; i < count; i++) {
        [titleArray addObject:[NSString stringWithFormat:@"title#%@", @(i)]];
        UIView *view = [[UIView alloc] initWithFrame:self.contentBGView.bounds];
        view.backgroundColor = [UIColor colorWithRed:rand() % 9 * 0.1 green:rand() % 9 * 0.1 blue:rand() % 9 * 0.1 alpha:1];
        [contentArray addObject:view];
    }
    
    _viewSlidePager = [DDViewSlidePager viewSlidePagerWithType:DDSlideBaseViewTypeView baseContent:self.contentBGView titles:titleArray contents:contentArray titleColor:nil indicatorColor:nil];
    _viewSlidePager.didSlideToIndexHandler = ^(NSInteger index){
        NSLog(@"%@", @(index));
    };
    _viewSlidePager.shouldIndicatorFollowing = NO;
    [_viewSlidePager show];
}

- (void)showWithViewControllers {
    
    NSInteger count = 8;
    NSMutableArray *titleArray = [NSMutableArray new];
    NSMutableArray *contentArray = [NSMutableArray new];
    for (NSInteger i = 0; i < count; i++) {
        [titleArray addObject:[NSString stringWithFormat:@"title#%@", @(i)]];
        UIViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"ContentViewController"];
        [contentArray addObject:vc];
    }
    
    _viewSlidePager = [DDViewSlidePager viewSlidePagerWithType:DDSlideBaseViewTypeViewController baseContent:self titles:titleArray contents:contentArray titleColor:nil indicatorColor:nil];
    _viewSlidePager.didSlideToIndexHandler = ^(NSInteger index){
        NSLog(@"%@", @(index));
    };
    _viewSlidePager.hasNavigationBar = YES;
    [_viewSlidePager show];
}

- (void)cleanUp
{
    [self.viewSlidePager cleanUp];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
