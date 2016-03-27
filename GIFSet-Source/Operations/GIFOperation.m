//
//  GIFOperation.m
//  GIFSet
//
//  Created by Alfred Hanssen on 3/19/16.
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

#import "GIFOperation.h"
#import "NSFileManager+Extensions.h"

@import UIKit;
@import ImageIO;
@import MobileCoreServices;

// TODO: add podspec

@interface GIFOperation ()
{
    CGImageDestinationRef _destination;
}

@property (nonatomic, copy) NSArray <NSURL *>*imageURLs;
@property (nonatomic, assign) NSTimeInterval frameDuration;
@property (nonatomic, copy, readwrite) NSURL *outputURL;

@property (nonatomic, strong, readwrite) NSError *error;

@end

@implementation GIFOperation

- (void)dealloc
{
    CFRelease(_destination);
    _destination = nil;
}

- (instancetype _Nullable)initWithImageURLs:(NSArray <NSURL *>* _Nonnull)imageURLs
                              frameDuration:(NSTimeInterval)frameDuration
                                  outputURL:(NSURL * _Nonnull)outputURL
{
    NSAssert([imageURLs count] > 0 && frameDuration > 0, @"Must be initialized with valid imageURL array and frameDuration");
    
    self = [super init];
    if (self)
    {
        _imageURLs = [imageURLs copy];
        _frameDuration = frameDuration;
        _outputURL = [NSURL fileURLWithPath:[outputURL absoluteString]];
        _destination = CGImageDestinationCreateWithURL((__bridge CFURLRef)_outputURL, kUTTypeGIF, [_imageURLs count], NULL);
        
        NSAssert(_destination, @"Unable to create destination.");
    }
    
    return self;
}

- (instancetype)init
{
    NSAssert(NO, @"Use designated initializer instead of -init.");
    
    return [self initWithImageURLs:@[] frameDuration:0 outputURL:[[NSURL alloc] init]];
}

#pragma mark - Overrides

- (void)cancel
{
    [super cancel];
    
    NSString *path = [self.outputURL path];
    [[NSFileManager defaultManager] removeFileAtPathIfPossible:path];
}

- (void)main
{
    for (NSURL *URL in self.imageURLs)
    {
        // TODO: wrap in autorelease pool?

        if ([self isCancelled])
        {
            return;
        }
        
        UIImage *image = [UIImage imageWithContentsOfFile:[URL absoluteString]];
        
        NSDictionary *gifProperties = @{(__bridge id)kCGImagePropertyGIFDelayTime: [NSNumber numberWithFloat:self.frameDuration]};
        NSDictionary *frameProperties = @{(__bridge id)kCGImagePropertyGIFDictionary: gifProperties};
        
        // TODO: wrap in autorelease pool?
        CGImageDestinationAddImage(_destination, image.CGImage, (__bridge CFDictionaryRef)frameProperties);
    }
    
    NSDictionary *gifProperties = @{(__bridge id)kCGImagePropertyGIFLoopCount : @0}; // 0 == loop forever
    
    NSDictionary *fileProperties = @{(__bridge id)kCGImagePropertyPixelWidth: @450, // TODO: update these values
                                     (__bridge id)kCGImagePropertyPixelHeight: @254,
                                     (__bridge id)kCGImagePropertyGIFDictionary: gifProperties};
    
    CGImageDestinationSetProperties(_destination, (__bridge CFDictionaryRef)fileProperties);
    
    if (!CGImageDestinationFinalize(_destination))
    {
        NSString *path = [self.outputURL path];
        [[NSFileManager defaultManager] removeFileAtPathIfPossible:path];

        self.error = [NSError errorWithDomain:@"GIFCreatorErrorDomain" code:0 userInfo:@{NSLocalizedDescriptionKey: @"Unable to finalize GIF image."}];
    }
    
    CFRelease(_destination);
    _destination = nil;
    
    [self completeOperation];
}

@end
