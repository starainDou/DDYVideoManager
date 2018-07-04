#import "DDYCameraView.h"
#import "Masonry.h"

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

@end

@implementation DDYCameraView

- (UIButton *)btnImg:(NSString *)img imgS:(NSString *)imgS sel:(SEL)sel {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:[UIImage imageNamed:img] forState:UIControlStateNormal];
    [button setImage:[UIImage imageNamed:imgS] forState:UIControlStateSelected];
    [button addTarget:self action:sel forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (UIButton *)backButton {
    if (!_backButton) {
        _backButton = [self btnImg:@"" imgS:@"" sel:@selector(handleBack:)];
    }
    return _backButton;
}

- (UIButton *)toneButton {
    if (!_toneButton) {
        _toneButton = [self btnImg:@"" imgS:@"" sel:@selector(handleBack:)];
    }
    return _toneButton;
}



+ (instancetype)cameraView {
    return [[self alloc] initWithFrame:[UIScreen mainScreen].bounds];
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self.backButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(12);
        make.top.mas_equalTo(30);
        make.width.height.mas_equalTo(30);
    }];
    [self.toneButton mas_makeConstraints:^(MASConstraintMaker *make) {
        
    }];
    [self.lightButton mas_makeConstraints:^(MASConstraintMaker *make) {
        
    }];
    [self.toggleButton mas_makeConstraints:^(MASConstraintMaker *make) {
        
    }];
    [self.takeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        
    }];
}

#pragma mark - 事件处理
#pragma mark 返回
- (void)handleBack:(UIButton *)sender {
    if (self.backBlock) self.backBlock();
}

#pragma mark 切换摄像头
- (void)handleToggle:(UIButton *)sender {
    if (self.toggleBlock) self.toggleBlock();
}

#pragma mark 切换闪光灯模式
- (void)handleFlash:(UIButton *)sender
{
    if (self.flashBlock) {
        self.flashBlock((sender.selected = !sender.selected));
    }
    //    if (_cameraType == DDYCameraTypeVideo)
    //    {
    //
    //    }
    //    else
    //    {
    //
    //    }
}

#pragma mark 拍照
- (void)handleTake:(UIButton *)sender {
    if (self.takeBlock) self.takeBlock();
}

#pragma mark 长按录制与结束
- (void)handleLangPress:(UILongPressGestureRecognizer *)longP
{
    //判断长按时的状态
    if (longP.state == UIGestureRecognizerStateBegan)
    {
        NSLog(@"开始录制");
        if (self.recordBlock) self.recordBlock(YES);
        
    }
    else if (longP.state == UIGestureRecognizerStateChanged)
    {
        NSLog(@"录制中");
    }
    else if (longP.state == UIGestureRecognizerStateEnded)
    {
        NSLog(@"录制结束");
        if (self.recordBlock) self.recordBlock(NO);
    }
}

@end
