//
//  YQDownloadButton.m
//  YQDownloadButton
//
//  Created by yingqiu huang on 2017/2/7.
//  Copyright © 2017年 yingqiu huang. All rights reserved.
//

#import "YQDownloadButton.h"
#import "UIView+YQBorderPath.h"
#import "YQStartButton.h"

@interface YQDownloadButton() <StartButtonDelegate>
{
    CGFloat _wave_offsety;//根据进度计算(波峰所在位置的y坐标)
    CGFloat _offsety_scale;//上升的速度
    CGFloat _wave_move_width;//移动的距离，配合速率设置
    CGFloat _wave_offsetx;//偏移,animation
    CADisplayLink *_waveDisplaylink;
}
@property (nonatomic, strong) YQStartButton *startButton;
@property (nonatomic, strong) UIView *vibrationWaveView;
@end

@implementation YQDownloadButton

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor whiteColor];
        [self addSubview: self.vibrationWaveView];
        [self addSubview: self.startButton];
        [self initView];
    }
    return self;
}

#pragma mark - initView
- (void)initView {
    
    _wave_Amplitude = self.frame.size.height/20;
    _wave_Cycle = 2*M_PI/(self.frame.size.width * .9);
    
    _wave_h_distance = 2*M_PI/_wave_Cycle * .65;
    _wave_v_distance = _wave_Amplitude * .2;
    
    _wave_move_width = 0.5;
    
    _wave_scale = 0.5;
    
    _offsety_scale = 0.01;
    
    _topColor = [UIColor colorWithRed:79/255.0 green:240/255.0 blue:255/255.0 alpha:1];
    _bottomColor = [UIColor colorWithRed:79/255.0 green:240/255.0 blue:255/255.0 alpha:.3];
    
    _progress_animation = YES;
    _wave_offsety = (1-_progress) * (self.frame.size.height + 2* _wave_Amplitude);
    
    CGRect rect = self.frame;
    
    rect.size.height = rect.size.width;
    
    self.borderPath = [UIView circlePathRect:rect lineWidth:0];
    self.border_fillColor = [UIColor groupTableViewBackgroundColor];
    [self startWave];
}

#pragma mark - 代理方法，开始波浪动画
- (void)startDownload{
    [self setProgress:1.0];
}


#pragma mark - drawRect
- (void)drawRect:(CGRect)rect {
    if (_borderPath) {
        if (_border_fillColor) {
            [_border_fillColor setFill];
            [_borderPath fill];
        }
        
        if (_border_strokeColor) {
            [_border_strokeColor setStroke];
            [_borderPath stroke];
        }
        
        [_borderPath addClip];
    }
    [self drawWaveColor:_topColor offsetx:0 offsety:0];
    [self drawWaveColor:_bottomColor offsetx:_wave_h_distance offsety:_wave_v_distance];
    
}

#pragma mark - draw wave
- (void)drawWaveColor:(UIColor *)color offsetx:(CGFloat)offsetx offsety:(CGFloat)offsety {
    //波浪动画，所以进度的实际操作范围是，多加上两个振幅的高度,到达设置进度的位置y坐标
    CGFloat end_offY = (1-_progress) * (self.frame.size.height + 2* _wave_Amplitude);
    if (_progress_animation) {
        if (_wave_offsety != end_offY) {
            if (end_offY < _wave_offsety) {//上升
                _wave_offsety = MAX(_wave_offsety-=(_wave_offsety - end_offY)*_offsety_scale, end_offY);
            } else {
                _wave_offsety = MIN(_wave_offsety+=(end_offY-_wave_offsety)*_offsety_scale, end_offY);
            }
        }
    } else {
        _wave_offsety = end_offY;
    }
    
    UIBezierPath *wave = [UIBezierPath bezierPath];
    for (float next_x= 0.f; next_x <= self.frame.size.width; next_x ++) {
        //正弦函数
        CGFloat next_y = _wave_Amplitude * sin(_wave_Cycle*next_x + _wave_offsetx + offsetx/self.bounds.size.width*2*M_PI) + _wave_offsety + offsety;
        if (next_x == 0) {
            [wave moveToPoint:CGPointMake(next_x, next_y - _wave_Amplitude)];
        } else {
            [wave addLineToPoint:CGPointMake(next_x, next_y - _wave_Amplitude)];
        }
    }
    [wave addLineToPoint:CGPointMake(self.frame.size.width, self.frame.size.height)];
    [wave addLineToPoint:CGPointMake(0, self.bounds.size.height)];
    [color set];
    [wave fill];
}

#pragma mark - 打钩动画
-(void)checkAnimation{
    
    CAShapeLayer *checkLayer = [CAShapeLayer layer];
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    CGRect rectInCircle = CGRectInset(self.bounds, self.bounds.size.width*(1-1/sqrt(2.0))/2, self.bounds.size.width*(1-1/sqrt(2.0))/2);
    [path moveToPoint:CGPointMake(rectInCircle.origin.x + rectInCircle.size.width/9, rectInCircle.origin.y + rectInCircle.size.height*2/3)];
    [path addLineToPoint:CGPointMake(rectInCircle.origin.x + rectInCircle.size.width/3,rectInCircle.origin.y + rectInCircle.size.height*9/10)];
    [path addLineToPoint:CGPointMake(rectInCircle.origin.x + rectInCircle.size.width*8/10, rectInCircle.origin.y + rectInCircle.size.height*2/10)];
    
    checkLayer.path = path.CGPath;
    checkLayer.fillColor = [UIColor clearColor].CGColor;
    checkLayer.strokeColor = [UIColor whiteColor].CGColor;
    checkLayer.lineWidth = 10.0;
    checkLayer.lineCap = kCALineCapRound;
    checkLayer.lineJoin = kCALineJoinRound;
    [self.layer addSublayer:checkLayer];
    
    CABasicAnimation *checkAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    checkAnimation.duration = 0.3f;
    checkAnimation.fromValue = @(0.0f);
    checkAnimation.toValue = @(1.0f);
    checkAnimation.delegate = self;
    [checkAnimation setValue:@"checkAnimation" forKey:@"animationName"];
    [checkLayer addAnimation:checkAnimation forKey:nil];
    
}

#pragma mark - 结束动画
- (void)endAnimation {
    
    self.layer.borderColor = [UIColor clearColor].CGColor;
    _vibrationWaveView.backgroundColor = [UIColor colorWithRed:79/255.0 green:240/255.0 blue:255/255.0 alpha:1];;
    _vibrationWaveView.transform = CGAffineTransformMakeScale(.9, .9);
    [UIView animateWithDuration: .9
                          delay: 1.2
                        options: UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         _vibrationWaveView.transform = CGAffineTransformMakeScale(.9, .9);
                         
                     }
                     completion:^(BOOL finished) {
                         [UIView animateWithDuration: 2.1
                                          animations:^{
                                              _vibrationWaveView.transform = CGAffineTransformMakeScale(3, 3);
                                              _vibrationWaveView.alpha = 0;
                                          }
                                          completion:^(BOOL finished) {
                                              [_vibrationWaveView removeFromSuperview];
                                          }];
                         
                         [UIView animateWithDuration: 1.f
                                               delay: 0.2
                              usingSpringWithDamping: 0.4
                               initialSpringVelocity: 0
                                             options: UIViewAnimationOptionCurveEaseInOut
                                          animations:^{
                                              self.transform = CGAffineTransformMakeScale(1.8, 1.8);
                                              self.transform = CGAffineTransformMakeScale(1.0, 1.0);
                                          }
                                          completion:^(BOOL finished) {
                                              
                                          }];
                     }];
    
    
}

#pragma mark - animation
- (void)changeoff {
    _wave_offsetx += _wave_move_width*_wave_scale;
    [self setNeedsDisplay];
    
    if (_wave_offsety < 5.0) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            [self checkAnimation];
            [self endAnimation];
            NSLog(@"finish");
        });
    }
}

#pragma mark - reStart
- (void)startWave {
    
    if (!_waveDisplaylink) {
        _waveDisplaylink = [CADisplayLink displayLinkWithTarget:self selector:@selector(changeoff)];
        [_waveDisplaylink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    }
}

- (void)dealloc {
    if (_waveDisplaylink) {
        [_waveDisplaylink invalidate];
        _waveDisplaylink = nil;
    }
    
}

#pragma mark - 懒加载
- (UIView *)vibrationWaveView {
    if (!_vibrationWaveView) {
        _vibrationWaveView = [[UIView alloc] initWithFrame: self.frame];
        _vibrationWaveView.center = self.center;
        _vibrationWaveView.backgroundColor = [UIColor clearColor];
        _vibrationWaveView.alpha = 0.4f;
        _vibrationWaveView.layer.cornerRadius = _vibrationWaveView.frame.size.width / 2.f;
    }
    return _vibrationWaveView;
}

- (YQStartButton *)startButton {
    if (!_startButton) {
        _startButton = [[YQStartButton alloc] initWithFrame:self.frame];
        _startButton.backgroundColor = [UIColor clearColor];
        _startButton.delegate = self;
    }
    return _startButton;
}

@end
