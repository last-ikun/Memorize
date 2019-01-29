//
//  JJJGameThemeManager.h
//  Memorize
//
//  Created by 华侨 on 3/7/15.
//  Copyright (c) 2015 HuaQiao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "JJJShareImageView.h"

@interface JJJGameThemeManager : NSObject

@property (nonatomic, copy) NSString *currentTheme;

+ (instancetype)defaultManager;

- (UIColor	*)randomColorWithCurrentTheme;
- (UIImage *)imageForShareTypeWithCurrentTheme:(NSInteger)shareType;

@end
