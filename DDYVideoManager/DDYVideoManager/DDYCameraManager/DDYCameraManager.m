#import "DDYCameraManager.h"

/** 更改属性 */
typedef void(^PropertyChangeBlock)(AVCaptureDevice *captureDevice);

@interface DDYCameraManager ()<AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate>
/** 串行队列 */
@property (nonatomic, strong) dispatch_queue_t cameraSerialQueue;
/** 视频预览层 */
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
/** 捕获会话 */
@property (nonatomic, strong) AVCaptureSession *captureSession;
/** 音频输入 */
@property (nonatomic, strong) AVCaptureDeviceInput *audioInput;
/** 视频输入 */
@property (nonatomic, strong) AVCaptureDeviceInput *videoInput;
/** 图片输出 */
@property (nonatomic, strong) AVCaptureStillImageOutput *imageOutput;
/** 音频输出 */
@property (nonatomic, strong) AVCaptureAudioDataOutput *audioOutput;
/** 视频输出 */
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoOutput;
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
/** 时间 */
@property (nonatomic, assign) CMTime currentSampleTime;

@end

@implementation DDYCameraManager

#pragma mark - 懒加载

- (dispatch_queue_t)cameraSerialQueue {
    if (!_cameraSerialQueue) {
        _cameraSerialQueue = dispatch_queue_create("com.ddyCamera.serialQueue", DISPATCH_QUEUE_SERIAL);
    }
    return _cameraSerialQueue;
}

- (AVCaptureVideoPreviewLayer *)previewLayer {
    if (!_previewLayer) {
        _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
        _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        _previewLayer.frame = [UIScreen mainScreen].bounds;
    }
    return _previewLayer;
}

- (AVCaptureSession *)captureSession {
    if (!_captureSession) {
        _captureSession = [[AVCaptureSession alloc] init];
        // 会话质量
        if ([_captureSession canSetSessionPreset:self.sessionPreset]) {
            [_captureSession setSessionPreset:self.sessionPreset];
        }
        // 视频输入
        if ([_captureSession canAddInput:self.videoInput]) {
            [_captureSession addInput:self.videoInput];
        }
        // 音频输入
        if ([_captureSession canAddInput:self.audioInput]) {
            [_captureSession addInput:self.audioInput];
        }
        // 图片输出
        if ([_captureSession canAddOutput:self.imageOutput]) {
            [_captureSession addOutput:self.imageOutput];
        }
        // 视频输出
        if ([_captureSession canAddOutput:self.videoOutput]) {
            [_captureSession addOutput:self.videoOutput];
        }
        // 音频输出
        if ([_captureSession canAddOutput:self.audioOutput]) {
            [_captureSession addOutput:self.audioOutput];
        }
    }
    return _captureSession;
}

#pragma mark 会话质量
- (NSString *)sessionPreset {
    if (!_sessionPreset) {
        _sessionPreset = AVCaptureSessionPresetHigh;
    }
    return _sessionPreset;
}

#pragma mark 音频输入
- (AVCaptureDeviceInput *)audioInput {
    if (!_audioInput) {
        AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
        _audioInput = [[AVCaptureDeviceInput alloc] initWithDevice:audioDevice error:nil];
    }
    return _audioInput;
}

#pragma mark 视频输入
- (AVCaptureDeviceInput *)videoInput {
    if (!_videoInput) {
        AVCaptureDevice *videoDevice = [self getCameraDeviceWithPosition:AVCaptureDevicePositionBack];
        _videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:videoDevice error:nil];
    }
    return _videoInput;
}

#pragma mark 图片输出
- (AVCaptureStillImageOutput *)imageOutput {
    if (!_imageOutput) {
        _imageOutput = [[AVCaptureStillImageOutput alloc] init];
        _imageOutput.outputSettings = @{AVVideoCodecKey:AVVideoCodecJPEG};
    }
    return _imageOutput;
}

#pragma mark 音频输出
- (AVCaptureAudioDataOutput *)audioOutput {
    if (!_audioOutput) {
        _audioOutput = [[AVCaptureAudioDataOutput alloc] init];
        [_audioOutput setSampleBufferDelegate:self queue:self.cameraSerialQueue];
    }
    return _audioOutput;
}

#pragma mark 视频输出
- (AVCaptureVideoDataOutput *)videoOutput {
    if (!_videoOutput) {
        _videoOutput = [[AVCaptureVideoDataOutput alloc] init];
        _videoOutput.alwaysDiscardsLateVideoFrames = YES; // 是否允许卡顿时丢帧
        [_videoOutput setSampleBufferDelegate:self queue:self.cameraSerialQueue];
    }
    return _videoOutput;
}

+ (instancetype)ddy_CameraWithContainerView:(UIView *)view {
    return [[self alloc] initWithContainerView:view];
}

- (instancetype)initWithContainerView:(UIView *)view {
    if (self = [super init]) {
        [self setupObserver];
        [view.layer insertSublayer:self.previewLayer atIndex:0];
        [self.captureSession startRunning];
    }
    return self;
}

#pragma mark 添加监听
- (void)setupObserver {
    
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
    AVCaptureConnection *imageConnection = [self.imageOutput connectionWithMediaType:AVMediaTypeVideo];
    if (imageConnection.isVideoOrientationSupported) {
        imageConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
    }
    // 根据连接取得设备输出的数据
    [self.imageOutput captureStillImageAsynchronouslyFromConnection:imageConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        if (imageDataSampleBuffer) {
            NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.takeFinishBlock) {
                    self.takeFinishBlock([UIImage imageWithData:imageData]);
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
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
    _videoURL = [NSURL fileURLWithPath:path];
    [self setAssetWriterVideoInput];
    [self setAssetWriterAudioInput];
    [_assetWriter startWriting];
    [_assetWriter startSessionAtSourceTime:_currentSampleTime];
}

#pragma mark 结束录制视频
- (void)ddy_StopRecord {
    [self.assetWriter finishWritingWithCompletionHandler:^{
        if (self.assetWriter.status == AVAssetWriterStatusCompleted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.recordFinishBlock) {
                    self.recordFinishBlock(self.videoURL);
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
    // 初始化写入媒体类型为MP4类型
    _assetWriter = [AVAssetWriter assetWriterWithURL:self.videoURL fileType:AVFileTypeMPEG4 error:nil];
    // 使其更适合在网络上播放
    _assetWriter.shouldOptimizeForNetworkUse = YES;
    
    //写入视频大小
    NSInteger numPixels = [UIScreen mainScreen].bounds.size.width * [UIScreen mainScreen].bounds.size.height;
    //每像素比特
    CGFloat bitsPerPixel = 6.0;
    NSInteger bitsPerSecond = numPixels * bitsPerPixel;
    // 码率和帧率设置
    NSDictionary *compressionProperties = @{ AVVideoAverageBitRateKey:@(bitsPerSecond),
                                             AVVideoExpectedSourceFrameRateKey:@(30),
                                             AVVideoMaxKeyFrameIntervalKey:@(30),
                                             AVVideoProfileLevelKey:AVVideoProfileLevelH264BaselineAutoLevel};
    
    NSDictionary *outputSetting = @{AVVideoCodecKey:AVVideoCodecH264,
                                    AVVideoWidthKey:@([UIScreen mainScreen].bounds.size.width),
                                    AVVideoHeightKey:@([UIScreen mainScreen].bounds.size.height),
                                    AVVideoCompressionPropertiesKey:compressionProperties};
    _assetVideoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:outputSetting];
    // 要从captureSession实时获取数据
    _assetVideoInput.expectsMediaDataInRealTime = YES;
    _assetVideoInput.transform = CGAffineTransformIdentity;
    if ([self.assetWriter canAddInput:_assetVideoInput]) {
        [self.assetWriter addInput:_assetVideoInput];
    }
}

#pragma mark 音频写入设置
- (void)setAssetWriterAudioInput {
    size_t aclSize = 0;
    const AudioStreamBasicDescription *audioASBD = CMAudioFormatDescriptionGetStreamBasicDescription(_audioFormatDescription);
    const AudioChannelLayout *audioChannelLayout = CMAudioFormatDescriptionGetChannelLayout(_audioFormatDescription, &aclSize);
    NSData *audioChannelLayoutData = (audioChannelLayout && aclSize>0) ? [NSData dataWithBytes:audioChannelLayout length:aclSize] : [NSData data];
    
    NSDictionary *outputSetting = @{AVFormatIDKey:[NSNumber numberWithInteger:kAudioFormatMPEG4AAC],
                                    AVSampleRateKey:[NSNumber numberWithFloat:audioASBD->mSampleRate],
                                    AVEncoderBitRatePerChannelKey:[NSNumber numberWithInt:64000],
                                    AVNumberOfChannelsKey:[NSNumber numberWithInteger:audioASBD->mChannelsPerFrame],
                                    AVChannelLayoutKey:audioChannelLayoutData};
    if ([self.assetWriter canApplyOutputSettings:outputSetting forMediaType:AVMediaTypeAudio]) {
        _assetAudioInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio outputSettings:outputSetting];
        _assetAudioInput.expectsMediaDataInRealTime = YES;
        
        if ([self.assetWriter canAddInput:_assetAudioInput]) {
            [self.assetWriter addInput:_assetAudioInput];
        }
    }
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if (captureOutput == self.videoOutput) {
        CMVideoFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
        _videoDimensions = CMVideoFormatDescriptionGetDimensions(formatDescription);
        _currentSampleTime = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer);
        if (_assetVideoInput && _assetVideoInput.readyForMoreMediaData) {
            [_assetVideoInput appendSampleBuffer:sampleBuffer];NSLog(@"777777");
        }
    } else if (captureOutput == self.audioOutput) {
        _audioFormatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
        if (_assetAudioInput && _assetAudioInput.readyForMoreMediaData) {
            [_assetAudioInput appendSampleBuffer:sampleBuffer];NSLog(@"555555");
        }
    }
}

@end
