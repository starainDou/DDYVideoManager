#import <UIKit/UIKit.h>

@interface DDYCameraView : UIView

/** 点击返回 */
@property (nonatomic, copy) void (^backBlock)(void);
/** 曝光模式 */
@property (nonatomic, copy) void (^toneBlock)(BOOL isOn);
/** 闪光灯模式 */
@property (nonatomic, copy) void (^lightBlock)(BOOL isOn);
/** 切换摄像头 */
@property (nonatomic, copy) void (^toggleBlock)(void);
/** 点击拍照 */
@property (nonatomic, copy) void (^takeBlock)(void);
/** 录制事件 */
@property (nonatomic, copy) void (^recordBlock)(BOOL isStart);

@end
