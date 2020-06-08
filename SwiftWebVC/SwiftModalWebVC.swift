//
//  SwiftModalWebVC.swift
//
//  Created by Myles Ringle on 24/06/2015.
//  Transcribed from code used in SVWebViewController.
//  Copyright (c) 2015 Myles Ringle & Oliver Letterer. All rights reserved.
//

import UIKit

public class SwiftModalWebVC: UINavigationController {
    
    public init(request: URLRequest, delegate: SwiftWebVCDelegate) {
        let webViewController = SwiftWebVC(aRequest: request)
        webViewController.delegate = delegate

        webViewController.storedStatusColor = UINavigationBar.appearance().barStyle
        let doneButton = UIBarButtonItem(title: "Done",
                                         style: UIBarButtonItemStyle.plain,
                                         target: webViewController,
                                         action: #selector(SwiftWebVC.doneButtonTapped))

        doneButton.tintColor = UIColor.white
        webViewController.buttonColor = UIColor.white
        webViewController.titleColor = UIColor.white

        if (UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad) {
            webViewController.navigationItem.leftBarButtonItem = doneButton
        }
        else {
            webViewController.navigationItem.rightBarButtonItem = doneButton
        }
        
        super.init(rootViewController: webViewController)

        self.hidesBarsOnSwipe = true
        self.hidesBarsOnTap = true
        self.hidesBarsWhenKeyboardAppears = true
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
    }
}
