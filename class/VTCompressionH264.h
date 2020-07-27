//
//  VTCompressionH264.h
//  Pods
//
//  Created by Dcell on 2017/7/6.
//
//

#import <Foundation/Foundation.h>
#import <VideoToolbox/VideoToolbox.h>
#import <CoreVideo/CoreVideo.h>

typedef enum : NSUInteger {
    FrameType_SPSPPS,
    FrameType_IFreme,
    FrameType_PFreme,
} FrameType;

@protocol H264EncodeDelegate <NSObject>

-(void)dataCallBack:(NSData *)data frameType:(FrameType)frameType;
-(void)spsppsDataCallBack:(NSData *)sps pps:(NSData *)pps;

@end

@interface VTCompressionH264 : NSObject

@property(nonatomic,assign) dispatch_queue_t enCodeQueue;///队列，如果未设置 默认会给你设置一个异步
@property(nonatomic,assign) int width;
@property(nonatomic,assign) int height;
@property(nonatomic,assign) int fps;
@property(nonatomic,weak) id<H264EncodeDelegate> delegate;
@property(nonatomic,assign) BOOL allowFrameReordering; //是否启用了帧重新排序,B帧

-(void)prepareToEncodeFrames;//准备开始出来数据
-(void)encode:(CMSampleBufferRef )sampleBuffer;///编码 CVPixelBufferRef
-(void)encodeBy:(CVPixelBufferRef )cVPixelBufferRef;///编码
-(void)invalidate;//终止
@end
