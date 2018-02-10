//
//  WebviewPictureViewCtrl.m
//  BoyingInstallment
//
//  Created by beck.wang on 17/3/29.
//  Copyright © 2017年 beck.wang. All rights reserved.
//

#import "WebviewPictureViewCtrl.h"

// 屏幕尺寸
#define KS_Width   [UIScreen mainScreen].bounds.size.width
#define KS_Heigth  [UIScreen mainScreen].bounds.size.height

@interface WebviewPictureViewCtrl ()
@property (nonatomic,strong) UIScrollView  *scrollView;
@property (nonatomic,strong) UIImageView   *imageView;
@property (nonatomic,strong) UIImage       *webImg;
@property (nonatomic,copy) NSString        *strUrl;
@property (nonatomic,strong) UIButton      *btnShare;
@property (nonatomic,strong) UIButton      *btnSave;
@end

@implementation WebviewPictureViewCtrl

-(void)setWebImg:(UIImage *)webImg andUrl:(NSString *)url{
    _webImg = webImg;
    _strUrl = url;
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationItem.title = @"图片预览";
    [self setHidesBottomBarWhenPushed:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(closeCtrl:)];
    
    [self.view addSubview:self.scrollView];
    [self.scrollView addSubview:self.imageView];
    [self.view addSubview:self.btnShare];
    [self.view addSubview:self.btnSave];
    self.scrollView.contentInset = UIEdgeInsetsMake(0, 0, self.imageView.frame.origin.y + self.imageView.frame.size.height - (KS_Heigth -30), 0);
}

#pragma mark - getter & setter
- (UIScrollView*)scrollView{
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 64 , KS_Width, KS_Heigth)];
        [_scrollView setContentSize:CGSizeMake(KS_Width, KS_Heigth + 80)];
        _scrollView.userInteractionEnabled = YES;
        _scrollView.scrollEnabled = YES;
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.showsVerticalScrollIndicator = NO;
    }
    return _scrollView;
}

-(UIImageView*)imageView{
    if (!_imageView) {
        CGRect rect = [UIScreen mainScreen].bounds;
        rect.origin.y -= 64;
        rect.size.height = _webImg.size.height;
        _imageView.backgroundColor = [UIColor whiteColor];
        _imageView = [[UIImageView alloc] initWithFrame:rect];
        _imageView.image = _webImg;
    }
    return _imageView;
}

-(UIButton*)btnShare{
    if (!_btnShare) {
        _btnShare = [UIButton buttonWithType:UIButtonTypeCustom];
        _btnShare.frame = CGRectMake(0, KS_Heigth - 52, KS_Width/2, 52);
        [_btnShare setImage:[UIImage imageNamed:@"icon-send"] forState:UIControlStateNormal];
        [_btnShare setTitle:@"发送给朋友" forState:UIControlStateNormal];
        [_btnShare setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_btnShare setTitleColor:[UIColor blueColor] forState:UIControlStateSelected];
        _btnShare.titleLabel.font = [UIFont systemFontOfSize:18.0f];
        _btnShare.backgroundColor = [UIColor colorWithWhite:0.f alpha:0.7f];
        
        _btnShare.imageEdgeInsets = UIEdgeInsetsMake(0, 20, 0, 25);
        _btnShare.titleEdgeInsets = UIEdgeInsetsMake(0, _btnShare.imageView.frame.size.width+5, 0, 0);
        [_btnShare addTarget:self action:@selector(goShare:) forControlEvents:UIControlEventTouchUpInside];
        
        UIButton *line = [[UIButton alloc] initWithFrame:CGRectMake(KS_Width/2-1, 10, 1, 32)];
        line.backgroundColor = [UIColor lightGrayColor];
        [_btnShare addSubview:line];
    }
    return _btnShare;
}

-(UIButton*)btnSave{
    if (!_btnSave) {
        _btnSave = [UIButton buttonWithType:UIButtonTypeCustom];
        _btnSave.frame = CGRectMake(KS_Width/2, KS_Heigth - 52, KS_Width/2,52);
        [_btnSave setImage:[UIImage imageNamed:@"icon-save-local"] forState:UIControlStateNormal];
        [_btnSave setTitle:@"保存到相册" forState:UIControlStateNormal];
        [_btnSave setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_btnSave setTitleColor:[UIColor blueColor] forState:UIControlStateSelected];
        _btnSave.titleLabel.font = [UIFont systemFontOfSize:18.0f];
        _btnSave.backgroundColor = [UIColor colorWithWhite:0.f alpha:0.7f];
        
        _btnSave.imageEdgeInsets = UIEdgeInsetsMake(0, 20, 0, 25);
        _btnSave.titleEdgeInsets = UIEdgeInsetsMake(0, _btnSave.imageView.frame.size.width + 5, 0, 0);
        [_btnSave addTarget:self action:@selector(goSave:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _btnSave;
}

-(void)cancelShare:(id)sender{
    [self dismissViewControllerAnimated:YES completion:^{
        NSLog(@"取消分享图片");
    }];
}

// 分享图片
-(void)goShare:(id)sender{
    NSLog(@"分享图片");
}

// 保存图片
-(void)goSave:(id)sender{
    UIImageWriteToSavedPhotosAlbum(_webImg, self, NULL, NULL);
    if ([[[UIDevice currentDevice]systemVersion] floatValue] <= 8.0) {
        UIAlertView *tmpAlertView = [[UIAlertView alloc] initWithTitle:@"" message:@"保存到相册成功！" delegate:self cancelButtonTitle:@"知道了" otherButtonTitles:nil];
        [tmpAlertView show];
    }else {
        UIAlertController *alterVc = [UIAlertController alertControllerWithTitle:@"" message:@"保存到相册成功！" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:nil];
        [alterVc addAction:okAction];
        [self presentViewController:alterVc animated:YES completion:nil];
    }
}

- (void)closeCtrl:(id)sender{
   [self dismissViewControllerAnimated:YES completion:nil];
}

@end
