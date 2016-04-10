//
//  MDHeaderView.m
//  MDLabel
//
//  Created by iNuoXia on 16/4/5.
//  Copyright © 2016年 taobao. All rights reserved.
//

#import "MDHeaderView.h"

@interface MDHeaderView () {
    NSInteger _state; // 0 : write; 1: preview; 2: fullscreen
}

@property (nonatomic, strong) UIButton *writeBtn;
@property (nonatomic, strong) UIButton *previewBtn;

@property (nonatomic, strong) UIButton *fullscreenBtn;

@property (nonatomic, strong) UIView *selectedLine;

@end

@implementation MDHeaderView

- (instancetype)init {
    if (self = [super init]) {
        self.frame = CGRectMake(0.f, 20.f, [UIScreen mainScreen].bounds.size.width, 44.f);
        [self setupView];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame: frame]) {
        [self setupView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect rect = self.fullscreenBtn.frame;
    rect.origin.x = self.bounds.size.width - rect.size.width;
    self.fullscreenBtn.frame = rect;
    
    NSLog(@"rect:{%f, %f, %f, %f}", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
    
    rect = CGRectMake(0, 0, 0, 2.f);
    if (_state == 0) {
        rect.origin.x = self.writeBtn.frame.origin.x;
        rect.origin.y = self.writeBtn.frame.origin.y + self.writeBtn.frame.size.height - 2.f;
        rect.size.width = self.writeBtn.frame.size.width;
    } else if (_state == 1) {
        rect.origin.x = self.previewBtn.frame.origin.x;
        rect.origin.y = self.previewBtn.frame.origin.y + self.writeBtn.frame.size.height - 2.f;
        rect.size.width = self.previewBtn.frame.size.width;
    } else {
        rect.origin.x = self.fullscreenBtn.frame.origin.x;
        rect.origin.y = self.fullscreenBtn.frame.origin.y + self.writeBtn.frame.size.height - 2.f;
        rect.size.width = self.fullscreenBtn.frame.size.width;
    }
    self.selectedLine.frame = rect;
}

- (void)setupView {
    _state = 0;
    
    [self addSubview:self.writeBtn];
    [self addSubview:self.previewBtn];
    [self addSubview:self.fullscreenBtn];
    [self addSubview:self.selectedLine];
    
    CALayer *layer = [CALayer layer];
    layer.backgroundColor = [UIColor lightGrayColor].CGColor;
    layer.frame = CGRectMake(0, 44.f - 1.f, self.frame.size.width, 1.f);
    [self.layer addSublayer:layer];
}

- (UIButton *)writeBtn {
    if (!_writeBtn) {
        _writeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _writeBtn.frame = CGRectMake(0.f, 0.f, 64.f, 44.f);
        _writeBtn.backgroundColor = self.backgroundColor;
        _writeBtn.titleLabel.font = [UIFont systemFontOfSize:14.f];
        _writeBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
        [_writeBtn setTitle:@"Write" forState:UIControlStateNormal];
        [_writeBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_writeBtn addTarget:self action:@selector(clicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _writeBtn;
}

- (UIButton *)previewBtn {
    if (!_previewBtn) {
        _previewBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _previewBtn.frame = CGRectMake(64.f, 0.f, 64.f, 44.f);
        _previewBtn.backgroundColor = self.backgroundColor;
        _previewBtn.titleLabel.font = [UIFont systemFontOfSize:14.f];
        _previewBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
        [_previewBtn setTitle:@"Preview" forState:UIControlStateNormal];
        [_previewBtn setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
        [_previewBtn addTarget:self action:@selector(clicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _previewBtn;
}

- (UIButton *)fullscreenBtn {
    if (!_fullscreenBtn) {
        _fullscreenBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _fullscreenBtn.frame = CGRectMake(self.bounds.size.width - 200.f, 0.f, 200.f, 44.f);
        _fullscreenBtn.backgroundColor = self.backgroundColor;
        _fullscreenBtn.titleLabel.font = [UIFont systemFontOfSize:14.f];
        _fullscreenBtn.titleLabel.textAlignment = NSTextAlignmentRight;
        [_fullscreenBtn setTitle:@"Edit in fullscreen" forState:UIControlStateNormal];
        [_fullscreenBtn setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
        [_fullscreenBtn addTarget:self action:@selector(clicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _fullscreenBtn;
}

- (UIView *)selectedLine {
    if (!_selectedLine) {
        _selectedLine = [[UIView alloc] initWithFrame:CGRectZero];
        _selectedLine.backgroundColor = [UIColor blueColor];
    }
    return _selectedLine;
}

- (void)clicked:(UIControl *)sender {
    if (sender == self.writeBtn) {
        if (_state == 0) {
            return;
        } else {
            _state = 0;
        }
        [self setNeedsLayout];
        if (self.writeBlock) {
            self.writeBlock ();
        }
    } else if (sender == self.previewBtn) {
        if (_state == 1) {
            return;
        } else {
            _state = 1;
        }
        [self setNeedsLayout];
        if (self.previewBlock) {
            self.previewBlock ();
        }
    } else if (sender == self.fullscreenBtn) {
        if (_state == 2) {
            return;
        } else {
            _state = 2;
        }
        [self setNeedsLayout];
        if (self.fullscreenBlock) {
            self.fullscreenBlock ();
        }
    }
}

@end
