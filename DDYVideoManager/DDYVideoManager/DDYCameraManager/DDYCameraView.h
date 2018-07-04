#import <UIKit/UIKit.h>

@interface DDYCameraView : UIView

/** 切换摄像头 */
@property (nonatomic, copy) void (^toggleBlock)(void);
/** 闪光灯模式 */
@property (nonatomic, copy) void (^flashBlock)(BOOL close);
/** 点击返回 */
@property (nonatomic, copy) void (^backBlock)(void);
/** 点击拍照 */
@property (nonatomic, copy) void (^takeBlock)(void);
/** 录制事件 */
@property (nonatomic, copy) void (^recordBlock)(BOOL startOrStop);

/** 相机视图 */
+ (instancetype)cameraView;

@end
