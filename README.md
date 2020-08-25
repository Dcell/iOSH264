# [iOSH264Compression](https://github.com/Code-Dogs/iOSH264)
iOS H264 decode&encode by VideoToolbox

# Installation with CocoaPods

```
pod 'iOSH264Compression'
```
# Usage
## H264 Encode
1.Create `VTCompressionH264Encode`

```
let vTCompressionH264:VTCompressionH264Encode = VTCompressionH264Encode()
```
2.Set Options

```
vTCompressionH264.width = 480
vTCompressionH264.height = 640
vTCompressionH264.fps = 10
```

3.Set Encode Delegate

```
vTCompressionH264.delegate = self
```
4.PrepareTo Encode

```
vTCompressionH264.prepareToEncodeFrames()
```
4.Add BufferRef

```
vTCompressionH264.encode(by: sampleBuffer)
```
5.Invalidate

```
vTCompressionH264.invalidate()
```
## H264 Decode
1.Create VTCompressionH264Decode

```
let vTCompressionH264Decode:VTCompressionH264Decode = VTCompressionH264Decode()
```

2.Set Decode Delegate

```
vTCompressionH264Decode.delegate = self
```

3.Decode H264 Buffer

```
vTCompressionH264Decode.decode(byteHeaderData)
```

# Demo
![](PXCQ9662.mp4)
# License
iOSH264 is released under the MIT license. See LICENSE for details.