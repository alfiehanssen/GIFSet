//
//  CompositionOperation.h
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

#import "ConcurrentOperation.h"

@import Foundation;
@import AVFoundation;

@interface CompositionOperation : ConcurrentOperation

@property (nonatomic, strong, readonly) AVMutableComposition * _Nullable composition;
@property (nonatomic, strong, readonly) AVMutableVideoComposition * _Nullable videoComposition;
@property (nonatomic, strong, readonly) NSError * _Nullable error;

- (instancetype _Nullable)initWithAssets:(NSArray<AVAsset *> * _Nonnull)assets NS_DESIGNATED_INITIALIZER;

@end
