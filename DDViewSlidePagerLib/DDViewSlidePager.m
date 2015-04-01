//
//  DDViewSlidePager.m
//  yeemiao
//
//  Created by Ddread Li on 19/3/15.
//  Copyright (c) 2015 ddread. All rights reserved.
//

#import "DDViewSlidePager.h"

#define kVSDefaultTitleColor                            ([UIColor redColor])
#define kVSTitleViewInterval                             20.0f

typedef NS_ENUM(NSInteger, VSDirection) {
    VSDirectionForward = 0,
    VSDirectionStay = 1,
    VSDirectionBackward = 2
};

@interface DDViewSlidePager() <UIScrollViewDelegate>

@property (nonatomic, assign) DDSlideBaseViewType slideBaseViewType;
@property (nonatomic, strong) NSArray *titles;
@property (nonatomic, strong) NSArray *contents;
@property (nonatomic, weak) id baseContent;

@property (nonatomic, strong) UIView *titleBGView;
@property (nonatomic, strong) NSMutableArray *titleViewArray;
@property (nonatomic, strong) NSMutableArray *contentViewArray;

@property (nonatomic, strong) UIView *indicatorView;
@property (nonatomic, strong) UIColor *indicatorColor;

@property (nonatomic, strong) UIScrollView *titleScrollView;
@property (nonatomic, strong) UIScrollView *contentScrollView;

@property (nonatomic, assign) NSInteger currentIndex;
@property (nonatomic, assign) NSInteger lastIndex;
@property (nonatomic, assign) VSDirection currentDirection;

@property (nonatomic, assign) CGFloat scrollStartOffsetX;
@property (nonatomic, assign) CGFloat indicatorStartX;

@property (nonatomic, assign) BOOL isContinuityScrolling;
@property (nonatomic, assign) BOOL titleViewNeedToScroll;
@property (nonatomic, assign) BOOL isTitleTaping;
@property (nonatomic, assign) BOOL isContentScrolling;


@end

@implementation DDViewSlidePager

+ (instancetype)viewSlidePagerWithType:(DDSlideBaseViewType)slideBaseViewType
                           baseContent:(id)baseContent
                                titles:(NSArray *)titles
                              contents:(NSArray *)contents
                            titleColor:(UIColor *)titleColor
                        indicatorColor:(UIColor *)indicatorColor
{
    return [[DDViewSlidePager alloc] initWithType:slideBaseViewType baseContent:baseContent titles:titles contents:contents titleColor:titleColor indicatorColor:indicatorColor];
}


- (instancetype)initWithType:(DDSlideBaseViewType)slideBaseViewType
                 baseContent:(id)baseContent
                      titles:(NSArray *)titles
                    contents:(NSArray *)contents
                  titleColor:(UIColor *)titleColor
              indicatorColor:(UIColor *)indicatorColor
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    NSAssert(([baseContent isKindOfClass:[UIView class]] || [baseContent isKindOfClass:[UIViewController class]]), @"! param error, baseContent must be UIView or UIViewController");
    NSAssert( titles && contents && titles.count > 1  && (titles.count == contents.count), @"! param error, the content or content count not match");
    
    _slideBaseViewType = slideBaseViewType;
    _baseContent = baseContent;
    _titles = [titles copy];
    _contents = [contents copy];
    _titleColor = titleColor ?: [UIColor whiteColor];
    _indicatorColor = indicatorColor ?: kVSDefaultTitleColor;
    
    _titleBGViewHeight = 44.0f;
    _titleSelectColor = _indicatorColor;
    _titleBGViewColor = [UIColor lightGrayColor];
    _titleFont = [UIFont systemFontOfSize:17.0f];
    _indicatorViewHeight = 3.0f;
    _titleViewVOffset = 0.0f;
    _hasNavigationBar = NO;
    _hasTabBar = NO;
    _shouldIndicatorFollowing = YES;
    _titleViewNeedToScroll = NO;
    
    _isTitleTaping = NO;
    _currentDirection = VSDirectionStay;
    _currentIndex = 0;
    _lastIndex = 0;
    
    [self setupUI];
    return self;
}

- (void)setupUI
{
    UIView *baseBGView = [self baseContentView];
    if (!baseBGView) {
        return;
    }
    
    _titleBGView = [[UIView alloc] init];
    _titleScrollView = [[UIScrollView alloc] init];
    _titleScrollView.showsHorizontalScrollIndicator = NO;
    _titleScrollView.showsVerticalScrollIndicator = NO;
    _indicatorView = [[UIView alloc] init];
    _contentScrollView = [[UIScrollView alloc] init];
    _contentScrollView.pagingEnabled = YES;
    _contentScrollView.showsHorizontalScrollIndicator = NO;
    _contentScrollView.showsVerticalScrollIndicator = NO;
    _contentScrollView.delegate = self;
    
    [baseBGView addSubview:_titleBGView];
    [baseBGView addSubview:_contentScrollView];
    [_titleBGView addSubview:_titleScrollView];
    [_titleScrollView addSubview:_indicatorView];
    
    _titleViewArray = [[NSMutableArray alloc] initWithCapacity:_titles.count];
    [self.titles enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL *stop) {
        
        UILabel*label = [[UILabel alloc] init];
        label.textAlignment = NSTextAlignmentCenter;
        label.text = obj;
        label.userInteractionEnabled = YES;
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTitleViewTap:)];
        [label addGestureRecognizer:tapGesture];
        [_titleScrollView addSubview:label];
        [_titleViewArray addObject:label];
        
    }];
    
    _contentViewArray = [[NSMutableArray alloc] initWithCapacity:self.contents.count];
    [self.contents enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        if (self.slideBaseViewType == DDSlideBaseViewTypeView) {
            [_contentScrollView addSubview:obj];
            [_contentViewArray addObject:obj];
        } else {
            UIViewController *baseVC = (UIViewController *)self.baseContent;
            UIViewController *currentVC = (UIViewController *)obj;
            [baseVC addChildViewController:currentVC];
            [_contentScrollView addSubview:currentVC.view];
            [_contentViewArray addObject:currentVC.view];
        }
        
    }];
    
}

- (void)reLayoutSubView
{
    UIView *baseBGView = [self baseContentView];
    CGFloat topViewHeight = [self topViewHeight];
    CGFloat buttomViewHeight = [self buttomViewHeight];
    _titleBGView.frame = CGRectMake(0.0f, topViewHeight, CGRectGetWidth(baseBGView.frame), self.titleBGViewHeight);
    _titleBGView.backgroundColor = self.titleBGViewColor;
    
    _titleScrollView.frame = CGRectMake(0.0f, 0.0f, CGRectGetWidth(_titleBGView.frame), CGRectGetHeight(_titleBGView.frame));
    _indicatorView.backgroundColor = self.indicatorColor;
    _contentScrollView.frame = CGRectMake(0.0f, CGRectGetMaxY(_titleBGView.frame), CGRectGetWidth(_titleBGView.frame), CGRectGetHeight([UIScreen mainScreen].bounds) - CGRectGetMaxY(_titleBGView.frame) - buttomViewHeight);
    
    // titles
    NSMutableArray *widthsArray = [[NSMutableArray alloc] init];
    __block CGFloat lastStartX = kVSTitleViewInterval;
    [self.titleViewArray enumerateObjectsUsingBlock:^(UILabel *obj, NSUInteger idx, BOOL *stop) {
        obj.font = self.titleFont;
        obj.textColor = self.titleColor;
        obj.backgroundColor = [UIColor clearColor];
        
        CGSize textSize = [obj.text sizeWithFont:obj.font constrainedToSize:CGSizeMake(CGRectGetWidth(self.titleScrollView.frame), CGRectGetHeight(self.titleScrollView.frame))];
        CGFloat currentWidth = textSize.width + kVSTitleViewInterval;
        [widthsArray addObject:@(currentWidth)];
        lastStartX += currentWidth;
    }];
    lastStartX += kVSTitleViewInterval;
    
    // over one screen
    if (lastStartX > CGRectGetWidth(self.titleScrollView.frame)) {
        self.titleViewNeedToScroll = YES;
        lastStartX = kVSTitleViewInterval;
        [self.titleViewArray enumerateObjectsUsingBlock:^(UILabel *obj, NSUInteger idx, BOOL *stop) {
            CGFloat currentWidth = [[widthsArray objectAtIndex:idx] floatValue];
            obj.frame = CGRectMake(lastStartX, self.titleViewVOffset, currentWidth, CGRectGetHeight(self.titleScrollView.frame) - self.titleViewVOffset);
            lastStartX += currentWidth;
        }];
        lastStartX += kVSTitleViewInterval;
        
        self.titleScrollView.contentSize = CGSizeMake(lastStartX, CGRectGetHeight(self.titleScrollView.frame));
    } else { // less than one screen
        lastStartX = kVSTitleViewInterval;
        CGFloat currentWidth = (CGRectGetWidth(self.titleScrollView.frame) - kVSTitleViewInterval * 2) / self.titleViewArray.count;
        [self.titleViewArray enumerateObjectsUsingBlock:^(UILabel *obj, NSUInteger idx, BOOL *stop) {
            obj.frame = CGRectMake(lastStartX, self.titleViewVOffset, currentWidth, CGRectGetHeight(self.titleScrollView.frame) - self.titleViewVOffset);
            lastStartX += currentWidth;
        }];
        lastStartX += kVSTitleViewInterval;
        
        self.titleScrollView.contentSize = CGSizeMake(CGRectGetWidth(self.titleScrollView.frame), CGRectGetHeight(self.titleScrollView.frame));
    }
    
    // contents
    [self.contentViewArray enumerateObjectsUsingBlock:^(UIView *obj, NSUInteger idx, BOOL *stop) {
        obj.frame = CGRectMake(idx * CGRectGetWidth(self.contentScrollView.frame), 0.0f, CGRectGetWidth(self.contentScrollView.frame), CGRectGetHeight(self.contentScrollView.frame));
    }];
    self.contentScrollView.contentSize = CGSizeMake(CGRectGetWidth(self.contentScrollView.frame) * self.contentViewArray.count, CGRectGetHeight(self.titleScrollView.frame));
    
    UILabel *currentTitleLabel = [self.titleViewArray objectAtIndex:self.currentIndex];
    _indicatorView.frame = CGRectMake(CGRectGetMinX(currentTitleLabel.frame), CGRectGetMaxY(currentTitleLabel.frame) - _indicatorViewHeight, CGRectGetWidth(currentTitleLabel.frame), _indicatorViewHeight);
    
    self.currentIndex = 0;
    [self didSlideToIndex:self.currentIndex];
    
}


- (void)show
{
    [self reLayoutSubView];
}

- (void)reloadData
{
    [self reLayoutSubView];
}

- (void)reloadViewWithType:(DDSlideBaseViewType)slideBaseViewType
               baseContent:(id)baseContent
                    titles:(NSArray *)titles
                  contents:(NSArray *)contents
{
    
    NSAssert(([baseContent isKindOfClass:[UIView class]] || [baseContent isKindOfClass:[UIViewController class]]), @"! param error, baseContent must be UIView or UIViewController");
    NSAssert( titles && contents && titles.count > 1  && (titles.count == contents.count), @"! param error, the content or content count not match");
    
    [self cleanUp];
    
    self.slideBaseViewType = slideBaseViewType;
    self.baseContent = baseContent;
    self.titles = [titles copy];
    self.contents = [contents copy];
    
    [self setupUI];
    [self show];
}

- (void)cleanUp
{
    if (self.slideBaseViewType == DDSlideBaseViewTypeViewController) {
        [self.contents enumerateObjectsUsingBlock:^(UIViewController *obj, NSUInteger idx, BOOL *stop) {
            [obj removeFromParentViewController];
        }];
    }
    
    [self.titleBGView removeFromSuperview];
    [self.contentScrollView removeFromSuperview];
    
    self.titles = nil;
    self.contents = nil;
    [self.titleViewArray removeAllObjects];
    [self.contentViewArray removeAllObjects];
    self.isTitleTaping = NO;
    self.currentDirection = VSDirectionStay;
    self.currentIndex = 0;
    self.lastIndex = 0;
}

#pragma mark -

- (UIView *)baseContentView
{
    if (self.slideBaseViewType == DDSlideBaseViewTypeView) {
        return self.baseContent;
    } else {
        return ((UIViewController *)self.baseContent).view;
    }
}

- (CGFloat)topViewHeight
{
    if (self.slideBaseViewType == DDSlideBaseViewTypeView) {
        return 0.0f;
    } else {
        if (self.hasNavigationBar) {
            return 64.0f;
        } else {
            return 0.0f;
        }
    }
}

- (CGFloat)buttomViewHeight
{
    if (self.slideBaseViewType == DDSlideBaseViewTypeView) {
        return 0.0f;
    } else {
        if (self.hasTabBar) {
            if ([[UIDevice currentDevice] systemVersion].floatValue < 7.0f) {
                return 49.0f;
            } else {
                return 49.0f;
            }
        } else {
            return 0.0f;
        }
    }
}

#pragma mark -

- (void)handleTitleViewTap:(UITapGestureRecognizer *)tapGestureRecognizer
{
    if (self.isContentScrolling) {
        return;
    }
    UILabel *selectTitleLabel = (UILabel *)tapGestureRecognizer.view;
    NSInteger selectIndex = [self.titleViewArray indexOfObject:selectTitleLabel];
    if (selectIndex == self.currentIndex) {
        return;
    }
    if (selectIndex != NSNotFound) {
        self.currentIndex = selectIndex;
        
        // we set currentDirection to scroll visibel region
        if (selectIndex > self.lastIndex) {
            self.currentDirection = VSDirectionForward;
        } else if (selectIndex < self.lastIndex) {
            self.currentDirection = VSDirectionBackward;
        }
        self.isTitleTaping = YES;
        [self indicatorSlideToTitleLabel:selectTitleLabel aniamted:YES duration:0.2f];
        [self contentViewSlideToIndex:selectIndex aniamted:NO];
        [self titleViewScrollToVisibleRegion];
        [self didSlideToIndex:self.currentIndex];
        self.currentDirection = VSDirectionStay;
        self.isTitleTaping = NO;
    }
    
}

- (void)indicatorSlideToTitleLabel:(UILabel *)selectTitleLabel aniamted:(BOOL)animated duration:(CGFloat)duration
{
    if (animated) {
        [UIView animateWithDuration:(duration > 0 ? duration : 0.25f) animations:^{
            self.indicatorView.frame = CGRectMake(CGRectGetMinX(selectTitleLabel.frame), CGRectGetMaxY(selectTitleLabel.frame) - _indicatorViewHeight, CGRectGetWidth(selectTitleLabel.frame), _indicatorViewHeight);
        }];
    } else {
        self.indicatorView.frame = CGRectMake(CGRectGetMinX(selectTitleLabel.frame), CGRectGetMaxY(selectTitleLabel.frame) - _indicatorViewHeight, CGRectGetWidth(selectTitleLabel.frame), _indicatorViewHeight);
    }
    
}

- (void)contentViewSlideToIndex:(NSInteger)selectIndex aniamted:(BOOL)animated
{
    [self.contentScrollView setContentOffset:CGPointMake(selectIndex * CGRectGetWidth(self.contentScrollView.frame), self.contentScrollView.contentOffset.y) animated:animated];
}


- (void)didSlideToIndex:(NSInteger)index
{
    if (index < 0 || index >= self.titleViewArray.count) return;
    if (self.didSlideToIndexHandler) self.didSlideToIndexHandler(index);
    
    UILabel *lastSelectTitleLabel = [self.titleViewArray objectAtIndex:self.lastIndex];
    lastSelectTitleLabel.textColor = self.titleColor;
    
    UILabel *selectTitleLabel = [self.titleViewArray objectAtIndex:index];
    selectTitleLabel.textColor = self.titleSelectColor;
}

#pragma mark -

- (void)setCurrentIndex:(NSInteger)currentIndex
{
    self.lastIndex = _currentIndex;
    _currentIndex = currentIndex;
}

#pragma mark  UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    
    self.isContentScrolling = YES;
    self.scrollStartOffsetX = scrollView.contentOffset.x;
    self.indicatorStartX = CGRectGetMidX(self.indicatorView.frame);
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    // if called setContentOffset/scrollRectVisible:animated: , just let go
    if (self.isTitleTaping) {
        return;
    }
    
    // get the first diretion
    if (self.currentDirection == VSDirectionStay) {
        self.currentDirection = [self getDirectionAtScrollView:scrollView];
    }
    
    // indicator following when scrolling
    if (self.shouldIndicatorFollowing) {
        [self indicatorFollowing:scrollView];
    }
    
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView
{
    // mark if continuityScrolling
    if (_isContinuityScrolling == NO) {
        _isContinuityScrolling = YES;
        return;
    }
    
    [self indicatorContinuityScroll];
    [self didSlideToIndex:self.currentIndex];
}


- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    self.isContinuityScrolling = NO;
    [self reloadScrollViewLocation:scrollView];
    [self titleViewScrollToVisibleRegion];
    [self didSlideToIndex:self.currentIndex];
    self.currentDirection = VSDirectionStay;
    self.isContentScrolling = NO;
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    self.isTitleTaping = NO;
}


#pragma mark -

// continue scroll fast
- (void)indicatorContinuityScroll
{
    VSDirection direction = self.currentDirection;
    NSInteger step = 0;
    if (direction == VSDirectionForward) step = 1;
    if (direction == VSDirectionBackward) step = -1;
    
    if (step != 0) {
        NSInteger nextIndex = self.currentIndex + step;
        if (nextIndex < 0) nextIndex = 0;
        if (nextIndex >= self.contentViewArray.count) nextIndex = self.contentViewArray.count - 1;
        
        UILabel *selectTitleLabel = [self.titleViewArray objectAtIndex:nextIndex];
        if (selectTitleLabel) {
            [self indicatorSlideToTitleLabel:selectTitleLabel aniamted:YES duration:0.1f];
            self.currentIndex = nextIndex;
            [self titleViewScrollToVisibleRegion];
        }
    }
}

- (VSDirection)getDirectionAtScrollView:(UIScrollView *)scrollView
{
    VSDirection direction = VSDirectionStay;
    CGFloat dx = scrollView.contentOffset.x - _scrollStartOffsetX;
    if (dx > 0) {
        direction = VSDirectionForward;
    } else if (dx < 0 ){
        direction = VSDirectionBackward;
    }
    return direction;
}

// indicator following one step
- (void)indicatorFollowing:(UIScrollView *)scrollView
{
    VSDirection direction = self.currentDirection;
    NSInteger step = 0;
    if (direction == VSDirectionForward) step = 1;
    if (direction == VSDirectionBackward) step = -1;
    NSInteger nextIndex = self.currentIndex + step;
    if (nextIndex >= 0 && nextIndex < self.titleViewArray.count) {
        UILabel *nextTitleLabel = [self.titleViewArray objectAtIndex:nextIndex];
        
        CGFloat detal = (scrollView.contentOffset.x -_scrollStartOffsetX) * fabs((CGRectGetMidX(nextTitleLabel.frame) - _indicatorStartX)) / CGRectGetWidth(self.contentScrollView.frame);
        self.indicatorView.center = CGPointMake(_indicatorStartX + detal, self.indicatorView.center.y);
    }
}


- (void)reloadScrollViewLocation:(UIScrollView *)scrollView
{
    NSInteger nextIndex = (NSInteger)(scrollView.contentOffset.x / CGRectGetWidth(self.contentScrollView.frame));
    
    if (nextIndex != self.currentIndex) {
        UILabel *selectTitleLabel = [self.titleViewArray objectAtIndex:nextIndex];
        if (selectTitleLabel) {
            [self indicatorSlideToTitleLabel:selectTitleLabel aniamted:YES duration:0.2f];
            self.currentIndex = nextIndex;
        }
    }
    
}

// do this check when scrollViewDidEndDecelerating
- (void)titleViewScrollToVisibleRegion
{
    if (!self.titleViewNeedToScroll) return;
    
    UILabel *selectTitleLabel = [self.titleViewArray objectAtIndex:self.currentIndex];
    CGRect visibleFrame = selectTitleLabel.frame;
    if (self.currentDirection == VSDirectionBackward) {
        visibleFrame.origin.x = visibleFrame.origin.x -  CGRectGetWidth(self.titleScrollView.frame) / 2 + CGRectGetWidth(visibleFrame) / 2;
        if (visibleFrame.origin.x < 0) {
            visibleFrame.origin.x = 0;
        }
    } else if (self.currentDirection == VSDirectionForward) {
        visibleFrame.origin.x = visibleFrame.origin.x +  CGRectGetWidth(self.titleScrollView.frame) / 2 - CGRectGetWidth(visibleFrame) / 2;
    }
    
    [self.titleScrollView scrollRectToVisible:visibleFrame animated:YES];
    
}

@end
