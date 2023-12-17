//
//  ARTrackingViewContainer.swift
//  VirtualTrainer
//
//  Created by Anastasia Holovash on 06.06.2022.
//

import SwiftUI
import RealityKit
import ARKit
import Combine

struct ARTrackingViewContainer: UIViewRepresentable {

    var exercise: Exercise
    @Binding var isRecording: Bool
    @Binding var currentResults: CurrentResults
    @Binding var iterations: [IterationResults]

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(
            frame: .zero,
            cameraMode: .ar,
            automaticallyConfigureSession: true
        )
        arView.session.delegate = context.coordinator

        let configuration = ARBodyTrackingConfiguration()
        arView.session.run(configuration)

        return arView
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            exercise: exercise,
            isRecording: $isRecording,
            currentResults: $currentResults,
            iterations: $iterations
        )
    }

    func updateUIView(_ uiView: ARView, context: Context) { }

    // MARK: - Coordinator

    class Coordinator: NSObject, ARSessionDelegate {

        @Binding var currentResults: CurrentResults

        /// True if timer is out
        @Binding var isTrainingInProgress: Bool
        @Binding var iterations: [IterationResults]

        /// True if recording training/exercise data is started
        private var isRecording: Bool = false
        @ObservedObject var timerObject = TimerObject()
        private let arDataProcessor: ARTrackingDataProcessor

        private let trackingJointNamesRawValues: [Int] = {
            GlobalConstants.trackingJointNames.map { $0.rawValue }
        }()

        init(
            exercise: Exercise,
            isRecording: Binding<Bool>,
            currentResults: Binding<CurrentResults>,
            iterations: Binding<[IterationResults]>
        ) {
            _isTrainingInProgress = isRecording
            _currentResults = currentResults
            _iterations = iterations

            arDataProcessor = ARTrackingDataProcessor(exercise: exercise)

            super.init()
        }

        // MARK: - Delegate method

        func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
            for anchor in anchors {
                guard let bodyAnchor = anchor as? ARBodyAnchor else { continue }

                let transforms = bodyAnchor.skeleton.jointModelTransforms
                let jointModelTransformsCurrent = trackingJointNamesRawValues.map {  transforms[$0] }

                if isTrainingInProgress && !isRecording {
                    isRecording = arDataProcessor.checkIfExerciseStarted(currentFrame: jointModelTransformsCurrent)
                    if isRecording {
                        timerObject.start()
                    }
                }

                if isTrainingInProgress && isRecording {
                    compareTrainingWithTarget(currentFrame: jointModelTransformsCurrent)
                }

                if !isTrainingInProgress && isRecording {
                    isRecording.toggle()
                }
            }
        }

        private func compareTrainingWithTarget(currentFrame: Frame) {
            if arDataProcessor.couldDetectEndOfIteration {
                arDataProcessor.detectEndOfIteration(currentFrame: currentFrame)
            }

            if arDataProcessor.couldDetectStartOfIteration {
                let previousShouldBeRecorded = arDataProcessor.detectIfNextIterationStarted(currentFrame: currentFrame)
                isRecording = false
                timerObject.stop()
                if let iterationResults = arDataProcessor.updateCurrentResults(
                    shouldBeRecorded: previousShouldBeRecorded,
                    iterationDuration: timerObject.elapsedSeconds
                ) {
                    iterations.append(iterationResults)
                    currentResults.update(with: iterationResults)
                }
            } else {
                arDataProcessor.recordingResults(currentFrame: currentFrame)
            }
        }
    }

}
