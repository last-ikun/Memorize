//
//  JJJShareImageView.h
//  Memorize
//
//  Created by 华侨 on 1/21/15.
//  Copyright (c) 2015 HuaQiao. All rights reserved.
//

#import <UIKit/UIKit.h>

@class JJJShareImageView;

enum JJJShareType {
	JJJShareTypeNone = 0,
	JJJShareTypeTwitter = 1,
	JJJShareTypeSetting = 2,
	JJJShareTypeReplay = 3,
	JJJShareTypeWeibo = 5,
	JJJShareTypePlay = 6,
	JJJShareTypeSound = 7,
	JJJShareTypeNoSound = 8,
	JJJShareTypeTheme = 9,
	JJJShareTypeNewRecord = 10,
	JJJShareTypeFacebook = 11,
	JJJShareTypeTencentWeibo = 12,
};

@protocol JJJShareImageViewDelegate <NSObject>

- (void)shareImageViewDidSelect:(JJJShareImageView *)shareImageView;

@end

@interface JJJShareImageView : UIImageView

@property (nonatomic, readonly) NSInteger shareType;
@property (nonatomic, weak) id<JJJShareImageViewDelegate> delegate;

- (instancetype)initWithFrame:(CGRect)frame shareType:(NSInteger)shareType;

@end
