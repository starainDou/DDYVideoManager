#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

@interface DDYCameraManager : NSObject

/** 拍照回调 */
@property (nonatomic, copy) void (^takePhotoBlock)(UIImage *image);

/** 录制回调 */
@property (nonatomic, copy) void (^recordBlock)(NSURL *videoURL);

/** 会话质量 默认AVCaptureSessionPresetHigh */
@property (nonatomic, copy) NSString *sessionPreset;

/** 初始化 */
- (void)ddy_CameraWithContainer:(UIView *)container;

/** 开启捕捉会话 */
- (void)ddy_StartCaptureSession;

/** 停止捕捉会话 */
- (void)ddy_StopCaptureSession;

/** 切换摄像头 */
- (void)ddy_ToggleCamera;

/** 设置闪光灯模式 */
- (void)ddy_SetFlashMode:(AVCaptureFlashMode)flashMode;

/** 手电筒补光模式 */
- (void)ddy_SetTorchMode:(AVCaptureTorchMode)torchMode;

/** 聚焦/曝光 */
- (void)ddy_FocusAtPoint:(CGPoint)point;

/** 拍照 */
- (void)ddy_TakePhotos;

/** 播放系统拍照声 */
- (void)ddy_palySystemTakePhotoSound;

/** 开始录制视频 */
- (void)ddy_StartRecord;

/** 结束录制视频 */
- (void)ddy_StopRecord;

@end