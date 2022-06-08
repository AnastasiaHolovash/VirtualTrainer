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

    private let clock = CMClockGetHostTimeClock()

    private var url: URL?
    private var completion: ((URL) -> Void)?

    var assetWriter: AVAssetWriter?
    var assetWriterInput: AVAssetWriterInput?
    var assetWriterAdaptor: AVAssetWriterInputPixelBufferAdaptor?

    var isRecording: Bool = false

    func getVideoTransform() -> CGAffineTransform {
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
            let time = CMClockGetTime(clock)
            assetWriterAdaptor.append(pixelBuffer, withPresentationTime: time)
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
            guard let self = self, let url = self.url else {
                return
            }
            self.completion?(url)
        }
    }

}
