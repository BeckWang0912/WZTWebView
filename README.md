# WebView生成长图

---

iOS开发中，几乎每个app都会有分享功能，有时分享的是一个网页链接，有时确需要把网页生成长图分享出去，iPhone的用户都知道Home键+电源键就可以截屏了，但是这种方式一次只能截取一个屏幕的高度，如果网页超过了屏幕高度，这种方式就行不通了。

所以我利用空闲时间写了一个WebView生成长图的Demo，整合了`UIWebView`和`WKWebView`，让系统去自适应以何种容器加载网页，并集成了防微信进度条功能，至于JS交互，里面就只有很基础的协议，因为每个公司的约定不一样，大家需要因地制宜。话不多说，先码图：

![image](https://github.com/BeckWang0912/WZTWebView/blob/master/WZTWebView/Icon/step1.png)                           ![image](https://github.com/BeckWang0912/WZTWebView/blob/master/WZTWebView/Icon/step2.png)

我们实现简单点的逻辑：把网页生成一张图片（UIImage）

```Objective-C
UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, scale);
[self.layer renderInContext:UIGraphicsGetCurrentContext()];
UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
UIGraphicsEndImageContext();
```

关键代码：`renderInContext` 是`CALayer`的方法,`CALayer`是CoreGraphic底层的图层, 组成UIView。UIGraphic等相关操作Context是Quartz 2D框架中的API, 而Quartz 2D是CoreGraphic的其中一个组成。

这样一个屏幕高度的网页我们就可以保存成图片了，那么多个屏幕的高度呢？思路也很简单，我们先计算出网页的全部可滚动长度

`self.scrollView.contentSize.height`与屏幕的高度 `self.bounds.size.height` ，利用while循环滚动网页来获取每次Context下的UIImage，存入images集合中:

```Objective-C
CGFloat scale = [UIScreen mainScreen].scale;
CGFloat boundsWidth = self.bounds.size.width;
CGFloat boundsHeight = self.bounds.size.height;
CGFloat contentWidth = self.scrollView.contentSize.height;
CGFloat contentHeight = self.scrollView.contentSize.height;
CGPoint offset = self.scrollView.contentOffset;
[self.scrollView setContentOffset:CGPointMake(0, 0)];
```

然后，将图片集合进行拼接，形成一个完整的长图：

```Objective-C
CGSize imageSize = CGSizeMake(contentWidth * scale, self.scrollView.contentSize.height * scale);
UIGraphicsBeginImageContext(imageSize);
[images enumerateObjectsUsingBlock:^(UIImage *image, NSUInteger idx, BOOL *stop) {
     [image drawInRect:CGRectMake(0,scale * boundsHeight * idx,scale * boundsWidth,scale * boundsHeight)];
}];
```

```Objective-C
UIImage *fullImage = UIGraphicsGetImageFromCurrentImageContext();
UIGraphicsEndImageContext();
UIImageView * snapshotView = [[UIImageView alloc] initWithFrame:CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height)];
snapshotView.image = [fullImage resizableImageWithCapInsets:capInsets];
```

完整代码附上：

```Objective-C
#pragma mark - UIWebview 滚动生成长图
- (void)ZTUIWebViewScrollCaptureCompletionHandler:(CGRect)rect withCapInsets:(UIEdgeInsets)capInsets completionHandler:(void(^)(UIImage *capturedImage))completionHandler{
       CGFloat scale = [UIScreen mainScreen].scale;
       CGFloat boundsWidth = self.bounds.size.width;
       CGFloat boundsHeight = self.bounds.size.height;
       CGFloat contentWidth = self.scrollView.contentSize.height;
       CGFloat contentHeight = self.scrollView.contentSize.height;
       CGPoint offset = self.scrollView.contentOffset;
       [self.scrollView setContentOffset:CGPointMake(0, 0)];

       NSMutableArray *images = [NSMutableArray array];
       while (contentHeight > 0) {
          UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, scale);
          [self.layer renderInContext:UIGraphicsGetCurrentContext()];
          UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
          UIGraphicsEndImageContext();
          [images addObject:image];

          CGFloat offsetY = self.scrollView.contentOffset.y;
          [self.scrollView setContentOffset:CGPointMake(0, offsetY + boundsHeight)];
          contentHeight -= boundsHeight;
          }
          
       [self.scrollView setContentOffset:offset];
       CGSize imageSize = CGSizeMake(contentWidth * scale, self.scrollView.contentSize.height * scale);
       UIGraphicsBeginImageContext(imageSize);
       [images enumerateObjectsUsingBlock:^(UIImage *image, NSUInteger idx, BOOL *stop) {
             [image drawInRect:CGRectMake(0,scale * boundsHeight * idx,scale * boundsWidth,scale * boundsHeight)];
       }];
       
       UIImage *fullImage = UIGraphicsGetImageFromCurrentImageContext();
       UIGraphicsEndImageContext();
       UIImageView * snapshotView = [[UIImageView alloc] initWithFrame:CGRectMake(rect.origin.x, rect.origin.y,
       rect.size.width, rect.size.height)];
       snapshotView.image = [fullImage resizableImageWithCapInsets:capInsets];
       completionHandler(snapshotView.image);
}
```

写完后很高兴，马上实践，UIWebView妥妥的完成目标，然而WKWebView生成的长图最后会有一大段的空白页，造成部分页面丢失，比较如下：

![](/assets/full.png) ![](/assets/empty.png)

如果你用WKWebView使用这个方法，会发现最终截取的只有屏幕上显示的一部分是因为UIWebView与WKWebView渲染机制的不同。WKWebView并不能简单的使用`layer.renderInContext`的方法去绘制图形。如果直接调用`layer.renderInContext`需要获取对应的Context, 但是在WKWebView中执行`UIGraphicsGetCurrentContext()`的返回结果是nil。

我做了大量搜索和实践后发现WKWebView中通过直接调用WKWebView的`drawViewHierarchyInRect`方法，可以成功的截取WKWebView的屏幕内容。

```Objective-C
- (BOOL)drawViewHierarchyInRect:(CGRect)rect afterScreenUpdates:(BOOL)afterUpdates NS_AVAILABLE_IOS(7_0);
```

使用时保证afterScreenUpdates = YES

完整代码附上：

`
``Objective-C
#pragma mark - WKWebView 滚动生成长图
- (void)ZTWKWebViewScrollCaptureCompletionHandler:(void(^)(UIImage *capturedImage))completionHandler{
// 制作了一个UIView的副本
UIView *snapShotView = [self snapshotViewAfterScreenUpdates:YES];

snapShotView.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, snapShotView.frame.size.width, snapShotView.frame.size.height);

[self.superview addSubview:snapShotView];

// 获取当前UIView可滚动的内容长度
CGPoint scrollOffset = self.scrollView.contentOffset;

// 向上取整数 － 可滚动长度与UIView本身屏幕边界坐标相差倍数
float maxIndex = ceilf(self.scrollView.contentSize.height/self.bounds.size.height);

// 保持清晰度
UIGraphicsBeginImageContextWithOptions(self.scrollView.contentSize, false, [UIScreen mainScreen].scale);

// 滚动截图
[self ZTContentScrollPageDraw:0 maxIndex:(int)maxIndex drawCallback:^{
UIImage *capturedImage = UIGraphicsGetImageFromCurrentImageContext();
UIGraphicsEndImageContext();

// 恢复原UIView
[self.scrollView setContentOffset:scrollOffset animated:NO];
[snapShotView removeFromSuperview];

completionHandler(capturedImage);
}];
}

// 滚动截图
- (void)ZTContentScrollPageDraw:(int)index maxIndex:(int)maxIndex drawCallback:(void(^)(void))drawCallback{
[self.scrollView setContentOffset:CGPointMake(0, (float)index * self.frame.size.height)];
CGRect splitFrame = CGRectMake(0, (float)index * self.frame.size.height, self.bounds.size.width, self.bounds.size.height);

dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
[self drawViewHierarchyInRect:splitFrame afterScreenUpdates:YES];
if(index < maxIndex){
[self ZTContentScrollPageDraw: index + 1 maxIndex:maxIndex drawCallback:drawCallback];
}else{
drawCallback();
}
});
}
```

至此，WKWebView截屏生成长图实现。

此外，demo还封装了加载进度条NJKWebViewProgress（KVO原理），能自适应UIWebView和WKWebView。

> NJKWebViewProgress

```Objective-C
// 添加KVO
[(ZTWKWebView *)_webView addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
[(ZTWKWebView *)_webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
```

```Objective-C
#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context{

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
```

> ZTWebViewDelegate

```Objective-C
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
```


后续将会更新内容截图功能。……^\_^

