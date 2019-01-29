//
//  JJJMemorizeGameContainerView.m
//  Memorize
//
//  Created by 华侨 on 1/17/15.
//  Copyright (c) 2015 HuaQiao. All rights reserved.
//

#import "JJJMemorizeGameContainerView.h"
#import "JJJMemorizeGameGridView.h"
#import "JJJGameThemeManager.h"

@interface JJJMemorizeGameContainerView ()

@property (nonatomic, assign) NSInteger dotCount;
@property (nonatomic, assign) NSTimeInterval animationDuration;
@property (nonatomic, assign) NSTimeInterval animationDelay;
@property (nonatomic, strong) NSMutableArray *gridViews;
@property (nonatomic, assign) NSInteger currentSelectedGridViewTag;
@property (nonatomic, assign) NSInteger gridBaseNumber;

@property (nonatomic, assign) NSInteger timerFiringCount;
@property (nonatomic, getter=isGameStarted) BOOL gameStarted;

@property (nonatomic, assign, getter=isInteractingPoppedGridView) BOOL interactingPoppedGridView;

@end

@implementation JJJMemorizeGameContainerView

- (instancetype)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		self.backgroundColor = [UIColor clearColor];
		
		self.gridBaseNumber = 4;
		_gridSideLength = self.bounds.size.width / self.gridBaseNumber;
		self.dotCount = 2;
		self.animationDuration = 0.4;
		self.animationDelay = 0.4;
		self.gridViews = [NSMutableArray array];
		self.gameStarted = NO;
		
		self.timerFiringCount = 0;
	}
	return self;
}

- (void)nextLevel {
	self.animationDelay = self.animationDelay - 0.4 / self.dotCount;
	if (self.animationDelay < 0) {
		self.dotCount++;
		self.animationDelay = 0.4;
	}
	
	[self startGame];
}

//- (void)previousLevel {
//	self.animationDelay = self.animationDelay + 0.4 / self.dotCount;
//	if (self.animationDelay > 0.4) {
//		self.animationDelay = 0.0;
//		self.dotCount--;
//		
//		if (self.dotCount < 2) {
//			self.dotCount = 2;
//			self.animationDelay = 0.4;
//		}
//	}
//	
//	[self startGame];
//}

- (void)clearGridsAndReload {
	for (int i = 0; i < self.subviews.count; i++) {
		JJJMemorizeGameGridView *gridView = self.subviews[i];
		
		if (i < self.subviews.count - 1) {
			[UIView animateKeyframesWithDuration:self.animationDuration delay:0.0 options:UIViewKeyframeAnimationOptionCalculationModeLinear animations:^ {
				[UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.6 animations:^ {
					gridView.transform = CGAffineTransformMakeScale(1.25, 1.25);
				}];
				[UIView addKeyframeWithRelativeStartTime:0.6 relativeDuration:0.4 animations:^ {
					gridView.transform = CGAffineTransformMakeScale(0.0, 0.0);
				}];
			} completion:nil];
		} else {
			[UIView animateKeyframesWithDuration:self.animationDuration delay:0.0 options:UIViewKeyframeAnimationOptionCalculationModeLinear animations:^ {
				[UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.6 animations:^ {
					gridView.transform = CGAffineTransformMakeScale(1.25, 1.25);
				}];
				[UIView addKeyframeWithRelativeStartTime:0.6 relativeDuration:0.4 animations:^ {
					gridView.transform = CGAffineTransformMakeScale(0.0, 0.0);
				}];
			} completion:^(BOOL finished) {
				for (UIView *subview in self.subviews) {
					[subview removeFromSuperview];
				}
				
				[self reloadGrid];
			}];
		}
	}
}

- (void)restartGame {
	self.dotCount = 2;
	self.animationDuration = 0.4;
	self.animationDelay = 0.4;
	
	[self startGame];
}

- (void)startGame{
	
	if (self.subviews.count) {
		[self clearGridsAndReload];
	} else {
		[self reloadGrid];
	}
}


- (void)reloadGrid {
	self.gameStarted = NO;
	
	NSMutableArray *allDots = [NSMutableArray array];
	for (NSInteger i = 0; i < self.gridBaseNumber * self.gridBaseNumber; i++) {
		[allDots addObject:[NSNumber numberWithInteger:i]];
	}
	
	NSMutableArray *chosenDots = [NSMutableArray array];
	while (chosenDots.count < self.dotCount) {
		NSInteger index = arc4random_uniform(self.gridBaseNumber * self.gridBaseNumber);
		NSNumber *dot = [allDots objectAtIndex:index];
		if (![chosenDots containsObject:dot]) {
			[chosenDots addObject:dot];
		}
	}
	
	for (NSInteger j = 0; j < chosenDots.count; j++) {
		NSInteger dotIndex = [[chosenDots objectAtIndex:j] integerValue];
		
		NSInteger row = dotIndex / self.gridBaseNumber;
		NSInteger column = dotIndex % self.gridBaseNumber;
		
		//Creating a JJJMemorizeGameGridView instance.
		CGRect frame = CGRectMake(self.gridSideLength * column, self.gridSideLength * row, self.gridSideLength, self.gridSideLength);
		JJJMemorizeGameGridView *gridView = [[JJJMemorizeGameGridView alloc] initWithFrame:frame tag:dotIndex];
		gridView.fillColor = [[JJJGameThemeManager defaultManager] randomColorWithCurrentTheme];
		
		[self addSubview:gridView];
		[self.gridViews addObject:gridView];
		
		if (j != chosenDots.count - 1) {
			[UIView animateKeyframesWithDuration:self.animationDuration delay:self.animationDuration * j + self.animationDelay * (j + 1) options:UIViewKeyframeAnimationOptionCalculationModeLinear animations:^ {
				[UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.3 animations:^ {
					gridView.transform = CGAffineTransformMakeScale(1.25, 1.25);
				}];
				[UIView addKeyframeWithRelativeStartTime:0.3 relativeDuration:0.4 animations:^ {
					gridView.transform = CGAffineTransformMakeScale(0.8, 0.8);
				}];
				[UIView addKeyframeWithRelativeStartTime:0.7 relativeDuration:0.3 animations:^ {
					gridView.transform = CGAffineTransformMakeScale(1.0, 1.0);
				}];
			} completion:nil];
		} else {
			[UIView animateKeyframesWithDuration:self.animationDuration delay:self.animationDuration * j + self.animationDelay * (j + 1) options:UIViewKeyframeAnimationOptionCalculationModeLinear animations:^ {
				[UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.3 animations:^ {
					gridView.transform = CGAffineTransformMakeScale(1.25, 1.25);
				}];
				[UIView addKeyframeWithRelativeStartTime:0.3 relativeDuration:0.4 animations:^ {
					gridView.transform = CGAffineTransformMakeScale(0.8, 0.8);
				}];
				[UIView addKeyframeWithRelativeStartTime:0.7 relativeDuration:0.3 animations:^ {
					gridView.transform = CGAffineTransformMakeScale(1.0, 1.0);
				}];
			} completion:^(BOOL finished) {
				//				NSLog(@"Grid View tagged #%li appeared", gridView.tag);
				
				for (NSUInteger k = 0; k < self.subviews.count; k++) {
					UIView *gridView = [self.subviews objectAtIndex:k];
					
					if (k != self.subviews.count - 1) {
						[UIView animateKeyframesWithDuration:self.animationDuration delay:0.0 options:UIViewKeyframeAnimationOptionCalculationModeLinear animations:^ {
							[UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.6 animations:^ {
								gridView.transform = CGAffineTransformMakeScale(1.25, 1.25);
							}];
							[UIView addKeyframeWithRelativeStartTime:0.6 relativeDuration:0.4 animations:^ {
								gridView.transform = CGAffineTransformMakeScale(0.0, 0.0);
							}];
						} completion:nil];
					} else {
						[UIView animateKeyframesWithDuration:self.animationDuration delay:0.0 options:UIViewKeyframeAnimationOptionCalculationModeLinear animations:^ {
							[UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.6 animations:^ {
								gridView.transform = CGAffineTransformMakeScale(1.25, 1.25);
							}];
							[UIView addKeyframeWithRelativeStartTime:0.6 relativeDuration:0.4 animations:^ {
								gridView.transform = CGAffineTransformMakeScale(0.0, 0.0);
							}];
						} completion:^(BOOL finished) {
							self.gameStarted = YES;
							
							if ([self.delegate ifUserFirstLaunch]) {
								
								UIView *baseView = self.gridViews.firstObject;
								CGRect baseFrame = baseView.frame;
								CGRect arrowFrame = CGRectMake(baseFrame.origin.x - self.gridSideLength / 2.0 + self.frame.origin.x, baseFrame.origin.y - self.gridSideLength / 2.0 + self.frame.origin.y - self.gridSideLength, self.gridSideLength, self.gridSideLength);
								[self.delegate showArrowAtFrame:arrowFrame];
							}
						}];
					}
				}
			}];
		}
		
	}
	
	[NSTimer scheduledTimerWithTimeInterval:self.animationDuration + self.animationDelay target:self selector:@selector(gridWillAppear:) userInfo:nil repeats:YES];
}

- (void)gridWillAppear:(NSTimer *)timer {
	self.timerFiringCount++;
	
	if (self.timerFiringCount <= self.dotCount) {
		[self.delegate gridViewWillAppear];
	} else {
		[timer invalidate];
		self.timerFiringCount = 0;
	}
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	if (!self.gameStarted) {
		return;
	}
	
	UITouch *touch = [touches anyObject];
	CGPoint point = [touch locationInView:self];
	
	NSInteger row, column;
	row = point.y / self.gridSideLength;
	column = point.x / self.gridSideLength;
	
	NSInteger viewTag = row * 4 + column;
	
	self.currentSelectedGridViewTag = viewTag;
	
	for (UIView *gridView in self.subviews) {
		if (viewTag == gridView.tag && CGAffineTransformIsIdentity(gridView.transform)) {
			self.interactingPoppedGridView = YES;
			
			[UIView animateKeyframesWithDuration:0.3 delay:0.0 options:UIViewKeyframeAnimationOptionCalculationModeLinear animations:^ {
				[UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.66 animations:^ {
					gridView.transform = CGAffineTransformMakeScale(0.75, 0.75);
				}];
				[UIView addKeyframeWithRelativeStartTime:0.66 relativeDuration:0.34 animations:^ {
					gridView.transform = CGAffineTransformMakeScale(0.8, 0.8);
				}];
			} completion:nil];
		}
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	if (!self.gameStarted) {
		[self.delegate shouldHandleGameTouchEvent:self];
		return;
	}
	
	if (self.isInteractingPoppedGridView) {
		self.interactingPoppedGridView = NO;
		
		UIView *gridView = [self viewWithTag:self.currentSelectedGridViewTag];
		
		[UIView animateKeyframesWithDuration:0.3 delay:0.0 options:UIViewKeyframeAnimationOptionCalculationModeLinear animations:^ {
			[UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.66 animations:^ {
				gridView.transform = CGAffineTransformMakeScale(1.1, 1.1);
			}];
			[UIView addKeyframeWithRelativeStartTime:0.66 relativeDuration:0.34 animations:^ {
				gridView.transform = CGAffineTransformMakeScale(1.0, 1.0);
			}];
		} completion:nil];
		
		return;
	}
	
	if ([self.delegate shouldHandleGameTouchEvent:self]) {
		UITouch *touch = [touches anyObject];
		CGPoint point = [touch locationInView:self];
		
		NSInteger row, column;
		row = point.y / self.gridSideLength;
		column = point.x / self.gridSideLength;
		
		NSInteger endTag = row * 4 + column;
		if (self.currentSelectedGridViewTag != endTag) {
			return;
		}
		
		UIView *gridView = [self.gridViews firstObject];
		if (gridView.tag == self.currentSelectedGridViewTag) {
			[self.gridViews removeObject:gridView];
			
			if (self.gridViews.count != 0) {
				[UIView animateKeyframesWithDuration:self.animationDuration delay:0.0 options:UIViewKeyframeAnimationOptionCalculationModeLinear animations:^ {
					[UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.3 animations:^ {
						gridView.transform = CGAffineTransformMakeScale(1.25, 1.25);
					}];
					[UIView addKeyframeWithRelativeStartTime:0.3 relativeDuration:0.4 animations:^ {
						gridView.transform = CGAffineTransformMakeScale(0.8, 0.8);
					}];
					[UIView addKeyframeWithRelativeStartTime:0.7 relativeDuration:0.3 animations:^ {
						gridView.transform = CGAffineTransformMakeScale(1.0, 1.0);
					}];
				} completion:^(BOOL finished) {
					if ([self.delegate ifUserFirstLaunch]) {
						CGRect baseFrame = ((UIView *)(self.gridViews.firstObject)).frame;
						CGRect arrowFrame = CGRectMake(baseFrame.origin.x + self.frame.origin.x - self.gridSideLength / 2.0, baseFrame.origin.y + self.frame.origin.y - self.gridSideLength * 1.5, self.gridSideLength, self.gridSideLength);
						[self.delegate moveArrowToFrame:arrowFrame];
					}
				}];
				[self.delegate gridViewWillAppear];
				
			} else {
				[UIView animateKeyframesWithDuration:self.animationDuration delay:0.0 options:UIViewKeyframeAnimationOptionCalculationModeLinear animations:^ {
					[UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.3 animations:^ {
						gridView.transform = CGAffineTransformMakeScale(1.25, 1.25);
					}];
					[UIView addKeyframeWithRelativeStartTime:0.3 relativeDuration:0.4 animations:^ {
						gridView.transform = CGAffineTransformMakeScale(0.8, 0.8);
					}];
					[UIView addKeyframeWithRelativeStartTime:0.7 relativeDuration:0.3 animations:^ {
						gridView.transform = CGAffineTransformMakeScale(1.0, 1.0);
					}];
					
					[self.delegate gridViewWillAppear];
				} completion:^(BOOL finished) {
					[self.delegate gameSessionDidEndWithResult:YES];
					
					if ([self.delegate ifUserFirstLaunch]) {
						[self.delegate userFinishTraining];
					}
				}];
			}
		} else {
			if ([self.delegate ifUserFirstLaunch]) {
				return;
			}
			
			[self.delegate gameSessionDidEndWithResult:NO];
			
			for (UIView *remainedGridView in self.gridViews) {
				[UIView animateKeyframesWithDuration:self.animationDuration delay:0.5 options:UIViewKeyframeAnimationOptionCalculationModeLinear animations:^ {
					[UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.3 animations:^ {
						remainedGridView.transform = CGAffineTransformMakeScale(1.25, 1.25);
					}];
					[UIView addKeyframeWithRelativeStartTime:0.3 relativeDuration:0.4 animations:^ {
						remainedGridView.transform = CGAffineTransformMakeScale(0.8, 0.8);
					}];[UIView addKeyframeWithRelativeStartTime:0.7 relativeDuration:0.3 animations:^ {
						remainedGridView.transform = CGAffineTransformMakeScale(1.0, 1.0);
					}];
				}completion:^(BOOL finished) {
					[self.gridViews removeObject:remainedGridView];
				}];
			}
		}
	}
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
	CGRect bounds = self.bounds;
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	for (NSInteger i = 1; i < 4; i++) {
		CGContextMoveToPoint(context, bounds.origin.x + self.gridSideLength * i, bounds.origin.y);
		CGContextAddLineToPoint(context, bounds.origin.x + self.gridSideLength * i, bounds.origin.y + bounds.size.height);
		
		CGContextMoveToPoint(context, bounds.origin.x, bounds.origin.y + self.gridSideLength * i);
		CGContextAddLineToPoint(context, bounds.origin.x + bounds.size.width, bounds.origin.y + self.gridSideLength * i);
	}
	
	CGContextSetLineWidth(context, 0.1);
	[[UIColor colorWithRed:202 / 255 green:226 / 255 blue:170 / 255 alpha:1.0] setStroke];
	CGContextStrokePath(context);
}


@end
