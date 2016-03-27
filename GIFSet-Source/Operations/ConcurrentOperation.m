//
//  ConcurrentOperation.m
//  GIFSet
//
//  Created by Alfie Hanssen on 12/25/14.
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

#import "ConcurrentOperation.h"

static NSString *const IsFinishedKey = @"isFinished";
static NSString *const IsExecutingKey = @"isExecuting";

@interface ConcurrentOperation ()
{
    BOOL _executing;
    BOOL _finished;
}

@end

@implementation ConcurrentOperation

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _executing = NO;
        _finished = NO;
    }
    
    return self;
}

- (void)start
{
    if ([self isCancelled])
    {
        [self willChangeValueForKey:IsFinishedKey];
        
        _finished = YES;
        
        [self didChangeValueForKey:IsFinishedKey];
        
        return;
    }
    
    [self willChangeValueForKey:IsExecutingKey];
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [weakSelf main];
    });
    
    _executing = YES;
    
    [self didChangeValueForKey:IsExecutingKey];
}

- (void)cancel
{
    [super cancel];
    
    [self completeOperation];
}

- (void)completeOperation
{
    [self willChangeValueForKey:IsFinishedKey];
    [self willChangeValueForKey:IsExecutingKey];
    
    _executing = NO;
    _finished = YES;
    
    [self didChangeValueForKey:IsExecutingKey];
    [self didChangeValueForKey:IsFinishedKey];
}

- (BOOL)isConcurrent
{
    return YES;
}

- (BOOL)isExecuting
{
    return _executing;
}

- (BOOL)isFinished
{
    return _finished;
}

@end
