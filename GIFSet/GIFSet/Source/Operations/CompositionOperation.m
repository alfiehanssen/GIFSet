//
//  CompositionOperation.m
//  GIFSet
//
//  Created by Alfred Hanssen on 3/24/16.
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

#import "CompositionOperation.h"

static NSString *CompositionOperationErrorDomain = @"CompositionOperationErrorDomain";

@interface CompositionOperation ()

@property (nonatomic, strong) NSArray<AVAsset *> *assets;

@property (nonatomic, strong, readwrite) AVMutableComposition *composition;
@property (nonatomic, strong, readwrite) AVMutableVideoComposition *videoComposition;
@property (nonatomic, strong, readwrite) NSError *error;

@end

@implementation CompositionOperation

- (instancetype _Nullable)initWithAssets:(NSArray<AVAsset *> * _Nonnull)assets
{
    NSAssert([assets count] > 0, @"Must be initialized with at least one asset.");
    
    self = [super init];
    if (self)
    {
        _assets = assets;
    }
    
    return self;
}

- (instancetype)init
{
    NSAssert(NO, @"Use designated initializer instead of -init.");
    
    return [self initWithAssets:@[]];
}

#pragma mark - Overrides

- (void)main
{
    NSMutableArray *instructions = [NSMutableArray array];
    
    AVMutableComposition *composition = [AVMutableComposition composition];
    AVMutableCompositionTrack *compositionTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    for (AVAsset *asset in self.assets)
    {
        NSArray *videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
        NSAssert([videoTracks count] == 1, @"Attempt to generate a composition from an asset with no video tracks.");
        
        AVAssetTrack *assetTrack = [videoTracks firstObject];
        AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:assetTrack];
        [layerInstruction setTransform:assetTrack.preferredTransform atTime:kCMTimeZero];

        CMTimeRange range = CMTimeRangeMake(kCMTimeZero, asset.duration);
        
        AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        instruction.timeRange = CMTimeRangeMake(composition.duration, range.duration);
        instruction.layerInstructions = @[layerInstruction];
        [instructions addObject:instruction];
        
        NSError *error = nil;
        if (![compositionTrack insertTimeRange:range ofTrack:assetTrack atTime:composition.duration error:&error])
        {
            self.error = error;
            
            [self completeOperation];

            return;
        }
    }
    
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition]; // TODO: use "withPropertiesOfAsset" constructor?
    videoComposition.instructions = instructions;
    videoComposition.frameDuration = CMTimeMake(1, compositionTrack.naturalTimeScale);
    videoComposition.renderScale = 1.0; // The docs are poor on this property, a value of 1 seems to be the standard
    videoComposition.renderSize = compositionTrack.naturalSize;
    
    if (CGSizeEqualToSize(CGSizeZero, videoComposition.renderSize))
    {
        self.error = [NSError errorWithDomain:CompositionOperationErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey: @"videoComposition.renderSize is zero."}];
    }
    else
    {
        self.composition = composition;
        self.videoComposition = videoComposition;
    }
    
    [self completeOperation];
}

@end
