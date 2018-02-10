//
//  ZTWebView.h
//  WZTWebView
//
//  Created by beck.wang on 17/6/6.
//  Copyright © 2017年 beck.wang. All rights reserved.
//  集合类：综合iOS8之前的UIWebView和之后的WKWebView,并集成了H5页面截取长图和长按内容截取短图功能

#import <UIKit/UIKit.h>

#define isWKWebView NSClassFromString(@"WKWebView")
#define KS_Width   [UIScreen mainScreen].bounds.size.width
#define KS_Heigth  [UIScreen mainScreen].bounds.size.height
#define BIWeakObj(o)   @autoreleasepool {} __weak typeof(o) o ## Weak = o;
#define BIStrongObj(o) @autoreleasepool {} __strong typeof(o) o = o ## Weak;

/**
 导航栏菜单类型
 */
typedef NS_ENUM(NSInteger,ZTWebViewNavType) {
    ZTWebViewNavLinkClicked,
    ZTWebViewNavFormSubmitted,
    ZTWebViewNavBackForward,
    ZTWebViewNavReload,
    ZTWebViewNavResubmitted,
    ZTWebViewNavOther = -1
};

@class ZTWebView;

/**
 定义ZTWebView协议
 */
@protocol ZTWebViewProtocol <NSObject>
@optional
@property (nonatomic, readonly, strong) UIScrollView *scrollView;
@property (nonatomic, readonly, getter=canGoBack) BOOL canGoBack;
@property (nonatomic, readonly, getter=canGoForward) BOOL canGoForward;
@property (nonatomic, readonly, getter=isLoading) BOOL loading;
// use KVO
@property (nonatomic, readonly, copy) NSString *title;
// use KVO
@property (nonatomic, readonly) double estimatedProgress;
// use KVO
@property (nonatomic, readonly) float pageHeight;
// webview's images (images = nil when captureImage is NO)
@property (nonatomic, readonly, copy) NSArray * images;

- (void)loadRequest:(NSURLRequest *)request;
- (void)loadHTMLString:(NSString *)string baseURL:(NSURL *)baseURL;
- (void)reload;
- (void)stopLoading;
- (void)goBack;
- (void)goForward;
- (void)zt_evaluateJavaScript:(NSString*)javaScriptString completionHandler:(void (^)(id, NSError*))completionHandler;
@end

/**
 定义ZTWebView代理
 */
@protocol ZTWebViewDelegate <NSObject>
@optional
- (BOOL)zt_webView:(id<ZTWebViewProtocol>)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(ZTWebViewNavType)navigationType;
- (void)zt_webViewDidStartLoad:(id<ZTWebViewProtocol>)webView;
- (void)zt_webViewDidFinishLoad:(id<ZTWebViewProtocol>)webView;
- (void)zt_webView:(id<ZTWebViewProtocol>)webView didFailLoadWithError:(NSError *)error;
@end

/**
 定义ZTWebView配置选项
 */
@interface ZTWebViewConfiguration : NSObject
@property (nonatomic,assign) BOOL allowsInlineMediaPlayback; // iPhone Safari defaults to NO. iPad Safari defaults to YES
@property (nonatomic,assign) BOOL mediaPlaybackRequiresUserAction; // iPhone and iPad Safari both default to YES
@property (nonatomic,assign) BOOL mediaPlaybackAllowsAirPlay; // iPhone and iPad Safari both default to YES
@property (nonatomic,assign) BOOL suppressesIncrementalRendering; // iPhone and iPad Safari both default to NO
@property (nonatomic,assign) BOOL scalesPageToFit;
@property (nonatomic,assign) BOOL loadingHUD;          //default NO ,if YES webview will add HUD when loading
@property (nonatomic,assign) BOOL captureImage;        //default NO ,if YES webview will capture all image in content;
@property (nonatomic,strong) UIColor *progressColor;   //default blue;
@end


@interface ZTWebView : UIView <ZTWebViewProtocol>
@property (nonatomic,weak) id<ZTWebViewDelegate> delegate;
@property (nonatomic,assign) BOOL  canShowProgress;
// WKWebView 初始化
+(ZTWebView *)webViewWithFrame:(CGRect)frame configuration:(ZTWebViewConfiguration *)configuration;
// WKWebView 滚屏生成长图
- (void)ZTWKWebViewScrollCaptureCompletionHandler:(void(^)(UIImage *capturedImage))completionHandler;
// UIWebView 滚屏生成长图
- (void)ZTUIWebViewScrollCaptureCompletionHandler:(CGRect)rect withCapInsets:(UIEdgeInsets)capInsets completionHandler:(void(^)(UIImage *capturedImage))completionHandler;
@end
