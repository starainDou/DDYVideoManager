#import "DDYCameraManager.h"

/** 更改属性 */
typedef void(^PropertyChangeBlock)(AVCaptureDevice *captureDevice);

@interface DDYCameraManager ()<AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate>
/** 捕获会话 */
@property (nonatomic, strong) AVCaptureSession *captureSession;
/** 视频输入 */
@property (nonatomic, strong) AVCaptureDeviceInput *videoInput;
/** 音频输入 */
@property (nonatomic, strong) AVCaptureDeviceInput *audioInput;
/** 图片输出 */
@property (nonatomic, strong) AVCaptureStillImageOutput *imageOutput;
/** 视频输出 */
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoOutput;
/** 音频输出 */
@property (nonatomic, strong) AVCaptureAudioDataOutput *audioOutput;
/** 图片连接 */
@property (nonatomic, strong) AVCaptureConnection *imageConnection;
/** 视频连接 */
@property (nonatomic, strong) AVCaptureConnection *videoConnection;
/** 音频连接 */
@property (nonatomic, strong) AVCaptureConnection *audioConnection;
/** 视频预览层 */
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
/** 视频URL */
@property (nonatomic, strong) NSURL *videoURL;
/** 资源写入 */
@property (nonatomic, strong) AVAssetWriter *assetWriter;
/** 音频输出 */
@property (nonatomic, strong) AVAssetWriterInput *assetAudioInput;
/** 视频输出 */
@property (nonatomic, strong) AVAssetWriterInput *assetVideoInput;
/** 视频尺寸 */
@property (nonatomic, assign) CMVideoDimensions videoDimensions;
/** 像素缓存适配器 */
@property (nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor *pixelBufferAdaptor;
/** 格式描述 */
@property (nonatomic, assign) CMFormatDescriptionRef audioFormatDescription;

@end

@implementation DDYCameraManager

- (void)ddy_CameraWithContainer:(UIView *)container {
    [self setupCaptureSession];
    [self setupSessionInput];
    [self setupSessionOutput];
    
    _captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    _captureVideoPreviewLayer.frame = container.layer.bounds;
    _captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [container.layer addSublayer:_captureVideoPreviewLayer];
    [container.layer setMasksToBounds:YES];
    
    [self ddy_SetFlashMode:AVCaptureFlashModeAuto];
}

#pragma mark 初始化会话
- (void)setupCaptureSession {
    _captureSession = [[AVCaptureSession alloc] init];
    if ([_captureSession canSetSessionPreset:self.sessionPreset]) {
        [_captureSession setSessionPreset:self.sessionPreset];
    }
}

- (NSString *)sessionPreset {
    if (!_sessionPreset) {
        _sessionPreset = AVCaptureSessionPresetHigh;
    }
    return _sessionPreset;
}

#pragma mark 添加输入
- (void)setupSessionInput {
    // 视频输入
    AVCaptureDevice *videoDevice = [self getCameraDeviceWithPosition:AVCaptureDevicePositionBack];
    _videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:videoDevice error:nil];
    if ([_captureSession canAddInput:_videoInput]) {
        [_captureSession addInput:_videoInput];
    }
    // 音频输入
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    _audioInput = [[AVCaptureDeviceInput alloc] initWithDevice:audioDevice error:nil];
    if ([_captureSession canAddInput:_audioInput]) {
        [_captureSession addInput:_audioInput];
    }
}

#pragma mark 添加输出
- (void)setupSessionOutput {
    dispatch_queue_t queue = dispatch_queue_create("com.ddyCamera.serialQueue", DISPATCH_QUEUE_SERIAL);
    // 图片输出
    _imageOutput = [[AVCaptureStillImageOutput alloc] init];
    _imageOutput.outputSettings = @{AVVideoCodecKey:AVVideoCodecJPEG};
    if ([_captureSession canAddOutput:_imageOutput]) {
        [_captureSession addOutput:_imageOutput];
    }
    
    // 视频输出
    _videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    _videoOutput.alwaysDiscardsLateVideoFrames = YES; // 是否允许卡顿时丢帧
    _videoOutput.videoSettings = @{(id)kCVPixelBufferPixelFormatTypeKey:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA]};
    [_videoOutput setSampleBufferDelegate:self queue:queue];
    if ([_captureSession canAddOutput:_videoOutput]) {
        [_captureSession addOutput:_videoOutput];
    }
    // 在AVCaptureInput和AVCaptureOutput之间建立连接。AVCaptureSession必须从AVCaptureConnection中获取实际数据
    _videoConnection = [_videoOutput connectionWithMediaType:AVMediaTypeVideo];
    _videoConnection.videoOrientation = AVCaptureVideoOrientationPortrait; // 设置视频方向, 若不设置, 视频默认是旋转90°的
    
    // 音频输出
    _audioOutput = [[AVCaptureAudioDataOutput alloc] init];
    [_audioOutput setSampleBufferDelegate:self queue:queue];
    if ([_captureSession canAddOutput:_audioOutput]) {
        [_captureSession addOutput:_audioOutput];
    }
    _audioConnection = [_audioOutput connectionWithMediaType:AVMediaTypeAudio];
}

#pragma mark 开启捕捉会话
- (void)ddy_StartCaptureSession {
    if (!_captureSession.isRunning){
        [_captureSession startRunning];
    }
}

#pragma mark 停止捕捉会话
- (void)ddy_StopCaptureSession {
    if (_captureSession.isRunning){
        [_captureSession stopRunning];
    }
}

#pragma mark 切换摄像头
- (void)ddy_ToggleCamera {
    if ([[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count] > 1) {
        AVCaptureDevice *currentDevice = [_videoInput device];
        AVCaptureDevicePosition currentPosition = [currentDevice position];
        // 如果原来是前置摄像头或未设置则切换后为后置摄像头
        BOOL toChangeBack = (currentPosition==AVCaptureDevicePositionUnspecified || currentPosition==AVCaptureDevicePositionFront);
        AVCaptureDevicePosition toChangePosition = toChangeBack ? AVCaptureDevicePositionBack : AVCaptureDevicePositionFront;
        AVCaptureDevice *toChangeDevice = [self getCameraDeviceWithPosition:toChangePosition];
        // 获得要调整的设备输入对象
        AVCaptureDeviceInput *toChangeDeviceInput = [[AVCaptureDeviceInput alloc]initWithDevice:toChangeDevice error:nil];
        // 改变会话的配置前一定要先开启配置，配置完成后提交配置改变
        [self.captureSession beginConfiguration];
        // 移除原有输入对象
        [self.captureSession removeInput:_videoInput];
        // 添加新的输入对象
        if ([self.captureSession canAddInput:toChangeDeviceInput]) {
            [self.captureSession addInput:toChangeDeviceInput];
            _videoInput = toChangeDeviceInput;
        }
        // 提交会话配置
        [self.captureSession commitConfiguration];
        // 切换摄像头后原来闪光灯失效
        [self ddy_SetFlashMode:AVCaptureFlashModeAuto];
    }
}

#pragma mark 设置闪光灯模式
- (void)ddy_SetFlashMode:(AVCaptureFlashMode)flashMode {
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        if ([captureDevice hasFlash] &&[captureDevice isFlashModeSupported:flashMode]) {
            // 如果手电筒补光打开则先关闭
            if ([captureDevice hasTorch] && [captureDevice torchMode]==AVCaptureTorchModeOn) {
                [self ddy_SetTorchMode:AVCaptureTorchModeOff];
            }
            [captureDevice setFlashMode:flashMode];
        } else {
            NSLog(@"设备不支持闪光灯");
        }
    }];
}

#pragma mark 设置补光模式
- (void)ddy_SetTorchMode:(AVCaptureTorchMode)torchMode {
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        if ([captureDevice hasTorch] &&[captureDevice isTorchModeSupported:torchMode]) {
            // 如果闪光灯打开则先关闭
            if ([captureDevice hasFlash] && [captureDevice flashMode]==AVCaptureFlashModeOn) {
                [self ddy_SetFlashMode:AVCaptureFlashModeOff];
            }
            [captureDevice setTorchMode:torchMode];
        } else {
            NSLog(@"设备不支持闪光灯");
        }
    }];
}

#pragma mark 聚焦/曝光
- (void)ddy_FocusAtPoint:(CGPoint)point {
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        if ([captureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
            [captureDevice setFocusMode:AVCaptureFocusModeAutoFocus];
        }
        if ([captureDevice isFocusPointOfInterestSupported]) {
            [captureDevice setFocusPointOfInterest:point];
        }
        if ([captureDevice isExposureModeSupported:AVCaptureExposureModeAutoExpose]) {
            [captureDevice setExposureMode:AVCaptureExposureModeAutoExpose];
        }
        if ([captureDevice isExposurePointOfInterestSupported]) {
            [captureDevice setExposurePointOfInterest:point];
        }
    }];
}

#pragma mark 拍照
- (void)ddy_TakePhotos {
    _imageConnection = [_imageOutput connectionWithMediaType:AVMediaTypeVideo];
    if (_imageConnection.isVideoOrientationSupported) {
        _imageConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
    }
    // 根据连接取得设备输出的数据
    [_imageOutput captureStillImageAsynchronouslyFromConnection:_imageConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        if (imageDataSampleBuffer) {
            NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.takePhotoBlock) {
                    self.takePhotoBlock([UIImage imageWithData:imageData]);
                }
            });
        }
    }];
}

#pragma mark 播放系统拍照声
- (void)ddy_palySystemTakePhotoSound {
    AudioServicesPlaySystemSound(1108);
}

#pragma mark 开始录制视频
- (void)ddy_StartRecord {
    NSString *path = [NSString stringWithFormat:@"%@ddy_video.mov",NSTemporaryDirectory()];
    _videoURL = [NSURL fileURLWithPath:path];
    [self setAssetWriterVideoInput];
    [self setAssetWriterAudioInput];
    [_assetWriter startWriting];
}

#pragma mark 结束录制视频
- (void)ddy_StopRecord {
    [self.assetWriter finishWritingWithCompletionHandler:^{
        if (self.assetWriter.status == AVAssetWriterStatusCompleted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.recordBlock) {
                    self.recordBlock(self.videoURL);
                }
            });
        }
    }];
}

#pragma mark - Private methods

- (AVCaptureDevice *)getCameraDeviceWithPosition:(AVCaptureDevicePosition)position {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *camera in devices) {
        if ([camera position] == position) {
            return camera;
        }
    }
    return nil;
}

#pragma mark 改变设备属性(闪光灯,手电筒,切换摄像头)
- (void)changeDeviceProperty:(PropertyChangeBlock)propertyChange {
    AVCaptureDevice *captureDevice = [_videoInput device];
    NSError *error = nil;
    // 注意改变设备属性前先加锁,调用完解锁
    if ([captureDevice lockForConfiguration:&error]) {
        propertyChange(captureDevice);
        [captureDevice unlockForConfiguration];
    }
    if (error) {
        NSLog(@"changeDevicePropertyError:%@",error.localizedDescription);
    };
}

#pragma mark 视频写入设置
- (void)setAssetWriterVideoInput {
    NSError *error = nil;
    _assetWriter = [[AVAssetWriter alloc] initWithURL:_videoURL fileType:AVFileTypeQuickTimeMovie error:&error];
    NSDictionary *outputSetting = @{AVVideoCodecKey : AVVideoCodecH264,
                                    AVVideoWidthKey : @(_videoDimensions.width),
                                    AVVideoHeightKey: @(_videoDimensions.height) };
    _assetVideoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:outputSetting];
    // 要从captureSession实时获取数据
    _assetVideoInput.expectsMediaDataInRealTime = YES;
    _assetVideoInput.transform = CGAffineTransformIdentity;

    NSDictionary *pixelBufferAttributes = @{(NSString *)kCVPixelBufferPixelFormatTypeKey:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA],
                                                  (NSString *)kCVPixelBufferWidthKey:@(_videoDimensions.width),
                                                  (NSString *)kCVPixelBufferHeightKey:@(_videoDimensions.height),
                                                  (NSString *)kCVPixelFormatOpenGLESCompatibility:(NSNumber *)kCFBooleanTrue};
    // AVCaptureMovieFileOutput和AVAssetWriterInputPixelBufferAdaptor有冲突
    _pixelBufferAdaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:_assetVideoInput
                                                                                           sourcePixelBufferAttributes:pixelBufferAttributes];
    if ([_assetWriter canAddInput:_assetVideoInput]) {
        [_assetWriter addInput:_assetVideoInput];
    }
}

#pragma mark 音频写入设置
- (void)setAssetWriterAudioInput {
    size_t aclSize = 0;
    const AudioStreamBasicDescription *audioASBD = CMAudioFormatDescriptionGetStreamBasicDescription(_audioFormatDescription);
    const AudioChannelLayout *audioChannelLayout = CMAudioFormatDescriptionGetChannelLayout(_audioFormatDescription, &aclSize);
    NSData *audioChannelLayoutData = (audioChannelLayout && aclSize>0) ? [NSData dataWithBytes:audioChannelLayout length:aclSize] : [NSData data];
    
    NSDictionary *outputSetting = @{AVFormatIDKey : [NSNumber numberWithInteger:kAudioFormatMPEG4AAC],
                                    AVSampleRateKey : [NSNumber numberWithFloat:audioASBD->mSampleRate],
                                    AVEncoderBitRatePerChannelKey : [NSNumber numberWithInt:64000],
                                    AVNumberOfChannelsKey : [NSNumber numberWithInteger:audioASBD->mChannelsPerFrame],
                                    AVChannelLayoutKey : audioChannelLayoutData};
    if ([_assetWriter canApplyOutputSettings:outputSetting forMediaType:AVMediaTypeAudio]) {
        _assetAudioInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio outputSettings:outputSetting];
        _assetAudioInput.expectsMediaDataInRealTime = YES;
        
        if ([_assetWriter canAddInput:_assetAudioInput]) {
            [_assetWriter addInput:_assetAudioInput];
        }
    }
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    @autoreleasepool {
        if (captureOutput == _videoOutput) {
            _videoDimensions = CMVideoFormatDescriptionGetDimensions(CMSampleBufferGetFormatDescription(sampleBuffer));
        } else {
            _audioFormatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
        }
    }
}

@end
