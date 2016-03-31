//
//  ViewController.swift
//  GIFSet-Example
//
//  Created by Alfred Hanssen on 3/23/16.
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
import VIMVideoPlayer
import GIFSet

class ViewController: UIViewController, VIMVideoPlayerViewDelegate, Dismissable
{
    let asset = AVURLAsset(URL: NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("Waterfall", ofType: "mp4")!))
    
    // MARK: IBOutlets
    
    @IBOutlet weak var videoPlayerView: VIMVideoPlayerView!
    @IBOutlet weak var numberOfImagesSlider: UISlider!
    @IBOutlet weak var durationInSecondsSlider: UISlider!
    @IBOutlet weak var durationInSecondsLabel: UILabel!
    @IBOutlet weak var numberOfImagesLabel: UILabel!

    // MARK: Computed Properties
    
    private var numberOfImages: Int
    {
        get
        {
            return Int(round(self.numberOfImagesSlider.value))
        }
    }

    private var durationInSeconds: NSTimeInterval
    {
        get
        {
            return NSTimeInterval(self.durationInSecondsSlider.value)
        }
    }

    // MARK: View Lifecycle
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        self.setupSliders()
        self.setupVideoPlayerView()
    }
    
    // MARK: Setup
    
    private func setupVideoPlayerView()
    {
        self.videoPlayerView.player.looping = true
        self.videoPlayerView.player.disableAirplay()
        self.videoPlayerView.setVideoFillMode(AVLayerVideoGravityResizeAspect)
        self.videoPlayerView.delegate = self
        self.videoPlayerView.player.setAsset(self.asset)
    }
    
    private func setupSliders()
    {
        // Set the slider values
        self.numberOfImagesSlider.value = self.numberOfImagesSlider.minimumValue
        self.durationInSecondsSlider.value = self.durationInSecondsSlider.minimumValue
        
        // Set the initial label.text values
        self.didChangeNumberOfImages(self.numberOfImagesSlider)
        self.didChangeDurationInSeconds(self.durationInSecondsSlider)
    }
    
    // MARK: VIMVideoPlayerViewDelegate
    
    func videoPlayerViewIsReadyToPlayVideo(videoPlayerView: VIMVideoPlayerView?)
    {
        self.videoPlayerView.player.play()
    }
    
    // MARK: Dismissable
    
    func requestDismissal(viewController viewController: UIViewController, animated: Bool)
    {
        viewController.dismissViewControllerAnimated(animated) { () -> Void in
            self.videoPlayerView.player.play()
        }
    }

    // MARK: Actions

    @IBAction func didChangeNumberOfImages(sender: UISlider)
    {
        self.numberOfImagesLabel.text = "\(self.numberOfImages)"
    }

    @IBAction func didChangeDurationInSeconds(sender: UISlider)
    {
        let formatter = NSNumberFormatter()
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        let duration = formatter.stringFromNumber(self.durationInSeconds)

        self.durationInSecondsLabel.text = duration
    }

    @IBAction func didTapMakeVideo(sender: UIButton)
    {
        self.makeVideo(numberOfImages: self.numberOfImages, durationInSeconds: self.durationInSeconds, asset: self.asset)
    }

    @IBAction func didTapMakeGIF(sender: UIButton)
    {
        self.makeGIF(numberOfImages: self.numberOfImages, durationInSeconds: self.durationInSeconds, asset: self.asset)
    }

    // MARK: Private API
    
    private func makeVideo(numberOfImages numberOfImages: Int, durationInSeconds: NSTimeInterval, asset: AVAsset)
    {
        self.videoPlayerView.player.pause()

        self.view.userInteractionEnabled = false
        
        let outputURL = NSURL.uniqueMp4URL()
        let operation = VideoGIFFromVideoOperation(numberOfImages:numberOfImages, durationInSeconds:durationInSeconds, asset:asset, outputURL:outputURL)
        
        operation?.progressBlock = { (progress) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                print("Progress: \(progress)")
            })
        }
        
        operation?.completionBlock = {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.view.userInteractionEnabled = true

                if let error = operation?.error
                {
                    print(error.localizedDescription)
                }
                else 
                {
                    let viewController = VideoViewController()
                    viewController.asset = AVURLAsset(URL: outputURL)
                    viewController.delegate = self
                    self.presentViewController(viewController, animated: true, completion: nil)
                }
            })
        }
        
        operation?.start()
    }
    
    private func makeGIF(numberOfImages numberOfImages: Int, durationInSeconds: NSTimeInterval, asset: AVAsset)
    {
        self.videoPlayerView.player.pause()
        
        self.view.userInteractionEnabled = false
        
        let outputURL = NSURL.uniqueGIFURL()
        let operation = GIFFromVideoOperation(numberOfImages:numberOfImages, durationInSeconds:durationInSeconds, asset:asset, outputURL:outputURL)
        
        operation?.progressBlock = { (progress) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                print("Progress: \(progress)")
            })
        }
        
        operation?.completionBlock = {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.view.userInteractionEnabled = true
                
                if let error = operation?.error
                {
                    print(error.localizedDescription)
                }
                else
                {
                    let viewController = GIFViewController()
                    viewController.URL = outputURL
                    viewController.delegate = self
                    self.presentViewController(viewController, animated: true, completion: nil)
                }
            })
        }
        
        operation?.start()
    }
}

