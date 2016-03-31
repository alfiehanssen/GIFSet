//
//  ImageExtractionOperation.m
//  GIFSet
//
//  Created by Alfie Hanssen on 1/3/15.
//  Copyright (c) 2015 Alfie Hanssen. All rights reserved.
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

#import "ImageExtractionOperation.h"
#import "AVAsset+Times.h"
#import "NSURL+Extensions.h"
#import "NSFileManager+Extensions.h"

@import UIKit;

static NSString *ImageExtractionOperationErrorDomain = @"ImageExtractionOperationErrorDomain";

@interface ImageExtractionOperation ()

@property (nonatomic, strong) NSArray <NSValue *> *times;
@property (nonatomic, strong) AVComposition *composition;
@property (nonatomic, strong) AVVideoComposition *videoComposition;

@property (nonatomic, strong) AVAssetImageGenerator *imageGenerator;
@property (nonatomic, assign) BOOL didCallCompletion;
@property (nonatomic, strong, readwrite) NSMutableArray<NSURL *> *tempImageURLs;

@property (nonatomic, strong, readwrite) NSArray<NSURL *> *imageURLs;
@property (nonatomic, strong, readwrite) NSError *error;

@end

@implementation ImageExtractionOperation

- (instancetype)initWithTimes:(NSArray <NSValue *>*)times
                  composition:(AVComposition *)composition
             videoComposition:(AVVideoComposition *)videoComposition
{
    NSAssert([times count] > 0 && composition, @"Must be initialized with valid times array and composition");
    
    self = [super init];
    if (self)
    {
        _times = times;
        _composition = composition;
        _videoComposition = videoComposition;
        _tempImageURLs = [NSMutableArray array];
        _imageURLs = [NSArray array];
    }
    
    return self;
}

- (instancetype)init
{
    NSAssert(NO, @"Use designated initializer instead of -init.");
    
    return [self initWithTimes:@[] composition:[[AVComposition alloc] init] videoComposition:nil];
}

#pragma mark - Overrides

- (void)cancel
{
    [super cancel];

    [self cleanup];
}

- (void)completeOperation
{
    // Because cancellation of imageGenerator doesn't stop it's callback from being called for all counts
    
    if (_didCallCompletion == YES)
    {
        return;
    }
    
    _didCallCompletion = YES;
    
    [super completeOperation];
}

- (void)main
{
    self.imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:self.composition];
    self.imageGenerator.requestedTimeToleranceAfter = kCMTimeZero;
    self.imageGenerator.requestedTimeToleranceBefore = kCMTimeZero;
    self.imageGenerator.appliesPreferredTrackTransform = YES;
    self.imageGenerator.videoComposition = self.videoComposition;
//    self.imageGenerator.maximumSize = CGSizeMake(720.0f, 720.0f);
    
    __block NSInteger completedOperations = 0;
    
    __weak typeof(self) weakSelf = self;
    [self.imageGenerator generateCGImagesAsynchronouslyForTimes:self.times completionHandler:^(CMTime requestedTime, CGImageRef imageRef, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error) {
        
        __strong typeof(self) strongSelf = weakSelf;
        if (strongSelf == nil)
        {
            return;
        }
        
        if ([strongSelf isCancelled])
        {
            return;
        }
        
        if (strongSelf.error)
        {
            return;
        }

        completedOperations++;

        if (strongSelf.progressBlock)
        {
            CGFloat progressFraction = (CGFloat)completedOperations / (CGFloat)[strongSelf.times count];
            strongSelf.progressBlock(progressFraction);
        }
        
        if (result == AVAssetImageGeneratorSucceeded)
        {
            NSURL *URL = [NSURL uniqueImageURL];
            UIImage *image = [UIImage imageWithCGImage:imageRef];
            NSData *data = UIImagePNGRepresentation(image);
            
            BOOL success = [data writeToFile:[URL absoluteString] atomically:YES];
            if (success)
            {
                [strongSelf.tempImageURLs addObject:URL];
            }
            else
            {
                strongSelf.error = [NSError errorWithDomain:ImageExtractionOperationErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey: @"Unable to write image data to file."}];
            }
        }
        else
        {
            strongSelf.error = error;
        }

        if (strongSelf.error)
        {
            [strongSelf cleanup];
            [strongSelf completeOperation];
        }
        else if (completedOperations == [strongSelf.times count])
        {
            strongSelf.imageURLs = strongSelf.tempImageURLs;
            [strongSelf completeOperation];
        }
    }];
}

#pragma mark - Private API

- (void)cleanup
{
    [self.imageGenerator cancelAllCGImageGeneration];
    self.imageGenerator = nil;
        
    self.imageURLs = @[];
    
    for (NSURL *imageURL in self.tempImageURLs)
    {
        NSString *path = [imageURL path];
        [[NSFileManager defaultManager] removeFileAtPathIfPossible:path];
    }

    [self.tempImageURLs removeAllObjects];

    self.progressBlock = nil;
}

@end
