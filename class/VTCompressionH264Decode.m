//
//  VTCompressionH264Decode.m
//  iOSH264
//
//  Created by mac_25648_newMini on 2020/7/28.
//

#import "VTCompressionH264Decode.h"

/// 在渲染之前，必须先拿到 sps和pps；一般的NALU头，前面4个字节默认都是0001，第5个字节是帧类型


@interface VTCompressionH264Decode()

@property (strong,nonatomic) NSData *cacheData;//缓存的数据
@property (strong,nonatomic) NSData *sps;
@property (strong,nonatomic) NSData *pps;
@property (nonatomic, assign) CMVideoFormatDescriptionRef formatDesc;
@property (nonatomic, assign) VTDecompressionSessionRef decompressionSession;
@property (nonatomic,strong) NSLock *lock;
@end

@implementation VTCompressionH264Decode


- (instancetype)init
{
    self = [super init];
    if (self) {
        self.cacheData = nil;
        self.sps = nil;
        self.pps = nil;
        self.lock = [NSLock new];
    }
    return self;
}

- (void)decode:(NSData *)decodeData{
    if(decodeData == nil){
        return;
    }
    [self.lock lock];
    NSMutableData *data;
    if (self.cacheData && self.cacheData.length > 0) {
        data =  [[NSMutableData alloc] initWithData:self.cacheData];
        [data appendData:decodeData];
    }else{
        data = [[NSMutableData alloc] initWithData:decodeData];
    }
    self.cacheData = data;
    NSData* naluData = [self findNextNalu];
    while (naluData) {
        char* frameBytes =  (char*)[naluData bytes];
        //帧类型
        int nalu_type = (frameBytes[4] & 0x1F);
        if(nalu_type == 7){//sps
            self.sps = [naluData subdataWithRange:NSMakeRange(4, naluData.length - 4)];;
        }else if(nalu_type == 8){//pps
            self.pps = [naluData subdataWithRange:NSMakeRange(4, naluData.length - 4)];;
        }else if(nalu_type == 5){//I Frame
            uint32_t dataLength32 = htonl (naluData.length - 4);//替换startCode -> size
            memcpy (frameBytes, &dataLength32, sizeof (uint32_t));
            [self decodeFrame:[NSData dataWithBytes:frameBytes length:naluData.length]];
        }else if(nalu_type == 1){//other
            uint32_t dataLength32 = htonl (naluData.length - 4);
            memcpy (frameBytes, &dataLength32, sizeof (uint32_t));
            [self decodeFrame:[NSData dataWithBytes:frameBytes length:naluData.length]];
        }
        if(self.sps && self.pps){
            //create session
            OSStatus status = [self createFromH264ParameterSets];
            if(status != noErr){
                NSLog(@"createFromH264ParameterSets error:%d",status);
            }
        }
        if(self.decompressionSession == NULL && self.formatDesc != NULL){
            OSStatus status = [self createDecompSession];
            if(status != noErr){
                NSLog(@"createDecompSession error:%d",status);
            }
        }
        
        naluData = [self findNextNalu];
    }
    [self.lock unlock];
}

#pragma mark FIND NEXT Nalu Data
- (NSData *)findNextNalu{
    NSData *data = self.cacheData;
    int startIndex = -1;
    int endIndex = -1;
    char* frameBytes =  (char*)[data bytes];
    for (int i = 0; i < data.length; i ++ ) {//是否可以优化，加快寻找速度:如每次2个字节
        if(i + 4 < data.length){
            if (frameBytes[i] == 0x00 && frameBytes[i + 1] == 0x00 && frameBytes[i + 2] == 0x00 && frameBytes[ i+3] == 0x01){
                if(startIndex == -1){
                    startIndex = i;
                }else{
                    endIndex = i;
                    break;
                }
            }
        }
    }
    if(startIndex != -1 && endIndex != -1){
        self.cacheData = [self.cacheData subdataWithRange:NSMakeRange(endIndex, self.cacheData.length - endIndex)];
        return [data subdataWithRange:NSMakeRange(startIndex, endIndex - startIndex)];
    }
    return nil;
}

#pragma mark createFromH264ParameterSets
- (OSStatus)createFromH264ParameterSets{
    // now we set our H264 parameters
    // See if decomp session can convert from previous format description
    // to the new one, if not we need to remake the decomp session.
    // This snippet was not necessary for my applications but it could be for yours
    CMVideoFormatDescriptionRef formatDesc = NULL;
    const uint8_t*  parameterSetPointers[2] = {(const uint8_t*)[self.sps bytes], (const uint8_t*)[self.pps bytes]};
    const size_t parameterSetSizes[2] = {self.sps.length, self.pps.length};
    OSStatus status = CMVideoFormatDescriptionCreateFromH264ParameterSets(kCFAllocatorDefault, 2,
                                                                parameterSetPointers,
                                                                 parameterSetSizes, 4,
                                                                 &formatDesc);
    if(self.decompressionSession != NULL){
        BOOL needNewDecompSession = (VTDecompressionSessionCanAcceptFormatDescription(_decompressionSession, formatDesc) == NO);
        if(needNewDecompSession){
            VTDecompressionSessionInvalidate(self.decompressionSession);
            self.decompressionSession = NULL;
        }
    }
    self.formatDesc = formatDesc;
    return status;
}

#pragma mark createDecompSession
-(OSStatus) createDecompSession
{
   // make sure to destroy the old VTD session
    self.decompressionSession = NULL;
   VTDecompressionOutputCallbackRecord callBackRecord;
   callBackRecord.decompressionOutputCallback = decompressionSessionDecodeFrameCallback;

   // this is necessary if you need to make calls to Objective C "self" from within in the callback method.
   callBackRecord.decompressionOutputRefCon = (__bridge void *)self;

   // you can set some desired attributes for the destination pixel buffer.  I didn't use this but you may
   // if you need to set some attributes, be sure to uncomment the dictionary in VTDecompressionSessionCreate
        

   return VTDecompressionSessionCreate(kCFAllocatorDefault, _formatDesc, NULL,
//                                                   (__bridge CFDictionaryRef)(destinationImageBufferAttributes),
                                       NULL,
                                                   &callBackRecord, &_decompressionSession);
}

#pragma mark decodeFrame
-(OSStatus) decodeFrame:(NSData *)frameData{
    
    CMBlockBufferRef blockBuffer = NULL;
    // create a block buffer from the IDR NALU
    OSStatus status = CMBlockBufferCreateWithMemoryBlock(NULL, (void *)[frameData bytes],  // memoryBlock to hold buffered data
                                                [frameData length],  // block length of the mem block in bytes.
                                                kCFAllocatorNull, NULL,
                                                0, // offsetToData
                                                [frameData length],   // dataLength of relevant bytes, starting at offsetToData
                                                0, &blockBuffer);
    if(status != noErr){
        return status;
    }
    const size_t sampleSize = [frameData length];
    CMSampleBufferRef sampleBuffer = NULL;
    status = CMSampleBufferCreate(kCFAllocatorDefault,
                                 blockBuffer, true, NULL, NULL,
                                 _formatDesc, 1, 0, NULL, 1,
                                 &sampleSize, &sampleBuffer);
    if(status != noErr){
        return status;
    }
    
    CFArrayRef attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, YES);
    CFMutableDictionaryRef dict = (CFMutableDictionaryRef)CFArrayGetValueAtIndex(attachments, 0);
    CFDictionarySetValue(dict, kCMSampleAttachmentKey_DisplayImmediately, kCFBooleanTrue);
    
    VTDecodeFrameFlags flags = kVTDecodeFrame_EnableAsynchronousDecompression;
    VTDecodeInfoFlags flagOut;
    NSDate* currentTime = [NSDate date];
    status = VTDecompressionSessionDecodeFrame(_decompressionSession, sampleBuffer, flags,(void*)CFBridgingRetain(currentTime), &flagOut);
    CFRelease(sampleBuffer);
    
    return status;

}

- (void)invalidate{
    [self.lock lock];
    if(self.decompressionSession != NULL){
        VTDecompressionSessionInvalidate(self.decompressionSession);
    }
    self.formatDesc = NULL;
    self.decompressionSession = NULL;
    self.cacheData = nil;
    self.sps = nil;
    self.pps = nil;
    [self.lock unlock];
}

#pragma mark decompressionSessionDecodeFrameCallback
void decompressionSessionDecodeFrameCallback(void *decompressionOutputRefCon,
                                             void *sourceFrameRefCon,
                                             OSStatus status,
                                             VTDecodeInfoFlags infoFlags,
                                             CVImageBufferRef imageBuffer,
                                             CMTime presentationTimeStamp,
                                             CMTime presentationDuration)
{
    
    if (status != noErr)
    {
       NSError *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
       NSLog(@"Decompressed error: %@", error);
   }
   else
   {
       VTCompressionH264Decode *decode = (__bridge VTCompressionH264Decode *)decompressionOutputRefCon;
       if(decode.delegate){
           [decode.delegate imageBufferCallBack:imageBuffer];
       }
   }
}
@end
