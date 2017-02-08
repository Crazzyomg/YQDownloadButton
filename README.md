# YQDownloadButton
这是一个带有波浪效果和震动波效果的动画

## 效果图

![](./screencast.gif)

动画主要有水波动画、振动波动画组成，具体实现可以看源码
动画主要有水波动画、振动波动画组成，以下分析主要实现，具体实现可以看源码，源码地址在文章最后
## 波浪效果实现
参考网上示例，主要有三种方式：

1. 切一张波浪形的图片，进行不断循环的位置变化的动画
2. 通过CAShapeLayer绘制波浪曲线，并不断改变垂直位置，来达到水面波动并上升的动画效果
3. 同时绘制两个波形图，让它们彼此错开，下层的波形图层设置一定的透明度，两层水波交替波动时就达到波浪的视觉效果

我这里采取了第三种方法，利用两层水波交替波动达到波浪效果
**实现代码**

```
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
    //同时绘制两个波形图
    [self drawWaveColor:_topColor offsetx:0 offsety:0];
    [self drawWaveColor:_bottomColor offsetx:_wave_h_distance offsety:_wave_v_distance];
    
}


#pragma mark - draw wave
- (void)drawWaveColor:(UIColor *)color offsetx:(CGFloat)offsetx offsety:(CGFloat)offsety {
    //波浪动画，所以进度的实际操作范围是，多加上两个振幅的高度,到达设置进度的位置y坐标
    CGFloat end_offY = (1-_progress) * (self.frame.size.height + 2* _wave_Amplitude);
        if (_wave_offsety != end_offY) {
            if (end_offY < _wave_offsety) {//上升
                _wave_offsety = MAX(_wave_offsety-=(_wave_offsety - end_offY)*_offsety_scale, end_offY);
            } else {
                _wave_offsety = MIN(_wave_offsety+=(end_offY-_wave_offsety)*_offsety_scale, end_offY);
            }
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

```

前面if语句的代码可以使得`progress`为1.0后,水波上升不是立即上升，而是通过一个动画缓慢上升；后面代码通过正弦曲线公式y=Asin(ωx+φ)+k，绘制在每个时刻的波形图以达到水波动画的效果。

- _wave_Amplitude，波纹振幅，A

- _wave_Cycle，波纹周期，T = 2π/ω

- offsetX，波浪x位移，φ

- _wave_offsety，当前波浪偏移高度，k


## 震动波效果
震动效果先是让整体是如图变小，然后瞬间变大并带有弹簧效果，同时让震动波视图逐渐变大，并修改其alpha值，所有效果都可以通过UIView Animation来实现

**实现代码**

```
#pragma mark - 结束动画
- (void)endAnimation {
    
    self.layer.borderColor = [UIColor clearColor].CGColor;
    _vibrationWaveView.backgroundColor = [UIColor colorWithRed:79/255.0 green:240/255.0 blue:255/255.0 alpha:1];
    // 为了不影响缩小后的效果，提前将振动波视图缩小
    _vibrationWaveView.transform = CGAffineTransformMakeScale(.9, .9);
    // 视图缩小动画
    [UIView animateWithDuration: .9
                          delay: 1.2
                        options: UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         _vibrationWaveView.transform = CGAffineTransformMakeScale(.9, .9);
                         
                     }
                     completion:^(BOOL finished) {
                         // 震动波效果
                         [UIView animateWithDuration: 2.1
                                          animations:^{
                                              _vibrationWaveView.transform = CGAffineTransformMakeScale(3, 3);
                                              _vibrationWaveView.alpha = 0;
                                          }
                                          completion:^(BOOL finished) {
                                              [_vibrationWaveView removeFromSuperview];
                                          }];
                         //弹簧震动效果
                         [UIView animateWithDuration: 1.f
                                               delay: 0.2
                              usingSpringWithDamping: 0.4
                               initialSpringVelocity: 0
                                             options: UIViewAnimationOptionCurveEaseInOut
                                          animations:^{
                                              // 视图瞬间增大一倍
                                              self.transform = CGAffineTransformMakeScale(1.8, 1.8);
                                              self.transform = CGAffineTransformMakeScale(1.0, 1.0);
                                          }
                                          completion:^(BOOL finished) {
                                              
                                          }];
                     }];
    
    
}

```

## 打钩动画

打勾动画的思路是给一个`CAShapeLayer`指定一个勾形的`path`,然后进行`strokeEnd`的动画，`strokeEnd`不是`CALayer`的属性，而是其子类`CAShapeLayer`的一个特有属性。所以我们先要创建一个`CAShapeLayer`，还有一个必须赋值的`path`，然后再进行绘制

**实现代码**

```
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
    checkLayer.lineCap = kCALineCapRound; //线条拐角
    checkLayer.lineJoin = kCALineJoinRound; //终点处理
    [self.layer addSublayer:checkLayer];
    
    CABasicAnimation *checkAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    checkAnimation.duration = 0.3f;
    checkAnimation.fromValue = @(0.0f);
    checkAnimation.toValue = @(1.0f);
    checkAnimation.delegate = self;
    //这个可以起到判断不同anim的方法：KVO
    [checkAnimation setValue:@"checkAnimation" forKey:@"animationName"];
    [checkLayer addAnimation:checkAnimation forKey:nil];
    
}
```

## 触发方法

```
#pragma mark - 代理方法，开始波浪动画
- (void)startDownload{
    [self setProgress:1.0];
}
```
这是个代理方法,刚开始点击箭头后就被调用，水波上升的动画执行时间，就是`_progress`被设置为1的过程，水波上升的最终高度可以通过`_progress`来控制


## 水波动画控制

**实现代码**

```
#pragma mark - animation
- (void)changeoff {
    _wave_offsetx += _wave_move_width*_wave_scale;
    [self setNeedsDisplay];
    
    //偏移较小的时候加速，节省时间
    if (_wave_offsety < 5.0) {
        _offsety_scale += 1.0;
    }
    
    //水满了，做打钩动画和震荡扩散动画并停止波浪动画
    if (_wave_offsety <= 0.01) {
        [self checkAnimation];
        [self endAnimation];
        [self stopWave];
        NSLog(@"finish");
    }
}

#pragma mark - start
- (void)startWave {
    if (!_waveDisplaylink) {
        //启动同步渲染绘制波纹
        _waveDisplaylink = [CADisplayLink displayLinkWithTarget:self selector:@selector(changeoff)];
        [_waveDisplaylink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    }
}

#pragma mark - stop
- (void)stopWave {
    [_waveDisplaylink invalidate];
    _waveDisplaylink = nil;
}
```
diaplayLink在屏幕刷新过程中不断调用`changeoff`方法，若水波上升到一定高度，也就是y轴偏移较小的时候，加快上升速率，待到水填满圆形容器的时候，执行打钩动画、震动波动画并停止波浪动画
