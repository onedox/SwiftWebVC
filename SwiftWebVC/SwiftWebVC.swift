//
//  SwiftWebVC.swift
//
//  Created by Myles Ringle on 24/06/2015.
//  Transcribed from code used in SVWebViewController.
//  Copyright (c) 2015 Myles Ringle & Sam Vermette. All rights reserved.
//

import WebKit

public protocol SwiftWebVCDelegate: class {
    func didStartLoading()
    func didFinishLoading(webView: WKWebView, navigation: WKNavigation, success: Bool)
    func decidePolicyFor(webView: WKWebView, navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void)
}

public class SwiftWebVC: UIViewController {
    
    static let configuration: WKWebViewConfiguration = {
        let configuration = WKWebViewConfiguration()
        configuration.processPool = WKProcessPool()
        return configuration
    }()
    
    public weak var delegate: SwiftWebVCDelegate?
    var storedStatusColor: UIBarStyle?
    var buttonColor: UIColor? = nil
    var titleColor: UIColor? = nil
    var closing: Bool! = false
    
    lazy var backBarButtonItem: UIBarButtonItem =  {
        var tempBackBarButtonItem = UIBarButtonItem(image: SwiftWebVC.bundledImage(named: "SwiftWebVCBack"),
                                                    style: UIBarButtonItemStyle.plain,
                                                    target: self,
                                                    action: #selector(SwiftWebVC.goBackTapped(_:)))
        tempBackBarButtonItem.width = 18.0
        tempBackBarButtonItem.tintColor = self.buttonColor
        return tempBackBarButtonItem
    }()
    
    lazy var forwardBarButtonItem: UIBarButtonItem =  {
        var tempForwardBarButtonItem = UIBarButtonItem(image: SwiftWebVC.bundledImage(named: "SwiftWebVCNext"),
                                                       style: UIBarButtonItemStyle.plain,
                                                       target: self,
                                                       action: #selector(SwiftWebVC.goForwardTapped(_:)))
        tempForwardBarButtonItem.width = 18.0
        tempForwardBarButtonItem.tintColor = self.buttonColor
        return tempForwardBarButtonItem
    }()
    
    lazy var refreshBarButtonItem: UIBarButtonItem = {
        var tempRefreshBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.refresh,
                                                       target: self,
                                                       action: #selector(SwiftWebVC.reloadTapped(_:)))
        tempRefreshBarButtonItem.tintColor = self.buttonColor
        return tempRefreshBarButtonItem
    }()
    
    lazy var stopBarButtonItem: UIBarButtonItem = {
        var tempStopBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.stop,
                                                    target: self,
                                                    action: #selector(SwiftWebVC.stopTapped(_:)))
        tempStopBarButtonItem.tintColor = self.buttonColor
        return tempStopBarButtonItem
    }()
    
    lazy var actionBarButtonItem: UIBarButtonItem = {
        var tempActionBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.action,
                                                      target: self,
                                                      action: #selector(SwiftWebVC.actionButtonTapped(_:)))
        tempActionBarButtonItem.tintColor = self.buttonColor
        return tempActionBarButtonItem
    }()
    
    var activityIndicator: UIActivityIndicatorView?
    
    lazy var loadingBarButtonItem: UIBarButtonItem = {
        activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        activityIndicator?.color = .blue
        let barButton = UIBarButtonItem(customView: activityIndicator!)
        return barButton
    }()
    
    func showLoadingIndicator() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        activityIndicator?.startAnimating()
    }
    
    func hideLoadingIndicator() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        activityIndicator?.stopAnimating()
    }
    
    lazy var webView: WKWebView = {
        var tempWebView = WKWebView(frame: UIScreen.main.bounds, configuration: SwiftWebVC.configuration)
        tempWebView.uiDelegate = self
        tempWebView.navigationDelegate = self
        return tempWebView
    }()
    
    var request: URLRequest!
    
    var sharingEnabled = true
    
    var hideToolBar: Bool = false
    
    ////////////////////////////////////////////////
    
    deinit {
        webView.stopLoading()
        hideLoadingIndicator()
        webView.uiDelegate = nil;
        webView.navigationDelegate = nil;
    }
    
    public convenience init(urlString: String, sharingEnabled: Bool = true, hideToolBar: Bool = false) {
        var urlString = urlString
        if !urlString.hasPrefix("https://") && !urlString.hasPrefix("http://") {
            urlString = "https://"+urlString
        }
        self.init(pageURL: URL(string: urlString)!, sharingEnabled: sharingEnabled, hideToolBar: hideToolBar)
    }
    
    public convenience init(pageURL: URL, sharingEnabled: Bool = true, hideToolBar: Bool = false) {
        self.init(aRequest: URLRequest(url: pageURL), sharingEnabled: sharingEnabled, hideToolBar: hideToolBar)
    }
    
    public convenience init(aRequest: URLRequest, sharingEnabled: Bool = true, hideToolBar: Bool = false) {
        self.init()
        self.sharingEnabled = sharingEnabled
        self.request = aRequest
        self.hideToolBar = hideToolBar
        
        if (UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad) {
            self.navigationItem.rightBarButtonItem = loadingBarButtonItem
        } else {
            self.navigationItem.leftBarButtonItem = loadingBarButtonItem
        }
        
        self.setTitle(title: "", subtitle: aRequest.url?.host ?? "Loading...")
    }
    
    func loadRequest(_ request: URLRequest) {
        webView.load(request)
    }
    
    ////////////////////////////////////////////////
    // View Lifecycle
    
    override public func loadView() {
        view = webView
        loadRequest(request)
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        assert(self.navigationController != nil, "SVWebViewController needs to be contained in a UINavigationController. If you are presenting SVWebViewController modally, use SVModalWebViewController instead.")
        
        updateToolbarItems()
        super.viewWillAppear(true)
        
        if (UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.phone) {
            self.navigationController?.setToolbarHidden(self.hideToolBar, animated: false)
        }
        else if (UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad) {
            self.navigationController?.setToolbarHidden(true, animated: true)
        }
    }
    
    func setTitle(title:String, subtitle:String) {
        let titleLabel = UILabel(frame: CGRect.init(x: 0, y: -5, width: 0, height: 0))
        titleLabel.backgroundColor = UIColor.clear
        titleLabel.textColor = UIColor.black
        titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
        titleLabel.text = title
        titleLabel.sizeToFit()

        let subtitleLabel = UILabel(frame: CGRect.init(x: 0, y: 18, width: 0, height: 0))
        subtitleLabel.backgroundColor = UIColor.clear
        subtitleLabel.textColor = UIColor.lightGray
        subtitleLabel.font = UIFont.systemFont(ofSize: 12)
        subtitleLabel.text = subtitle
        subtitleLabel.sizeToFit()
        
        let titleView = UIView(frame: CGRect.init(x: 0, y: 0, width: max(titleLabel.frame.size.width, subtitleLabel.frame.size.width), height: 30))
        titleView.addSubview(titleLabel)
        titleView.addSubview(subtitleLabel)

        self.navigationItem.titleView = titleView
        titleLabel.center.x = titleView.center.x
        subtitleLabel.center.x = titleView.center.x
    }
    
    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        
        if (UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.phone) {
            self.navigationController?.setToolbarHidden(true, animated: true)
        }
    }
    
    override public func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        hideLoadingIndicator()
    }
    
    ////////////////////////////////////////////////
    // Toolbar
    
    func updateToolbarItems() {
        guard hideToolBar == false else {
            return
        }
        backBarButtonItem.isEnabled = webView.canGoBack
        forwardBarButtonItem.isEnabled = webView.canGoForward
        
        let refreshStopBarButtonItem: UIBarButtonItem = webView.isLoading ? stopBarButtonItem : refreshBarButtonItem
        
        let fixedSpace: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.fixedSpace, target: nil, action: nil)
        let flexibleSpace: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        
        if (UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad) {
            
            let toolbarWidth: CGFloat = 250.0
            fixedSpace.width = 35.0
            
            let items: NSArray = sharingEnabled ? [fixedSpace, refreshStopBarButtonItem, fixedSpace, backBarButtonItem, fixedSpace, forwardBarButtonItem, fixedSpace, actionBarButtonItem] : [fixedSpace, refreshStopBarButtonItem, fixedSpace, backBarButtonItem, fixedSpace, forwardBarButtonItem]
            
            let toolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0.0, y: 0.0, width: toolbarWidth, height: 44.0))
            if !closing {
                toolbar.items = items as? [UIBarButtonItem]
                if presentingViewController == nil {
                    toolbar.barTintColor = navigationController!.navigationBar.barTintColor
                }
                else {
                    toolbar.barStyle = navigationController!.navigationBar.barStyle
                }
                toolbar.tintColor = navigationController!.navigationBar.tintColor
            }
            navigationItem.rightBarButtonItems = items.reverseObjectEnumerator().allObjects as? [UIBarButtonItem]
        }
        else {
            let items: NSArray = sharingEnabled ? [fixedSpace, backBarButtonItem, flexibleSpace, forwardBarButtonItem, flexibleSpace, refreshStopBarButtonItem, flexibleSpace, actionBarButtonItem, fixedSpace] : [fixedSpace, backBarButtonItem, flexibleSpace, forwardBarButtonItem, flexibleSpace, refreshStopBarButtonItem, fixedSpace]
            
            if let navigationController = navigationController, !closing {
                if presentingViewController == nil {
                    navigationController.toolbar.barTintColor = navigationController.navigationBar.barTintColor
                }
                else {
                    navigationController.toolbar.barStyle = navigationController.navigationBar.barStyle
                }
                navigationController.toolbar.tintColor = navigationController.navigationBar.tintColor
                toolbarItems = items as? [UIBarButtonItem]
            }
        }
        updateInset()
    }
    
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: nil) { [weak self] context in
            self?.updateInset() //Fix the bottom insets after rotating the device
        }
    }
    
    func updateInset() {
        var topInset: CGFloat = 0
        if #available(iOS 11, *) {
            // 0 is correct
        } else {
            topInset = 20 + (navigationController?.navigationBar.frame.height ?? 0)
        }
        
        // Leave space for the toolbar at the bottom
        webView.scrollView.contentInset = UIEdgeInsets(top: topInset, left: 0, bottom: navigationController?.toolbar.frame.height ?? 0, right: 0)
    }
    
    ////////////////////////////////////////////////
    // Target Actions
    
    @objc func goBackTapped(_ sender: UIBarButtonItem) {
        webView.goBack()
    }
    
    @objc func goForwardTapped(_ sender: UIBarButtonItem) {
        webView.goForward()
    }
    
    @objc func reloadTapped(_ sender: UIBarButtonItem) {
        webView.reload()
    }
    
    @objc func stopTapped(_ sender: UIBarButtonItem) {
        webView.stopLoading()
        updateToolbarItems()
    }
    
    @objc func actionButtonTapped(_ sender: AnyObject) {
        
        if let url: URL = ((webView.url != nil) ? webView.url : request.url) {
            let activities: NSArray = [SwiftWebVCActivitySafari(), SwiftWebVCActivityChrome()]
            
            if url.absoluteString.hasPrefix("file:///") {
                let dc: UIDocumentInteractionController = UIDocumentInteractionController(url: url)
                dc.presentOptionsMenu(from: view.bounds, in: view, animated: true)
            }
            else {
                let activityController: UIActivityViewController = UIActivityViewController(activityItems: [url], applicationActivities: activities as? [UIActivity])
                
                if floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1 && UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
                    let ctrl: UIPopoverPresentationController = activityController.popoverPresentationController!
                    ctrl.sourceView = view
                    ctrl.barButtonItem = sender as? UIBarButtonItem
                }
                
                present(activityController, animated: true, completion: nil)
            }
        }
    }
    
    ////////////////////////////////////////////////
    
    @objc func doneButtonTapped() {
        closing = true
        UINavigationBar.appearance().barStyle = storedStatusColor!
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Class Methods
    
    /// Helper function to get image within SwiftWebVCResources bundle
    ///
    /// - parameter named: The name of the image in the SwiftWebVCResources bundle
    class func bundledImage(named: String) -> UIImage? {
        let image = UIImage(named: named)
        if image == nil {
            return UIImage(named: named, in: Bundle(for: SwiftWebVC.classForCoder()), compatibleWith: nil)
        } // Replace MyBasePodClass with yours
        return image
    }
}

extension SwiftWebVC: WKUIDelegate {
    
    // Add any desired WKUIDelegate methods here: https://developer.apple.com/reference/webkit/wkuidelegate
    
    public func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if (navigationAction.targetFrame == nil) {
            let url = navigationAction.request.url
            if UIApplication.shared.canOpenURL(url!) {
                UIApplication.shared.openURL(url!)
            }
        }
        return nil
    }
}

extension SwiftWebVC: WKNavigationDelegate {
    
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        self.delegate?.didStartLoading()
        showLoadingIndicator()
        updateToolbarItems()
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.delegate?.didFinishLoading(webView: webView, navigation: navigation, success: true)
        webView.evaluateJavaScript("document.title", completionHandler: {(title, error) in
            webView.evaluateJavaScript("document.location.origin", completionHandler: {(host, error) in
                self.setTitle(title: title as! String, subtitle: host as! String)
                self.updateToolbarItems()
            })
        })
        
        hideLoadingIndicator()
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        self.delegate?.didFinishLoading(webView: webView, navigation: navigation, success: false)
        hideLoadingIndicator()
        updateToolbarItems()
    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        self.delegate?.decidePolicyFor(webView: webView, navigationAction: navigationAction, decisionHandler: decisionHandler)
    }
}
