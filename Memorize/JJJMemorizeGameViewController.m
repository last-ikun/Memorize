  //
  //  JJJMemorizeGameViewController.m
  //  Memorize
  //
  //  Created by 华侨 on 1/17/15.
  //  Copyright (c) 2015 HuaQiao. All rights reserved.
  //

#import "JJJMemorizeGameViewController.h"
#import "JJJMemorizeGameContainerView.h"
#import "JJJShareImageView.h"
#import "JJJScoreLabel.h"
#import "JJJGameThemeManager.h"
#import "UIView+Shake.h"
#import "IAPManager.h"

#import <AudioToolbox/AudioToolbox.h>
#import <Social/Social.h>
#import <AVFoundation/AVFoundation.h>
#import <GameKit/GameKit.h>

@import GoogleMobileAds;

NSString * const MemorizeHighestScoreKey = @"MemorizeHighestScoreKey";
NSString * const MemorizeSoundPrefKey = @"MemorizeSoundPrefKey";
NSString * const MemorizeThemePrefKey = @"MemorizeThemePrefKey";
NSString * const MemorizeFirstLaunch = @"MemorizeFirstLaunch";

NSString * const MemorizeShareURLString = @"https://itunes.apple.com/us/app/memtrix/id977632864?ls=1&mt=8";

NSString * const GKLeaderboardIdentifier = @"memorize_score";

NSString * const ADUnitID = @"ca-app-pub-3261022732810553/6439830028";

@interface JJJMemorizeGameViewController () <JJJScoreLabelDelegate, JJJShareImageViewDelegate, JJJMemorizeGameContainerViewDelegate, GADInterstitialDelegate>

@property (nonatomic, strong) JJJMemorizeGameContainerView *gameContainerView;
@property (nonatomic, strong) NSMutableArray *shareImageViews;
@property (nonatomic, strong) NSMutableArray *settingImageViews;
@property (nonatomic, strong) JJJShareImageView *generalShareImageView;
@property (nonatomic, strong) JJJShareImageView *levelControlImageView;
@property (nonatomic, strong) JJJShareImageView *settingImageView;
@property (nonatomic, strong) JJJScoreLabel *scoreLabel;

@property (nonatomic, strong) JJJShareImageView *breakRecordImageView;


  //Properties that's gonna be writen to and loaded from the User Preferrence
@property (nonatomic, assign) NSInteger highestScore;
@property (nonatomic, assign) BOOL soundON;
@property (nonatomic, copy) NSString *preferredTheme;
@property (nonatomic, assign) BOOL userFirstLaunch;

@property (nonatomic, assign) NSUInteger levelBonus;

  //Properties that store the registered system sound ID
@property (nonatomic, strong) AVAudioPlayer *musicPlayer;
@property (nonatomic, assign) SystemSoundID popSound;

@property (nonatomic, strong) UIImageView *guideArrowImageView;
@property (nonatomic, strong) NSTimer *guideTimer;

@property (nonatomic, strong) UIImage *sharedImage;


@property (nonatomic, strong) GADInterstitial *interstitial;

@end

@implementation JJJMemorizeGameViewController

- (void)showArrowAtFrame:(CGRect)arrowFrame {
  
  UIImage *guideImage = [UIImage imageNamed:@"guide_arrow"];
  _guideArrowImageView = [[UIImageView alloc] initWithFrame:arrowFrame];
  self.guideArrowImageView.image = guideImage;
  self.guideArrowImageView.transform = CGAffineTransformMakeScale(0.0, 0.0);
  
  [self.view addSubview:self.guideArrowImageView];
  
  [UIView animateWithDuration:0.5 animations:^ {
    self.guideArrowImageView.transform = CGAffineTransformMakeScale(1.2, 1.2);
  } completion:^(BOOL finished) {
    [UIView animateKeyframesWithDuration:1.6 delay:0.5 options:UIViewKeyframeAnimationOptionRepeat animations:^ {
      [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.6 animations:^ {
        self.guideArrowImageView.transform = CGAffineTransformMakeScale(0.8, 0.8);
      }];
      [UIView addKeyframeWithRelativeStartTime:0.6 relativeDuration:0.4 animations:^ {
        self.guideArrowImageView.transform = CGAffineTransformMakeScale(1.2, 1.2);
      }];
    } completion:nil];
  }];
}

- (void)moveArrowToFrame:(CGRect)arrowFrame {
  
  [UIView animateWithDuration:0.5 animations:^ {
    self.guideArrowImageView.frame = arrowFrame;
  }];
}

- (void)userFinishTraining {
  
  [UIView animateWithDuration:0.5 animations:^ {
    self.guideArrowImageView.transform = CGAffineTransformMakeScale(0.0, 0.0);
  } completion:^(BOOL finished) {
    [self.guideArrowImageView removeFromSuperview];
    self.guideArrowImageView = nil;
  }];
  
  self.userFirstLaunch = NO;
  [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:self.userFirstLaunch]
                                            forKey:MemorizeFirstLaunch];
}

- (BOOL)ifUserFirstLaunch {
  return self.userFirstLaunch;
}

- (void)gridViewWillAppear {
  [self playSoundIfSoundSettingIsON];
}

- (void)awakeFromNib {
  
    //Authenticate the local Game Center player
  [self authenticateLocalPlayer];
  
    //Initialise the settings and highest score from the user defaults
  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
  
  self.preferredTheme = [userDefaults objectForKey:MemorizeThemePrefKey];
  self.highestScore = [[userDefaults objectForKey:MemorizeHighestScoreKey] integerValue];
  self.soundON = [[userDefaults objectForKey:MemorizeSoundPrefKey] boolValue];
  self.userFirstLaunch = [[userDefaults objectForKey:MemorizeFirstLaunch] boolValue];
  
  NSString *soundPath = [[NSBundle mainBundle] pathForResource:@"pop" ofType:@"wav"];
  
  if (soundPath) {
    NSURL *soundURL = [NSURL fileURLWithPath:soundPath];
    
    OSStatus err = AudioServicesCreateSystemSoundID((__bridge CFURLRef)(soundURL), &_popSound);
    
    if (err != kAudioServicesNoError) {
        //			NSLog(@"Oops! There is an error creating system sound.");
    }
    
  }
}

- (void)authenticateLocalPlayer {
  GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
  
  localPlayer.authenticateHandler = ^(UIViewController *viewController, NSError *error) {
    if (viewController) {
      [self presentAuthenticationViewControllerIfReasonable:viewController];
    } else if (localPlayer.isAuthenticated) {
      [self authenticatedPlayer:localPlayer];
    } else {
      [self disableGameCenter];
    }
  };
}

- (void)presentAuthenticationViewControllerIfReasonable:(UIViewController *)viewController {
  [self presentViewController:viewController
                     animated:YES
                   completion:nil];
}

- (void)authenticatedPlayer:(GKLocalPlayer *)localPlayer {
    //	NSLog(@"Game Center enabled");
}

- (void)disableGameCenter {
    //	NSLog(@"Game Center disabled");
}

- (BOOL)deviceIdiomIsiPhoneOriPhone4s {
  return self.view.bounds.size.height == 480;
}

+ (void)initialize {
  [super initialize];
  
  NSUInteger themeIndex = arc4random_uniform(3);
  
  NSDictionary *defaults = [NSDictionary dictionaryWithObjects:@[[NSNumber numberWithInteger:0], [NSNumber numberWithBool:YES], [[JJJMemorizeGameViewController avalaibleThemes] objectAtIndex:themeIndex] , [NSNumber numberWithBool:YES]]
                                                       forKeys:@[MemorizeHighestScoreKey, MemorizeSoundPrefKey, MemorizeThemePrefKey, MemorizeFirstLaunch]];
  [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}

+ (NSArray *)avalaibleThemes {
  return @[@"impressionism", @"baroque", @"pop_art"];
}

- (void)setPreferredTheme:(NSString *)preferredTheme {
  _preferredTheme = preferredTheme;
  [JJJGameThemeManager defaultManager].currentTheme = preferredTheme;
}

- (void)changeTheme {
  NSUInteger themeIndex = [[JJJMemorizeGameViewController avalaibleThemes] indexOfObject:self.preferredTheme];
  themeIndex++;
  if (themeIndex == [JJJMemorizeGameViewController avalaibleThemes].count) {
    themeIndex = 0;
  }
  self.preferredTheme = [[JJJMemorizeGameViewController avalaibleThemes] objectAtIndex:themeIndex];
  
  [[NSUserDefaults standardUserDefaults] setObject:self.preferredTheme forKey:MemorizeThemePrefKey];
    //	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSMutableArray *)shareImageViews {
  if (!_shareImageViews) {
    _shareImageViews = [[NSMutableArray alloc] init];
  }
  return _shareImageViews;
}

- (NSMutableArray *)settingImageViews {
  if (!_settingImageViews) {
    _settingImageViews = [[NSMutableArray alloc] init];
  }
  return _settingImageViews;
}

- (void)setHighestScore:(NSInteger)highestScore {
  _highestScore = highestScore;
  
  [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:highestScore]
                                            forKey:MemorizeHighestScoreKey];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

static const CGFloat STANDARD_MARGIN = 16.0;

- (GADInterstitial *)createAndLoadInterstitial {
  GADInterstitial *interstitial = [[GADInterstitial alloc] initWithAdUnitID:ADUnitID];
  interstitial.delegate = self;
  [interstitial loadRequest:[GADRequest request]];
	 
  return interstitial;
}

- (void)interstitialDidDismissScreen:(GADInterstitial *)ad {
  self.interstitial = [self createAndLoadInterstitial];
}

- (void)interstitial:(GADInterstitial *)ad didFailToReceiveAdWithError:(GADRequestError *)error {
  [ad loadRequest:[GADRequest request]];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
//  NSLog(@"%@", [[IAPManager sharedManager] fetchProductIdentifiers]);
  // Do any additional setup after loading the view.
  self.interstitial = [self createAndLoadInterstitial];
  
  if (self.soundON) {
    [self initialiseMusic];
  }
  
    //Initialise and add the share ShareImageView button.
  CGFloat sideLength = self.view.bounds.size.width / 6.0;
  CGRect shareImageFrame = CGRectMake(STANDARD_MARGIN, self.view.bounds.size.height - sideLength - STANDARD_MARGIN, sideLength, sideLength);
  
  _generalShareImageView = [[JJJShareImageView alloc] initWithFrame:shareImageFrame shareType:JJJShareTypeNone];
  self.generalShareImageView.delegate = self;
  [self.view addSubview:self.generalShareImageView];
  
  
    //Initialise and add the setting image button.
  CGRect settingImageFrame = CGRectMake(self.view.bounds.size.width - sideLength - STANDARD_MARGIN, self.view.bounds.size.height - sideLength - STANDARD_MARGIN, sideLength, sideLength);
  _settingImageView = [[JJJShareImageView alloc] initWithFrame:settingImageFrame shareType:JJJShareTypeSetting];
  self.settingImageView.delegate = self;
  [self.view addSubview:self.settingImageView];
  
  
    //Initialise and add the gameContainerView to self.view.
  CGSize size = self.view.bounds.size;
  CGFloat maxSideLength = size.width - STANDARD_MARGIN * 2.0;
  CGRect gameContainerViewFrame;
  
  if ([self deviceIdiomIsiPhoneOriPhone4s]) {
    gameContainerViewFrame = CGRectMake(STANDARD_MARGIN, self.generalShareImageView.frame.origin.y - STANDARD_MARGIN - maxSideLength, maxSideLength, maxSideLength);
  } else {
    gameContainerViewFrame = CGRectMake(STANDARD_MARGIN, (size.height - maxSideLength) / 2.0, maxSideLength, maxSideLength);
  }
  
  _gameContainerView = [[JJJMemorizeGameContainerView alloc] initWithFrame:gameContainerViewFrame];
  self.gameContainerView.delegate = self;
  [self.view insertSubview:self.gameContainerView belowSubview:self.generalShareImageView];
  
  
    //Initailise and add the play image button
  CGRect frame = self.generalShareImageView.frame;
  CGRect playImageFrame = CGRectMake((self.view.bounds.size.width - frame.size.width) / 2.0, frame.origin.y, frame.size.width, frame.size.height);
  _levelControlImageView = [[JJJShareImageView alloc] initWithFrame:playImageFrame shareType:JJJShareTypePlay];
  self.levelControlImageView.delegate = self;
  [self.view addSubview:self.levelControlImageView];
  
  
    //Add the score label
  
  CGRect scoreLabelFrame;
  if ([self deviceIdiomIsiPhoneOriPhone4s]) {
    scoreLabelFrame = CGRectMake(STANDARD_MARGIN, self.gameContainerView.frame.origin.y / 2.0 - 25.0, self.view.bounds.size.width - STANDARD_MARGIN * 2.0, self.gameContainerView.frame.origin.y - STANDARD_MARGIN * 2.0 - 20.0);
  } else {
    scoreLabelFrame = CGRectMake(STANDARD_MARGIN, self.gameContainerView.frame.origin.y / 2.0 - 25.0, self.view.bounds.size.width - STANDARD_MARGIN * 2.0, self.gameContainerView.frame.origin.y - STANDARD_MARGIN * 3.0 - 50.0);
  }
  
  _scoreLabel = [[JJJScoreLabel alloc] initWithFrame:scoreLabelFrame];
  self.scoreLabel.delegate = self;
  self.scoreLabel.fillColor = [[JJJGameThemeManager defaultManager] randomColorWithCurrentTheme];
  
  [self.view addSubview:self.scoreLabel];
  
  self.levelBonus = 0;
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)captureCurrentScreenForSharing{
  UIGraphicsBeginImageContext(self.view.bounds.size);
  [self.view drawViewHierarchyInRect:self.view.bounds
                  afterScreenUpdates:NO];
  self.sharedImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  
  [self captureCurrentScreenForSharing];
  
    //	if (self.soundON) {
    //		[self initialiseMusic];
    //	}
  
  if (self.userFirstLaunch) {
    self.guideTimer = [NSTimer scheduledTimerWithTimeInterval:1.5
                                                       target:self
                                                     selector:@selector(showGuideArrow:)
                                                     userInfo:nil
                                                      repeats:NO];
  }
}

- (void)showGuideArrow:(NSTimer *)timer {
  
  if (self.levelControlImageView.shareType == JJJShareTypePlay) {
    CGRect frame = self.generalShareImageView.frame;
    CGRect baseFrame = CGRectMake((self.view.bounds.size.width - frame.size.width) / 2.0, frame.origin.y, frame.size.width, frame.size.height);
    
    CGRect guideArrowImageFrame = CGRectMake(baseFrame.origin.x, baseFrame.origin.y - baseFrame.size.height, baseFrame.size.width, baseFrame.size.height);
    UIImage *guideImage = [UIImage imageNamed:@"guide_arrow"];
    _guideArrowImageView = [[UIImageView alloc] initWithFrame:guideArrowImageFrame];
    self.guideArrowImageView.image = guideImage;
    self.guideArrowImageView.transform = CGAffineTransformMakeScale(0.0, 0.0);
    
    [self.view addSubview:self.guideArrowImageView];
    
    [UIView animateWithDuration:0.5 animations:^ {
      self.guideArrowImageView.transform = CGAffineTransformMakeScale(1.2, 1.2);
    } completion:^(BOOL finished) {
      [UIView animateKeyframesWithDuration:1.6 delay:0.5 options:UIViewKeyframeAnimationOptionRepeat animations:^ {
        [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.6 animations:^ {
          self.guideArrowImageView.transform = CGAffineTransformMakeScale(0.8, 0.8);
        }];
        [UIView addKeyframeWithRelativeStartTime:0.6 relativeDuration:0.4 animations:^ {
          self.guideArrowImageView.transform = CGAffineTransformMakeScale(1.2, 1.2);
        }];
      } completion:nil];
    }];
  }
}

- (void)playSoundIfSoundSettingIsON {
  if (self.soundON) {
    AudioServicesPlaySystemSound(self.popSound);
  }
}

- (void)shareImageViewDidSelect:(JJJShareImageView *)shareImageView {
    //If the shareImage is the general one
  if (shareImageView.shareType == JJJShareTypeNone) {
    
      //If the setting image views are shown, then hide then
    if (self.settingImageViews.count) {
      [self hideShareImageViews:self.settingImageView];
    }
    
      //Pop up the share image views
    if (!self.shareImageViews.count) {
      CGRect baseFrame = shareImageView.frame;
      for (int i = 0; i < 4; i++) {
        JJJShareImageView *shareView;
        if (i == 0) {
          shareView = [[JJJShareImageView alloc] initWithFrame:baseFrame shareType:JJJShareTypeTwitter];
        } else if (i == 1) {
          shareView = [[JJJShareImageView alloc] initWithFrame:baseFrame shareType:JJJShareTypeWeibo];
        } else if (i == 2) {
          shareView = [[JJJShareImageView alloc] initWithFrame:baseFrame shareType:JJJShareTypeFacebook];
        } else {
          shareView = [[JJJShareImageView alloc] initWithFrame:baseFrame shareType:JJJShareTypeTencentWeibo];
        }
        shareView.delegate = self;
        
        [self.view insertSubview:shareView belowSubview:shareImageView];
        [self.shareImageViews addObject:shareView];
      }
      
      for (int j = 0; j < self.shareImageViews.count; j++) {
        JJJShareImageView *share = [self.shareImageViews objectAtIndex:j];
        [UIView animateWithDuration:0.4 delay:0.0 usingSpringWithDamping:0.4 initialSpringVelocity:0.8 options:UIViewAnimationOptionTransitionNone animations:^ {
          share.frame = CGRectMake(share.frame.origin.x, share.frame.origin.y - (share.frame.size.width + 16.0) * (j + 1), share.frame.size.width, share.frame.size.height);
        } completion:nil];
      }
    } else {
      [self hideShareImageViews:shareImageView];
    }
    
  } else if (shareImageView.shareType == JJJShareTypeSetting) {
      //If the setting icon tapped
    
      //If the share image views are shown, then hide them
    if (self.shareImageViews.count) {
      [self hideShareImageViews:self.generalShareImageView];
    }
    
      //Pop up the setting images including sound and theme
    if (!self.settingImageViews.count) {
      CGRect baseFrame = self.settingImageView.frame;
      for (int i = 0; i < 2; i++) {
        JJJShareImageView *settingView;
        if (i == 0) {
          settingView = [[JJJShareImageView alloc] initWithFrame:baseFrame
                                                       shareType:JJJShareTypeSound];
          settingView.image = [self soundSettingImageForCurrentStatus];
        } else {
          settingView = [[JJJShareImageView alloc] initWithFrame:baseFrame
                                                       shareType:JJJShareTypeTheme];
        }
        settingView.delegate = self;
        
        [self.view insertSubview:settingView belowSubview:shareImageView];
        [self.settingImageViews addObject:settingView];
      }
      
      for (int j = 0; j < 2; j++) {
        JJJShareImageView *setting = [self.settingImageViews objectAtIndex:j];
        [UIView animateWithDuration:0.4 delay:0.0 usingSpringWithDamping:0.4 initialSpringVelocity:0.8 options:UIViewAnimationOptionTransitionNone animations:^ {
          setting.frame = CGRectMake(setting.frame.origin.x, setting.frame.origin.y - (setting.frame.size.width + 16.0) * (j + 1), setting.frame.size.width, setting.frame.size.height);
        } completion:nil];
      }
    } else {
      [self hideShareImageViews:shareImageView];
    }
    
  } else if (shareImageView.shareType == JJJShareTypeReplay) {
      //If the share image views are shown, then hide them
    if (self.shareImageViews.count) {
      [self hideShareImageViews:self.generalShareImageView];
    }
    
      //If the setting image views are shown, then hide them
    if (self.settingImageViews.count) {
      [self hideShareImageViews:self.settingImageView];
    }
    
    if (self.breakRecordImageView) {
      [UIView animateKeyframesWithDuration:0.8 delay:0.0 options:UIViewKeyframeAnimationOptionCalculationModePaced animations:^ {
        [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.6 animations:^ {
          self.breakRecordImageView.transform = CGAffineTransformMakeScale(1.0, 1.2);
        }];
        [UIView addKeyframeWithRelativeStartTime:0.6 relativeDuration:0.4 animations:^ {
          self.breakRecordImageView.transform = CGAffineTransformMakeScale(0.0, 0.0);
        }];
      } completion:^(BOOL finished) {
        [self.breakRecordImageView removeFromSuperview];
        self.breakRecordImageView = nil;
      }];
    }
    
      //If user tapped the replay icon
    [self.gameContainerView restartGame];
    self.levelBonus = 0;
    [UIView transitionWithView:self.scoreLabel duration:0.5 options:UIViewAnimationOptionTransitionFlipFromLeft animations:^ {
      self.scoreLabel.score = 0;
      self.scoreLabel.fillColor = [[JJJGameThemeManager defaultManager] randomColorWithCurrentTheme];
    } completion:nil];
    
    [UIView animateKeyframesWithDuration:0.3 delay:0.0 options:UIViewKeyframeAnimationOptionCalculationModeLinear animations:^ {
      [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.6 animations:^ {
        self.levelControlImageView.transform = CGAffineTransformMakeScale(1.25, 1.25);
      }];
      [UIView addKeyframeWithRelativeStartTime:0.6 relativeDuration:0.4 animations:^ {
        self.levelControlImageView.transform = CGAffineTransformMakeScale(0.0, 0.0);
      }];
    } completion:^(BOOL finished) {
      [self.levelControlImageView removeFromSuperview];
      self.levelControlImageView = nil;
    }];
    
    
    if (self.soundON) {
      [self.musicPlayer stop];
      self.musicPlayer = nil;
      
      [self playGameMusic];
    }
  } else if (shareImageView.shareType == JJJShareTypePlay) {
      //If the share image views are shown, then hide them
    if (self.userFirstLaunch) {
      [self.guideTimer invalidate];
      self.guideTimer = nil;
    }
    
    if (self.guideArrowImageView) {
      [UIView animateWithDuration:0.3 animations:^ {
        self.guideArrowImageView.transform = CGAffineTransformMakeScale(0.0, 0.0);
      } completion:^(BOOL finished) {
        [self.guideArrowImageView removeFromSuperview];
        self.guideArrowImageView = nil;
      }];
    }
    
    if (self.shareImageViews.count) {
      [self hideShareImageViews:self.generalShareImageView];
    }
    
      //If the setting image views are shown, then hide them
    if (self.settingImageViews.count) {
      [self hideShareImageViews:self.settingImageView];
    }
    
    [self.gameContainerView startGame];
    
    [UIView animateKeyframesWithDuration:0.3 delay:0.0 options:UIViewKeyframeAnimationOptionCalculationModeLinear animations:^ {
      [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.6 animations:^ {
        self.levelControlImageView.transform = CGAffineTransformMakeScale(1.25, 1.25);
      }];
      [UIView addKeyframeWithRelativeStartTime:0.6 relativeDuration:0.4 animations:^ {
        self.levelControlImageView.transform = CGAffineTransformMakeScale(0.0, 0.0);
      }];
    } completion:^(BOOL finished) {
      [self.levelControlImageView removeFromSuperview];
      self.levelControlImageView = nil;
    }];
    
    if (self.soundON) {
      [self.musicPlayer stop];
      self.musicPlayer = nil;
      
      [self playGameMusic];
    }
  } else if (shareImageView.shareType == JJJShareTypeTwitter) {
      //If user press the wechat share button
    [self hideShareImageViews:self.generalShareImageView];
    [self shareToTwitter];
  } else if (shareImageView.shareType == JJJShareTypeSound) {
      //If user press the Sound setting button
    [self toggleSoundSetting];
    [UIView transitionWithView:shareImageView duration:0.3 options:UIViewAnimationOptionTransitionFlipFromLeft animations:^ {
      shareImageView.image = [self soundSettingImageForCurrentStatus];
    } completion:nil];
  } else if (shareImageView.shareType == JJJShareTypeTheme) {
      //If user tapped the theme setting button
    [self changeTheme];
    [UIView transitionWithView:shareImageView duration:0.3 options:UIViewAnimationOptionTransitionFlipFromLeft animations:^ {
      shareImageView.image = [[JJJGameThemeManager defaultManager] imageForShareTypeWithCurrentTheme:JJJShareTypeTheme];
    } completion:^(BOOL finished) {
      [self animateToChangeAllUIElementsOfCurrentTheme];
    }];
  } else if (shareImageView.shareType == JJJShareTypeWeibo) {
    [self hideShareImageViews:self.generalShareImageView];
    [self shareToWeibo];
  } else if (shareImageView.shareType == JJJShareTypeFacebook) {
    [self hideShareImageViews:self.generalShareImageView];
    [self shareToFacebook];
  } else if (shareImageView.shareType == JJJShareTypeTencentWeibo) {
    [self hideShareImageViews:self.generalShareImageView];
    [self shareToTencentWeibo];
  }
}

#pragma mark - Share methods

- (void)shareToWeibo {
  if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeSinaWeibo]) {
    SLComposeViewController *weiboSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeSinaWeibo];
    [weiboSheet setInitialText:[NSString stringWithFormat:NSLocalizedString(@"I just created a new RECORD of %li points in this new game! Dare you challenge me?", nil), self.highestScore]];
    [weiboSheet addImage:self.sharedImage];
    [weiboSheet addURL:[NSURL URLWithString:MemorizeShareURLString]];
    
    [self presentViewController:weiboSheet animated:YES completion:nil];
  } else {
    [self alertUserToLoginSocialAccountWithMediaName:NSLocalizedString(@"Weibo", nil)];
  }
}

- (void)shareToFacebook {
  if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]) {
    SLComposeViewController *facebookSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
    [facebookSheet setInitialText:[NSString stringWithFormat:NSLocalizedString(@"I just created a new RECORD of %li points in this new game! Dare you challenge me?", nil), self.highestScore]];
    [facebookSheet addImage:self.sharedImage];
    [facebookSheet addURL:[NSURL URLWithString:MemorizeShareURLString]];
    
    [self presentViewController:facebookSheet animated:YES completion:nil];
  } else {
    [self alertUserToLoginSocialAccountWithMediaName:NSLocalizedString(@"Facebook", nil)];
  }
}

- (void)shareToTencentWeibo {
  if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTencentWeibo]) {
    SLComposeViewController *tencentWeiboSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTencentWeibo];
    [tencentWeiboSheet setInitialText:[NSString stringWithFormat:NSLocalizedString(@"I just created a new RECORD of %li points in this new game! Dare you challenge me?", nil), self.highestScore]];
    [tencentWeiboSheet addImage:self.sharedImage];
    [tencentWeiboSheet addURL:[NSURL URLWithString:MemorizeShareURLString]];
    
    [self presentViewController:tencentWeiboSheet animated:YES completion:nil];
  } else {
    [self alertUserToLoginSocialAccountWithMediaName:NSLocalizedString(@"Tencent Weibo", nil)];
  }
}

- (void)shareToTwitter {
    //	NSLog(@"Share to Twitter");
  if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
    SLComposeViewController *twitterSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
    [twitterSheet setInitialText:[NSString stringWithFormat:NSLocalizedString(@"I just created a new RECORD of %li points in this new game! Dare you challenge me?", nil), self.highestScore]];
    [twitterSheet addImage:self.sharedImage];
    [twitterSheet addURL:[NSURL URLWithString:MemorizeShareURLString]];
    
    [self presentViewController:twitterSheet animated:YES completion:nil];
  } else {
    [self alertUserToLoginSocialAccountWithMediaName:NSLocalizedString(@"Twitter", nil)];
  }
}

- (void)alertUserToLoginSocialAccountWithMediaName:(NSString *)socialName {
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Not Logged In", nil)
                                                                 message:[NSString stringWithFormat:NSLocalizedString(@"Oops! It seems you haven't logged in your %@ account yet, just launch Setting App and enter your %@ username and password to share your achievement", nil), socialName, socialName]
                                                          preferredStyle:UIAlertControllerStyleAlert];
  UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction *action) { }];
  [alert addAction:defaultAction];
  
  [self presentViewController:alert animated:YES completion:nil];
}

- (void)animateToChangeAllUIElementsOfCurrentTheme {
  JJJShareImageView *soundSettingImageView = self.settingImageViews.firstObject;
  [UIView transitionWithView:soundSettingImageView duration:0.5 options:[self randomAnimationOptionsFlipDirection] animations:^ {
    soundSettingImageView.image = [self soundSettingImageForCurrentStatus];
  } completion:nil];
  
  [UIView transitionWithView:self.settingImageView duration:0.5 options:[self randomAnimationOptionsFlipDirection] animations:^ {
    self.settingImageView.image = [[JJJGameThemeManager defaultManager] imageForShareTypeWithCurrentTheme:self.settingImageView.shareType];
  } completion:nil];
  
  [UIView transitionWithView:self.levelControlImageView duration:0.5 options:[self randomAnimationOptionsFlipDirection] animations:^ {
    self.levelControlImageView.image = [[JJJGameThemeManager defaultManager] imageForShareTypeWithCurrentTheme:self.levelControlImageView.shareType];
  } completion:nil];
  
  [UIView transitionWithView:self.generalShareImageView duration:0.5 options:[self randomAnimationOptionsFlipDirection] animations:^ {
    self.generalShareImageView.image = [[JJJGameThemeManager defaultManager] imageForShareTypeWithCurrentTheme:self.generalShareImageView.shareType];
  } completion:nil];
  
  [UIView transitionWithView:self.scoreLabel duration:0.5 options:[self randomAnimationOptionsFlipDirection] animations:^ {
    self.scoreLabel.fillColor = [[JJJGameThemeManager defaultManager] randomColorWithCurrentTheme];
  } completion:nil];
  
  if (self.breakRecordImageView) {
    [UIView transitionWithView:self.breakRecordImageView duration:0.5 options:[self randomAnimationOptionsFlipDirection] animations:^ {
      self.breakRecordImageView.image = [[JJJGameThemeManager defaultManager] imageForShareTypeWithCurrentTheme:self.breakRecordImageView.shareType];
    } completion:nil];
  }
}

- (UIViewAnimationOptions)randomAnimationOptionsFlipDirection {
  NSUInteger index = arc4random_uniform(2);
  if (index == 0) {
    return UIViewAnimationOptionTransitionFlipFromLeft;
  } else {
    return UIViewAnimationOptionTransitionFlipFromRight;
  }
}

- (UIImage *)soundSettingImageForCurrentStatus {
  return self.soundON ? [[JJJGameThemeManager defaultManager] imageForShareTypeWithCurrentTheme:JJJShareTypeSound] : [[JJJGameThemeManager defaultManager] imageForShareTypeWithCurrentTheme:JJJShareTypeNoSound];
}

- (void)toggleSoundSetting {
  if (self.soundON) {
    self.soundON = NO;
    
    [self.musicPlayer stop];
    self.musicPlayer = nil;
  } else {
    self.soundON = YES;
    
    if (self.levelControlImageView.shareType == JJJShareTypePlay) {
      [self initialiseMusic];
      [self.musicPlayer play];
    } else {
      [self playGameMusic];
    }
  }
  
  [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:self.soundON] forKey:MemorizeSoundPrefKey];
    //	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)initialiseMusic {
  NSString *initialMusicPath = [[NSBundle mainBundle] pathForResource:@"initial_music" ofType:@"mp3"];
  
  if (initialMusicPath) {
    NSURL *initialMusicURL = [NSURL fileURLWithPath:initialMusicPath];
    _musicPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:initialMusicURL error:nil];
    self.musicPlayer.numberOfLoops = -1;
  }
}

- (void)playGameMusic {
  
  NSString *backgroundMusicPath = [[NSBundle mainBundle] pathForResource:@"background_music"
                                                                  ofType:@"mp3"];
  
  if (backgroundMusicPath) {
    NSURL *backgroundMusicURL = [NSURL fileURLWithPath:backgroundMusicPath];
    _musicPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:backgroundMusicURL
                                                          error:nil];
    self.musicPlayer.numberOfLoops = -1;
    [self.musicPlayer play];
  }
}

- (BOOL)shouldHandleGameTouchEvent:(JJJMemorizeGameContainerView *)gameContainer {
  if (self.shareImageViews.count) {
    [self hideShareImageViews:self.generalShareImageView];
    return NO;
  } else if (self.settingImageViews.count) {
    [self hideShareImageViews:self.settingImageView];
    return NO;
  }
  return YES;
}

- (void)gameSessionDidEndWithResult:(BOOL)win {
  
  if (win) {
    self.levelBonus += 50;
    
    CGRect frame = self.generalShareImageView.frame;
    CGRect winImageViewFrame = CGRectMake((self.view.bounds.size.width - frame.size.width) / 2.0, frame.origin.y, frame.size.width, frame.size.height);
    
    JJJShareImageView *winImageView = [[JJJShareImageView alloc] initWithFrame:winImageViewFrame];
    winImageView.image = [UIImage imageNamed:[@"win_" stringByAppendingString:self.preferredTheme]];
    winImageView.transform = CGAffineTransformMakeScale(0.0, 0.0);
    _levelControlImageView = winImageView;
    
    [self.view addSubview:winImageView];
    [UIView animateKeyframesWithDuration:0.8 delay:0.0 options:UIViewKeyframeAnimationOptionCalculationModeLinear animations:^ {
      [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.3 animations:^ {
        winImageView.transform = CGAffineTransformMakeScale(1.5, 1.5);
      }];
      [UIView addKeyframeWithRelativeStartTime:0.3 relativeDuration:0.4 animations:^ {
        winImageView.transform = CGAffineTransformMakeScale(0.8, 0.8);
      }];
      [UIView addKeyframeWithRelativeStartTime:0.7 relativeDuration:0.3 animations:^ {
        winImageView.transform = CGAffineTransformMakeScale(1.2, 1.2);
      }];
    } completion:^(BOOL finished) {
      [self.gameContainerView nextLevel];
      
      [UIView transitionWithView:self.scoreLabel duration:0.5 options:UIViewAnimationOptionTransitionFlipFromRight animations:^ {
        self.scoreLabel.score += self.levelBonus;
        self.scoreLabel.fillColor = [[JJJGameThemeManager defaultManager] randomColorWithCurrentTheme];
      } completion:nil];
      
      [UIView animateKeyframesWithDuration:0.3 delay:0.0 options:UIViewKeyframeAnimationOptionCalculationModeLinear animations:^ {
        [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:1.0 animations:^ {
          winImageView.transform = CGAffineTransformMakeScale(0.0, 0.0);
        }];
      } completion:^(BOOL finished) {
        [self.levelControlImageView removeFromSuperview];
        self.levelControlImageView = nil;
      }];
    }];
  } else {
      //If user break the record
    if (self.scoreLabel.score > self.highestScore) {
      self.highestScore = self.scoreLabel.score;
      [self createBreakRecordImageView];
      [self reportScoreToGameCenter];
      
      [UIView animateKeyframesWithDuration:0.8 delay:0.0 options:UIViewKeyframeAnimationOptionCalculationModePaced animations:^ {
        [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.4 animations:^ {
          self.breakRecordImageView.transform = CGAffineTransformMakeScale(1.2, 1.2);
        }];
        [UIView addKeyframeWithRelativeStartTime:0.4 relativeDuration:0.6 animations:^ {
          self.breakRecordImageView.transform = CGAffineTransformMakeScale(1.0, 1.0);
        }];
      } completion:^(BOOL finished) {
        [self captureCurrentScreenForSharing];
        
        [UIView animateKeyframesWithDuration:2.0 delay:0.0 options:UIViewKeyframeAnimationOptionCalculationModePaced animations:^ {
          [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.25 animations:^ {
            self.scoreLabel.scoreLabel.transform = CGAffineTransformMakeScale(1.2, 1.2);
          }];
          [UIView addKeyframeWithRelativeStartTime:0.25 relativeDuration:0.25 animations:^ {
            self.scoreLabel.scoreLabel.transform = CGAffineTransformMakeScale(0.9, 0.9);
          }];
          [UIView addKeyframeWithRelativeStartTime:0.5 relativeDuration:0.25 animations:^ {
            self.scoreLabel.scoreLabel.transform = CGAffineTransformMakeScale(1.2, 1.2);
          }];
          [UIView addKeyframeWithRelativeStartTime:0.75 relativeDuration:0.25 animations:^ {
            self.scoreLabel.scoreLabel.transform = CGAffineTransformMakeScale(1.0, 1.0);
          }];
        } completion:^(BOOL finished) {
          CGRect frame = self.generalShareImageView.frame;
          CGRect replayImageViewFrame = CGRectMake((self.view.bounds.size.width - frame.size.width) / 2.0, frame.origin.y, frame.size.width, frame.size.height);
          JJJShareImageView *replayImageView = [[JJJShareImageView alloc] initWithFrame:replayImageViewFrame
                                                                              shareType:JJJShareTypeReplay];
          replayImageView.delegate = self;
          replayImageView.transform = CGAffineTransformMakeScale(0.0, 0.0);
          _levelControlImageView = replayImageView;
          
          [self.view addSubview:self.levelControlImageView];
          [UIView animateKeyframesWithDuration:0.5 delay:0.0 options:UIViewKeyframeAnimationOptionCalculationModeLinear animations:^ {
            [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.3 animations:^ {
              replayImageView.transform = CGAffineTransformMakeScale(1.5, 1.5);
            }];
            [UIView addKeyframeWithRelativeStartTime:0.3 relativeDuration:0.7 animations:^ {
              replayImageView.transform = CGAffineTransformMakeScale(1.0, 1.0);
            }];
          } completion:nil];
          
          [self.generalShareImageView shake:15
                                  withDelta:8.0
                                   andSpeed:0.05
                             shakeDirection:ShakeDirectionHorizontal completionHandler:^ {
                               [self.generalShareImageView shake:15 withDelta:8.0 andSpeed:0.05 shakeDirection:ShakeDirectionVertical completionHandler:nil];
                             }];
        }];
      }];
    } else {
      CGRect frame = self.generalShareImageView.frame;
      CGRect replayImageViewFrame = CGRectMake((self.view.bounds.size.width - frame.size.width) / 2.0, frame.origin.y, frame.size.width, frame.size.height);
      JJJShareImageView *replayImageView = [[JJJShareImageView alloc] initWithFrame:replayImageViewFrame
                                                                          shareType:JJJShareTypeReplay];
      replayImageView.delegate = self;
      replayImageView.transform = CGAffineTransformMakeScale(0.0, 0.0);
      _levelControlImageView = replayImageView;
      
      [self.view addSubview:self.levelControlImageView];
      [UIView animateKeyframesWithDuration:0.5 delay:0.0 options:UIViewKeyframeAnimationOptionCalculationModeLinear animations:^ {
        [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.3 animations:^ {
          replayImageView.transform = CGAffineTransformMakeScale(1.5, 1.5);
        }];
        [UIView addKeyframeWithRelativeStartTime:0.3 relativeDuration:0.7 animations:^ {
          replayImageView.transform = CGAffineTransformMakeScale(1.0, 1.0);
        }];
      } completion:^(BOOL finished) {
          // TODO: Add ads
        if ([self.interstitial isReady]) {
          [self.interstitial presentFromRootViewController:self];
        }
      }];
    }
  }
}

- (void)reportScoreToGameCenter {
  GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
  if (localPlayer.isAuthenticated) {
    GKScore *scoreReporter = [[GKScore alloc] initWithLeaderboardIdentifier:GKLeaderboardIdentifier];
    scoreReporter.value = self.highestScore;
    scoreReporter.context = 0;
    
    NSArray *scores = @[scoreReporter];
    [GKScore reportScores:scores withCompletionHandler:nil];
  }
}

- (void)createBreakRecordImageView {
  if (self.breakRecordImageView) {
    self.breakRecordImageView = nil;
  }
  
  CGPoint scoreLabelOrigin = self.scoreLabel.frame.origin;
  CGSize scoreLabelSize = self.scoreLabel.frame.size;
  
  CGRect breakRecordImageViewFrame = CGRectMake(scoreLabelOrigin.x, scoreLabelOrigin.y - scoreLabelSize.height / 2.0, scoreLabelSize.height, scoreLabelSize.height);
  
  _breakRecordImageView = [[JJJShareImageView alloc] initWithFrame:breakRecordImageViewFrame
                                                         shareType:JJJShareTypeNewRecord];
  
  self.breakRecordImageView.transform = CGAffineTransformMakeScale(0.0, 0.0);
  [self.view addSubview:self.breakRecordImageView];
}

- (void)hideShareImageViews:(JJJShareImageView *)shareImageView {
  CGRect baseFrame = shareImageView.frame;
  
  if (shareImageView.shareType == JJJShareTypeNone) {
    for (JJJShareImageView *share in self.shareImageViews) {
      [UIView animateWithDuration:0.1 animations:^ {
        share.frame = baseFrame;
      } completion:^(BOOL finished)  {
        [share removeFromSuperview];
        [self.shareImageViews removeObject:share];
      }];
    }
  } else {
    for (JJJShareImageView *setting in self.settingImageViews) {
      [UIView animateWithDuration:0.1 animations:^ {
        setting.frame = baseFrame;
      } completion:^(BOOL finished)  {
        [setting removeFromSuperview];
        [self.settingImageViews removeObject:setting];
      }];
    }
  }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  if (self.shareImageViews.count) {
    [self hideShareImageViews:self.generalShareImageView];
  }
  
  if (self.settingImageViews.count) {
    [self hideShareImageViews:self.settingImageView];
  }
}

- (void)scoreLabelDidInteract:(JJJScoreLabel *)scoreLabel {
  if (self.shareImageViews.count) {
    [self hideShareImageViews:self.generalShareImageView];
  } else if (self.settingImageViews.count) {
    [self hideShareImageViews:self.settingImageView];
  }
}

- (void)applicationDidEnterBackground {
  if (self.soundON) {
    [self.musicPlayer stop];
  }
}

- (void)applicationDidBecomeActive {
  if (self.soundON) {
    [self.musicPlayer play];
  }
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
