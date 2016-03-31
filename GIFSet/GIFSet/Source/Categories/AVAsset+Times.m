//
//  AVAsset+Times.m
//  GIFSet
//
//  Created by Alfred Hanssen on 3/25/16.
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

#import "AVAsset+Times.h"

static const NSTimeInterval TimeTolerance = 0.01;

@implementation AVAsset (Times)

- (NSArray <NSValue *>*)timesWithCount:(NSInteger)count
{
    if (count <= 0)
    {
        NSAssert(count > 0, @"Count must be greater than zero.");

        return @[];
    }
    
    Float64 duration = CMTimeGetSeconds(self.duration);
    Float64 interval = duration / count;
    
    return [self timesAtInterval:interval];
}

- (NSArray <NSValue *>*)timesAtInterval:(NSTimeInterval)interval
{
    if (interval <= 0)
    {
        NSAssert(interval > 0, @"Interval must be greater than zero.");

        return @[];
    }
    
    AVAssetTrack *track = [[self tracksWithMediaType:AVMediaTypeVideo] firstObject];
    if (!track)
    {
        return @[];
    }
    
    Float64 duration = CMTimeGetSeconds(track.asset.duration);
    CMTimeScale timescale = track.naturalTimeScale;
    NSMutableArray <NSValue *>*times = [NSMutableArray array];

    Float64 currentTime = 0;
    
    // We use TimeTolerance as a buffer because if we construct a time too close to the end of the asset
    // image extraction at that time will fail [AH] 3/25/2016
    
    while (currentTime < duration - TimeTolerance)
    {
        CMTime time = CMTimeMakeWithSeconds(currentTime, timescale);
        [times addObject:[NSValue valueWithCMTime:time]];
        
        currentTime += interval;
    }
        
    return times;
}

@end
