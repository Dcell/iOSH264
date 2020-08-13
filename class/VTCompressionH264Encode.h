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

@protocol VTCompressionH264EncodeDelegate <NSObject>

-(void)dataCallBack:(NSData *)data frameType:(FrameType)frameType;
-(void)spsppsDataCallBack:(NSData *)sps pps:(NSData *)pps;

@end

@interface VTCompressionH264Encode : NSObject
@property(nonatomic,assign) int width;
@property(nonatomic,assign) int height;
@property(nonatomic,assign) int fps;
@property(nonatomic,assign) int frameInterval;
@property(nonatomic,assign) int bitRate;
@property(nonatomic,assign) int dataRateLimit;

@property(nonatomic,weak) id<VTCompressionH264EncodeDelegate> delegate;
@property(nonatomic,assign) BOOL allowFrameReordering; //是否启用了帧重新排序，有些不支持B帧解析，则需要关闭B帧


-(void)prepareToEncodeFrames;//准备开始出来数据
-(void)encodeBySampleBuffer:(CMSampleBufferRef )sampleBuffer;///编码 CMSampleBufferRef
-(void)encodeByPixelBuffer:(CVPixelBufferRef )cVPixelBufferRef;///编码 CVPixelBufferRef
-(void)invalidate;//终止
@end
