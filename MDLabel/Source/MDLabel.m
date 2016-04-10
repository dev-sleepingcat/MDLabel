//
//  MDLabel.m
//  MDLabel
//
//  Created by iNuoXia on 16/4/5.
//  Copyright © 2016年 taobao. All rights reserved.
//

#import "MDLabel.h"
#import "MDImageAttachment.h"
#import <CoreText/CoreText.h>

#define IMAGE_FLAG @"![image]"
#define LEFT_BRACKET @"("
#define RIGHT_BRACKET @")"

static unichar imagePlaceholderChar = 0xFFFC;

static void * kMDLabelContext;

@interface MDLabel ()

@property (nonatomic, strong) NSMutableDictionary *attributes;
@property (nonatomic, strong) NSMutableArray      *attachments;

@property (nonatomic, strong) NSMutableArray *imageRunObjects;

@property (nonatomic, strong) NSMutableAttributedString *attributedText; // 用于最终选择的文本内容，其中image会被0xfffc替换

@property (nonatomic, assign) CTFrameRef ctFrame;

@end

@implementation MDLabel

- (instancetype)init {
    if (self = [super init]) {
        [self defaultConfig];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self defaultConfig];
    }
    return self;
}

- (void)dealloc {
    CFRelease(self.ctFrame);
    [self removeObserver:self forKeyPath:@"font" context:kMDLabelContext];
    [self removeObserver:self forKeyPath:@"text" context:kMDLabelContext];
    [self removeObserver:self forKeyPath:@"kerning" context:kMDLabelContext];
    [self removeObserver:self forKeyPath:@"lineSpace" context:kMDLabelContext];
}

- (void)defaultConfig {
    _textColor = [UIColor blackColor];
    _textAlignment = NSTextAlignmentLeft;
    _font = [UIFont systemFontOfSize:12.f];
    _lineBreakMode = NSLineBreakByWordWrapping;
    _imageKerning = 6.f; 
    
    [self addObserver:self forKeyPath:@"font" options:NSKeyValueObservingOptionNew context:kMDLabelContext];
    [self addObserver:self forKeyPath:@"text" options:NSKeyValueObservingOptionNew context:kMDLabelContext];
    [self addObserver:self forKeyPath:@"kerning" options:NSKeyValueObservingOptionNew context:kMDLabelContext];
    [self addObserver:self forKeyPath:@"lineSpace" options:NSKeyValueObservingOptionNew context:kMDLabelContext];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    // 更新 text size + imagePosition
}

- (void)setText:(NSString *)text {
    if (text.length == 0) {
        return;
    }
    _text = text;
    
    // parse text
    [self parseImages];
}

- (void)parseImages {
    NSMutableAttributedString *mutAttrText = [[NSMutableAttributedString alloc] initWithString:@""];
    NSString *text = self.text;
    while ([text rangeOfString:IMAGE_FLAG].location != NSNotFound) {
        NSInteger location = [text rangeOfString:IMAGE_FLAG].location;
        if (location == text.length - IMAGE_FLAG.length) { // 位于最后
            [mutAttrText appendAttributedString:[[NSAttributedString alloc] initWithString:[text substringToIndex:location + IMAGE_FLAG.length]]];
            break; // 匹配结束了
        }

        // 检测下一个字符是不是左括号, 如果不是，则认为非图片
        NSRange lbPosition = NSMakeRange(location + IMAGE_FLAG.length, 1);
        if (![LEFT_BRACKET isEqualToString:[text substringWithRange:lbPosition]]) {
            [mutAttrText appendAttributedString:[[NSAttributedString alloc] initWithString:[text substringToIndex:lbPosition.location + 1]]];
            text = [text substringFromIndex:lbPosition.location + 1];
            continue;
        }
        
        // 在余下的字符串中匹配右括号，如果右括号没有，则认为非图片
        NSString *substring = [text substringFromIndex:lbPosition.location+1];
        NSInteger rbPosition = [substring rangeOfString:RIGHT_BRACKET].location;
        if (rbPosition == NSNotFound) {
            [mutAttrText appendAttributedString:[[NSAttributedString alloc] initWithString:text]];
            break;
        }
        
        [mutAttrText appendAttributedString:[[NSAttributedString alloc] initWithString:[text substringToIndex:location]]];
        
        // update mutableattributedstring. replace image with 0xfffc
        NSString *imageText = [text substringWithRange:NSMakeRange(location + IMAGE_FLAG.length + 1, rbPosition)];
        MDImageAttachment *imageAttachment = [self generateImageAttachementWithText:imageText];
        if (imageAttachment == nil) {
            text = [text substringFromIndex:location + IMAGE_FLAG.length + rbPosition + 1];
            [mutAttrText appendAttributedString:[[NSAttributedString alloc] initWithString:[text substringToIndex:location + IMAGE_FLAG.length + rbPosition]]];
            continue;
        }
        
        imageAttachment.imagePosition = mutAttrText.length;
        imageAttachment.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, imageAttachment.imageWidth, imageAttachment.imageHeight)];
        imageAttachment.imageView.backgroundColor = [UIColor redColor];
        [self addSubview:imageAttachment.imageView];
        
        // 添加图片占位符
        NSString *objText = [NSString stringWithCharacters:&imagePlaceholderChar length:1];
        NSMutableAttributedString *placeholderText = [[NSMutableAttributedString alloc] initWithString:objText];
        
        CTRunDelegateCallbacks callbacks;
        memset(&callbacks, 0, sizeof(CTRunDelegateCallbacks));
        callbacks.version = kCTRunDelegateVersion1;
        callbacks.getAscent = ascentCallback;
        callbacks.getDescent = descentCallback;
        callbacks.getWidth = widthCallback;
        
        CTRunDelegateRef delegate = CTRunDelegateCreate(&callbacks, (__bridge void *)imageAttachment);
    
        [placeholderText setAttributes:@{(__bridge NSString *)kCTRunDelegateAttributeName:(__bridge id)delegate} range:NSMakeRange(0, 1)];
        
        MDImageRunObject *runObj = [[MDImageRunObject alloc] init];
        runObj.position = mutAttrText.length;
        runObj.attributes = @{(__bridge NSString *)kCTRunDelegateAttributeName:(__bridge id)delegate};
        [self.imageRunObjects addObject:runObj];
        
        CFRelease(delegate);
        
        [mutAttrText appendAttributedString:placeholderText];
        
        [self.attachments addObject:imageAttachment];
        
        text = [text substringFromIndex:location + IMAGE_FLAG.length + lbPosition.length + rbPosition + 1];
    }
    if (mutAttrText.length > 0) {
        self.attributedText = mutAttrText;
    } else {
        self.attributedText = [[NSMutableAttributedString alloc] initWithString:self.text];
    }
}

/*!
 *  @brief pattern: ![image](http://image.com.cn/xxx width=xx height=xx)
 *
 *  @param text imageText
 *
 *  @return MDLabelImageAttachment
 */
- (MDImageAttachment *)generateImageAttachementWithText:(NSString *)text {
    
    if (text.length == 0) {
        return  nil;
    }
    
    NSString *substring = [[text copy] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]; // 去除两边的空格
    if (substring.length == 0) {
        return nil;
    }
    
    MDImageAttachment *imageAttachment = [[MDImageAttachment alloc] init];
    
    NSInteger location = [substring rangeOfString:@" "].location;
    if (location == NSNotFound) {
        imageAttachment.imageUrl = substring;
    } else {
        imageAttachment.imageUrl = [substring substringToIndex:location];
        
        CGFloat width = [self extractImageSizeFromString:[substring substringFromIndex:location + 1] withKey:@"width"];
        if (width > 0) {
            imageAttachment.imageWidth = width;
        }
        CGFloat height = [self extractImageSizeFromString:[substring substringFromIndex:location + 1] withKey:@"height"];
        if (height > 0.f) {
            imageAttachment.imageHeight = height;
        }
    }
    
    return imageAttachment;
}

// 根据关键字(width or height)，提取图片的尺寸
- (CGFloat)extractImageSizeFromString:(NSString *)string withKey:(NSString *)key {
    
    if (key.length == 0) {
        return 0.f;
    }
    
    key = [key stringByAppendingString:@"="]; // update key
    
    NSInteger location = [string rangeOfString:key].location;
    if (location != NSNotFound && location < string.length - 1) {
        NSInteger tempLoc = [[string substringFromIndex:location + 1] rangeOfString:@" "].location;
        NSString *floatStr = nil;
        if (tempLoc == NSNotFound) {
            floatStr = [string substringFromIndex:location + key.length];
        } else {
            floatStr = [string substringWithRange:NSMakeRange(location + key.length, tempLoc - key.length - location + 1)];
        }
        return [floatStr floatValue];
    }
    return 0.f;
}

static CGFloat ascentCallback(void *ref) {
    MDImageAttachment *attachment = (__bridge MDImageAttachment *)ref;
    if (attachment) {
        return attachment.imageHeight;
    }
    return 0.f;
}

static CGFloat descentCallback(void *ref) {
    return 0.f;
}

static CGFloat widthCallback(void *ref) {
    MDImageAttachment *attachment = (__bridge MDImageAttachment *)ref;
    if (attachment) {
        return attachment.imageWidth;
    }
    return 0.f;
}

#pragma mark -
#pragma mark Setter and Getter

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    [super setBackgroundColor:backgroundColor];
    self.attributes[NSBackgroundColorAttributeName] = backgroundColor;
}

- (void)setFont:(UIFont *)font {
    _font = font;
    self.attributes[NSFontAttributeName] = font;
}

- (void)setTextAlignment:(NSTextAlignment)textAlignment {
    _textAlignment = textAlignment;
    [self mutableParagraphStyle].alignment = textAlignment;
}

- (void)setTextColor:(UIColor *)textColor {
    _textColor = textColor;
    self.attributes[NSForegroundColorAttributeName] = textColor;
}

- (void)setLineSpace:(CGFloat)lineSpace {
    _lineSpace = lineSpace;
    [self mutableParagraphStyle].lineSpacing = lineSpace;
}

- (void)setKerning:(CGFloat)kerning {
    _kerning = kerning;
    self.attributes[NSKernAttributeName] = @(kerning);
}

- (void)setLineBreakMode:(NSLineBreakMode)lineBreakMode {
    _lineBreakMode = lineBreakMode;
    [self mutableParagraphStyle].lineBreakMode = lineBreakMode;
}

#pragma mark -
#pragma mark Helper Function

- (NSMutableParagraphStyle *)mutableParagraphStyle {
    NSMutableParagraphStyle *style = self.attributes[NSParagraphStyleAttributeName];
    if (!style) {
        style = [[NSMutableParagraphStyle alloc] init];
        self.attributes[NSParagraphStyleAttributeName] = style;
    }
    return style;
}

- (NSMutableDictionary *)attributes {
    if (!_attributes) {
        _attributes = [[NSMutableDictionary alloc] init];
    }
    return _attributes;
}

- (NSMutableArray *)attachments {
    if (!_attachments) {
        _attachments = [[NSMutableArray alloc] init];
    }
    return _attachments;
}

- (NSMutableArray *)imageRunObjects {
    if (!_imageRunObjects) {
        _imageRunObjects = [[NSMutableArray alloc] init];
    }
    return _imageRunObjects;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
//    if (self.attachments.count == 0) {
//        return;
//    }
    
    [self.attributedText setAttributes:self.attributes range:NSMakeRange(0, self.attributedText.length)];
    
    for (MDImageRunObject *runObj in self.imageRunObjects) {
        [self.attributedText addAttributes:runObj.attributes range:NSMakeRange(runObj.position, 1)];
    }
    self.ctFrame = [self ctFrameWithAttributeText:self.attributedText];
    
    CGPathRef path = CTFrameGetPath(self.ctFrame);
    CGRect rect = CGPathGetBoundingBox(path);
    CGFloat textOriginX = 0.f;
    if (self.textAlignment == NSTextAlignmentCenter) {
        textOriginX = (self.bounds.size.width - rect.size.width)/2;
    } else if (self.textAlignment == NSTextAlignmentRight) {
        textOriginX = self.bounds.size.width - rect.size.width;
    }
    
    CFArrayRef lines = CTFrameGetLines(self.ctFrame);
    CFIndex lineCount = CFArrayGetCount(lines);
    CGPoint lineOrigins[lineCount];
    CTFrameGetLineOrigins(self.ctFrame, CFRangeMake(0, 0), lineOrigins);
    NSInteger numberOfLines = lineCount; // TODO custom lines
    for (CFIndex i = 0; i < numberOfLines; i ++) {
        CTLineRef line = CFArrayGetValueAtIndex(lines, i);
        CFArrayRef runs = CTLineGetGlyphRuns(line);
        CFIndex runCount = CFArrayGetCount(runs);
        
        CGPoint lineOrigin = lineOrigins[i];
        
        // Iterate through each of the "runs" (i.e. a chunk of text) and find the runs that
        // intersect with the range.
        for (CFIndex j = 0; j < runCount; j ++) {
            CTRunRef run = CFArrayGetValueAtIndex(runs, j);
            NSDictionary *runAttributes = (NSDictionary *)CTRunGetAttributes(run);
            CTRunDelegateRef delegate = (__bridge CTRunDelegateRef)[runAttributes valueForKey:(id)kCTRunDelegateAttributeName];
            
            if (nil == delegate) {
                continue;
            }
            
            MDImageAttachment *imageAttachment = (MDImageAttachment *)CTRunDelegateGetRefCon(delegate);
            CGFloat xOffset = CTLineGetOffsetForStringIndex(line, CTRunGetStringRange(run).location, nil);
            
            CGFloat imageOriginY = lineOrigin.y;
            CGFloat imageOriginX = textOriginX + lineOrigin.x + xOffset;
            
            imageAttachment.imageView.frame =CGRectMake(imageOriginX, imageOriginY, imageAttachment.imageWidth, imageAttachment.imageHeight);
        }
    }
}

- (CTFrameRef)ctFrameWithAttributeText:(NSAttributedString *)text {
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)text);
    // 获得要绘制的区域的高度
    CGSize restrictSize = CGSizeMake(self.bounds.size.width, CGFLOAT_MAX);
    CGSize size = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0,0), nil, restrictSize, nil);
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, CGRectMake(0, 0, size.width, size.height));
    
    CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, NULL);
    CFRelease(path);
    return frame;
}

#pragma mark -
#pragma mark 

- (void)drawRect:(CGRect)rect {
    //[super drawRect:rect];
    
    // step 1: 得到当前画布，用于后续将内容绘制到画布上
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // setp 2: 将坐标系上下翻转，对于底层绘制引擎而言，(0,0)位于左下角，而对于上层UIKit而言, (0,0)位于左上角
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CGContextTranslateCTM(context, 0, self.bounds.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    // step 3: 创建绘制区域
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, self.bounds);
    
    // step 4: 构造 CTFrame
//    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
//    style.alignment = NSTextAlignmentCenter;
//    NSDictionary *attributes = @{
//                                 NSFontAttributeName:[UIFont systemFontOfSize:11.f],
//                                 NSForegroundColorAttributeName: [UIColor blackColor],
//                                 NSParagraphStyleAttributeName: style,
//                                 };
    
//    [attributedString enumerateAttributesInRange:NSMakeRange(0, attributedString.length) options:NSAttributedStringEnumerationReverse usingBlock:^(NSDictionary<NSString *,id> * _Nonnull attrs, NSRange range, BOOL * _Nonnull stop) {
//        NSLog(@"Attributes: %@", attrs);
//        
//        *stop = YES;
//    }];
    
//    CGSize size = [attributedString boundingRectWithSize:self.bounds.size options:NSStringDrawingUsesLineFragmentOrigin context:nil].size;
//    NSLog(@"String size:(%f, %f)", size.width, size.height);
    
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)self.attributedText);
    CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, self.attributedText.length), path, NULL);
    
    CFRange fitRange;
    // Maybe: size.height = round(ascent) + round(descent)
    CGSize size = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, self.attributedText.length), NULL, CGSizeMake(self.bounds.size.width, 10000), &fitRange);
    NSLog(@"suggestion size:{%f, %f}", size.width, size.height);
    
    NSArray *lines = (NSArray *)CTFrameGetLines(frame);
    for (CFIndex i = 0; i < lines.count; i ++) {
        CTLineRef line = (__bridge CTLineRef)[lines objectAtIndex:i];
        
        CGFloat ascent, descent, leading;
        CGFloat lineWidth = CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
        NSLog(@"Line %li:(ascent:%f, descent:%f, leading:%f, width:%f)", i, ascent, descent,leading, lineWidth);
    }
    
    // step 5: 绘制 CTFrame
    CTFrameDraw(frame, context);
    
    // step 6: 释放资源
    CFRelease(frame);
    CFRelease(framesetter);
    CFRelease(path);
}

@end
