#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

@interface DDYCameraTool : NSObject

/**
 视频转码/压缩
 @param videoURL 原始视频URL路径
 @param presetName 视频质量 建议(默认)AVAssetExportPresetMediumQuality
 @param saveURL 转码压缩后保存URL路径
 @param progress 转码压缩进度
 @param complete 完成回调
 */
+ (void)ddy_CompressVideo:(NSURL *)videoURL
               presetName:(NSString *)presetName
                  saveURL:(NSURL *)saveURL
                 progress:(void (^)(CGFloat progress))progress
                 complete:(void (^)(NSError *error))complete;


/**
 截取视频某个时刻的缩略图
 @param videoURL 视频地址
 @param time 要截取的时刻
 @return 截取到的缩略图
 */
+ (UIImage *)ddy_ThumbnailImageInVideo:(NSURL *)videoURL andTime:(CGFloat)time;

/** 添加背景音乐 */
- (void)ddy_VideoAddBackGroundMusic:(NSURL *)musicPath;



@end
