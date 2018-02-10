//
//  BrowserViewCtrlBase.m
//  BoyingInstallment
//
//  Created by beck.wang on 16/8/24.
//  Copyright © 2016年 sboying. All rights reserved.
//  网页(h5)页面基类

#import "BrowserViewCtrlBase.h"
#import "ZTWebView.h"
#import "WebviewPictureViewCtrl.h"

@interface BrowserViewCtrlBase () <ZTWebViewDelegate,ZTWebViewProtocol>
@property (nonatomic,strong)UIScrollView    *mainScrollView;
@property (nonatomic,strong)ZTWebView       *viewWeb;
@end

@implementation BrowserViewCtrlBase

#pragma mark - life cycle
- (instancetype)initWithTitle:(NSString*)strPath strTitle:(NSString*)strTitle{
    self = [super init];
    @synchronized (self) {
        self.canShowProgress = YES;
        self.canCutSavePic = YES;
        self.needReload = NO;
        self.title = strTitle;
        _strUrlPath = strPath;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    
    [self.view addSubview:self.mainScrollView];
    [self.mainScrollView addSubview:self.viewWeb];
    [self.viewWeb setCanShowProgress:self.canShowProgress];
    
    if(self.canCutSavePic){
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(shareWebView:)];
    }
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reloadWebView:)];
    
    [self loadData:_strUrlPath];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationItem.title = self.title;
    
    if([self.title isEqualToString:@""]){ //使用H5自带导航头部
        UIView *statusBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, KS_Width, 20)];
        statusBarView.backgroundColor=[UIColor whiteColor];
        [self.view addSubview:statusBarView];
        [self.navigationController setNavigationBarHidden:YES animated:NO];
    }
    else{  // 使用原生导航头部
        [self.navigationController setNavigationBarHidden:NO animated:NO];
    }
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    self.navigationItem.title = @"";
    [self.viewWeb loadHTMLString:@" " baseURL:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    float ver = [[[UIDevice currentDevice] systemVersion] floatValue];
    if(ver >= 6.0f){
        if(self.isViewLoaded && !self.view.window){
            self.view = nil; //确保下次重新加载
        }
    }
}

- (void)dealloc{
    NSLog(@"webview测试dealloc调用");
}

#pragma mark - UIWebViewDelegate
- (BOOL)zt_webView:(id<ZTWebViewProtocol>)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(ZTWebViewNavType)navigationType{

    if (webView != self.viewWeb) {
        return YES;
    }

    NSString *strUrl = [[request URL] absoluteString];
    
    if ([strUrl isEqualToString:@"about:blank"]){
        return NO;
    }
    
    return [self jsFunctionDo:strUrl];
}

- (void)zt_webViewDidStartLoad:(id<ZTWebViewProtocol>)webView{
    NSLog(@"开始加载");
}

- (void)zt_webViewDidFinishLoad:(id<ZTWebViewProtocol>)webView{
    NSLog(@"加载完成");
}

- (void)zt_webView:(id<ZTWebViewProtocol>)webView didFailLoadWithError:(NSError *)error{
    NSLog(@"加载失败");
    if([error code] == NSURLErrorCancelled){
        return;
    }else if (error.code == NSURLErrorCannotFindHost){
        if ([[[UIDevice currentDevice]systemVersion] floatValue] <= 8.0) {
            UIAlertView *tmpAlertView = [[UIAlertView alloc] initWithTitle:@"" message:@"网络不稳定，请切换网络环境重试！" delegate:self cancelButtonTitle:@"知道了" otherButtonTitles:nil];
            [tmpAlertView show];
        }else {
            UIAlertController *alterVc = [UIAlertController alertControllerWithTitle:@"" message:@"网络不稳定，请切换网络环境重试！" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:nil];
            [alterVc addAction:okAction];
            [self presentViewController:alterVc animated:YES completion:nil];
        }
    }else{
        if ([[[UIDevice currentDevice]systemVersion] floatValue] <= 8.0) {
            UIAlertView *tmpAlertView = [[UIAlertView alloc] initWithTitle:@"" message:@"页面丢失!" delegate:self cancelButtonTitle:@"知道了" otherButtonTitles:nil];
            [tmpAlertView show];
        }else {
            UIAlertController *alterVc = [UIAlertController alertControllerWithTitle:@"" message:@"页面丢失！" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:nil];
            [alterVc addAction:okAction];
            [self presentViewController:alterVc animated:YES completion:nil];
        }
    }
}

#pragma mark - BrowserViewCtrlDelegate
// JS返回函数
- (BOOL)jsFunctionDo:(NSString*)strJsFunction{
    if (!strJsFunction || [strJsFunction length] <= 0 ||[strJsFunction isEqualToString:@"about:blank"]){
        return NO;
    }
    BOOL isDo = YES;
    
    // 这里可以处理与js简单的交互，通用处理在基类即可，如回退操作，jsGoBack()是与前端人员约定的调用函数，具体到每个不同的页面可以在子类中复写该函数
    NSRange range = [strJsFunction rangeOfString:@"jsGoBack"];
    if (range.location != NSNotFound) {
        [self.navigationController popViewControllerAnimated:YES];
        isDo = NO;
    }
    
    return isDo;
}

#pragma mark - 数据加载
- (void)loadData:(NSString*)tagertUrl{
    NSURL *url = [NSURL URLWithString:tagertUrl];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    request = [NSURLRequest requestWithURL:[NSURL URLWithString:request.URL.absoluteString]];
    [self.viewWeb loadRequest:request];
}

#pragma mark - getters and setters
- (UIScrollView*)mainScrollView{
    if (!_mainScrollView) {
        CGRect rect = [UIScreen mainScreen].bounds;
        _mainScrollView = [[UIScrollView alloc] initWithFrame:rect];
    }
    return _mainScrollView;
}

- (ZTWebView*)viewWeb{
    if (!_viewWeb) {
        ZTWebViewConfiguration *configuration = [[ZTWebViewConfiguration alloc] init];
        configuration.scalesPageToFit = YES;
        configuration.loadingHUD = YES;
        configuration.captureImage = NO; // 是否捕获H5内的image
        configuration.progressColor = [UIColor redColor];
        _viewWeb = [ZTWebView webViewWithFrame:[UIScreen mainScreen].bounds configuration:configuration];
        _viewWeb.delegate = self;
        _viewWeb.scrollView.showsVerticalScrollIndicator = NO;
        _viewWeb.scrollView.showsHorizontalScrollIndicator = NO;
    }
    return _viewWeb;
}

#pragma mark - private mthod
- (void)webGoBack:(UIButton *)sender{
    return [self.viewWeb canGoBack] ? [self.viewWeb goBack] : [self commonGoBack:nil];
}

- (void)commonGoBack:(UIButton*)sender{
    CATransition* transition = [CATransition animation];
    transition.duration = 0.3;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionPush;
    [self.navigationController.view.layer addAnimation:transition forKey:nil];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)shareWebView:(id)sender{
    BIWeakObj(self)
    if(isWKWebView){ // >= iOS8 WKWebView截图生成长图
        [self.viewWeb ZTWKWebViewScrollCaptureCompletionHandler:^(UIImage *capturedImage) {
            [selfWeak shareForCutPIC:capturedImage];
        }];
    }else{
        // <=iOS7 UIWebView截图生成长图
        CGRect snapshotFrame = CGRectMake(0, 0, selfWeak.viewWeb.scrollView.contentSize.width, selfWeak.viewWeb.scrollView.contentSize.height);
        UIEdgeInsets snapshotEdgeInsets = UIEdgeInsetsZero;
        [self.viewWeb ZTUIWebViewScrollCaptureCompletionHandler:snapshotFrame withCapInsets:snapshotEdgeInsets completionHandler:^(UIImage *capturedImage) {
            [selfWeak shareForCutPIC:capturedImage];
        }];
    }
}

-(void)shareForCutPIC:(UIImage*)shareImage{
    WebviewPictureViewCtrl *picCtrl = [[WebviewPictureViewCtrl alloc] init];
    [picCtrl setWebImg:shareImage andUrl:_strUrlPath];
    [self presentViewController:[[UINavigationController alloc] initWithRootViewController:picCtrl] animated:YES completion:nil];
}

- (void)reloadWebView:(id)sender{
    [self.viewWeb reload];
}

@end
