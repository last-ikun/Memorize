//
//  JJJScoreLabel.m
//  SoundTest
//
//  Created by 华侨 on 3/4/15.
//  Copyright (c) 2015 HuaQiao. All rights reserved.
//

#import "JJJScoreLabel.h"
#import "JJJGameThemeManager.h"
#import <Foundation/Foundation.h>

@interface JJJScoreLabel ()

@property (nonatomic, strong, readwrite) UILabel *scoreLabel;

@end

@implementation JJJScoreLabel

- (void)setFillColor:(UIColor *)fillColor {
	_fillColor = fillColor;
	[self setNeedsDisplay];
}

- (void)setScore:(NSInteger)score {
	_score = score;
	
	self.scoreLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Score: %li", nil), (long)score];
}

- (instancetype)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	
	if (self) {
		self.backgroundColor = [UIColor clearColor];
		
		_scoreLabel = [[UILabel alloc] initWithFrame:self.bounds];
		self.scoreLabel.textColor = [UIColor whiteColor];
		self.scoreLabel.textAlignment = NSTextAlignmentCenter;
		self.scoreLabel.backgroundColor = [UIColor clearColor];
		self.scoreLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Score: %li", nil), 0];
		self.scoreLabel.font = [self.scoreLabel.font fontWithSize:self.bounds.size.height * 0.7];
		self.scoreLabel.adjustsFontSizeToFitWidth = YES;
		
		[self addSubview:self.scoreLabel];
	}
	
	return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
	CGRect bounds = self.bounds;
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	[self.fillColor setFill];
	
	CGFloat radius = bounds.size.height / 2.0;
	
	CGContextAddArc(context, radius, radius, radius, -0.0, M_PI * 2.0, YES);
	CGContextFillPath(context);
	CGContextAddArc(context, bounds.size.width - radius, radius, radius, 0.0, M_PI * 2.0, YES);
	CGContextFillPath(context);
	CGContextAddRect(context, CGRectMake(radius, 0.0, bounds.size.width - radius * 2.0, radius * 2.0));
	CGContextFillPath(context);
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	[UIView animateKeyframesWithDuration:0.3 delay:0.0 options:UIViewKeyframeAnimationOptionCalculationModeLinear animations:^ {
		[UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.66 animations:^ {
			self.transform = CGAffineTransformMakeScale(0.75, 0.75);
		}];
		[UIView addKeyframeWithRelativeStartTime:0.66 relativeDuration:0.34 animations:^ {
			self.transform = CGAffineTransformMakeScale(0.8, 0.8);
		}];
	} completion:nil];
}

//- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
//	
//}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	
	[UIView animateKeyframesWithDuration:0.3 delay:0.0 options:UIViewKeyframeAnimationOptionCalculationModeLinear animations:^ {
		[UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.66 animations:^ {
			self.transform = CGAffineTransformMakeScale(1.1, 1.1);
		}];
		[UIView addKeyframeWithRelativeStartTime:0.66 relativeDuration:0.34 animations:^ {
			self.transform = CGAffineTransformMakeScale(1.0, 1.0);
		}];
	} completion:^(BOOL finished) {
		NSInteger randomNumber = arc4random_uniform(3);
		if (randomNumber == 1) {
			[UIView transitionWithView:self duration:0.5 options:UIViewAnimationOptionTransitionFlipFromBottom animations:^ {
				self.fillColor = [[JJJGameThemeManager defaultManager] randomColorWithCurrentTheme];
			} completion:nil];
		}
	}];
	
	[self.delegate scoreLabelDidInteract:self];
}

@end
