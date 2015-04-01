//
//  DDViewSlidePager.h
//  yeemiao
//
//  Created by Ddread Li on 19/3/15.
//  Copyright (c) 2015 ddread. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, DDSlideBaseViewType) {
    DDSlideBaseViewTypeView,  // slide with views, less than full screen
    DDSlideBaseViewTypeViewController // slide with viewControllers , at full screen
};

@interface DDViewSlidePager : NSObject

// nomal title label color
@property (nonatomic, strong) UIColor *titleColor;

// select title label color
@property (nonatomic, strong) UIColor *titleSelectColor;

// title label font
@property (nonatomic, strong) UIFont *titleFont;

// title background view's color
@property (nonatomic, strong) UIColor *titleBGViewColor;

// title label vertical offset, default is centre
@property (nonatomic, assign) CGFloat titleViewVOffset;

// title background view's height, default is 44.0f
@property (nonatomic, assign) CGFloat titleBGViewHeight;

// the rectangle indicator's height, default is 3.0f
@property (nonatomic, assign) CGFloat indicatorViewHeight;

// when YES, the title background view will start below navigationbar, default is NO
@property (nonatomic, assign) BOOL hasNavigationBar;

// has Tabbar ? default is NO
@property (nonatomic, assign) BOOL hasTabBar;

// the indicator following the content scrollView scrolling
@property (nonatomic, assign) BOOL shouldIndicatorFollowing;

// trigger when indicator slide to next index
@property (nonatomic, copy) void (^didSlideToIndexHandler)(NSInteger index);

// init with two type, baseContent can be view and viewControllers
+ (instancetype)viewSlidePagerWithType:(DDSlideBaseViewType)slideBaseViewType
                           baseContent:(id)baseContent
                                titles:(NSArray *)titles
                              contents:(NSArray *)contents
                            titleColor:(UIColor *)titleColor
                        indicatorColor:(UIColor *)indicatorColor;

// when init, then show
- (void)show;

// remove all from superview
- (void)cleanUp;

// you can set some property then reloadData
- (void)reloadData;

// total reload type, but all property will same as last time
- (void)reloadViewWithType:(DDSlideBaseViewType)slideBaseViewType
               baseContent:(id)baseContent
                    titles:(NSArray *)titles
                  contents:(NSArray *)contents;

@end
