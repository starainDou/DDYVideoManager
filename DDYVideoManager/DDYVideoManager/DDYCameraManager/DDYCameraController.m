#import "DDYCameraController.h"
#import "DDYCameraManager.h"
#import "DDYCameraView.h"

@interface DDYCameraController ()

@property (nonatomic, strong) DDYCameraManager *cameraManager;

@property (nonatomic, strong) DDYCameraView *cameraView;

@property (nonatomic, assign) BOOL statusBarHidden;

@end

@implementation DDYCameraController

- (DDYCameraManager *)cameraManager {
    if (!_cameraManager) {
        __weak __typeof__ (self)weakSelf = self;
        _cameraManager = [[DDYCameraManager alloc] init];
        [_cameraManager setTakeFinishBlock:^(UIImage *image) {[weakSelf handleTakeFinish:image];}];
        [_cameraManager setRecordFinishBlock:^(NSURL *videoURL) {[weakSelf handleRecordFinish:videoURL];}];
    }
    return _cameraManager;
}

- (DDYCameraView *)cameraView {
    if (!_cameraView) {
        __weak __typeof__ (self)weakSelf = self;
        _cameraView = [[DDYCameraView alloc] initWithFrame:self.view.bounds];
        [_cameraView setBackBlock:^{[weakSelf handleBack];}];
        [_cameraView setToneBlock:^(BOOL isOn) {[weakSelf handleTone:isOn];}];
        [_cameraView setLightBlock:^(BOOL isOn) {[weakSelf handleLight:isOn];}];
        [_cameraView setToggleBlock:^{[weakSelf handleToggle];}];
        [_cameraView setTakeBlock:^{[weakSelf handleTake];}];
        [_cameraView setRecordBlock:^(BOOL isStart) {[weakSelf handleRecord:isStart];}];
    }
    return _cameraView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor blackColor]];
    [self.cameraManager ddy_CameraWithContainer:self.view];
    [self.view addSubview:self.cameraView];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.cameraManager ddy_StartCaptureSession];
    [self hiddenStatusBar:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.cameraManager ddy_StopCaptureSession];
    [self hiddenStatusBar:NO];
}

#pragma mark - 事件响应
#pragma mark 返回
- (void)handleBack {
    if (![self.navigationController popViewControllerAnimated:YES]) {
        [self dismissViewControllerAnimated:YES completion:^{ }];
    }
}

#pragma mark 曝光模式
- (void)handleTone:(BOOL)isOn {
    
}

#pragma mark 闪光灯模式
- (void)handleLight:(BOOL)isOn {
    [self.cameraManager ddy_SetFlashMode:isOn ? AVCaptureFlashModeOff : AVCaptureFlashModeOn];
}

#pragma mark 切换摄像头
- (void)handleToggle {
    [self.cameraManager ddy_ToggleCamera];
}

#pragma mark 拍照
- (void)handleTake {
    [self.cameraManager ddy_TakePhotos];
}

#pragma mark 录制开始与结束
- (void)handleRecord:(BOOL)isStart {
    isStart ? [self.cameraManager ddy_StartRecord] : [self.cameraManager ddy_StopRecord];
}

#pragma mark 拍照成功
- (void)handleTakeFinish:(UIImage *)image {
    if (image && self.takePhotoBlock) {
        self.takePhotoBlock(image, self);
    }
}

#pragma mark 录制成功
- (void)handleRecordFinish:(NSURL *)videoURL {
    
}

#pragma mark - 状态栏显隐性
- (void)hiddenStatusBar:(BOOL)sender {
    _statusBarHidden = sender;
    [self setNeedsStatusBarAppearanceUpdate];
}
#pragma mark 显隐性
- (BOOL)prefersStatusBarHidden {
    return _statusBarHidden;
}

@end
