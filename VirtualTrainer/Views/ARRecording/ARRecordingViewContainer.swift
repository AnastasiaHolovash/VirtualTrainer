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

struct ARRecordingViewContainer: UIViewRepresentable {

    @ObservedObject var arRecordingViewModel: ARRecordingViewModel

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: true)
        arView.session.delegate = context.coordinator

        let configuration = ARBodyTrackingConfiguration()
        arView.session.run(configuration)

        return arView
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(arRecordingViewModel: arRecordingViewModel)
    }

    func updateUIView(_ uiView: ARView, context: Context) {

    }

    // MARK: - Coordinator

    class Coordinator: NSObject, ARSessionDelegate {

        @ObservedObject var arRecordingViewModel: ARRecordingViewModel
        private let recorder = Recorder()

        private var isRecording: Bool = false
        private var isTrainingInProgress: Bool {
            willSet {
                arRecordingViewModel.isTrainingInProgress = isTrainingInProgress
                if isTrainingInProgress {
                    recorder.start()
                }
            }
        }
        private let trackingJointNamesRawValues: [Int] = {
            GlobalConstants.trackingJointNames.map { $0.rawValue }
        }()


        private var jointModelTransformsCurrent: Frame = []
        private var comparisonFrameValue: Frame = []
        private var exerciseFrames: Frames = []


        init(arRecordingViewModel: ARRecordingViewModel) {
            self.isTrainingInProgress = arRecordingViewModel.isTrainingInProgress
            self.arRecordingViewModel = arRecordingViewModel
            
            super.init()

            recorder.setup { [weak self] url in
                self?.arRecordingViewModel.exercise.localVideoURL = url
            }
        }

        // MARK: - Delegate method

        func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
            for anchor in anchors {
                guard let bodyAnchor = anchor as? ARBodyAnchor else { continue }

                let transforms = bodyAnchor.skeleton.jointModelTransforms
                jointModelTransformsCurrent = trackingJointNamesRawValues.map { transforms[$0] }

                if isTrainingInProgress && !isRecording {
                    print("\n----- Check If STARTED -----")
                    _ = self.checkIfExerciseStarted()
                }

                if isTrainingInProgress && isRecording {
                    exerciseFrames.append(jointModelTransformsCurrent)
                    print(exerciseFrames.count)

                    if let capturedImage = session.currentFrame?.capturedImage {
                        if !recorder.isRecording {
                            recorder.start()
                        }
                        recorder.render(pixelBuffer: capturedImage)
                    }
                }

                /// STOP Recording
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

        // MARK: - Check If Started

        private func checkIfExerciseStarted() -> Bool {
            guard !comparisonFrameValue.isEmpty else {
                comparisonFrameValue = jointModelTransformsCurrent
                return false
            }

            let resultValue = jointModelTransformsCurrent.compare(to: comparisonFrameValue)

            let result = resultValue.isStartStopMovement
            
            if result {
                exerciseFrames = [comparisonFrameValue]
            }

            isRecording = result

            return result
        }

        // MARK: - Сropp Recorded Data

        private func cropOneIteration() {
            let previousChecked = exerciseFrames.last
            let (frameIndex, _) = exerciseFrames.reversed().enumerated().first { index, frame in
                guard index < exerciseFrames.count - 1,
                      let previous = previousChecked
                else {
                    return false
                }
                print("index", index)

                let resultValue = frame.compare(to: previous)
                let result = resultValue.isStartStopMovement

                print("\n---- Compare ---- \(resultValue)% ----- \(result)")

                return result
            } ?? (exerciseFrames.count - 1, exerciseFrames.last)

            let lastFrameIndex = frameIndex > 1 ? exerciseFrames.count - (frameIndex - 1) : exerciseFrames.count - 1
            let croppedFrames: Frames = Array(exerciseFrames[0...lastFrameIndex])

            print("Size: \(croppedFrames.count)")
            let smoothedData = applyExponentialSmoothing(frames: croppedFrames)

            // Saving new frames to model
            arRecordingViewModel.exercise.frames = smoothedData
        }
    }

}

extension Collection {

    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }

}
