#import "DDYCameraView.h"
#import "Masonry.h"
#import "NSTimer+DDYExtension.h"

static inline UIImage *cameraImg(NSString *imageName) {return [UIImage imageNamed:[NSString stringWithFormat:@"DDYCamera.bundle/%@", imageName]];}

@interface DDYCameraView ()
/** 返回按钮 */
@property (nonatomic, strong) UIButton *backButton;
/** 改变色调按钮 */
@property (nonatomic, strong) UIButton *toneButton;
/** 闪光灯/补光灯按钮 */
@property (nonatomic, strong) UIButton *lightButton;
/** 切换前后摄像头按钮 */
@property (nonatomic, strong) UIButton *toggleButton;
/** 拍照录制按钮 */
@property (nonatomic, strong) UIButton *takeButton;
/** 进度layer */
@property (nonatomic, strong) CAShapeLayer *progressLayer;
/** 定时器 */
@property (nonatomic, strong) NSTimer *recordTimer;
/** 时长 s */
@property (nonatomic, assign) CGFloat recordSeconds;

@end

@implementation DDYCameraView

- (UIButton *)btnImg:(NSString *)img imgS:(NSString *)imgS sel:(SEL)sel {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    if (img) [button setImage:cameraImg(img) forState:UIControlStateNormal];
    if (imgS) [button setImage:cameraImg(imgS) forState:UIControlStateSelected];
    [button addTarget:self action:sel forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:button];
    return button;
}

- (UIButton *)backButton {
    if (!_backButton) {
        _backButton = [self btnImg:@"back" imgS:nil sel:@selector(handleBack:)];
    }
    return _backButton;
}

- (UIButton *)toneButton {
    if (!_toneButton) {
        _toneButton = [self btnImg:@"toneN" imgS:@"toneS" sel:@selector(handleTone:)];
    }
    return _toneButton;
}

- (UIButton *)lightButton {
    if (!_lightButton) {
        _lightButton = [self btnImg:@"lightN" imgS:@"lightS" sel:@selector(handleLight:)];
    }
    return _lightButton;
}

- (UIButton *)toggleButton {
    if (!_toggleButton) {
        _toggleButton = [self btnImg:@"toggle" imgS:nil sel:@selector(handleToggle:)];
    }
    return _toggleButton;
}

- (UIButton *)takeButton {
    if (!_takeButton) {
        _takeButton = [self btnImg:nil imgS:nil sel:@selector(handleTake:)];
        [_takeButton addGestureRecognizer:[[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(handleLongPress:)]];
    }
    return _takeButton;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self.backButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(12);
            make.top.mas_equalTo(12);
            make.width.height.mas_equalTo(30);
        }];
        
        [self.toneButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.mas_equalTo(self.lightButton.mas_left).offset(-15);
            make.top.mas_equalTo(self.backButton);
            make.width.height.mas_equalTo(30);
        }];
        
        [self.lightButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.mas_equalTo(self.toggleButton.mas_left).offset(-15);
            make.top.mas_equalTo(self.backButton);
            make.width.height.mas_equalTo(30);
        }];
        
        [self.toggleButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.mas_equalTo(self).offset(-15);
            make.top.mas_equalTo(self.backButton);
            make.width.height.mas_equalTo(30);
        }];
        
        [self.takeButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.mas_equalTo(self);
            make.bottom.mas_equalTo(self).offset(-20);
            make.width.height.mas_equalTo(50);
        }];
        self.toneButton.hidden = YES;
        [self addShapeLayer];
    }
    return self;
}

- (void)addShapeLayer {
    CGRect rect = CGRectMake(0, 0, 50, 50);
    CGPoint center = CGPointMake(25, 25);
    UIBezierPath *circlePath = [UIBezierPath bezierPathWithArcCenter:center radius:25 startAngle:-M_PI_2 endAngle:2*M_PI-M_PI_2 clockwise:YES];;
    
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    shapeLayer.frame = rect;
    shapeLayer.lineWidth = 4.0f;
    shapeLayer.strokeColor = [UIColor whiteColor].CGColor;
    shapeLayer.fillColor = [UIColor clearColor].CGColor;
    shapeLayer.path = circlePath.CGPath;
    [self.takeButton.layer addSublayer:shapeLayer];
    
    self.progressLayer = [CAShapeLayer layer];
    self.progressLayer.frame = rect;
    self.progressLayer.lineWidth = 4.0f;
    self.progressLayer.strokeColor = [UIColor redColor].CGColor;
    self.progressLayer.fillColor = [UIColor clearColor].CGColor;
    self.progressLayer.lineCap = kCALineCapSquare;
    self.progressLayer.path = circlePath.CGPath;
    self.progressLayer.strokeEnd = 0./10.;
    [self.takeButton.layer addSublayer:_progressLayer];
}

- (void)startTimer {
    self.recordSeconds = 0.;
    self.recordTimer = [NSTimer ddy_scheduledTimerWithTimeInterval:1. repeats:YES block:^(NSTimer *timer) {
        self.recordSeconds += 1.;
    }];
}

- (void)stopTimer {
    [self.recordTimer invalidate];
    self.recordTimer = nil;
}

#pragma mark - 事件处理
#pragma mark 返回
- (void)handleBack:(UIButton *)sender {
    if (self.backBlock) self.backBlock();
}

#pragma mark 曝光模式
- (void)handleTone:(UIButton *)sender {
    if (self.toneBlock) self.toneBlock((sender.selected = !sender.selected));
}
#pragma mark 切换摄像头
- (void)handleToggle:(UIButton *)sender {
    if (self.toggleBlock) self.toggleBlock();
}

#pragma mark 切换闪光灯模式
- (void)handleLight:(UIButton *)sender {
    if (self.lightBlock) self.lightBlock((sender.selected = !sender.selected));
}

#pragma mark 拍照
- (void)handleTake:(UIButton *)sender {
    if (self.takeBlock) self.takeBlock();
}

#pragma mark 长按录制与结束
- (void)handleLongPress:(UILongPressGestureRecognizer *)longP {
    //判断长按时的状态
    if (longP.state == UIGestureRecognizerStateBegan) {
        if (self.recordBlock) self.recordBlock(YES);
    } else if (longP.state == UIGestureRecognizerStateEnded) {
        if (self.recordBlock) self.recordBlock(NO);
    } else if (longP.state == UIGestureRecognizerStateChanged) {
        
    }
}

@end
