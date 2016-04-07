//
//  SHBPlayerController.h
//  AVPlayerDemo
//
//  Created by shenhongbang on 16/4/6.
//  Copyright © 2016年 shenhongbang. All rights reserved.
//

 /**
  *本播放器功能 ：
  *可播放本地和网络视频，暂停、继续播放，拖动滑块快进或快退播放进度，点击视频空白区域显隐导航栏及工具栏，点击视频区域播放或暂停视频，调节系统音量
  */

#import <UIKit/UIKit.h>

@class SHBPlayerController;
@protocol SHBPlayerControllerDelegate <UINavigationControllerDelegate>

@optional
/**
 *  播放完毕， 非必实现方法
 */
- (void)playerControllerDidFinishPlay:(SHBPlayerController *)playerController;

@end

@interface SHBPlayerController : UINavigationController

@property (nonatomic, assign) id<SHBPlayerControllerDelegate>   delegate;

+ (SHBPlayerController *)playerWithUrl:(NSURL *)url;

- (void)play;



@end

