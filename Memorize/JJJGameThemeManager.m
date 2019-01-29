//
//  JJJGameThemeManager.m
//  Memorize
//
//  Created by 华侨 on 3/7/15.
//  Copyright (c) 2015 HuaQiao. All rights reserved.
//

#import "JJJGameThemeManager.h"

static JJJGameThemeManager *defaultManager = nil;

@implementation JJJGameThemeManager

- (NSString *)currentTheme {
	return _currentTheme ? _currentTheme : @"impressionism";
}

+ (instancetype)defaultManager {
	if (!defaultManager) {
		defaultManager = [[super alloc] init];
		
	}
	return defaultManager;
}

- (instancetype)init {
	if (defaultManager) {
		return defaultManager;
	}
	
	self = [super init];
	return self;
}

- (UIColor *)randomColorWithCurrentTheme {
	NSString *colorFileName = [@"theme_" stringByAppendingString:self.currentTheme];
	NSString *colorFilePath = [[NSBundle mainBundle] pathForResource:colorFileName
															  ofType:@"plist"];
	
	NSArray *colorHexNumbers = [NSArray arrayWithContentsOfFile:colorFilePath];
	NSUInteger index = arc4random_uniform(colorHexNumbers.count);
	NSInteger colorHex = [[colorHexNumbers objectAtIndex:index] integerValue];
	
	NSInteger red, green, blue;
	red = colorHex / 65536;
	colorHex %= 65536;
	green = colorHex / 256;
	blue = colorHex % 256;
	
	return [UIColor colorWithRed:red / 255.0
						   green:green / 255.0
							blue:blue / 255.0
						   alpha:1.0];
}

- (UIImage *)imageForShareTypeWithCurrentTheme:(NSInteger)shareType {
	NSString *imageFileName;
	
	switch (shareType) {
		case JJJShareTypeNone:
			imageFileName = [@"share_" stringByAppendingString:self.currentTheme];
			break;
			
		case JJJShareTypePlay:
			imageFileName = [@"play_" stringByAppendingString:self.currentTheme];
			break;
			
		case JJJShareTypeReplay:
			imageFileName = [@"replay_" stringByAppendingString:self.currentTheme];
			break;
			
		case JJJShareTypeSetting:
			imageFileName = [@"setting_" stringByAppendingString:self.currentTheme];
			break;
			
		case JJJShareTypeSound:
			imageFileName = [@"sound_" stringByAppendingString:self.currentTheme];
			break;
			
		case JJJShareTypeTheme:
			imageFileName = [@"setting_theme_" stringByAppendingString:self.currentTheme];
			break;
			
		case JJJShareTypeNoSound:
			imageFileName = [@"nosound_" stringByAppendingString:self.currentTheme];
			break;
			
		case JJJShareTypeNewRecord:
			imageFileName = [@"new_record_" stringByAppendingString:self.currentTheme];
			break;
			
  default:
			break;
	}
	return [UIImage imageNamed:imageFileName];
}

@end
