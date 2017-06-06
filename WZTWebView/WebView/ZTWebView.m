//
//  ZTWebView.m
//  WZTWebView
//
//  Created by beck.wang on 17/6/6.
//  Copyright © 2017年 beck.wang. All rights reserved.
//

#import "ZTWebView.h"
#import <WebKit/WebKit.h>
#import "NJKWebViewProgress.h"

#pragma mark - ZTWKWebView
@interface ZTWKWebView : WKWebView<ZTWebViewProtocol>

@end

#pragma mark - ZTUIWebView
@interface ZTUIWebView : UIWebView<ZTWebViewProtocol>

@end

#pragma mark - ZTWebViewJS
@interface ZTWebViewJS : NSObject
+(NSString *)scalesPageToFitJS;
+(NSString *)imgsElement;
@end

#pragma mark - ZTWebView
@interface ZTWebView () <WKNavigationDelegate,UIWebViewDelegate,NJKWebViewProgressDelegate>

@property (nonatomic,strong) id<ZTWebViewProtocol> webView;
@property (nonatomic,copy) NSString     *title;
@property (nonatomic,assign) double     estimatedProgress;
@property (nonatomic,assign) float      pageHeight;
@property (nonatomic,copy) NJKWebViewProgress         *webViewProgress;
@property (nonatomic,strong) UIActivityIndicatorView  *indicatorView;
@property (nonatomic,strong) ZTWebViewConfiguration   *configuration;
@property (nonatomic,copy) NSArray      *images;
@property (nonatomic,strong) UIProgressView           *progressView;

@end

@implementation ZTWebView
// 初始化
+ (ZTWebView *)webViewWithFrame:(CGRect)frame configuration:(ZTWebViewConfiguration *)configuration
{
    return [[self alloc] initWithFrame:frame configuration:configuration];
}

-(instancetype)initWithFrame:(CGRect)frame configuration:(ZTWebViewConfiguration *)configuration
{
    if (self = [super initWithFrame:frame])
    {
        _configuration = configuration;
        
        if (isWKWebView) // iOS8 WKWebView
        {
            if (configuration)
            {
                WKWebViewConfiguration *webViewconfiguration = [[WKWebViewConfiguration alloc] init];
                webViewconfiguration.allowsInlineMediaPlayback = configuration.allowsInlineMediaPlayback;
                webViewconfiguration.mediaTypesRequiringUserActionForPlayback = configuration.mediaPlaybackRequiresUserAction;
                webViewconfiguration.allowsAirPlayForMediaPlayback = configuration.mediaPlaybackAllowsAirPlay;
                webViewconfiguration.suppressesIncrementalRendering = configuration.suppressesIncrementalRendering;
                
                WKUserContentController *wkUController = [[WKUserContentController alloc] init];
                
                if (!configuration.scalesPageToFit) {
                    NSString *jScript = [ZTWebViewJS scalesPageToFitJS];
                    WKUserScript *wkUScript = [[WKUserScript alloc] initWithSource:jScript injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
                    [wkUController addUserScript:wkUScript];
                    WKUserScript *wkScript1 = [[WKUserScript alloc] initWithSource:[ZTWebViewJS imgsElement] injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
                    [wkUController addUserScript:wkScript1];
                }
                
                if (configuration.captureImage) {
                    NSString *jScript = [ZTWebViewJS imgsElement];
                    WKUserScript *wkUScript = [[WKUserScript alloc] initWithSource:jScript injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
                    [wkUController addUserScript:wkUScript];
                }
                
                webViewconfiguration.userContentController = wkUController;
                _webView = (id)[[ZTWKWebView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height) configuration:webViewconfiguration];
            }
            else{
                _webView = (id)[[ZTWKWebView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
            }
            
            [(ZTWKWebView *)_webView setNavigationDelegate:self];
            // 添加KVO
            [(ZTWKWebView *)_webView addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
            [(ZTWKWebView *)_webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
        }
        else // iOS7 UIWebView
        {
            _webView = (id)[[ZTUIWebView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
            
            if (configuration)
            {
                [(ZTUIWebView *)_webView setAllowsInlineMediaPlayback:configuration.allowsInlineMediaPlayback];
                [(ZTUIWebView *)_webView setMediaPlaybackRequiresUserAction:configuration.mediaPlaybackRequiresUserAction];
                [(ZTUIWebView *)_webView setMediaPlaybackAllowsAirPlay:configuration.mediaPlaybackAllowsAirPlay];
                [(ZTUIWebView *)_webView setSuppressesIncrementalRendering:configuration.suppressesIncrementalRendering];
                [(ZTUIWebView *)_webView setScalesPageToFit:configuration.scalesPageToFit];
            }
            
            _webViewProgress = [[NJKWebViewProgress alloc] init];
            [(ZTUIWebView *)_webView setDelegate:_webViewProgress];
            _webViewProgress.webViewProxyDelegate = self;
            _webViewProgress.progressDelegate = self;
        }
        
        if (configuration.loadingHUD) {
            [(UIView *)_webView addSubview:self.indicatorView];
        }
        
        [(UIView *)_webView setBackgroundColor:[UIColor clearColor]];
        
        [self addSubview:(UIView *)_webView];
        
        [self addSubview:self.progressView];
    }
    return self;
}

#pragma mark - WKWebView 滚动生成长图
- (void)ZTWKWebViewScrollCaptureCompletionHandler:(void(^)(UIImage *capturedImage))completionHandler
{
    // 制作了一个UIView的副本
    UIView *snapShotView = [self snapshotViewAfterScreenUpdates:YES];
    
    snapShotView.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, snapShotView.frame.size.width, snapShotView.frame.size.height);
    
    [self.superview addSubview:snapShotView];
    
    // 获取当前UIView可滚动的内容长度
    CGPoint scrollOffset = self.scrollView.contentOffset;
    
    // 向上取整数 － 可滚动长度与UIView本身屏幕边界坐标相差倍数
    float maxIndex = ceilf(self.scrollView.contentSize.height/self.bounds.size.height);
    
    // [UIScreen mainScreen].scale 保持清晰度
    UIGraphicsBeginImageContextWithOptions(self.scrollView.contentSize, false, [UIScreen mainScreen].scale);
    
    // 循环截图
    [self ZTContentScrollPageDraw:0 maxIndex:(int)maxIndex drawCallback:^{
        
        UIImage *capturedImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        // 恢复原UIView
        [self.scrollView setContentOffset:scrollOffset animated:NO];
        [snapShotView removeFromSuperview];
        
        completionHandler(capturedImage);
    }];
}

- (void)ZTContentScrollPageDraw:(int)index maxIndex:(int)maxIndex drawCallback:(void(^)())drawCallback
{
    
    [self.scrollView setContentOffset:CGPointMake(0, (float)index * self.frame.size.height)];
    
    CGRect splitFrame = CGRectMake(0, (float)index * self.frame.size.height, self.bounds.size.width, self.bounds.size.height);
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        [self drawViewHierarchyInRect:splitFrame afterScreenUpdates:YES];
        
        if(index < maxIndex){
            [self ZTContentScrollPageDraw:index + 1 maxIndex:maxIndex drawCallback:drawCallback];
        }
        else{
            drawCallback();
        }
    });
}

#pragma mark getter & setter
- (UIProgressView*)progressView{
    if (!_progressView) {
        _progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 0.5)];
        _progressView.tintColor = [UIColor blueColor];
        _progressView.trackTintColor = [UIColor whiteColor];
    }
    return _progressView;
}

- (void)setCanShowProgress:(BOOL)canShowProgress{
    _canShowProgress = canShowProgress;
}

-(UIActivityIndicatorView *)indicatorView{
    if (!_indicatorView) {
        _indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        _indicatorView.hidesWhenStopped = YES;
    }
    return _indicatorView;
}

#pragma mark - ZTWebViewProtocol
- (UIScrollView *)scrollView{
    return _webView.scrollView;
}

- (void)loadRequest:(NSURLRequest *)request{
    [_webView loadRequest:request];
}

- (void)loadHTMLString:(NSString *)string baseURL:(NSURL *)baseURL{
    [_webView loadHTMLString:string baseURL:baseURL];
}

- (void)reload{
    [_webView reload];
}

- (void)stopLoading{
    [_webView stopLoading];
}

- (void)goBack{
    [_webView goBack];
}

- (void)goForward{
    [_webView goForward];
}

- (BOOL)canGoBack{
    return _webView.canGoBack;
}

- (BOOL)canGoForward{
    return _webView.canGoForward;
}

- (BOOL)isLoading{
    return _webView.isLoading;
}

- (void)zt_evaluateJavaScript:(NSString*)javaScriptString completionHandler:(void (^)(id, NSError*))completionHandler{
    [_webView zt_evaluateJavaScript:javaScriptString completionHandler:completionHandler];
}

#pragma mark - NJKWebViewProgressDelegate
- (void)webViewProgress:(NJKWebViewProgress *)webViewProgress updateProgress:(float)progress{
    self.estimatedProgress = progress;
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"title"]) {
        self.title = change[NSKeyValueChangeNewKey];
        return;
    }
    
    if (self.canShowProgress && object == self.webView && [keyPath isEqualToString:@"estimatedProgress"]) {
        CGFloat newprogress = [[change objectForKey:NSKeyValueChangeNewKey] doubleValue];
        self.estimatedProgress = newprogress;
        if (newprogress == 1) {
            self.progressView.hidden = YES;
            [self.progressView setProgress:0 animated:NO];
        }else {
            self.progressView.hidden = NO;
            [self.progressView setProgress:newprogress animated:YES];
        }
        return;
    }
    
    return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

#pragma mark - WKWebViewNavigation Delegate
- (void)webView:(WKWebView*)webView decidePolicyForNavigationAction:(WKNavigationAction*)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    BOOL load = YES;
    if ([self.delegate respondsToSelector:@selector(zt_webView:shouldStartLoadWithRequest:navigationType:)]) {
        load = [self.delegate zt_webView:(ZTWebView<ZTWebViewProtocol>*)self shouldStartLoadWithRequest:navigationAction.request navigationType:[self navigationTypeConvert:navigationAction.navigationType]];
    }
    if (load) {
        decisionHandler(WKNavigationActionPolicyAllow);
    }else{
        decisionHandler(WKNavigationActionPolicyCancel);
    }
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation
{
    [_indicatorView startAnimating];
    if ([self.delegate respondsToSelector:@selector(zt_webViewDidStartLoad:)]) {
        [self.delegate zt_webViewDidStartLoad:(ZTWebView<ZTWebViewProtocol>*)self];
    }
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation
{
    [_indicatorView stopAnimating];
    if ([self.delegate respondsToSelector:@selector(zt_webViewDidFinishLoad:)]) {
        [self.delegate zt_webViewDidFinishLoad:(ZTWebView<ZTWebViewProtocol>*)self];
    }
    
    [self zt_evaluateJavaScript:@"document.body.scrollHeight" completionHandler:^(id heitht, NSError *error) {
        if (!error) {
            self.pageHeight = [heitht floatValue];
        }
    }];
    
    if (_configuration.captureImage) {
        [self zt_evaluateJavaScript:@"imgsElement()" completionHandler:^(NSString * imgs, NSError *error) {
            if (!error && imgs.length) {
                _images = [imgs componentsSeparatedByString:@","];
            }
        }];
    }
}

- (void)webView:(WKWebView *)webView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error
{
    [_indicatorView stopAnimating];
    if ([self.delegate respondsToSelector:@selector(zt_webViewDidFinishLoad:)]) {
        [self.delegate zt_webView:(ZTWebView<ZTWebViewProtocol>*)self didFailLoadWithError:error];
    }
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error
{
    [_indicatorView stopAnimating];
    if ([self.delegate respondsToSelector:@selector(zt_webView:didFailLoadWithError:)]) {
        [self.delegate zt_webView:(ZTWebView<ZTWebViewProtocol>*)self didFailLoadWithError:error];
    }
}

#pragma mark - UIWebView Delegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    BOOL isLoad = YES;
    if ([self.delegate respondsToSelector:@selector(zt_webView:shouldStartLoadWithRequest:navigationType:)]) {
        isLoad = [self.delegate zt_webView:(ZTWebView<ZTWebViewProtocol>*)self shouldStartLoadWithRequest:request navigationType:[self navigationTypeConvert:navigationType]];
    }
    return isLoad;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [_indicatorView startAnimating];
    if ([self.delegate respondsToSelector:@selector(zt_webViewDidStartLoad:)]) {
        [self.delegate zt_webViewDidStartLoad:(ZTWebView<ZTWebViewProtocol>*)self];
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [_indicatorView stopAnimating];
    self.title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    if ([self.delegate respondsToSelector:@selector(zt_webViewDidFinishLoad:)]) {
        [self.delegate zt_webViewDidFinishLoad:(ZTWebView<ZTWebViewProtocol> *)self];
    }
    
    [self zt_evaluateJavaScript:@"document.body.scrollHeight" completionHandler:^(id heitht, NSError *error) {
        if (!error) {
            self.pageHeight = [heitht floatValue];
        }
    }];
    
    if (_configuration.captureImage) {
        [self zt_evaluateJavaScript:[ZTWebViewJS imgsElement] completionHandler:nil];
        [self zt_evaluateJavaScript:@"imgsElement()" completionHandler:^(NSString * imgs, NSError *error) {
            if (!error && imgs.length) {
                _images = [imgs componentsSeparatedByString:@","];
            }
        }];
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [_indicatorView stopAnimating];
    if ([self.delegate respondsToSelector:@selector(zt_webView:didFailLoadWithError:)]) {
        [self.delegate zt_webView:(ZTWebView<ZTWebViewProtocol>*)self didFailLoadWithError:error];
    }
}

#pragma mark -Privity
-(NSInteger)navigationTypeConvert:(NSInteger)type;
{
    NSInteger navigationType;
    
    if (isWKWebView) {
        switch (type) {
                case WKNavigationTypeLinkActivated:
                navigationType = ZTWebViewNavLinkClicked;
                break;
                case WKNavigationTypeFormSubmitted:
                navigationType = ZTWebViewNavFormSubmitted;
                break;
                case WKNavigationTypeBackForward:
                navigationType = ZTWebViewNavBackForward;
                break;
                case WKNavigationTypeReload:
                navigationType = ZTWebViewNavReload;
                break;
                case WKNavigationTypeFormResubmitted:
                navigationType = ZTWebViewNavResubmitted;
                break;
                case WKNavigationTypeOther:
                navigationType = ZTWebViewNavOther;
                break;
            default:
                navigationType = ZTWebViewNavOther;
                break;
        }
    }
    else{
        switch (type) {
                case UIWebViewNavigationTypeLinkClicked:
                navigationType = ZTWebViewNavLinkClicked;
                break;
                case UIWebViewNavigationTypeFormSubmitted:
                navigationType = ZTWebViewNavFormSubmitted;
                break;
                case UIWebViewNavigationTypeBackForward:
                navigationType = ZTWebViewNavBackForward;
                break;
                case UIWebViewNavigationTypeReload:
                navigationType = ZTWebViewNavReload;
                break;
                case UIWebViewNavigationTypeFormResubmitted:
                navigationType = ZTWebViewNavResubmitted;
                break;
                case UIWebViewNavigationTypeOther:
                navigationType = ZTWebViewNavOther;
                break;
            default:
                navigationType = ZTWebViewNavOther;
                break;
        }
    }
    return navigationType;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [(UIView *)_webView setFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
    _indicatorView.frame = CGRectMake(0, 0, 20, 20);
    _indicatorView.center = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
}

- (void)setNeedsLayout
{
    [super setNeedsLayout];
    [(UIView *)_webView setNeedsLayout];
}

- (void)dealloc
{
    if (isWKWebView) {
        [(ZTWebView *)_webView removeObserver:self forKeyPath:@"title"];
        [(ZTWebView *)_webView removeObserver:self forKeyPath:@"estimatedProgress"];
    }
}
@end

@implementation ZTWKWebView

- (void)zt_evaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^)(id, NSError *))completionHandler
{
    [self evaluateJavaScript:javaScriptString completionHandler:completionHandler];
}

@end

@implementation ZTUIWebView

- (void)zt_evaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^)(id, NSError *))completionHandler
{
    NSString* result = [self stringByEvaluatingJavaScriptFromString:javaScriptString];
    if (completionHandler) {
        completionHandler(result,nil);
    }
}

@end

@implementation ZTWebViewConfiguration

- (instancetype)init
{
    if (self = [super init]) {
        _allowsInlineMediaPlayback = NO;
        _mediaPlaybackRequiresUserAction = YES;
        _suppressesIncrementalRendering = NO;
    }
    return self;
}
@end

@implementation ZTWebViewJS

+ (NSString *)scalesPageToFitJS{
    
    return @"var meta = document.createElement('meta'); \
    meta.name = 'viewport'; \
    meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no'; \
    var head = document.getElementsByTagName('head')[0];\
    head.appendChild(meta);";
}

+(NSString *)imgsElement{
    
    return @"function imgsElement(){\
    var imgs = document.getElementsByTagName(\"img\");\
    var imgScr = '';\
    for(var i=0;i<imgs.length;i++){\
    imgs[i].onclick=function(){\
    document.location='img'+this.src;\
    };\
    if(i == imgs.length-1){\
    imgScr = imgScr + imgs[i].src;\
    break;\
    }\
    imgScr = imgScr + imgs[i].src + ',';\
    };\
    return imgScr;\
    };";
}


@end
