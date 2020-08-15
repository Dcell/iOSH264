//
//  ViewController.swift
//  h264demo
//
//  Created by mac_25648_newMini on 2020/8/12.
//  Copyright © 2020 code-dogs. All rights reserved.
//

import UIKit
import AVFoundation
import iOSH264Compression

class ViewController: UIViewController {
    @IBOutlet weak var decodeView: UIView!
    @IBOutlet weak var encodeView: UIView!
    let vTCompressionH264:VTCompressionH264Encode = VTCompressionH264Encode()
    let vTCompressionH264Decode:VTCompressionH264Decode = VTCompressionH264Decode()
    var aAPLEAGLLayer:AAPLEAGLLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { (notification) in
            self.startEncode()
        }
        NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: nil) { (notification) in
            self.stopEncode()
        }
        vTCompressionH264Decode.delegate = self
        
        
        aAPLEAGLLayer = AAPLEAGLLayer(frame: self.view.frame)
        
        self.decodeView.layer.addSublayer(aAPLEAGLLayer)
        
        // Do any additional setup after loading the view.
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.startEncode()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.stopEncode()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension ViewController{
    func startEncode(){
        let aVCaptureSession =  AVCaptureSession()
        if aVCaptureSession.canSetSessionPreset(AVCaptureSession.Preset.vga640x480){
           aVCaptureSession.sessionPreset = AVCaptureSession.Preset.vga640x480
        }
        let videoDevices = AVCaptureDevice.DiscoverySession.init(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .unspecified).devices//  AVCaptureDevice.devices(for: AVMediaTypeVideo)
        var videoInputDevice =  AVCaptureDevice.default(for: AVMediaType.video)//视频输入设备
        videoDevices.forEach({ (aVCaptureDevice) in
            if aVCaptureDevice.position == .back {
                videoInputDevice = aVCaptureDevice
            }
        })
        
        if videoInputDevice?.isTorchAvailable ?? false {
            do {
                try videoInputDevice?.lockForConfiguration()
                videoInputDevice?.torchMode = .off
                videoInputDevice?.unlockForConfiguration()
            } catch {
                
            }
        }
        ///input
        if let curVideoInputDevice = videoInputDevice {
            if let videoInput = try? AVCaptureDeviceInput(device: curVideoInputDevice) {
                if aVCaptureSession.canAddInput(videoInput) {
                    aVCaptureSession.addInput(videoInput)
                }
            }
        }
        aVCaptureSession.outputs.forEach { (output) in
            aVCaptureSession.removeOutput(output)
        }
        //output
        let videoOutPut =  AVCaptureVideoDataOutput()
        videoOutPut.setSampleBufferDelegate(self, queue: DispatchQueue.main)
        if aVCaptureSession.canAddOutput(videoOutPut) {
            aVCaptureSession.addOutput(videoOutPut)
            //如果没有相机权限，执行如下会闪退 videoOutPut.connection(withMediaType: AVMediaTypeVideo).videoOrientation = .portrait
            let outPutAVCaptureConnection = videoOutPut.connection(with: AVMediaType.video)
            outPutAVCaptureConnection?.videoOrientation = .portrait
        }
        let aVCaptureVideoPreviewLayer  = AVCaptureVideoPreviewLayer(session: aVCaptureSession)
        aVCaptureVideoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.encodeView.layer.addSublayer(aVCaptureVideoPreviewLayer)
        aVCaptureVideoPreviewLayer.frame = self.encodeView.bounds
        
        if !aVCaptureSession.isRunning {
            aVCaptureSession.startRunning()
        }
        
        vTCompressionH264.width = 480
        vTCompressionH264.height = 640
        vTCompressionH264.fps = 10
        vTCompressionH264.delegate = self
        vTCompressionH264.prepareToEncodeFrames()
    }
    
    func stopEncode(){
        if  let aVCaptureVideoPreviewLayer = self.encodeView.layer.sublayers?[0] as? AVCaptureVideoPreviewLayer{
            aVCaptureVideoPreviewLayer.session?.stopRunning()
        }
        vTCompressionH264.invalidate()
    }
}

extension ViewController:VTCompressionH264EncodeDelegate{
    func dataCallBack(_ data: Data!, frameType: FrameType) {
        let byteHeader:[UInt8] = [0,0,0,1]
        var byteHeaderData = Data(byteHeader)
        byteHeaderData.append(data)
        vTCompressionH264Decode.decode(byteHeaderData)
    }
    
    func spsppsDataCallBack(_ sps: Data!, pps: Data!) {
        let spsbyteHeader:[UInt8] = [0,0,0,1]
        var spsbyteHeaderData = Data(spsbyteHeader)
        var ppsbyteHeaderData = Data(spsbyteHeader)
        spsbyteHeaderData.append(sps)
        ppsbyteHeaderData.append(pps)
        vTCompressionH264Decode.decode(spsbyteHeaderData)
        vTCompressionH264Decode.decode(ppsbyteHeaderData)
    }
}

extension ViewController:VTCompressionH264DecodeDelegate{
    func imageBufferCallBack(_ imageBuffer: CVImageBuffer) {
        aAPLEAGLLayer.pixelBuffer = imageBuffer
    }
}

extension ViewController:AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureFileOutputRecordingDelegate{
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        vTCompressionH264.encode(by: sampleBuffer)
    }
}
