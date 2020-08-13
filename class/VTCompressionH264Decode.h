//
//  VTCompressionH264Decode.h
//  iOSH264
//
//  Created by mac_25648_newMini on 2020/7/28.
//

#import <Foundation/Foundation.h>
#import <VideoToolbox/VideoToolbox.h>

NS_ASSUME_NONNULL_BEGIN

@protocol VTCompressionH264DecodeDelegate <NSObject>
- (void)imageBufferCallBack:(CVImageBufferRef)imageBuffer;
@end

@interface VTCompressionH264Decode : NSObject
@property(weak,nonatomic) id<VTCompressionH264DecodeDelegate> delegate;

- (void)decode:(NSData *)decodeData;
- (void)invalidate;//终止

@end

NS_ASSUME_NONNULL_END
