//
//  BLHud.h
//  EggSaves
//
//  Created by 郭洪军 on 6/1/16.
//  Copyright © 2016 郭洪军. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BLHud : UIView

@property (nonatomic, strong) UIColor* hudColor;

- (void)showAnimated:(BOOL)animated;
- (void)hide;

@end
