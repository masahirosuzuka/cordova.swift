//
//  CDVViewController.swift
//  CordovaSwiftLib
//
//  Created by Masahiro Suzuka on 2014/10/05.
//  Copyright (c) 2014年 Masahiro Suzuka. All rights reserved.
//

import UIKit

class CDVViewController: UIViewController, UIWebViewDelegate, CDVScreenOrientationDelegate {
  
  @IBOutlet var webView : UIWebView?;
  
  var pluginObjects : NSMutableDictionary;
  var pluginsMap : NSDictionary;
  var supportedOrientations : NSArray;
  var settings : NSMutableDictionary;
  var configParser : NSXMLParser;
  var whiteList : CDVWhiteList;
  var loadFromString : Bool;
  var wwwFolderName : NSString;
  var startPage : NSString;
  var commandQueue : AnyObject<CDVCommandQueue>.Type;
  var commandDelegate : CDVCommandDelegate;
  var userAgent : NSString;
  var initialized : Bool;
  var openURL : NSURL;
  
  internal var _commandDelegate : AnyObject<CDVCommandDelegate>.Type;
  internal var _userAgent : CDVCommendQueue;
  internal var _userAgent : NSString;
  
  private var _userAgentLockToken : NSInteger;
  private var _webViewDelegate : CDVWebViewDelegate;
  
  func __init() {
    if self != nil && self.initialized {
      _commandQueue = CDVCommandQueue(self);
      _commandDelegate = CDVCommandDelegate(self);
      
      NSNotificationCenter.defaultCenter().addObserver(self, selector:"onAppWillTerminale:", name: UIApplicationWillTerminateNotification, object: nil);
      
      NSNotificationCenter.defaultCenter().addObserver(self, selector: "onAppWillResignActive:", name: UIApplicationWillResignActiveNotification, object: nil);
      
      NSNotificationCenter.defaultCenter().addObserver(self, selector: "onAppDidBecomeActive:", name: UIApplicationDidBecomeActiveNotification, object: nil);
      
      NSNotificationCenter.defaultCenter().addObserver(self, selector:"onAppWillEnterForeground:" , name: UIApplicationWillEnterForegroundNotification, object: nil);
      
      NSNotificationCenter.defaultCenter().addObserver(self, selector: "onAppDidEnterBackground:", name: UIApplicationDidEnterBackgroundNotification, object: nil);
      
      NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleOpenURL:", name: CDVPluginHandleOpenURLNotification, object: nil);
      
      self.supportedOrientations = self.parseInterfaceOrientations(NSBundle.mainBundle().infoDictionary["UISupportedInterfaceOrientations"]);
      
//      self.printMultitaskingInfo();
      self.printDeprecationNotice();
      self.initialized = true;
      self.loadSettings();
    }
  }
  
  init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
    self = super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil);
    self.__init();
    return self;
  }
  
  init(coder aDecoder: NSCoder) {
    self = super.init(coder: aDecoder);
    self.__init();
    return self;
  }
  
  init() {
    self = super.init();
    self.__init();
    return self;
  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated);
  }
  
  override func viewDidDisappear(animated: Bool) {
    super.viewWillDisappear(animated);
  }
  
//  func printDeprecationNotice() {
//    if IsAtLeastiOSVersion("5.0") {
//      print("CRITICAL: For Cordova 2.0, you will need to upgrade to at least iOS 5.0 or greater. Your current version of iOS is \(UIDevice.currentDevice().systemVersion)");
//    }
//  }
  
  func printMultitaskingInfo() {
    var device = UIDevice.currentDevice();
    var backgroundSupported = false;
    
    if device.respondsToSelector(isMultitaskingSupprted) {
      backgroundSupported = true;
    }
    
    var exsistsOnSuspend = NSBundle.mainBundle().objectForInfoDictionaryKey("UIApplicationExsitsOnSuspend");
    if exsistsOnSuspend == nil {
      exsistsOnSuspend = NSNumber.numberWithBool(false);
    }
    
    let string = NSString(format: "Multi-tasking -> Device: %s, App: %s", backgroundSupported ? "YES" : "NO", exsistsOnSuspend.intValue ? "YES" : "NO");
    print(string);
  }
  
  func URLisAllowed(url : NSURL) -> Bool {
    if self.whiteList == nil {
      return true;
    }
    
    return self.whiteList.URLIsAllowed(url);
  }
  
  func loadSettings() -> Bool {
    var delegate = CDVConfigParser();
    
    var path = NSBundle.mainBundle().pathForResource("config", ofType: "xml");
    
    if NSFileManager.defaultManager().fileExistsAtPath(path) {
      assert(false, "ERROR: config.xml does not exist. Please run cordova-ios/bin/cordova_plist_to_config_xml path/to/project.");
      return;
    }
    
    var url = NSURL.fileURLWithPath(path);
    configParser = NSXMLParser(url);
    if configParser == nil {
      print("Failed to initialize XML parser.");
      return;
    }
    configParser.delete(delegate);
    configParser.parse();
    
    self.pluginsMap = delegate.pluginsDict;
    self.startupPluginsNames = delegate.startupPluginNames;
    self.whitelist = CDVWhitelist(delegate.whilelistHosts);
    self.settings = delegate.settings;
    
    self.wwwFolderName = "www";
    self.startPage = delegate.startPage;
    if self.startPage == nil {
      self.startPage = "index.html";
    }
    
    self.pluginObjects = NSMutableDictionary(capacity: 30);
  }
  
  override func viewDidLoad() {
    super.viewDidLoad();
    
    var appURL:NSURL;
    var loadErr:NSString;
    
    if self.startPage.rangeOfString("://").location != NSNotFound {
      appURL = NSURL(string: self.startPage);
    } else if self.wwwFolderName.rangeOfString("://").location != NSNotFound {
      appURL = NSURL(string: NSString(format: "%@/%@", self.wwwFolderName, self.startPage));
    } else {
      var startURL:NSURL = NSURL(self.startPage);
      var startFilePath:NSString = self.commandDelegate.pathForResource(startURL);
      if startFilePath == nil {
        loadErr = NSString(format: "ERROR: Start Page at '%@/%@' was not found.", self.wwwFolderName, self.startPage);
        println(loadErr);
        self.loadFromString = true;
        appURL = nil;
      } else {
        appURL = NSURL(fileURLWithPath:startFilePath);
        var startPageNoParentDirs:NSString = self.startPage;
        var r:NSRange = startPageNoParentDirs.rangeOfString("?#");
        if r.location != NSNotFound {
          var queryAndOrFragment = self.startPage.substringFromIndexr.location;
          appURL = NSURL(URLWithString:queryAndOrFragment, rellativeToURL:appURL);
        }
      }
    }
    
    // // Instantiate the WebView ///////////////
    if !self.webView {
      self.createGapView();
    }
    
    // Configure WebView
    _webViewDelegate = CDVWebViewDelegate(self);
    self.webView.delegate = _webViewDelegate;
    
    // register this viewcontroller with the NSURLProtocol, only after the User-Agent is set
    CDVURLProtocol.registerViewController(self);
    
    // /////////////////
    var enableViewportScale = self.settingForKey("EnableViewportScale");
    var allowInlineMediaPlayback:NSNumber = self.settingForKey("AllowInlineMediaPlayback");
    var mediaPlaybackRequireUserAction:Bool = true;
    if self.settingForKey("MediaPlaybackRequiresUserAction") {
      mediaPlaybackRequireUserAction = Bool(self.settingForKey("MediaPlaybackRequiresUserAction"));
    }
    
    self.webView.scalePageToFit = Bool(enableViewportScale);
    
    var bounceAllowed:Bool = true;
    var disallowOverscroll:NSNumber = self.settingForKey("DisallowOverscroll");
    if disallowOverscroll == nil {
      var boucePreferance:NSNumber = self.settingForKey("UIWebViewBounce");
      bounceAllowed = (boucePreferance == nil) || Bool(boucePreferance);
    } else {
      bounceAllowed = !Bool(disallowOverscroll);
    }
    
    if !bounceAllowed {
      if self.webView.respondeToSelector("scrollView:") {
        UIScrollView(self.webView.scrollView).bounces = false;
      } else {
        for (subView:UIView in self.webView.subViews) {
          if subView.self == UIScrollView.self {
            UIScrollView(subView).bounces = false;
          }
        }
      }
    }
    
    var decelerationSetting:NSString = self.settingForKey("UIWebViewDecelerationSpeed");
    if "fast" == decelerationSetting {
      self.webView.scrollView.setDecelerationRate(UIScrollViewDecelarationRateNormal);
    }
    
    // /////////////////
    CDVUserAgentUtil.acquireLock^(var lockToken:NSInteger) {
      _userAgentLockToken = lockToken;
      CDVUserAgentUtil.setUserAgent(self.userAgent lockToken:lockToken);
      if !loadErr {
        var appReq:NSURLRequest = NSURLRequest(requestWithUrl:appURL, cachePolicy:NSURLRequestUseProtocolCachePolicy, timeoutInterval:20.0);
        self.webView.loadRequest(appReq);
      } else {
        var html:NSString = NSString(format: "<html><body> %@ </body></html>", loadErr);
        self.webView(loadHTMLString: html, baseURL:nil);
      }
    };
  }
  
  func settingForKey(key: NSString) -> AnyObject {
    return self.settings[key.lowercaseString];
  }
  
  func setSetting(setring: AnyObject, key:NSString) {
    self.settings.setObject(settings, forKey: key.lowercaseString).scheduledOnRunLoop(false);
  }
  
  func parseInterfaceOrientations(orientations:NSArray) {
    var result:NSMutableArray = NSMutableArray();
    if (orientations != nil) {
      var enumerator:NSEnumerator = orientations.objectEnumerator();
      var orientationString:NSString;
      while (orientationString = enumerator.nextObject()) {
        if orientationString == "UIInterfaceOrientationPortrait" {
            result.addObject(NSNumber.numberWithInt(UIInterfaceOrientationPortrait));
        } else if orientationString == "UIInterfaceOrientationPortraitUpsideDown" {
          result.addObject(NSNumber.numberWithInt(UIInterfaceOrientationPortraitUpsideDown));
        } else if orientationString == "UIInterfaceOrientationLandscapeLeft" {
          result.addObject(NSNumber.numberWithInt(UIInterfaceOrientationLandscapeLeft));
        } else if  orientationString == "UIInterfaceOrientationLandscapeRight" {
          result.addObject(NSNumber.numberWithInt(UIInterfaceOrientationLandscapeRight));
        }
      }
    }
    
    if result.count == 0 {
      result.addObject(NSNumber.numberWithInt(UIInterfaceOrientation.Portrait));
    }
    
    return result;
   }
  
  func mapsIosOrientationToJsOrientation(orientation:UIInterfaceOrientation) {
    switch orientation {
    case UIInterfaceOrientation.PortraitUpsideDown:
        return 180;
    case UIInterfaceOrientation.LandscapeLeft:
      return -90;
    case UIInterfaceOrientation.LandscapeRight:
      return 90;
    case UIInterfaceOrientation.Portrait:
      return 0;
    default:
      return 0;
    }
  }
  
  func shouldAutoroteteToInterfaceOrientaion(interfaceOrientation: UIInterfaceOrientation) {
    var jsCall = NSString(format: "window.shouldRotateToOrientation && window.shouldRotateToOrientation(%ld);",self.mapsIosOrientationToJsOrientation(interfaceOrientation()));
    var res = webView?.stringByEvaluatingJavaScriptFromString(jsCall);
    
    if res?.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 0 {
      return Boolean(res);
    }
    
    return self.supporttedInterfaceOrientations();
  }
  
  override func shouldAutorotate() -> Bool {
    return true;
  }
  
  func func supporttedInterfaceOrientations() {
    var ret:NSInteger = 0
    
    
    
    return ret;
  }
  
  func supportsOrientation(orientation:UIInterfaceOrientation) {
    return self.supportedOrientations(containsObject: NSNumber.numberWithInt(orientation));
  }
  
  func newCordovaViewWithFrame(bounds:CGRect) {
    return UIWebView(frame: bounds);
  }
  
  func userAgent() -> NSString {
    if _userAgent == nil {
      var originalUserAgnet:NSString = CDVUserAgentUtil.originalUserAgent();
      _userAgent = NSString(format: "%@(%lld)", originalUserAgnet, (long long)self);
    }
    return _userAgent;
  }
  
  func createGapView() {
    let webViewBounds:CGRect = self.webView?.bounds;
    webViewBounds.origin = self.view.bounds.origin;
    self.webView = self.newCordovaViewWithFrame(webViewBounds);
    self.webView?.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHegith);
    self.view.addSubview(self.webView);
    self.view.sendSubviewToBack(self.webView);
  }
  
  override func didReceiveMemoryWarning() {
    var enumerator:NSEnumerator = self.pluginObjects.objectEnumerator();
    var plugin:CDVPlugin;
    var doPurge:Bool = true;
    
    while (plugin = enumerator.nextObject()) {
      if (plugin.hasPendingOperation()) {
        println("Plugin '%@' has a pending operation, memory purge is delayed for didReceiveMemoryWarning.", plugin.self);
        doPurge = false;
      }
    }
    
    if (doPurge) {
      super.didReceiveMemoryWarning();
    }
  }
  
  func viewDidUnload() {
    self.webView?.delegate = nil;
    self.webView? = nil;
    CDVUserAvgentUtil.releaseLock(_userAgentLockToken);
  }
  
// MARK: UIWebViewDelegate
  
  override func webViewDidStartLoad(theWebView:UIWebView) {
    _commandQueue.resetRequestId();
    NSNotificationCenter.defaultCenter().postNotification(NSNotification.notification(CDVPluginResetNotification(object: self.webView)));
  }
  
  override func webViewDIdFinishLoad(theWebView:UIWebView) {
    CDVUserAvgentUtil.releaseLock(_userAgentLockToken);
    UIApplication.sharedApplication().setNetWorkActivityIndicatorVisible(false);
    self.processOpenUrl();
    NSNotificationCenter.defaultCenter().postNotification(NSNotification.notification(CDVPageDidLoadNotification(object: self.webView)));
  }
  
  override func webView(webView: UIWebView, didFailLoadWithError error: NSError) {
    CDVUserAgentUtil.releaseLock(_userAgentLockToken);
    println("%@", error.description);
  }
  
  func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
    var url = request.URL;
    
    if url.scheme == "gap" {
      _commandQueue.fetchCommandFormJs();
      _commandQueue.executePending();
      return false;
    }
    
    if url.fragment?.hasPrefix("%01") || url.fragment?.hasPrefix("%02") {
      var inlineCommands:NSString = url.fragment?.substringFromIndex(3);
      if inlineCommands.length == 0 {
        _commandQueue.fetchCommnadsFormJs();
      } else {
        inlineCommands = inlineCommands.stringByRemovingPercentEncoding(NSUTF8StringEncoding);
        _commandQueue.enqueueCommandBatch(inlineCommands);
      }
      
      CDVCommandDelegateImpl(_commandDelegate).flushCommandQueueWithDelayedJs();
      
      return false
    }
    
    for (pluginName:NSString in pluginObjects) {
      var plugin:CDVPlugin = pluginObjects[pluginName];
    }
    
    if url.isFileReferenceURL() {
      return true;
    }
    
    else if self.loadFromString == true {
      self.loadFromString = true;
      return true;
    }
    
    else if url.scheme == "tel" {
      return true;
    }
    
    else if url.scheme == "about" {
      return false;
    }
    
    else if url.scheme == "data" {
      return true;
    }
    
    else {
      if self.whiteList(schemeIsAllowed: url.scheme) {
        return self.whiteList(URLisAllowed:url);
      } else {
        if UIApplication.sharedApplication().canOpenURL(url); {
          UIApplication.sharedApplication().openURL(url);
        } else {
          NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: CDVPliginHandleOpenURLNotifivcation, object: url));
        }
      }
      return false;
    }
    return false;
  }
  
// MARK: Gaphelpers
  
  func javascriptAlert(text: NSString) {
    let jsString = NSString(format: "alert('%@');", text);
    self.commandDelegate.evalJs(jsString);
  }
  
  class func resolveImageResource(resource:NSString) -> NSString {
    if CDV_IsIPad() {
      return NSString(format : "%@~ipad.png", resource);
    } else {
      return NSString(format : "%@.png", resource);
    }
    return resource;
  }
  
  class func applicationDocumentsDirectory() {
    let paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirecotry, NSUserDocumentMask, true);
    let basePath = (paths.count() > 0) ? paths[0] : nil;
    
    return basePath;
  }
  
// MARK: CordovaCommands
  
  func registerPlugin(plugin:CDVPlugin, className:NSString) {
    if plugin.respondeToSelector("setViewController:") {
      plugin.setViewController(self);
    }
    
    if plugin.respondeToSelector("setCommandDelegate:") {
      plugin.setCommandDelegate(_commandDelegate);
    }
    
    self.pluginObjects.setObject(plugin, forKey: className);
    plugin.pluginInitialize();
  }
  
  func registerPlugin(plugin:CDVPlugin, pluginName:NSString) {
    if plugin.respondeToSelector("setViewController:") {
      plugin.setViewController(self);
    }
    
    if plugin.respondeToSelector("setCommandDelegate:") {
      plugin.setCommandDelegate(_commandDelegate);
    }
    
    let className = NSStringFromClass(plugin.self);
    self.pluginObjects.setObject(plugin, forKey: className);
    self.pluginMap.setValue(className, pluginName.lowweString);
    plugin.pluginInitialize();
  }
  
  func getCommandInstance(pluginName:NSString) -> AnyObject {
    var className = self.pluginsMap[pluginName.lowercaseString];
    
    if className == nil {
      return nil;
    }
    
    var obj = self.pluginObjects[className];
    if !obj {
      obj = (NSClassFromString(className))(webView: webView);
      if obj != nil {
        self.registerPlugin(obj:AnyObject, className:NSString);
      } else {
        print("CDVPlugin class \(className) (pluginName: \(pluginName)) does not exist.");
      }
    }
  }

// MARK: -
  
  func appURLScheme() -> NSString {
    var URLScheme:NSString;
    var URLTypes:NSArray = NSBundle.mainBundle().infoDictionary["CFBundleURLTypes"];
    
    if URLTypes != nil {
      var dict = URLTypes[0];
      if dict != nil {
        var URLSchemes = dict["CFBundleURLSchemes"];
        URLScheme = URLSchemes[0];
      }
    }
    return URLScheme;
  }
  
  class func getBundlePlist(plistName:NSString) -> NSDictionary {
    var errorDesc:NSString;
    var format:NSPropertyListFormat;
    let plistPath = NSBundle.mainBundle().pathForResource(plistName, ofType: "plist");
    var plistXML = NSFileManager.defaultManager().contentsAtPath(plistPath);
    let temp = NSPropertyListSerialization.propertyListFromData(plistXML, mutabilityOption:NSPropertyListMutabilityOptions, format: format, errorDescription: errorDesc);
    return temp;
  }
  
// MARK: -
// MARK: UIApplicationDelegate impl
  
  func onAppWillTerminale(notification:NSNotification) {
    var fileManager = NSFileManager.defaultManager();
    var error;
    
    var tempDirectoryPath = NSTemporaryDirectory();
    var directoryEnumerator = fileManager.enumeratorAtPath(tempDirectoryPath);
    
    var fileName
    var result:Bool;
    while(fileName = directoryEnumerator?.nextObject()) {
      var filePath = tempDirectoryPath.stringByAppendingPathComponent(fileName);
      result = fileManager.removeItemAtPath(filePath, error: error);
      if !result && result {
        print("Failed to delete: \(filePath) (error: \(error))");
      }
    }
  }
  
  func onAppWillResignActive(notification:NSNotification) {
    self.commandDelegate.evalJS("cordova.fireDocumentEvent('resign');");
  }
  
  func onAppWillEnterForeground(notification:NSNotification) {
    self.commandDelegate.evalJs("cordova.fireDocumentEvent('resume');");
  }
  
  func onAppBecomeActive(notification:NSNotification) {
    self.commandDelegate.evalJs("cordova.fireDocumentEvent('active');");
  }
  
  func onAppDidEnterbackground(notification:NSNotification) {
    self.commandDelegate.evalJs("cordova.fireDocumentEvent('pause', null, true);").scheduleOnRunLoop(false);
  }
  
  func handleOpenURL(notification: NSNotification) {
    self.openURL = notification.object;
  }
  
  func processOpenUrl() {
    if self.openURL {
      var jsString = "handleOpenURL(\"\(self.openURL.description)\");"
      self.webView?.stringByEvaluatingJavaScriptFromString(jsString);
      self.openURL = nil;
    }
  }
  
  override func dealloc() {
    CDVURLProtocol.unregisterViewCOntroller(self);
    NSNotificationCenter.defaultCenter().removeObserver(self);
    self.webView?.delegate = nil;
    self.webView = nil;
    CDVUserAgentUtil.releaseLock(_userAgentLockToken);
    _commandQueue.dispose();
    self.pluginObjects.allValues.makeObjectsPerformSelector(dispose);
  }
}
