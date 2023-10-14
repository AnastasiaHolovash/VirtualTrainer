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

    @Binding var exercise: NewExercise
    @Binding var isRecording: Bool
    @Binding var recordingData: RecordingData

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: true)
        arView.session.delegate = context.coordinator

        let configuration = ARBodyTrackingConfiguration()
        arView.session.run(configuration)

        return arView
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            exercise: $exercise,
            isRecording: $isRecording,
            recordingData: $recordingData
        )
    }

    func updateUIView(_ uiView: ARView, context: Context) {

    }

    // MARK: - Coordinator

    class Coordinator: NSObject, ARSessionDelegate {
        private var jointModelTransformsCurrent: Frame = []
        private var comparisonFrameValue: Frame = []

        @Binding var recordingData: RecordingData
        /// True if timer is out
        @Binding var isTrainingInProgress: Bool {
            willSet {
                if isTrainingInProgress {
                    recorder.start()
                }
            }
        }

        @Binding var exercise: NewExercise

        /// True if recording exercise data is started
        private var isRecording: Bool = false
        private var exerciseFrames: Frames = []
        private let recorder = Recorder()

        init(
            exercise: Binding<NewExercise>,
            isRecording: Binding<Bool>,
            recordingData: Binding<RecordingData>
        ) {
            _exercise = exercise
            _isTrainingInProgress = isRecording
            _recordingData = recordingData

            super.init()

            recorder.setup { [weak self] url in
                self?.exercise.localVideoURL = url
            }
        }

        // MARK: - Delegate method

        private let trackingJointNamesRawValues: [Int] = {
            GlobalConstants.trackingJointNames.map { $0.rawValue }
        }()

        private var wasRecorded = false

        func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
            for anchor in anchors {
                guard let bodyAnchor = anchor as? ARBodyAnchor else { continue }

                let transforms = bodyAnchor.skeleton.jointModelTransforms
                jointModelTransformsCurrent = trackingJointNamesRawValues.map { transforms[$0] }

                print("Right hand joint: \n")
                jointModelTransformsCurrent.last?.printf()

                if isTrainingInProgress && !isRecording {
                    print("\n----- Check If STARTED -----")
                    _ = self.checkIfExerciseStarted()
                }

                if isTrainingInProgress && isRecording {
                    wasRecorded = true
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
            print("---- Compare ---- \(resultValue)% ----- \(result) --- \(comparisonFrameValue)")
//            jointModelTransformsCurrent.newValue(arraySimd4x4: comparisonFrameValue)
            
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
//                if let newPreviousChecked = exerciseFrames.reversed()[safe: index - 1] {
//                    previousChecked = newPreviousChecked
//                } else {
////                    assertionFailure("Something wrong with index")
//                    return false
//                }
                let resultValue = frame.compare(to: previous)
                let result = resultValue.isStartStopMovement

                print("\n---- Compare ---- \(resultValue)% ----- \(result)")
//                frame.newValue(arraySimd4x4: previous)

                return result
            } ?? (exerciseFrames.count - 1, exerciseFrames.last)

            let lastFrameIndex = frameIndex > 1 ? exerciseFrames.count - (frameIndex - 1) : exerciseFrames.count - 1
            let croppedFrames: Frames = Array(exerciseFrames[0...lastFrameIndex])

            print("Size: \(croppedFrames.count)")

            // Saving new frames to model
            exercise.frames = croppedFrames
        }
    }

}

extension Collection {

    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
