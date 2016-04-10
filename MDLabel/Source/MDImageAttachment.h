//
//  MDImageAttachment.h
//  MDLabel
//
//  Created by iNuoXia on 16/4/7.
//  Copyright © 2016年 taobao. All rights reserved.
//

#import <UIKit/UIKit.h>

#define IMAGE_DEFAULT_WIDTH 100
#define IMAGE_DEFAULT_HEIGHT 100

@interface MDImageAttachment : NSObject

@property (nonatomic, strong) UIImage *image;

@property (nonatomic, copy) NSString *imageUrl;
@property (nonatomic, assign) CGFloat imageWidth;
@property (nonatomic, assign) CGFloat imageHeight;
@property (nonatomic, assign) CGFloat imageKerning; // 图片和文字之间的间距。默认 6.0f (暂不支持)

@property (nonatomic, assign) NSInteger imagePosition; // 图片在字符串中的位置

@property (nonatomic, strong) UIImageView *imageView;

@end

@interface MDImageRunObject : NSObject

@property (nonatomic, assign) NSInteger position;
@property (nonatomic, strong) NSDictionary *attributes;

@end
