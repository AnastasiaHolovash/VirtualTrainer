//
//  ARRecordingViewContainer.swift
//  VirtualTrainer
//
//  Created by Anastasia Holovash on 07.06.2022.
//

import SwiftUI
import RealityKit
import ARKit
import Combine
import Vision

struct ARViewContainer: UIViewRepresentable {

    @Binding var jointModelTransforms: Frame
    @Binding var isRecording: Bool
    @Binding var recordingData: RecordingData
    @Binding var comparisonFrameValue: Frame
    @Binding var isReviewing: Bool

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: true)
        arView.session.delegate = context.coordinator

        let configuration = ARBodyTrackingConfiguration()
        arView.session.run(configuration)
        arView.scene.addAnchor(context.coordinator.characterAnchor)

        return arView
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            jointModelTransforms: $jointModelTransforms,
            isRecording: $isRecording,
            recordingData: $recordingData,
            comparisonFrameValue: $comparisonFrameValue,
            isReviewing: $isReviewing
        )
    }

    func updateUIView(_ uiView: ARView, context: Context) {

    }

    // MARK: - Coordinator

    class Coordinator: NSObject, ARSessionDelegate {
        let characterAnchor = AnchorEntity()

        @Binding var jointModelTransformsCurrent: Frame
        @Binding var recordingData: RecordingData
        @Binding var comparisonFrameValue: Frame
        /// True if timer is out
        @Binding var isTrainingInProgress: Bool {
            willSet {
                if isTrainingInProgress {
                    recorder.start()
                }
            }
        }

        @Binding var isReviewing: Bool

        /// True if recording training/exercise data is started
        var isRecording: Bool = false
        var exerciseFrames: Frames = []

        let recorder = Recorder()

        init(
            jointModelTransforms: Binding<[simd_float4x4]>,
            isRecording: Binding<Bool>,
            recordingData: Binding<RecordingData>,
            comparisonFrameValue: Binding<Frame>,
            isReviewing: Binding<Bool>
        ) {
            _jointModelTransformsCurrent = jointModelTransforms
            _isTrainingInProgress = isRecording
            _recordingData = recordingData
            _comparisonFrameValue = comparisonFrameValue
            _isReviewing = isReviewing

            super.init()

            recorder.setup { url in
                self.isReviewing = true
//                print("!!!!!!!!! RECORDER")
            }
        }

        // MARK: - Delegate method

        let trackingJointNamesRawValues: [Int] = {
            GlobalConstants.trackingJointNames.map { $0.rawValue }
        }()

        var wasRecorded = false

        func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
            for anchor in anchors {
                guard let bodyAnchor = anchor as? ARBodyAnchor else { continue }

                let transforms = bodyAnchor.skeleton.jointModelTransforms
                jointModelTransformsCurrent = trackingJointNamesRawValues.map {  transforms[$0] }

                if isTrainingInProgress && !isRecording {
                    print("\n***** Check If STARTED *****")
                    _ = self.checkIfExerciseStarted()
                }

                if isTrainingInProgress && isRecording {
                    wasRecorded = true
                    exerciseFrames.append(jointModelTransformsCurrent)
                    print(exerciseFrames.count)

                    if let capturedImage = session.currentFrame?.capturedImage {
                        if !recorder.isRecording {
                            let ciImage = CIImage(cvPixelBuffer: capturedImage)
                            ciImage.transformed(by: CGAffineTransform(rotationAngle: .pi / 2))
                            let previewImage = UIImage(ciImage: ciImage)
                            // TODO: save preview
                            recorder.start()
                        }
                        recorder.render(pixelBuffer: capturedImage)
                    }
                }

                if !isTrainingInProgress && isRecording {
                    print("--- STOP Recording ---")
                    isRecording.toggle()

                    cropOneIteration()
                    exerciseFrames = []
                }

                if !isTrainingInProgress && recorder.isRecording {
                    recorder.stop()
                }
            }
        }

//        func writeImage(_ image: CVPixelBuffer, thisTimestamp: TimeInterval) {
//
//                guard let videoDirector = videoWriter else { return }
//
//                serialQueue.async(execute: {
//
//                    let scale = CMTimeScale(NSEC_PER_SEC)
//
//                    if (!self.seenTimestamps.contains(thisTimestamp)) {
//
//                        self.seenTimestamps.append(thisTimestamp)
//                        let pts = CMTime(value: CMTimeValue((thisTimestamp) * Double(scale)),
//                                         timescale: scale)
//                        var timingInfo = CMSampleTimingInfo(duration: kCMTimeInvalid,
//                                                            presentationTimeStamp: pts,
//                                                            decodeTimeStamp: kCMTimeInvalid)
//
//                        var vidInfo:CMVideoFormatDescription! = nil
//                        CMVideoFormatDescriptionCreateForImageBuffer(kCFAllocatorDefault, image, &vidInfo)
//
//                        var sampleBuffer:CMSampleBuffer! = nil
//                        CMSampleBufferCreateForImageBuffer(kCFAllocatorDefault, image, true, nil, nil, vidInfo, &timingInfo, &sampleBuffer)
//
//                        let imageBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
//
//                        if self.videoWriterInput == nil {
//
//                            let width = CVPixelBufferGetWidth(imageBuffer)
//                            let height = CVPixelBufferGetHeight(imageBuffer)
//
//
//                            let numPixels: Double = Double(width * height);
//                            let bitsPerPixel = 11.4;
//                            let bitsPerSecond = Int(numPixels * bitsPerPixel)
//
//                            // add video input
//                            let outputSettings: [String: Any] = [
//                                AVVideoCodecKey : AVVideoCodecType.h264,
//                                AVVideoWidthKey : width,
//                                AVVideoHeightKey : height,
//                                AVVideoCompressionPropertiesKey : [
//                                    AVVideoExpectedSourceFrameRateKey: 30,
//                                    AVVideoAverageBitRateKey : bitsPerSecond,
//                                    AVVideoMaxKeyFrameIntervalKey : 1
//                                ]
//                            ]
//                            self.videoWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: outputSettings)
//                            self.videoWriterInput?.expectsMediaDataInRealTime = true
//                            guard let input = self.videoWriterInput else { return }
//
//                            if videoDirector.canAdd(input) {
//                                videoDirector.add(input)
//                            }
//                            videoDirector.startWriting()
//                        }
//
//                        let writable = self.canWrite()
//                        if writable, self.sessionAtSourceTime == nil {
//                            let timeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
//                            self.sessionAtSourceTime = timeStamp
//                            videoDirector.startSession(atSourceTime: timeStamp)
//                        }
//
//                        if self.videoWriterInput?.isReadyForMoreMediaData == true {
//                            let appendResult = self.videoWriterInput?.append(sampleBuffer)
//                            if appendResult == false {
//                                printDebug("writer status: \(videoDirector.status.rawValue)")
//                                printDebug("writer error: \(videoDirector.error.debugDescription)")
//                            }
//                        }
//                    }
//                })
//            }
//            func canWrite() -> Bool {
//                return isRecording && videoWriter?.status == .writing
//            }

//    }

        // MARK: - Check If Started

        func checkIfExerciseStarted() -> Bool {
            guard !comparisonFrameValue.isEmpty else {
                comparisonFrameValue = jointModelTransformsCurrent
                return false
            }

            let resultValue = jointModelTransformsCurrent.compare(to: comparisonFrameValue)

            let result = resultValue.isStartStopMovement
            print("---- Compare ---- \(resultValue * 100)% ----- \(result)")

            if result {
                exerciseFrames = [comparisonFrameValue]
            }

            isRecording = result

            return result
        }

        /// For exercise recording process
        func cropOneIteration() {
            let previousChecked = exerciseFrames.last
            let (frameIndex, _) = exerciseFrames.reversed().enumerated().first { index, frame in
                guard index < exerciseFrames.count - 1,
                      let previous = previousChecked
                else {
                    return false
                }

                let resultValue = frame.compare(to: previous)
                let result = resultValue.isStartStopMovement

                print("\n---- Compare ---- \(resultValue * 100)% ----- \(result)")

                return result
            } ?? (exerciseFrames.count - 1, exerciseFrames.last)

            let lastFrameIndex = frameIndex > 1 ? exerciseFrames.count - (frameIndex - 1) : exerciseFrames.count - 1
            let croppedFrames: Frames = Array(exerciseFrames[0...lastFrameIndex])

            print("Size: \(croppedFrames.count)")

            recordingData
//            Defaults.shared.setExerciseTargetFrames(croppedFrames)
        }
    }

}
