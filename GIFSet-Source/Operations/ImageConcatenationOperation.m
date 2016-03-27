//
//  ImageConcatenationOperation.m
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

#import "ImageConcatenationOperation.h"
#import "NSURL+Extensions.h"
#import "NSFileManager+Extensions.h"

@import UIKit;

static NSString *ImageConcatenationOperationErrorDomain = @"ImageConcatenationOperationErrorDomain";

static CGFloat ThreadSleepTime = 0.2f;

@interface ImageConcatenationOperation ()

@property (nonatomic, copy) NSArray <NSURL *>*imageURLs;
@property (nonatomic, assign) Float64 duration;

@property (nonatomic, strong) AVAssetWriter *assetWriter;
@property (nonatomic, strong) AVAssetWriterInput *assetWriterInput;
@property (nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor *assetWriterAdaptor;

@property (nonatomic, copy, readwrite) NSURL *outputURL;
@property (nonatomic, strong, readwrite) NSError *error;

@end

@implementation ImageConcatenationOperation

- (void)dealloc
{
    [_assetWriter cancelWriting];
    _progressBlock = nil;
}

- (instancetype)initWithImageURLs:(NSArray *)imageURLs duration:(Float64)duration outputURL:(NSURL *)outputURL
{
    NSAssert([imageURLs count] > 0 && duration > 0, @"Must be initialized with valid imageURL array and duration");
    
    self = [super init];
    if (self)
    {
        _imageURLs = [imageURLs copy];
        _duration = duration;
        _outputURL = [outputURL copy];
    }
    
    return self;
}

- (instancetype)init
{
    NSAssert(NO, @"Use designated initializer instead of -init.");
    
    return [self initWithImageURLs:@[] duration:0 outputURL:[[NSURL alloc] init]];
}

#pragma mark - Overrides

- (void)cancel
{    
    [super cancel];
    
    [self.assetWriter cancelWriting];

    _progressBlock = nil;
    _error = nil;

    self.assetWriter = nil;
    self.assetWriterInput = nil;
    self.assetWriterAdaptor = nil;
    
    [self removeOutputFile];
}

- (void)completeOperation
{
    if (self.error)
    {
        [self removeOutputFile];
    }
    
    self.assetWriter = nil;
    self.assetWriterInput = nil;
    self.assetWriterAdaptor = nil;

    [super completeOperation];
}

- (void)main
{
    NSAssert([self.imageURLs count] > 0, @"imageURLs.count must be greater than zero.");

    for (int i = 0; i < [self.imageURLs count]; i++)
    {
        @autoreleasepool
        {
            if ([self isCancelled])
            {
                return;
            }
            
            NSURL *URL = self.imageURLs[i];
            NSData *data = [NSData dataWithContentsOfFile:[URL absoluteString]];
            UIImage *image = [UIImage imageWithData:data];
            CGImageRef cgImage = image.CGImage;
            
            int width = (int)CGImageGetWidth(cgImage);
            int height = (int)CGImageGetHeight(cgImage);
            
            if (self.assetWriter == nil) // If this is the first iteration of our loop
            {
                // TODO: we initialize assetWriter with dimensions of only the first image when we should take all images into account [AH] 3/27/2016

                NSError *error = nil;
                if (![self beginWritingVideoWithWidth:width height:height error:&error])
                {
                    self.error = error;
                    
                    [self completeOperation];
                    
                    return;
                }
            }
            
            CVPixelBufferRef pixelBuffer = [self newPixelBufferFromCGImage:cgImage withWidth:width andHeight:height];
            if (pixelBuffer)
            {
                Float64 currentTime = i * (self.duration / [self.imageURLs count]);
                int32_t timescale = 600;
                CMTime imageTime = CMTimeMakeWithSeconds(currentTime, timescale);
                
                [self writePixelBufferToVideo:pixelBuffer atTime:imageTime];
                
                CVPixelBufferRelease(pixelBuffer);
                
                if (self.assetWriter.error)
                {
                    self.error = self.assetWriter.error;
                }
                else if (self.assetWriter.status == AVAssetWriterStatusFailed)
                {
                    self.error = [NSError errorWithDomain:ImageConcatenationOperationErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : @"AssetWriter status = failed."}];
                }
                
                if (self.error)
                {
                    [self completeOperation];
                    
                    return;
                }
            }
            
            if (self.progressBlock)
            {
                CGFloat progressFraction = (CGFloat)(i+1) / (CGFloat)[self.imageURLs count];
                self.progressBlock(progressFraction);
            }
        }
    }
    
    [self.assetWriterInput markAsFinished];
    
    [self.assetWriter finishWritingWithCompletionHandler:^{
        
        CVPixelBufferPoolRelease(self.assetWriterAdaptor.pixelBufferPool);
        
        [self completeOperation];
        
    }];
}

#pragma mark - Private API

- (BOOL)beginWritingVideoWithWidth:(int)width height:(int)height error:(NSError **)error
{
    self.assetWriter = [[AVAssetWriter alloc] initWithURL:self.outputURL fileType:AVFileTypeMPEG4 error:error];
    if (self.assetWriter == nil)
    {
        return NO;
    }
    
//    NSDictionary *compressionSettings = @{AVVideoProfileLevelKey : AVVideoProfileLevelH264HighAutoLevel};
    
    NSDictionary *videoSettings = @{AVVideoCodecKey : AVVideoCodecH264,
                                    AVVideoWidthKey : @(width),
                                    AVVideoHeightKey : @(height)};//,
//                                    AVVideoScalingModeKey : AVVideoScalingModeResizeAspectFill,
//                                    AVVideoCompressionPropertiesKey : compressionSettings};

    self.assetWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    self.assetWriterInput.expectsMediaDataInRealTime = NO;
//    self.assetWriterInput.transform = CGAffineTransformMakeRotation(M_PI_2);
    
    self.assetWriterAdaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:self.assetWriterInput sourcePixelBufferAttributes:nil];
    
    [self.assetWriter addInput:self.assetWriterInput];
    self.assetWriter.shouldOptimizeForNetworkUse = YES;
    [self.assetWriter startWriting];
    [self.assetWriter startSessionAtSourceTime:kCMTimeZero];
    
    return YES;
}

- (CVPixelBufferRef)newPixelBufferFromCGImage:(CGImageRef)image withWidth:(int)width andHeight:(int)height
{
    // This is necessary in portrait view, NOT SURE WHY, investigate later
    if (width < height)
    {
        int tempHeight = height;
        height = width;
        width = tempHeight;
    }
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             @YES, kCVPixelBufferCGImageCompatibilityKey,
                             @YES, kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options, &pxbuffer);
    
    if (status != kCVReturnSuccess || pxbuffer == NULL)
    {
        return nil;
    }
    
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(pxbuffer);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Big;
    CGContextRef context = CGBitmapContextCreate(pxdata, width, height, 8, bytesPerRow, rgbColorSpace, bitmapInfo);
    NSParameterAssert(context);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), image);
    
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

- (void)writePixelBufferToVideo:(CVPixelBufferRef)pixelBuffer atTime:(CMTime)frameTime
{
    while (!self.assetWriterAdaptor.assetWriterInput.readyForMoreMediaData && ![self isCancelled])
    {
        NSLog(@"AssetWriter not ready for media. Waiting...");
        
        [NSThread sleepForTimeInterval:ThreadSleepTime];
    }
    
    if (![self.assetWriterAdaptor appendPixelBuffer:pixelBuffer withPresentationTime:frameTime])
    {
        NSLog(@"Error adding image to video: %lld %@", frameTime.value/frameTime.timescale, self.assetWriter.error);
    }
}

- (void)removeOutputFile
{
    NSString *path = [self.outputURL path];
    [[NSFileManager defaultManager] removeFileAtPathIfPossible:path];
}

@end
