//
//  JJJScoreLabel.h
//  SoundTest
//
//  Created by 华侨 on 3/4/15.
//  Copyright (c) 2015 HuaQiao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JJJShareImageView.h"

@class JJJScoreLabel;

@protocol JJJScoreLabelDelegate <NSObject>

- (void)scoreLabelDidInteract:(JJJScoreLabel *)scoreLabel;

@end

@interface JJJScoreLabel : UIView

@property (nonatomic, assign) NSInteger score;
@property (nonatomic, strong, readonly) UILabel *scoreLabel;
@property (nonatomic, strong) UIColor *fillColor;

@property (nonatomic, weak) IBOutlet id <JJJScoreLabelDelegate> delegate;

@end
