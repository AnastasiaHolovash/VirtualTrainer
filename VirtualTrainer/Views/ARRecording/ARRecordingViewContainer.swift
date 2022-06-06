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
            comparisonFrameValue: $comparisonFrameValue
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
        @Binding var isTrainingInProgress: Bool

        /// True if recording training/exercise data is started
        var isRecording: Bool = false
        var exerciseFrames: Frames = []

        init(
            jointModelTransforms: Binding<[simd_float4x4]>,
            isRecording: Binding<Bool>,
            recordingData: Binding<RecordingData>,
            comparisonFrameValue: Binding<Frame>
        ) {
            _jointModelTransformsCurrent = jointModelTransforms
            _isTrainingInProgress = isRecording
            _recordingData = recordingData
            _comparisonFrameValue = comparisonFrameValue

            super.init()
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

                }
                if !isTrainingInProgress && isRecording {
                    print("--- STOP Recording ---")
                    isRecording.toggle()

                    cropOneIteration()
                    exerciseFrames = []
                }

            }
        }

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
