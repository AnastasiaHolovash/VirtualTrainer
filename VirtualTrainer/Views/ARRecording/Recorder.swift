//
//  Test3.swift
//  VirtualTrainer
//
//  Created by Anastasia Holovash on 07.06.2022.
//

import Foundation
import CoreImage
import AVFoundation
import UIKit

class Recorder {

//    var frameRate: Int
    private let clock = CMClockGetHostTimeClock()

    private var url: URL?
    private var completion: ((URL) -> Void)?

    var assetWriter: AVAssetWriter?
    var assetWriterInput: AVAssetWriterInput?
    var assetWriterAdaptor: AVAssetWriterInputPixelBufferAdaptor?

    var isRecording: Bool = false

    func getVideoTransform() -> CGAffineTransform {
//        UIDevice.current.userInterfaceIdiom
        switch UIDevice.current.orientation {
        case .portrait:
            return CGAffineTransform(rotationAngle: .pi/2)
        case .portraitUpsideDown:
            return CGAffineTransform(rotationAngle: -.pi/2)
        case .landscapeLeft:
            return .identity
        case .landscapeRight:
            return CGAffineTransform(rotationAngle: .pi)
        default:
            return .identity
        }
    }

    func setup(completion: @escaping (URL) -> Void) {
        guard
            let outputMovieURL = FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
            ).first?.appendingPathComponent("test.mov")
        else {
            return
        }
        self.url = outputMovieURL
        self.completion = completion

        //delete any old file
        do {
            try FileManager.default.removeItem(at: outputMovieURL)
        } catch {
            print("Could not remove file \(error.localizedDescription)")
        }

        //create an assetwrite instance
        guard let assetWriter = try? AVAssetWriter(outputURL: outputMovieURL, fileType: .mov) else {
            abort()
        }

        //generate 1080p settings
        var settingsAssistant = AVOutputSettingsAssistant(preset: .preset1920x1080)?.videoSettings
        settingsAssistant?["AVVideoHeightKey"] = Int64(1440)
        settingsAssistant?["AVVideoWidthKey"] = Int64(1920)

        //create a single video input
        let assetWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: settingsAssistant)

        assetWriterInput.transform = CGAffineTransform(rotationAngle: .pi / 2)

        //create an adaptor for the pixel buffer
        let assetWriterAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: assetWriterInput, sourcePixelBufferAttributes: nil)

        //add the input to the asset writer
        assetWriter.add(assetWriterInput)

        self.assetWriter = assetWriter
        self.assetWriterInput = assetWriterInput
        self.assetWriterAdaptor = assetWriterAdaptor
    }

    func start() {
        guard let assetWriter = assetWriter else {
            return
        }
        assetWriter.startWriting()
        assetWriter.startSession(atSourceTime: CMClockGetTime(clock))

//        assetWriter.startSession(atSourceTime: CMTime.zero)
        isRecording = true
    }

    func render(pixelBuffer: CVPixelBuffer) {

        guard
            let assetWriterInput = assetWriterInput,
            let assetWriterAdaptor = assetWriterAdaptor
        else {
            return
        }

        if assetWriterInput.isReadyForMoreMediaData {
//            capture(pixelBuffer: frame.capturedImage, at: time)

//            guard assetWriterInput.isReadyForMoreMediaData else { return }

//            let _ =
            let time = CMClockGetTime(clock)
            assetWriterAdaptor.append(pixelBuffer, withPresentationTime: time)
//            let frameTime = CMTimeMake(value: Int64(frameCount), timescale: Int32(frameRate))
            //append the contents of the pixelBuffer at the correct ime
//            assetWriterAdaptor.append(pixelBuffer, withPresentationTime: frameTime)
            frameCount += 1
        }
    }

    func stop() {

        guard
            let assetWriterInput = assetWriterInput,
            let assetWriter = assetWriter
        else {
            return
        }

        assetWriterInput.markAsFinished()
        isRecording = false
        assetWriter.finishWriting { [weak self] in
    //        pixelBuffer = nil
            //outputMovieURL now has the video
//            print("outputMovieURL")
            guard let self = self, let url = self.url else {
                return
            }
            self.completion?(url)
    //        Logger().info("Finished video location: \(outputMovieURL)")
        }
    }

}


func test() throws {

    guard let outputMovieURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("test.mov") else {
        throw NSError()
    }

    //delete any old file
    do {
        try FileManager.default.removeItem(at: outputMovieURL)
    } catch {
        print("Could not remove file \(error.localizedDescription)")
    }

    //create an assetwrite instance
    guard let assetWriter = try? AVAssetWriter(outputURL: outputMovieURL, fileType: .mov) else {
        abort()
    }

    //generate 1080p settings
    var settingsAssistant = AVOutputSettingsAssistant(preset: .preset1920x1080)?.videoSettings
//    print("!!!! settingsAssistant \(settingsAssistant)")
//    settingsAssistant?["AVVideoHeightKey"] = 1920
//    settingsAssistant?["AVVideoWidthKey"] = 1080

//    "AVVideoHeightKey": 2160,
//    "AVVideoWidthKey": 3840

    let some = AVOutputSettingsAssistant(preset: .preset1920x1080)?.videoSettings
    //create a single video input
    let assetWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: settingsAssistant)

//    AVAssetWriter.init(url: <#T##URL#>, fileType: .mp)
    //create an adaptor for the pixel buffer
    let assetWriterAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: assetWriterInput, sourcePixelBufferAttributes: nil)

    //add the input to the asset writer
    assetWriter.add(assetWriterInput)

    //begin the session
    assetWriter.startWriting()
    assetWriter.startSession(atSourceTime: CMTime.zero)

    //determine how many frames we need to generate


    //close everything
    assetWriterInput.markAsFinished()
    assetWriter.finishWriting {
//        pixelBuffer = nil
        //outputMovieURL now has the video
        print("outputMovieURL")
//        completion(outputMovieURL)
//        Logger().info("Finished video location: \(outputMovieURL)")
    }

    func render(pixelBuffer: CVPixelBuffer) {

        let framesPerSecond = 30
//        let totalFrames = duration * framesPerSecond
//
//        while frameCount < totalFrames {
//
//        }
        if assetWriterInput.isReadyForMoreMediaData {
            let frameTime = CMTimeMake(value: Int64(frameCount), timescale: Int32(framesPerSecond))
            //append the contents of the pixelBuffer at the correct ime
            assetWriterAdaptor.append(pixelBuffer, withPresentationTime: frameTime)
            frameCount+=1
        }
    }

}

var frameCount = 0
