//
//  NSURL+Extensions.m
//  GIFSet
//
//  Created by Alfie Hanssen on 8/29/14.
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

#import "NSURL+Extensions.h"

@import MobileCoreServices;
@import AVFoundation;

static NSString *MP4Directory = @"mp4s";
static NSString *ImageDirectory = @"pngs";
static NSString *GIFDirectory = @"gifs";

@implementation NSURL (Extensions)

+ (NSURL *)uniqueMp4URL
{
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:MP4Directory];
    
    NSError *error = nil;
    if (![[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error])
    {
        NSLog(@"Error creating MP4 directory: %@", error.localizedDescription);
    }
    
    NSString *uniqueString = [[NSProcessInfo processInfo] globallyUniqueString];
    path = [path stringByAppendingPathComponent:uniqueString];
    
    NSString *pathExtension = CFBridgingRelease(UTTypeCopyPreferredTagWithClass((CFStringRef)AVFileTypeMPEG4, kUTTagClassFilenameExtension));
    path = [path stringByAppendingPathExtension:pathExtension];
    
    return [NSURL fileURLWithPath:path];
}

+ (NSURL *)uniqueImageURL
{
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:ImageDirectory];

    NSError *error = nil;
    if (![[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error])
    {
        NSLog(@"Error creating image directory: %@", error.localizedDescription);
    }
    
    NSString *uniqueString = [[NSProcessInfo processInfo] globallyUniqueString];
    path = [path stringByAppendingPathComponent:uniqueString];
    
    path = [path stringByAppendingPathExtension:@"data"];
    
    return [NSURL URLWithString:path];
}

+ (NSURL *)uniqueGIFURL
{
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:GIFDirectory];

    NSError *error = nil;
    if (![[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error])
    {
        NSLog(@"Error creating GIF directory: %@", error.localizedDescription);
    }
    
    NSString *uniqueString = [[NSProcessInfo processInfo] globallyUniqueString];
    path = [path stringByAppendingPathComponent:uniqueString];
    
    NSString *pathExtension = CFBridgingRelease(UTTypeCopyPreferredTagWithClass((CFStringRef)kUTTypeGIF, kUTTagClassFilenameExtension));
    path = [path stringByAppendingPathExtension:pathExtension];
    
    return [NSURL URLWithString:path];
}

@end
