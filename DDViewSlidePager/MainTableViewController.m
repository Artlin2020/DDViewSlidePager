//
//  MainTableViewController.m
//  DDViewSlidePager
//
//  Created by Ddread Li on 4/1/15.
//  Copyright (c) 2015 ddread. All rights reserved.
//

#import "MainTableViewController.h"
#import "ViewController.h"

@interface MainTableViewController ()

@end

@implementation MainTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.title = @"DDViewSlidePager";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        ViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"ViewController"];
        vc.slideType = DDSlideBaseViewTypeViewController;
        [self.navigationController pushViewController:vc animated:YES];
    }
    
    if (indexPath.row == 1) {
        ViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"ViewController"];
        vc.slideType = DDSlideBaseViewTypeView;
        [self.navigationController pushViewController:vc animated:YES];
    }
    
    
}


@end
