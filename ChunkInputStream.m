//
//  ChunkInputStream.m
//
//  Copyright © 2015 Sebastian Volland. All rights reserved.
//  Copyright © 2011 BJ Homer. All rights reserved.
//

#import "ChunkInputStream.h"

@implementation ChunkInputStream
{
    NSInputStream *parentStream;
    id <NSStreamDelegate> delegate;

    CFReadStreamClientCallBack copiedCallback;
    CFStreamClientContext copiedContext;
    CFOptionFlags requestedEvents;

    NSInteger bytesLeft;
}

#pragma mark Object lifecycle

- (id)initWithInputStream:(NSInputStream *)stream
{
    self = [super init];
    if (self) {
        parentStream = stream;
        [parentStream setDelegate:self];

        [self setDelegate:self];
    }

    return self;
}

#pragma mark NSStream subclass methods

- (void)open {
    [parentStream open];
    [parentStream setProperty:[NSNumber numberWithUnsignedLong:self.startPosition] forKey:NSStreamFileCurrentOffsetKey];
    bytesLeft = self.readMax;
}

- (void)close {
    [parentStream close];
}

- (id <NSStreamDelegate> )delegate {
    return delegate;
}

- (void)setDelegate:(id<NSStreamDelegate>)aDelegate {
    if (aDelegate == nil) {
        delegate = self;
    }
    else {
        delegate = aDelegate;
    }
}

- (void)scheduleInRunLoop:(NSRunLoop *)aRunLoop forMode:(NSString *)mode {
    [parentStream scheduleInRunLoop:aRunLoop forMode:mode];
}

- (void)removeFromRunLoop:(NSRunLoop *)aRunLoop forMode:(NSString *)mode {
    [parentStream removeFromRunLoop:aRunLoop forMode:mode];
}

- (id)propertyForKey:(NSString *)key {
    return [parentStream propertyForKey:key];
}

- (BOOL)setProperty:(id)property forKey:(NSString *)key {
    return [parentStream setProperty:property forKey:key];
}

- (NSStreamStatus)streamStatus {
    return [parentStream streamStatus];
}

- (NSError *)streamError {
    return [parentStream streamError];
}

#pragma mark NSInputStream subclass methods

- (NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)len {
    NSInteger readLen = len;
    if (readLen > bytesLeft) {
        readLen = bytesLeft;
    }

    NSInteger bytesRead = [parentStream read:buffer maxLength:readLen];

    bytesLeft -= bytesRead;

    return bytesRead;
}

- (BOOL)getBuffer:(uint8_t **)buffer length:(NSUInteger *)len {
    return NO;
}

- (BOOL)hasBytesAvailable {
    if (bytesLeft <= 0) {
        return NO;
    }

    return [parentStream hasBytesAvailable];
}

#pragma mark Undocumented CFReadStream bridged methods

- (void)_scheduleInCFRunLoop:(CFRunLoopRef)aRunLoop forMode:(CFStringRef)aMode {

    CFReadStreamScheduleWithRunLoop((CFReadStreamRef)parentStream, aRunLoop, aMode);
}

- (BOOL)_setCFClientFlags:(CFOptionFlags)inFlags
                 callback:(CFReadStreamClientCallBack)inCallback
                  context:(CFStreamClientContext *)inContext {

    if (inCallback != NULL) {
        requestedEvents = inFlags;
        copiedCallback = inCallback;
        memcpy(&copiedContext, inContext, sizeof(CFStreamClientContext));

        if (copiedContext.info && copiedContext.retain) {
            copiedContext.retain(copiedContext.info);
        }
    }
    else {
        requestedEvents = kCFStreamEventNone;
        copiedCallback = NULL;
        if (copiedContext.info && copiedContext.release) {
            copiedContext.release(copiedContext.info);
        }

        memset(&copiedContext, 0, sizeof(CFStreamClientContext));
    }

    return YES;
}

- (void)_unscheduleFromCFRunLoop:(CFRunLoopRef)aRunLoop forMode:(CFStringRef)aMode {

    CFReadStreamUnscheduleFromRunLoop((CFReadStreamRef)parentStream, aRunLoop, aMode);
}

#pragma mark NSStreamDelegate methods

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {

    assert(aStream == parentStream);

    switch (eventCode) {
        case NSStreamEventOpenCompleted:
            if (requestedEvents & kCFStreamEventOpenCompleted) {
                copiedCallback((__bridge CFReadStreamRef)self,
                               kCFStreamEventOpenCompleted,
                               copiedContext.info);
            }
            break;

        case NSStreamEventHasBytesAvailable:
            if (requestedEvents & kCFStreamEventHasBytesAvailable) {
                copiedCallback((__bridge CFReadStreamRef)self,
                               kCFStreamEventHasBytesAvailable,
                               copiedContext.info);
            }
            break;

        case NSStreamEventErrorOccurred:
            if (requestedEvents & kCFStreamEventErrorOccurred) {
                copiedCallback((__bridge CFReadStreamRef)self,
                               kCFStreamEventErrorOccurred,
                               copiedContext.info);
            }
            break;
            
        case NSStreamEventEndEncountered:
            if (requestedEvents & kCFStreamEventEndEncountered) {
                copiedCallback((__bridge CFReadStreamRef)self,
                               kCFStreamEventEndEncountered,
                               copiedContext.info);
            }
            break;
            
        case NSStreamEventHasSpaceAvailable:
            break;
            
        default:
            break;
    }
}

@end
