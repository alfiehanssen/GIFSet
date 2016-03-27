//
//  GIFFromVideoOperation.m
//  GIFSet
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

#import "GIFFromVideoOperation.h"
#import "CompositionOperation.h"
#import "ImageExtractionOperation.h"
#import "GIFOperation.h"
#import "AVAsset+Times.h"

// TODO: There's a bunch of duplicate code in this class, same code as in VideoGIFFromVideoOperation
// Need to consolidate but VideoGIFFromVideoOperation might change significantly so hold off for now [AH] 3/27/2016

@interface GIFFromVideoOperation ()

@property (nonatomic, assign) NSInteger numberOfImages;
@property (nonatomic, assign) NSTimeInterval durationInSeconds;
@property (nonatomic, strong) AVAsset *originalAsset;
@property (nonatomic, copy, readwrite) NSURL *outputURL;

@property (nonatomic, strong) NSOperationQueue *operationQueue;

@property (nonatomic, strong, readwrite) NSError *error;

@end

@implementation GIFFromVideoOperation

- (instancetype)initWithNumberOfImages:(NSInteger)numberOfImages
                     durationInSeconds:(NSTimeInterval)durationInSeconds
                                 asset:(AVAsset *)asset
                             outputURL:(NSURL *)outputURL
{
    self = [super init];
    if (self)
    {
        _numberOfImages = numberOfImages;
        _durationInSeconds = durationInSeconds;
        _originalAsset = asset;
        _outputURL = [outputURL copy];
        
        _operationQueue = [[NSOperationQueue alloc] init];
        _operationQueue.maxConcurrentOperationCount = 1;
    }
    
    return self;
}

- (instancetype)init
{
    NSAssert(NO, @"Use designated initializer instead of -init.");
    
    return [self initWithNumberOfImages:0 durationInSeconds:0 asset:[[AVAsset alloc] init] outputURL:[[NSURL alloc] init]];
}

#pragma mark - Overrides

- (void)main
{
    [self composition];
}

- (void)cancel
{
    [super cancel];
    
    [self.operationQueue cancelAllOperations];
}

#pragma mark - Private API

- (void)composition
{
    CompositionOperation *operation = [[CompositionOperation alloc] initWithAssets:@[self.originalAsset]];
    
    __weak typeof(operation) weakOperation = operation;
    __weak typeof(self) weakSelf = self;
    operation.completionBlock = ^{
        
        if (weakOperation.cancelled)
        {
            return;
        }
        
        if (weakOperation.error)
        {
            weakSelf.error = weakOperation.error;
            [weakSelf completeOperation];
        }
        else if (weakOperation.composition)
        {
            [weakSelf extractionWithComposition:weakOperation.composition videoComposition:weakOperation.videoComposition];
        }
    };
    
    [self.operationQueue addOperation:operation];
}

- (void)extractionWithComposition:(AVMutableComposition *)composition videoComposition:(AVMutableVideoComposition *)videoComposition
{
    NSArray *times = [composition timesWithCount:self.numberOfImages];
    ImageExtractionOperation *operation = [[ImageExtractionOperation alloc] initWithTimes:times composition:composition videoComposition:videoComposition];
    
    __weak typeof(self) weakSelf = self;
    operation.progressBlock = ^(CGFloat progress) {
        [weakSelf reportProgressIfNecessary:progress];
    };
    
    __weak typeof(operation) weakOperation = operation;
    operation.completionBlock = ^{
        
        if (weakOperation.cancelled)
        {
            return;
        }
        
        if (weakOperation.error)
        {
            weakSelf.error = weakOperation.error;
            [weakSelf completeOperation];
        }
        else if (weakOperation.imageURLs)
        {
            [weakSelf GIFWithImageURLs:weakOperation.imageURLs];
        }
    };
    
    [self.operationQueue addOperation:operation];
}

- (void)GIFWithImageURLs:(NSArray <NSURL *> *)imageURLs
{
    NSTimeInterval frameDuration = self.durationInSeconds / [imageURLs count];
    GIFOperation *operation = [[GIFOperation alloc] initWithImageURLs:imageURLs frameDuration:frameDuration outputURL:self.outputURL];
    
    __weak typeof(self) weakSelf = self;
    __weak typeof(operation) weakOperation = operation;
    operation.completionBlock = ^{
        
        if (weakOperation.cancelled)
        {
            return;
        }
        
        if (weakOperation.error)
        {
            weakSelf.error = weakOperation.error;
        }
        
        [weakSelf completeOperation];
    };
    
    [self.operationQueue addOperation:operation];
}

- (void)reportProgressIfNecessary:(CGFloat)progress
{
    if (self.progressBlock)
    {
        self.progressBlock(progress);
    }
}

@end
