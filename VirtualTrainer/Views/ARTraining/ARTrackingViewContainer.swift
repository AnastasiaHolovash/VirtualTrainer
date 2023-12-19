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

    // MARK: - Accessible Properties

    @ObservedObject var arTrainingViewModel: ARTrainingViewModel

    // MARK: - Lifecycle

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
        Coordinator(arTrainingViewModel: arTrainingViewModel)
    }

    func updateUIView(_ uiView: ARView, context: Context) { }

    // MARK: - Coordinator

    class Coordinator: NSObject, ARSessionDelegate {

        // MARK: - Accessible Properties

        @ObservedObject var arTrainingViewModel: ARTrainingViewModel

        // MARK: - Private Properties

        private var isRecording: Bool = false
        private var timerObject = TimerObject()
        private let arDataProcessor: ARTrackingDataProcessor
        private let trackingJointNamesRawValues: [Int] = {
            GlobalConstants.trackingJointNames.map { $0.rawValue }
        }()

        // MARK: - Lifecycle

        init(arTrainingViewModel: ARTrainingViewModel) {
            self.arTrainingViewModel = arTrainingViewModel
            self.arDataProcessor = ARTrackingDataProcessor(exercise: arTrainingViewModel.exercise)

            super.init()
        }

        // MARK: - Delegate method

        func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
            for anchor in anchors {
                guard let bodyAnchor = anchor as? ARBodyAnchor else { continue }

                let transforms = bodyAnchor.skeleton.jointModelTransforms
                let jointModelTransformsCurrent = trackingJointNamesRawValues.map {  transforms[$0] }

                if arTrainingViewModel.isTrainingInProgress && !isRecording {
                    isRecording = arDataProcessor.checkIfIterationStarted(currentFrame: jointModelTransformsCurrent)
                    if isRecording {
                        timerObject.start()
                    }
                }

                if arTrainingViewModel.isTrainingInProgress && isRecording {
                    compareTrainingWithTarget(currentFrame: jointModelTransformsCurrent)
                }

                if !arTrainingViewModel.isTrainingInProgress && isRecording {
                    isRecording.toggle()
                }
            }
        }

        // MARK: - Private Methods
        
        private func compareTrainingWithTarget(currentFrame: Frame) {
            if arDataProcessor.couldDetectEndOfIteration {
                arDataProcessor.checkIfIterationEnded(currentFrame: currentFrame)
            }

            if arDataProcessor.couldDetectStartOfIteration {
                let previousShouldBeRecorded = arDataProcessor.detectIfNextIterationStarted(currentFrame: currentFrame)
                isRecording = false
                timerObject.stop()
                arDataProcessor.updateCurrentResults(
                    shouldBeRecorded: previousShouldBeRecorded,
                    iterationDuration: timerObject.elapsedSeconds
                ) { [weak self] iterationResults in
                    guard let iterationResults else { return }
                    self?.arTrainingViewModel.iterations.append(iterationResults)
                    self?.arTrainingViewModel.currentResults.update(with: iterationResults)
                }
            } else {
                arDataProcessor.recordingResults(currentFrame: currentFrame)
            }
        }
    }

}
