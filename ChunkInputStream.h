//
//  ChunkInputStream.h
//
//  Copyright © 2015 Sebastian Volland. All rights reserved.
//  Copyright © 2011 BJ Homer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ChunkInputStream : NSInputStream <NSStreamDelegate>

@property (nonatomic) NSUInteger startPosition;
@property (nonatomic) NSUInteger readMax;

- (id)initWithInputStream:(NSInputStream *)stream;

@end
