//
//  BrowserViewCtrlBase.h
//  BoyingInstallment
//
//  Created by beck.wang on 16/8/24.
//  Copyright © 2016年 beck.wang. All rights reserved.
//  网页(h5)页面基类
//  特别提醒：针对有些页面头部会重复截取的问题，可以和前端开发约定方案解决：如在点击生成截图的时候，前端跑js隐藏头部，或者把头部和滚动内容放在一个层里

#import <UIKit/UIKit.h>

@interface BrowserViewCtrlBase : UIViewController

// 是否显示加载进度
@property (nonatomic,assign)BOOL  canShowProgress;
// 是否截图保存
@property (nonatomic,assign)BOOL  canCutSavePic;
// 是否需要刷新
@property (nonatomic,assign)BOOL  needReload;
// H5 Url
@property (nonatomic,copy)NSString  *strUrlPath;

- (instancetype)initWithTitle:(NSString*)strPath strTitle:(NSString*)strTitle;

- (void)webGoBack:(UIButton*)sender;

- (void)commonGoBack:(UIButton*)sender;

- (BOOL)jsFunctionDo:(NSString*)strJsFunction;

- (void)shareWebView:(id)sender;

@end
