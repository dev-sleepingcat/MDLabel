//
//  MDLabel.h
//  MDLabel
//
//  Created by iNuoXia on 16/4/5.
//  Copyright © 2016年 taobao. All rights reserved.
//

/*
    ![image](http://image.com width=xx height=xx) 高度和宽度可选。不填采用默认值。
    [link](http://h5.taobao.com)
 */

#import <UIKit/UIKit.h>

@interface MDLabel : UIView

@property (nonatomic, strong) UIFont *font;
@property (nonatomic, assign) NSTextAlignment textAlignment;
@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic, copy)   NSString *text;
@property (nonatomic, assign) NSLineBreakMode lineBreakMode;

@property (nonatomic, assign) CGFloat lineSpace; // 行间距.默认系统默认值
@property (nonatomic, assign) CGFloat kerning;   // 字与字之间的间距. 默认系统默认值

@property (nonatomic, assign) CGFloat imageKerning; // 图片和文字之间的间距。默认 6.0f

@end
