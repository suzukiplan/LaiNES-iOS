//
//  NESView.m
//
//  Created by Yoji Suzuki on 2017/01/07.
//  Copyright © 2017年 SUZUKI PLAN. All rights reserved.
//

#import <pthread.h>
#import "NESView.h"
#import "nes-core.h"

@interface NESView()
@property (readwrite) CADisplayLink* mpDisplayLink;
@property (readwrite) BOOL initialized;
@property (readwrite) BOOL setViewport;
@end

static unsigned short imgbuf[2][VRAM_WIDTH * 2 * VRAM_HEIGHT * 2 * 2];
static CGContextRef img[2];
static pthread_t tid=0;
static volatile int bno;
static volatile bool event_flag=false;
static volatile bool alive_flag=true;
static volatile bool end_flag=false;

@interface NESLayer : CALayer
@property (weak) NESView* view;
@end

@implementation NESView

#pragma mark - use custom layer

+(Class)layerClass {
    return [NESLayer class];
}

#pragma mark - Initializer

-(id)initWithCoder:(NSCoder *)aDecoder {
    if ([super initWithCoder:aDecoder]) {
        [self _init];
    }
    return self;
}

-(id)initWithFrame:(CGRect)frame {
    if ([super initWithFrame:frame]) {
        [self _init];
    }
    return self;
}

-(id)init {
    if ([super init]) {
        [self _init];
    }
    return self;
}

-(void)_init {
    nes_init();
    self.opaque = NO;
    self.clearsContextBeforeDrawing = NO;
    self.multipleTouchEnabled = NO;
    self.userInteractionEnabled = NO;
    ((NESLayer*)self.layer).view = self;
    _mpDisplayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(setNeedsDisplay)];
    [_mpDisplayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

-(void)drawRect:(CGRect)rect
{
}

#pragma mark - Public methods

-(BOOL)loadRomWithData:(NSData*)data {
    return nes_loadRom([data bytes], [data length]) ? YES : NO;
}

@end

@implementation NESLayer

// Main loop
static void* GameLoop(void* args)
{
    while(alive_flag) {
        while(event_flag) usleep(100);
        nes_vram_copy(imgbuf[bno]);
        event_flag = true;
    }
    end_flag = true;
    return NULL;
}

+(id)defaultActionForKey:(NSString *)key
{
    return nil;
}

- (id)init {
    if (self = [super init]) {
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        for(int i = 0; i < 2; i++) {
            img[i] = CGBitmapContextCreate(imgbuf[i],
                                           VRAM_WIDTH,
                                           VRAM_HEIGHT,
                                           5,
                                           VRAM_WIDTH * 2,
                                           colorSpace,
                                           kCGImageAlphaNoneSkipFirst|
                                           kCGBitmapByteOrder16Little
                                           );
            if (!img[i]) NSLog(@"CREATE FAILED");
        }
        CFRelease(colorSpace);
        pthread_create(&tid, NULL, GameLoop, NULL);
        struct sched_param param;
        memset(&param,0,sizeof(param));
        param.sched_priority = 46;
        pthread_setschedparam(tid,SCHED_OTHER,&param);
    }
    return self;
}

- (void)orientationChanged:(NSNotification *)notification
{
}

- (void)display {
    while (!event_flag) usleep(100);
    bno = 1 - bno;
    event_flag = false;
    CGImageRef cgImage = CGBitmapContextCreateImage(img[1 - bno]);
    self.contents = (__bridge id)cgImage;
    CFRelease(cgImage);
    [self.view.delegate gameScreenDidUpdate];
}

- (void)dealloc
{
    alive_flag = false;
    while (!end_flag) usleep(100);
    for (int i = 0; i < 2; i++) {
        if (img[i]) {
            CFRelease(img[i]);
            img[i] = nil;
        }
    }
}

@end
