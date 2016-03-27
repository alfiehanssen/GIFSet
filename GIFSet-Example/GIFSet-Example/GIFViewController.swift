//
//  GIFViewController.swift
//  GIFSet-Example
//
//  Created by Alfred Hanssen on 3/27/16.
//  Copyright © 2016 Alfie Hanssen. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import UIKit

// TODO: Figure out why GIF is scaling weird in webview

class GIFViewController: UIViewController
{
    var URL: NSURL!
    weak var delegate: Dismissable?

    // MARK: IBOUtlets
    
    @IBOutlet weak var webView: UIWebView!
    
    // MARK: View Lifecycle
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        self.setupWebView()
    }
    
    // MARK: Setup
    
    private func setupWebView()
    {
        let request = NSURLRequest(URL: self.URL)
        self.webView.loadRequest(request)
        self.webView.scalesPageToFit = true
    }
    
    // MARK: Actions
    
    @IBAction func didTapShare(sender: UIButton)
    {
        // TODO: implement share
    }
    
    @IBAction func didTapDismiss(sender: UIButton)
    {
        self.delegate?.requestDismissal(viewController: self, animated: true)
    }
}
