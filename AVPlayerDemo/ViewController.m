//
//  ViewController.m
//  AVPlayerDemo
//
//  Created by shenhongbang on 16/4/6.
//  Copyright © 2016年 shenhongbang. All rights reserved.
//

#import "ViewController.h"
#import "SHBPlayerController.h"
#import <MobileCoreServices/MobileCoreServices.h>

@interface ViewController ()<UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate, UIImagePickerControllerDelegate, SHBPlayerControllerDelegate>

@end

@implementation ViewController {
    
    __weak IBOutlet UITableView *_tableView;
    
    NSArray         *_dataArray;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    NSString *chidaohebeiji = @"http://main.gslb.ku6.com/s1/wPdFbrJ7V578E2bx/1228953319193/7d9963cd96e0fb1eda9623ec3a504c89/1459923636272/v517/30/27/GIZTEuhSQZOsfPJ1j2Lntg.mp4";
    NSString *xihaiqingge = @"http://150.138.217.85:110/118/15/31/letv-uts/14/ver_00_22-303331727-avc-651506-aac-64009-353867-31928314-9eef407cd5ec30cae397dcc2f258e56c-1421986899071.letv?crypt=61aa7f2e800&b=721&nlh=4096&nlt=60&bf=89&p2p=1&video_type=mp4&termid=2&tss=no&platid=3&splatid=301&its=0&qos=1&fcheck=0&mltag=1&proxy=2525663541,709972053,1032384081&uid=1931268481.rp&keyitem=GOw_33YJAAbXYE-cnQwpfLlv_b2zAkYctFVqe5bsXQpaGNn3T1-vhw..&ntm=1459934400&nkey=015ec55389608c4f7f3108b731991c37&nkey2=a093d1dd312c67e692468f3e4c730446&geo=CN-15-187-1&mmsid=20256800&tm=1459923456&key=58ade618f244d09ab7508d96c6a59393&playid=0&vtype=13&cvid=1054671859447&payff=0&p1=0&p2=04&ostype=android&hwtype=un&uuid=192345613537&errc=0&gn=1224&buss=0&cips=115.28.209.129";
    
    NSString *hongyanjiu = @"http://150.138.217.99:110/172/51/5/letv-uts/14/ver_00_22-1004125265-avc-317704-aac-32018-225800-10119786-6d6178ad9a190bec0114555f2f816ee6-1446539801248.letv?crypt=35aa7f2e402&b=358&nlh=4096&nlt=60&bf=90&p2p=1&video_type=mp4&termid=2&tss=no&platid=3&splatid=301&its=0&qos=1&fcheck=0&mltag=1&proxy=3702879626,611246599,3702879623&uid=1931268481.rp&keyitem=GOw_33YJAAbXYE-cnQwpfLlv_b2zAkYctFVqe5bsXQpaGNn3T1-vhw..&ntm=1459945800&nkey=8ef59a07fbf0604eaeca8bd21ef5f65e&nkey2=5778ed7fcfe48ffd689685ef4f9a9d9b&geo=CN-15-187-1&mmsid=36751843&tm=1459934873&key=48ef64c724f5c7727d2ae5090b233e43&playid=0&vtype=21&cvid=1054671859447&payff=0&p1=0&p2=04&ostype=android&hwtype=un&uuid=193488315933&errc=0&gn=1224&buss=0&cips=115.28.209.129";
    
    _dataArray = @[chidaohebeiji, xihaiqingge, hongyanjiu];
    [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:NSStringFromClass([UITableViewCell class])  ];
    _tableView.tableFooterView = [UIView new];
    
}

- (IBAction)gotoPlayer:(id)sender {
    
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.mediaTypes = @[(NSString *)kUTTypeMovie];
    picker.delegate = self;
    [self presentViewController:picker animated:true completion:nil];
}

#pragma mark - <UITableViewDelegate, UITableViewDataSource>
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([UITableViewCell class]) forIndexPath:indexPath];
    
    NSString *title = nil;
    
    switch (indexPath.row) {
        case 0:
            title = @"赤道和北极";
            break;
            case 1:
            title = @"西海情歌";
            break;
            case 2:
            title = @"红颜旧";
            break;
        default:
            break;
    }
    cell.textLabel.text = title;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _dataArray.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *url = _dataArray[indexPath.row];
    [self gotoPlayWithUrl:[NSURL URLWithString:url]];
}

#pragma mark - UINavigationControllerDelegate, UIImagePickerControllerDelegate
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:true completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    
    __weak typeof(self) SHB = self;
    [picker dismissViewControllerAnimated:true completion:^{
        if ([info[UIImagePickerControllerMediaType] isEqualToString:(NSString *)kUTTypeMovie]) {
            NSURL *url = info[UIImagePickerControllerMediaURL];
            //加个暂停
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [SHB gotoPlayWithUrl:url];
            });
        }
    }];
}

- (void)gotoPlayWithUrl:(NSURL *)url {
    SHBPlayerController *player = [SHBPlayerController playerWithUrl:url];
    player.delegate = self;
    __weak typeof(self) SHB = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [SHB presentViewController:player animated:true completion:^{
            [player play];
        }];
    });
}

#pragma mark - SHBPlayerControllerDelegate
- (void)playerControllerDidFinishPlay:(SHBPlayerController *)playerController {
    [playerController dismissViewControllerAnimated:true completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
