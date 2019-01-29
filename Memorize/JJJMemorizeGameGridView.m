//
//  JJJMemorizeGameGridView.m
//  Memorize
//
//  Created by 华侨 on 1/17/15.
//  Copyright (c) 2015 HuaQiao. All rights reserved.
//

#import "JJJMemorizeGameGridView.h"

@interface JJJMemorizeGameGridView ()

@end

@implementation JJJMemorizeGameGridView

- (instancetype)initWithFrame:(CGRect)frame tag:(NSInteger)tag {
	self = [super initWithFrame:frame];
	if (self) {
		self.tag = tag;
		
		self.transform = CGAffineTransformMakeScale(0.0, 0.0);
		self.backgroundColor = [UIColor clearColor];
	}
	return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		self.backgroundColor = [UIColor clearColor];
	}
	return self;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
	CGRect bounds = self.bounds;
	CGPoint center;
	center.x = bounds.origin.x + bounds.size.width / 2.0;
	center.y = bounds.origin.y + bounds.size.height / 2.0;
	CGFloat radius = bounds.size.width * 0.4;
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	[self.fillColor setFill];
	
	CGContextAddArc(context, center.x, center.y, radius, 0.0, M_PI * 2.0, YES);
	CGContextFillPath(context);
}

//- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
//	[UIView animateKeyframesWithDuration:0.3 delay:0.0 options:UIViewKeyframeAnimationOptionCalculationModeLinear animations:^ {
//		[UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.66 animations:^ {
//			self.transform = CGAffineTransformMakeScale(0.75, 0.75);
//		}];
//		[UIView addKeyframeWithRelativeStartTime:0.66 relativeDuration:0.34 animations:^ {
//			self.transform = CGAffineTransformMakeScale(0.8, 0.8);
//		}];
//	} completion:nil];
//}
//
//- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
//	[UIView animateKeyframesWithDuration:0.3 delay:0.0 options:UIViewKeyframeAnimationOptionCalculationModeLinear animations:^ {
//		[UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.66 animations:^ {
//			self.transform = CGAffineTransformMakeScale(1.1, 1.1);
//		}];
//		[UIView addKeyframeWithRelativeStartTime:0.66 relativeDuration:0.34 animations:^ {
//			self.transform = CGAffineTransformMakeScale(1.0, 1.0);
//		}];
//	} completion:nil];
//}


@end
