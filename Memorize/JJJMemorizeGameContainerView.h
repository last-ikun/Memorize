//
//  JJJMemorizeGameContainerView.h
//  Memorize
//
//  Created by 华侨 on 1/17/15.
//  Copyright (c) 2015 HuaQiao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JJJMemorizeGameGridView.h"

@class JJJMemorizeGameContainerView;

@protocol JJJMemorizeGameContainerViewDelegate <NSObject>

- (BOOL)shouldHandleGameTouchEvent:(JJJMemorizeGameContainerView *)gameContainer;
- (void)gameSessionDidEndWithResult:(BOOL)win;
- (void)gridViewWillAppear;

- (BOOL)ifUserFirstLaunch;
- (void)showArrowAtFrame:(CGRect)arrowFrame;
- (void)moveArrowToFrame:(CGRect)arrowFrame;
- (void)userFinishTraining;

@end

@interface JJJMemorizeGameContainerView : UIView

@property (nonatomic, readonly) CGFloat gridSideLength;
@property (nonatomic, weak) id<JJJMemorizeGameContainerViewDelegate> delegate;

- (void)nextLevel;
- (void)startGame;
- (void)restartGame;

@end
