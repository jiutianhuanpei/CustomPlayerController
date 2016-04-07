//
//  SHBPlayerController.m
//  AVPlayerDemo
//
//  Created by shenhongbang on 16/4/6.
//  Copyright © 2016年 shenhongbang. All rights reserved.
//

#import "SHBPlayerController.h"
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <MediaPlayer/MediaPlayer.h>

UIColor *SHBColorWithHexstring(NSString *string) {
    NSString *color= string;
    if ([color hasPrefix:@"0x"]) {
        color = [color substringFromIndex:2];
    }
    if ([color hasPrefix:@"#"]) {
        color = [color substringFromIndex:1];
    }
    if (color.length != 6) {
        return [UIColor clearColor];
    }
    
    NSString *rString = [color substringWithRange:NSMakeRange(0, 2)];
    NSString *gString = [color substringWithRange:NSMakeRange(2, 2)];
    NSString *bString = [color substringWithRange:NSMakeRange(4, 2)];
    
    unsigned int red, green, blue;
    [[NSScanner scannerWithString:rString] scanHexInt:&red];
    [[NSScanner scannerWithString:gString] scanHexInt:&green];
    [[NSScanner scannerWithString:bString] scanHexInt:&blue];
    UIColor *col = [UIColor colorWithRed:(CGFloat)red / 255. green:(CGFloat)green / 255. blue:(CGFloat)blue / 255. alpha:1];
    
    return col;
}

@interface MovieView : UIView

@end
@implementation MovieView

+ (Class)layerClass {
    return [AVPlayerLayer class];
}

@end


@interface PlayerController : UIViewController<UIGestureRecognizerDelegate>

@property (nonatomic, assign) id<SHBPlayerControllerDelegate> delegate;
@property (nonatomic, strong) NSURL     *url;

- (void)play;

@end

@implementation PlayerController {
    AVPlayerItem        *_item;
//    AVPlayerLayer       *_playerLayer;
    
    MovieView              *_backView;
    
    id                  _addPeriodic;
    
    NSLayoutConstraint  *_toolBottom;
    UIView              *_toolView;
    UIButton            *_btn;
    UISlider            *_progress;
    UILabel             *_begin;
    UILabel             *_end;
    
    UITapGestureRecognizer      *_tap;
    UIPanGestureRecognizer      *_pan;
    CGPoint                     _beginPoint;
    CGPoint                     _changePoint;
    
    MPVolumeView                *_volumeView;
    BOOL                _userStop;  //手动暂停
}

- (void)dismiss:(UIBarButtonItem *)item {
    AVPlayer *player = ((AVPlayerLayer *)_backView.layer).player;
    [player pause];
    
    [self dismissViewControllerAnimated:true completion:^{
        
    }];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_item removeObserver:self forKeyPath:@"loadedTimeRanges"];
    AVPlayer *player = ((AVPlayerLayer *)_backView.layer).player;
    if (_addPeriodic) {
        [player removeTimeObserver:_addPeriodic];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"✕" style:UIBarButtonItemStylePlain target:self action:@selector(dismiss:)];
    
    _backView = [[MovieView alloc] initWithFrame:CGRectZero];
    _backView.translatesAutoresizingMaskIntoConstraints = false;
    _backView.backgroundColor = SHBColorWithHexstring(@"413f55");
    [self.view addSubview:_backView];
    
    CGFloat one = 1. / [UIScreen mainScreen].scale;
    CGFloat width = CGRectGetWidth(self.view.frame);
    CGFloat height = CGRectGetHeight(self.view.frame);
    CGFloat toolH = 50;
    
    _toolView = [[UIView alloc] initWithFrame:CGRectMake(-one, height - toolH + one, width + 2 * one, toolH)];
    _toolView.translatesAutoresizingMaskIntoConstraints = false;
    _toolView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5];
    _toolView.layer.borderWidth = one;
    _toolView.layer.borderColor = [UIColor grayColor].CGColor;
    [self.view addSubview:_toolView];
    
    _btn = [self creatBtn:@"▷" selectedTitle:@"💢" action:@selector(controlPlayer:) frame:CGRectMake(10, 0, toolH, toolH)];
    _btn.translatesAutoresizingMaskIntoConstraints = false;
    [_item addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    
    _begin = [[UILabel alloc] initWithFrame:CGRectZero];
    _begin.translatesAutoresizingMaskIntoConstraints = false;
    _begin.text = @"00:00";
    _begin.textColor = [UIColor whiteColor];
    [_toolView addSubview:_begin];
    
    _end = [[UILabel alloc] initWithFrame:CGRectZero];
    _end.translatesAutoresizingMaskIntoConstraints = false;
    _end.textColor = [UIColor whiteColor];
    _end.text = @"00:00";
    [_toolView addSubview:_end];

    _progress = [[UISlider alloc] initWithFrame:CGRectZero];
    _progress.translatesAutoresizingMaskIntoConstraints = false;
    [_progress addTarget:self action:@selector(seekProgress:) forControlEvents:UIControlEventValueChanged];
    [_toolView addSubview:_progress];
    _progress.continuous = false;
    
    
    NSDictionary *views = NSDictionaryOfVariableBindings(_btn, _begin, _end, _progress, _toolView, _backView);
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-10-[_btn]-5-[_begin(50)]-5-[_progress]-[_end(50)]-10-|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_btn]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_begin]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_end]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_progress]|" options:0 metrics:nil views:views]];
    //
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[_backView]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_backView]|" options:0 metrics:nil views:views]];
    
    //
    NSDictionary *me = @{@"one" : @(-one), @"th" : @(toolH)};
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-one-[_toolView]-one-|" options:0 metrics:me views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_toolView(th)]" options:0 metrics:me views:views]];
    _toolBottom = [NSLayoutConstraint constraintWithItem:_toolView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1 constant:0];
    [self.view addConstraint:_toolBottom];
    
    _tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapView:)];
    _tap.delegate = self;
    [self.view addGestureRecognizer:_tap];
    
    _pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(changeVolume:)];
    _pan.delegate = self;
    [self.view addGestureRecognizer:_pan];
    
    _volumeView = [[MPVolumeView alloc] init];
//    [_volumeView sizeToFit];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reset) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    
}



- (void)showToolViewAndNavigationBar:(BOOL)show {
    __weak typeof(self) SHB = self;
    if (!show) {
        [self.navigationController setNavigationBarHidden:false animated:true];
        _toolBottom.constant = 0;
        [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
            [SHB.view layoutIfNeeded];
        }];
    } else {
        [self.navigationController setNavigationBarHidden:true animated:true];
        _toolBottom.constant = CGRectGetHeight(_toolView.frame);
        [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
            [SHB.view layoutIfNeeded];
        }];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    _item = [AVPlayerItem playerItemWithURL:_url];
    AVPlayer *player = [AVPlayer playerWithPlayerItem:_item];
    ((AVPlayerLayer *)_backView.layer).player = player;
    [_item addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];// 监听loadedTimeRanges属性

    
    __weak typeof(_begin) begin = _begin;
    __weak typeof(_end) end = _end;
    __weak typeof(self) SHB = self;
    __weak typeof(_item) item = _item;
    __weak typeof(_progress) progress = _progress;
    
//    __weak typeof(_backView) backView = _backView;
    
    _addPeriodic = [((AVPlayerLayer *)_backView.layer).player addPeriodicTimeObserverForInterval:CMTimeMake(1, 30) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        
        end.text = [SHB timeWithCMTime:item.duration];
        begin.text = [SHB timeWithCMTime:item.currentTime];
        
        CGFloat pro = CMTimeGetSeconds(item.currentTime) / CMTimeGetSeconds(item.duration);
        if (progress.state != UIControlStateHighlighted) {
            [progress setValue:pro animated:true];
        }
    }];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
        
        CMTime loadTime = [self availableDuration];
        
        NSLog(@"%f   %f   %f   %d", CMTimeGetSeconds(_item.currentTime), CMTimeGetSeconds(loadTime), CMTimeGetSeconds(_item.duration), CMTimeCompare(_item.currentTime, loadTime));
        
        if (CMTimeGetSeconds(_item.currentTime) < CMTimeGetSeconds(loadTime) - 5 && !_userStop) {
            [self play];
        } else {
            [self pause];
        }
        
//        if (-1 == CMTimeCompare(_item.currentTime, loadTime)) {
//            [self play];
//        } else {
//            [self pause];
//        }
        
    }
}

- (void)play {
    _btn.selected = true;
    [((AVPlayerLayer *)_backView.layer).player play];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self showToolViewAndNavigationBar:false];
    });
}

- (void)pause {
    _btn.selected = false;
    [((AVPlayerLayer *)_backView.layer).player pause];
    [self showToolViewAndNavigationBar:true];
}

- (CMTime)availableDuration {
    NSArray *loadedTimeRanges = [[((AVPlayerLayer *)_backView.layer).player currentItem] loadedTimeRanges];
    CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];// 获取缓冲区域
    return timeRange.duration;
}

- (void)reset {
    AVPlayer *player = ((AVPlayerLayer *)_backView.layer).player;
    
    [self pause];
    _progress.value = 0;
    [player seekToTime:CMTimeMake(0, 30)];
    if ([_delegate respondsToSelector:@selector(playerControllerDidFinishPlay:)]) {
        [_delegate playerControllerDidFinishPlay:(SHBPlayerController *)self.navigationController];
    }
}

- (NSString *)timeWithCMTime:(CMTime)time {
    
    CGFloat temp = CMTimeGetSeconds(time);
    
    NSInteger tempTime = floor(temp);
    
    NSInteger min = tempTime / 60;
    NSInteger sec = tempTime % 60;
    NSString *m = [NSString stringWithFormat:@"%02ld", (long)min];
    NSString *s = [NSString stringWithFormat:@"%02ld", (long)sec];
    
    return [NSString stringWithFormat:@"%@:%@", m, s];
}

- (void)controlPlayer:(UIButton *)btn {
    AVPlayer *player = ((AVPlayerLayer *)_backView.layer).player;

    if (!btn.selected) {
        [player play];
        _userStop = false;
    } else {
        [player pause];
        _userStop = true;
    }
    btn.selected = !btn.selected;
}

#pragma mark - 
- (void)seekProgress:(UISlider *)slider {
    CGFloat current = slider.value * CMTimeGetSeconds(_item.duration);
    AVPlayer *player = ((AVPlayerLayer *)_backView.layer).player;

    [player pause];
    CMTime time = CMTimeMake(30 * current, 30);
    [player seekToTime:time completionHandler:^(BOOL finished) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            AVPlayer *player = ((AVPlayerLayer *)_backView.layer).player;

            [player play];
        });
    }];
}

#pragma mark - 手势
- (void)tapView:(UITapGestureRecognizer *)tap {
    
    CGPoint point = [tap locationInView:self.view];
    AVPlayer *player = ((AVPlayerLayer *)_backView.layer).player;

    if (CGRectContainsPoint(((AVPlayerLayer *)_backView.layer).videoRect, point)) {
        if (!_btn.selected) {
            [player play];
            _userStop = false;
        } else {
            [player pause];
            _userStop = true;
        }
        _btn.selected = !_btn.selected;
        return;
    }
    
    [self showToolViewAndNavigationBar:!self.navigationController.navigationBarHidden];
}

- (void)changeVolume:(UIPanGestureRecognizer *)pre {
    
    CGPoint point = [pre locationInView:_backView];
    
    switch (pre.state) {
        case UIGestureRecognizerStateBegan: {
            _beginPoint = point;
            break;
        }
        case UIGestureRecognizerStateChanged: {
            CGFloat spaceX = point.x - _beginPoint.x;
            CGFloat spaceY = point.y - _beginPoint.y;
            if (fabs(spaceX) > fabs(spaceY)) {
                break;
            }
            
            CGFloat changeVo = spaceY / 6000.;
            
            UISlider *slider = nil;
            for (UIView *subView in _volumeView.subviews) {
                if ([[subView.class description] isEqualToString:@"MPVolumeSlider"]) {
                    slider = (UISlider *)subView;
                    break;
                }
            }
            
            
            CGFloat temp = slider.value - changeVo;
            temp = temp < 0 ? 0 : (temp > 1 ? 1 : temp);
            slider.value = temp;
            
            if (spaceY > 0) {
                if (point.y < _changePoint.y) {
                    _beginPoint = _changePoint;
                }
            } else {
                //上
                if (point.y > _changePoint.y) {
                    _beginPoint = _changePoint;
                }
            }
            
            _changePoint = point;
            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStateCancelled: {
            _beginPoint = point;
            break;
        }
        default:
            break;
    }
}

#pragma mark - 创建btn
- (UIButton *)creatBtn:(NSString *)title selectedTitle:(NSString *)selectedTitle action:(SEL)action frame:(CGRect)frame {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitle:selectedTitle forState:UIControlStateSelected];
    [btn addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    btn.frame = frame;
    [_toolView addSubview:btn];
    return btn;
}

#pragma mark - UIGestureRecognizerDelegate
/**
 *  过滤手势操作，如果点在_toolView上无效
 */
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    
    CGPoint point = [gestureRecognizer locationInView:self.view];
    
    return !CGRectContainsPoint(_toolView.frame, point);
}


@end

@implementation SHBPlayerController

@dynamic delegate;

+ (SHBPlayerController *)playerWithUrl:(NSURL *)url {
    PlayerController *player = [[PlayerController alloc] init];
    player.url = url;
    SHBPlayerController *shb = [[SHBPlayerController alloc] initWithRootViewController:player];
    return shb;
}

- (void)play {
    PlayerController *player = (PlayerController *)self.topViewController;
    [player play];
}

- (void)setDelegate:(id<SHBPlayerControllerDelegate>)delegate {
    PlayerController *player = (PlayerController *)self.topViewController;
    player.delegate = delegate;
}

#pragma mark - 横屏
- (BOOL)shouldAutorotate {
    return true;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (BOOL)prefersStatusBarHidden {
    return false;
}

//- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
//    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
//    
//    PlayerController *player = (PlayerController *)self.topViewController;
//    [player layout];
//}

@end

