//
//  IAPManager.m
//  Memorize
//
//  Created by 华侨 on 5/5/16.
//  Copyright © 2016 HuaQiao. All rights reserved.
//

#import "IAPManager.h"

@implementation IAPManager


+ (instancetype)sharedManager {
  static IAPManager *sharedManager = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedManager = [[self alloc] init];
  });
  
  return sharedManager;
}

- (NSArray *)fetchProductIdentifiers {
  NSURL *url = [[NSBundle mainBundle] pathForResource:@"InAppPurchaseIDs" ofType:@"plist"];
  return [NSArray arrayWithContentsOfURL:url];
}

@end
