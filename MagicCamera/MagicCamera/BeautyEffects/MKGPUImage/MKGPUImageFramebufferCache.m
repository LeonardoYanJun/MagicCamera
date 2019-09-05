//
//  MKGPUImageFramebufferCache.m
//  MagicCamera
//
//  Created by mkil on 2019/9/4.
//  Copyright © 2019 黎宁康. All rights reserved.
//

#import "MKGPUImageFramebufferCache.h"

#import "MKGPUImageOutput.h"
#import "MKGPUImageFramebuffer.h"
#import "MKGPUImageContext.h"

@interface MKGPUImageFramebufferCache()
{
    NSMutableDictionary *framebufferCache;
}

@property (nonatomic, weak) MKGPUImageContext *context;

- (NSString *)hashForSize:(CGSize)size textureOptions:(MKGPUTextureOptions)textureOptions missCVPixelBuffer:(BOOL)missCVPixelBuffer;

@end


@implementation MKGPUImageFramebufferCache

#pragma mark -
#pragma mark Initialization and teardown

- (id)initWithContext:(MKGPUImageContext *)context;
{
    if (!(self = [super init]))
    {
        return nil;
    }
    
    self.context = context;
    
    framebufferCache = [[NSMutableDictionary alloc] init];
    
    return self;
}

- (void)dealloc;
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -
#pragma mark Framebuffer management

- (NSString *)hashForSize:(CGSize)size textureOptions:(MKGPUTextureOptions)textureOptions missCVPixelBuffer:(BOOL)missCVPixelBuffer;
{
    if (missCVPixelBuffer)
    {
        return [NSString stringWithFormat:@"%.1fx%.1f-%d:%d:%d:%d:%d:%d:%d-CVBF", size.width, size.height, textureOptions.minFilter, textureOptions.magFilter, textureOptions.wrapS, textureOptions.wrapT, textureOptions.internalFormat, textureOptions.format, textureOptions.type];
    }
    else
    {
        return [NSString stringWithFormat:@"%.1fx%.1f-%d:%d:%d:%d:%d:%d:%d", size.width, size.height, textureOptions.minFilter, textureOptions.magFilter, textureOptions.wrapS, textureOptions.wrapT, textureOptions.internalFormat, textureOptions.format, textureOptions.type];
    }
}

- (MKGPUImageFramebuffer *)fetchFramebufferForSize:(CGSize)framebufferSize textureOptions:(MKGPUTextureOptions)textureOptions missCVPixelBuffer:(BOOL)missCVPixelBuffer;
{
    __block MKGPUImageFramebuffer *framebufferFromCache = nil;
    runAYSynchronouslyOnContextQueue(self.context, ^{
        NSString *lookupHash = [self hashForSize:framebufferSize textureOptions:textureOptions missCVPixelBuffer:missCVPixelBuffer];
        
        
        NSMutableArray *frameBufferArr = [framebufferCache objectForKey:lookupHash];
        
        if (frameBufferArr != nil && frameBufferArr.count > 0){
            framebufferFromCache = [frameBufferArr lastObject];
            [frameBufferArr removeLastObject];
            [framebufferCache setObject:frameBufferArr forKey:lookupHash];
        }
        
        if (framebufferFromCache == nil)
        {
            framebufferFromCache = [[MKGPUImageFramebuffer alloc] initWithContext:self.context size:framebufferSize textureOptions:textureOptions missCVPixelBuffer:missCVPixelBuffer];
        }
    });
    
    [framebufferFromCache lock];
    return framebufferFromCache;
}

- (MKGPUImageFramebuffer *)fetchFramebufferForSize:(CGSize)framebufferSize missCVPixelBuffer:(BOOL)missCVPixelBuffer;
{
    MKGPUTextureOptions defaultTextureOptions;
    defaultTextureOptions.minFilter = GL_LINEAR;
    defaultTextureOptions.magFilter = GL_LINEAR;
    defaultTextureOptions.wrapS = GL_CLAMP_TO_EDGE;
    defaultTextureOptions.wrapT = GL_CLAMP_TO_EDGE;
    defaultTextureOptions.internalFormat = GL_RGBA;
    defaultTextureOptions.format = GL_BGRA;
    defaultTextureOptions.type = GL_UNSIGNED_BYTE;
    
    return [self fetchFramebufferForSize:framebufferSize textureOptions:defaultTextureOptions missCVPixelBuffer:missCVPixelBuffer];
}

- (void)returnFramebufferToCache:(MKGPUImageFramebuffer *)framebuffer;
{
    [framebuffer clearAllLocks];
    
    runAYSynchronouslyOnContextQueue(self.context, ^{
        CGSize framebufferSize = framebuffer.size;
        MKGPUTextureOptions framebufferTextureOptions = framebuffer.textureOptions;
        NSString *lookupHash = [self hashForSize:framebufferSize textureOptions:framebufferTextureOptions missCVPixelBuffer:framebuffer.missCVPixelBuffer];
        
        NSMutableArray *frameBufferArr = [framebufferCache objectForKey:lookupHash];
        if (!frameBufferArr) {
            frameBufferArr = [NSMutableArray array];
        }
        
        [frameBufferArr addObject:framebuffer];
        [framebufferCache setObject:frameBufferArr forKey:lookupHash];
        
    });
}


@end
