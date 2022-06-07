//
//  Test.swift
//  VirtualTrainer
//
//  Created by Anastasia Holovash on 07.06.2022.
//

import UIKit
import AVFoundation
import Photos

class ViewControllerTest: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    private let recordingClipQueue = DispatchQueue(label: "com.example.recordingClipQueue")
    private let videoDataOutputQueue = DispatchQueue(label: "com.example.videoDataOutputQueue")
    private let session = AVCaptureSession()
    private var backfillSampleBufferList = [CMSampleBuffer]()

    override func viewDidLoad() {
        super.viewDidLoad()

        session.sessionPreset = AVCaptureSession.Preset.vga640x480

        let videoDevice = AVCaptureDevice.default(for: .video)
        let videoDeviceInput: AVCaptureDeviceInput;

        do {
            videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice!)
        } catch {
            print("Error creating device input from video device: \(error).")
            return
        }

        guard session.canAddInput(videoDeviceInput) else {
            print("Could not add video device input to capture session.")
            return
        }

        session.addInput(videoDeviceInput)

        let videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String : Int(kCMPixelFormat_32BGRA) ]
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)

        guard session.canAddOutput(videoDataOutput) else {
            print("Could not add video data output to capture session.")
            return
        }

        session.addOutput(videoDataOutput)
        videoDataOutput.connection(with: AVMediaType.video)?.isEnabled = true

        session.startRunning()
    }

    private func backfillSizeInSeconds() -> Double {
        if backfillSampleBufferList.count < 1 {
            return 0.0
        }

        let earliestSampleBuffer = backfillSampleBufferList.first!
        let latestSampleBuffer = backfillSampleBufferList.last!

        let earliestSampleBufferPTS = CMSampleBufferGetOutputPresentationTimeStamp(earliestSampleBuffer).value
        let latestSampleBufferPTS = CMSampleBufferGetOutputPresentationTimeStamp(latestSampleBuffer).value
        let timescale = CMSampleBufferGetOutputPresentationTimeStamp(latestSampleBuffer).timescale

        return Double(latestSampleBufferPTS - earliestSampleBufferPTS) / Double(timescale)
    }

    private func createClipFromBackfill() {
        guard backfillSampleBufferList.count > 0 else {
            print("createClipFromBackfill() called before any samples were recorded.")
            return
        }

        let clipURL = URL(fileURLWithPath:
            NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] +
            "/recorded_clip.mp4")

        if FileManager.default.fileExists(atPath: clipURL.path) {
            do {
                try FileManager.default.removeItem(atPath: clipURL.path)
            } catch {
                print("Could not delete existing clip file: \(error).")
            }
        }

        var _videoFileWriter: AVAssetWriter?
        do {
            _videoFileWriter = try AVAssetWriter(url: clipURL, fileType: AVFileType.mp4)
        } catch {
            print("Could not create video file writer: \(error).")
            return
        }

        guard let videoFileWriter = _videoFileWriter else {
            print("Video writer was nil.")
            return
        }

        let settingsAssistant = AVOutputSettingsAssistant(preset: AVOutputSettingsPreset.preset640x480)!

        guard videoFileWriter.canApply(outputSettings: settingsAssistant.videoSettings, forMediaType: AVMediaType.video) else {
            print("Video file writer could not apply video output settings.")
            return
        }

        let earliestRecordedSampleBuffer = backfillSampleBufferList.first!

        let _formatDescription = CMSampleBufferGetFormatDescription(earliestRecordedSampleBuffer)
        guard let formatDescription = _formatDescription else {
            print("Earliest recording pixel buffer format description was nil.")
            return
        }

        let videoWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video,
                                                  outputSettings: settingsAssistant.videoSettings,
                                                  sourceFormatHint: formatDescription)

        guard videoFileWriter.canAdd(videoWriterInput) else {
            print("Could not add video writer input to video file writer.")
            return
        }

        videoFileWriter.add(videoWriterInput)

        let pixelAdapterBufferAttributes = [ kCVPixelBufferPixelFormatTypeKey as String : Int(kCMPixelFormat_32BGRA) ]
        let pixelAdapter = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoWriterInput,
                                                                sourcePixelBufferAttributes: pixelAdapterBufferAttributes)

        guard videoFileWriter.startWriting() else {
            print("Video file writer not ready to write file.")
            return
        }

        videoFileWriter.startSession(atSourceTime: CMSampleBufferGetOutputPresentationTimeStamp(earliestRecordedSampleBuffer))

        videoWriterInput.requestMediaDataWhenReady(on: recordingClipQueue) {
            while videoWriterInput.isReadyForMoreMediaData {
                if self.backfillSampleBufferList.count > 0 {
                    let sampleBufferToAppend = self.backfillSampleBufferList.first!.deepCopy()
                    let appendSampleBufferSucceeded = pixelAdapter.append(CMSampleBufferGetImageBuffer(sampleBufferToAppend)!,
                                                                          withPresentationTime: CMSampleBufferGetOutputPresentationTimeStamp(sampleBufferToAppend))
                    if !appendSampleBufferSucceeded {
                        print("Failed to append sample buffer to asset writer input: \(videoFileWriter.error!)")
                        print("Video file writer status: \(videoFileWriter.status.rawValue)")
                    }

                    self.backfillSampleBufferList.remove(at: 0)
                } else {
                    videoWriterInput.markAsFinished()
                    videoFileWriter.finishWriting {
                        print("Saving clip to \(clipURL)")
                    }

                    break
                }
            }
        }
    }

    func captureOutput(_ captureOutput: AVCaptureOutput!,
                       didOutputSampleBuffer sampleBuffer: CMSampleBuffer!,
                       from connection: AVCaptureConnection!) {
        guard let buffer = sampleBuffer else {
            print("Captured sample buffer was nil.")
            return
        }
//        sampleBuffer.imageBuffer

        let sampleBufferCopy = buffer.deepCopy()

        backfillSampleBufferList.append(sampleBufferCopy)

        if backfillSizeInSeconds() > 3.0 {
            session.stopRunning()
            createClipFromBackfill()
        }
    }

    func captureOutput(_ captureOutput: AVCaptureOutput,
                       didDrop sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        print("Sample buffer dropped.")
    }

}


import CoreMedia
extension CMSampleBuffer {
    func deepCopy() -> CMSampleBuffer {
        let _pixelBuffer = CMSampleBufferGetImageBuffer(self)
        guard let pixelBuffer = _pixelBuffer else {
            print("Pixel buffer to copy was nil.")
            fatalError()
        }
        let pixelBufferCopy = pixelBuffer.deepCopy()

        let _formatDescription = CMSampleBufferGetFormatDescription(self)
        guard let formatDescription = _formatDescription else {
            print("Format description to copy was nil.")
            fatalError()
        }

        var timingInfo = CMSampleTimingInfo.invalid
        let getTimingInfoResult = CMSampleBufferGetSampleTimingInfo(self, at: 0, timingInfoOut: &timingInfo)
        guard getTimingInfoResult == noErr else {
            print("Could not get timing info to copy: \(getTimingInfoResult).")
            fatalError()
        }

        timingInfo.presentationTimeStamp = CMSampleBufferGetOutputPresentationTimeStamp(self)

        var _copy : CMSampleBuffer?
        let createCopyResult = CMSampleBufferCreateForImageBuffer(allocator: kCFAllocatorDefault,
                                                                  imageBuffer: pixelBufferCopy,
                                                                  dataReady: true,
                                                                  makeDataReadyCallback: nil,
                                                                  refcon: nil,
                                                                  formatDescription: formatDescription,
                                                                  sampleTiming: &timingInfo,
                                                                  sampleBufferOut: &_copy);

        guard createCopyResult == noErr else {
            print("Error creating copy of sample buffer: \(createCopyResult).")
            fatalError()
        }

        guard let copy = _copy else {
            print("Copied sample buffer was nil.")
            fatalError()
        }

        return copy
    }
}

import CoreVideo
extension CVPixelBuffer {
    func deepCopy() -> CVPixelBuffer {
        precondition(CFGetTypeID(self) == CVPixelBufferGetTypeID(), "deepCopy() cannot copy a non-CVPixelBuffer")

        var _copy : CVPixelBuffer?
        CVPixelBufferCreate(
            nil,
            CVPixelBufferGetWidth(self),
            CVPixelBufferGetHeight(self),
            CVPixelBufferGetPixelFormatType(self),
            CVBufferGetAttachments(self, CVAttachmentMode.shouldPropagate),
            &_copy)

        guard let copy = _copy else {
            print("Pixel buffer copy was nil.")
            fatalError()
        }

        CVBufferPropagateAttachments(self, copy)
        CVPixelBufferLockBaseAddress(self, CVPixelBufferLockFlags.readOnly)
        CVPixelBufferLockBaseAddress(copy, CVPixelBufferLockFlags(rawValue: 0))

        let sourceBaseAddress = CVPixelBufferGetBaseAddress(self)
        let copyBaseAddress = CVPixelBufferGetBaseAddress(copy)
        memcpy(copyBaseAddress, sourceBaseAddress, CVPixelBufferGetHeight(self) * CVPixelBufferGetBytesPerRow(self))
        CVPixelBufferUnlockBaseAddress(copy, CVPixelBufferLockFlags(rawValue: 0))
        CVPixelBufferUnlockBaseAddress(self, CVPixelBufferLockFlags.readOnly)

        return copy
    }
}
