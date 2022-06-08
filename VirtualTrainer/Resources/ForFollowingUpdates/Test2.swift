////
////  Test2.swift
////  VirtualTrainer
////
////  Created by Anastasia Holovash on 07.06.2022.
////
//
//import CoreImage
//import AVFoundation
////https://stackoverflow.com/questions/69714369/avassetwriter-video-output-does-not-play-appended-audio
//func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
//
//    let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds
//
//    if output == _videoOutput {
//        if connection.isVideoOrientationSupported { connection.videoOrientation = .portrait }
//
//        guard let cvImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
//        let ciImage = CIImage(cvImageBuffer: cvImageBuffer)
//
//        guard let filteredCIImage = applyFilters(inputImage: ciImage) else { return }
//        self.ciImage = filteredCIImage
//
//        guard let cvPixelBuffer = getCVPixelBuffer(from: filteredCIImage) else { return }
//        self.cvPixelBuffer = cvPixelBuffer
//
//        self.ciContext.render(filteredCIImage, to: cvPixelBuffer, bounds: filteredCIImage.extent, colorSpace: CGColorSpaceCreateDeviceRGB())
//
//        metalView.draw()
//    }
//
//    switch _captureState {
//    case .start:
//
////        let urls = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
////        guard let documentDirectory: NSURL = urls.first else {
////            fatalError("documentDir Error")
////        }
////
////        let videoOutputURL = documentDirectory.URLByAppendingPathComponent("OutputVideo.mp4")
//
//
//        guard let outputUrl = tempURL else { return }
//
//        let writer = try! AVAssetWriter(outputURL: outputUrl, fileType: .mp4)
//
//        let videoSettings = _videoOutput!.recommendedVideoSettingsForAssetWriter(writingTo: .mp4)
//        let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
//        videoInput.mediaTimeScale = CMTimeScale(bitPattern: 600)
//        videoInput.expectsMediaDataInRealTime = true
//
//        let pixelBufferAttributes = [
//            kCVPixelBufferCGImageCompatibilityKey: NSNumber(value: true),
//            kCVPixelBufferCGBitmapContextCompatibilityKey: NSNumber(value: true),
//            kCVPixelBufferPixelFormatTypeKey: NSNumber(value: Int32(kCVPixelFormatType_32ARGB))
//        ] as [String:Any]
//
//        let adapter = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoInput, sourcePixelBufferAttributes: pixelBufferAttributes)
//        if writer.canAdd(videoInput) { writer.add(videoInput) }
//
////        let audioSettings = _audioOutput!.recommendedAudioSettingsForAssetWriter(writingTo: .mp4) as? [String:Any]
////        let audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
////        audioInput.expectsMediaDataInRealTime = true
////        if writer.canAdd(audioInput) { writer.add(audioInput) }
//
//        _filename = outputUrl.absoluteString
//        _assetWriter = writer
//        _assetWriterVideoInput = videoInput
//        _assetWriterAudioInput = audioInput
//        _adapter = adapter
//        _captureState = .capturing
//        _time = timestamp
//
//        writer.startWriting()
//        writer.startSession(atSourceTime: .zero)
//
//    case .capturing:
//
//        if output == _videoOutput {
//            if _assetWriterVideoInput?.isReadyForMoreMediaData == true {
//                let time = CMTime(seconds: timestamp - _time, preferredTimescale: CMTimeScale(600))
//                _adapter?.append(self.cvPixelBuffer, withPresentationTime: time)
//            }
//        } else if output == _audioOutput {
//            if _assetWriterAudioInput?.isReadyForMoreMediaData == true {
//                _assetWriterAudioInput?.append(sampleBuffer)
//            }
//        }
//        break
//
//    case .end:
//
//        guard _assetWriterVideoInput?.isReadyForMoreMediaData == true, _assetWriter!.status != .failed else { break }
//
//        _assetWriterVideoInput?.markAsFinished()
//        _assetWriterAudioInput?.markAsFinished()
//        _assetWriter?.finishWriting { [weak self] in
//
//            guard let output = self?._assetWriter?.outputURL else { return }
//
//            self?._captureState = .idle
//            self?._assetWriter = nil
//            self?._assetWriterVideoInput = nil
//            self?._assetWriterAudioInput = nil
//
//
//            self?.previewRecordedVideo(with: output)
//        }
//
//    default:
//        break
//    }
//}
