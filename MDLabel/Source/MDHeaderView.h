//
//  MDHeaderView.h
//  MDLabel
//
//  Created by iNuoXia on 16/4/5.
//  Copyright © 2016年 taobao. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MDHeaderView : UIView

@property (nonatomic, strong) dispatch_block_t writeBlock;
@property (nonatomic, strong) dispatch_block_t previewBlock;
@property (nonatomic, strong) dispatch_block_t fullscreenBlock;

@end
