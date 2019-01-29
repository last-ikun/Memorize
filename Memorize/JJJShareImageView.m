//
//  JJJShareImageView.m
//  Memorize
//
//  Created by 华侨 on 1/21/15.
//  Copyright (c) 2015 HuaQiao. All rights reserved.
//

#import "JJJShareImageView.h"
#import "JJJGameThemeManager.h"

@interface JJJShareImageView ()

@end

@implementation JJJShareImageView

- (instancetype)initWithFrame:(CGRect)frame shareType:(NSInteger)shareType {
	self = [super initWithFrame:frame];
	if (self) {
		_shareType = shareType;
		switch (shareType) {
			case JJJShareTypeNone:
			self.image = [[JJJGameThemeManager defaultManager] imageForShareTypeWithCurrentTheme:shareType];
		    break;
				
			case JJJShareTypeTwitter:
				self.image = [UIImage imageNamed:@"share_twitter"];
				break;
				
			case JJJShareTypeTencentWeibo:
				self.image = [UIImage imageNamed:@"share_tencent_weibo"];
				break;
				
			case JJJShareTypeSetting:
				self.image = [[JJJGameThemeManager defaultManager] imageForShareTypeWithCurrentTheme:shareType];
				break;
				
			case JJJShareTypeReplay:
				self.image = [[JJJGameThemeManager defaultManager] imageForShareTypeWithCurrentTheme:shareType];
				break;
				
			case JJJShareTypeWeibo:
				self.image = [UIImage imageNamed:@"share_weibo"];
				break;
				
			case JJJShareTypeFacebook:
				self.image = [UIImage imageNamed:@"share_facebook"];
				break;
				
			case JJJShareTypePlay:
				self.image = [[JJJGameThemeManager defaultManager] imageForShareTypeWithCurrentTheme:shareType];
				break;
				
			case JJJShareTypeSound:
				self.image = [[JJJGameThemeManager defaultManager] imageForShareTypeWithCurrentTheme:shareType];
				break;
				
			case JJJShareTypeTheme:
				self.image = [[JJJGameThemeManager defaultManager] imageForShareTypeWithCurrentTheme:shareType];
				break;
				
			case JJJShareTypeNewRecord:
				self.image = [[JJJGameThemeManager defaultManager] imageForShareTypeWithCurrentTheme:shareType];
				break;
				
			default:
    break;
		}
		
		self.userInteractionEnabled = YES;
	}
	return self;
}

- (BOOL)canBecomeFirstResponder {
	return YES;
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


- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	CGPoint point = [[touches anyObject] locationInView:self];
	[UIView animateKeyframesWithDuration:0.3 delay:0.0 options:UIViewKeyframeAnimationOptionCalculationModeLinear animations:^ {
		[UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.66 animations:^ {
			self.transform = CGAffineTransformMakeScale(1.1, 1.1);
		}];
		[UIView addKeyframeWithRelativeStartTime:0.66 relativeDuration:0.34 animations:^ {
			self.transform = CGAffineTransformMakeScale(1.0, 1.0);
		}];
	} completion:nil];
	
	if (CGRectContainsPoint(self.bounds, point)) {
		[self.delegate shareImageViewDidSelect:self];
	}
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
