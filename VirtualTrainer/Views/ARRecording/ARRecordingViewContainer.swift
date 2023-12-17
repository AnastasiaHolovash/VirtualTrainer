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
        private let arRecordingDataProcessor = ARRecordingDataProcessor()

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
                let jointModelTransformsCurrent = trackingJointNamesRawValues.map { transforms[$0] }

                if isTrainingInProgress && !isRecording {
                    isRecording = arRecordingDataProcessor.checkIfExerciseStarted(
                        currentFrame: jointModelTransformsCurrent
                    )
                }

                if isTrainingInProgress && isRecording {
                    arRecordingDataProcessor.updateExerciseFrames(currentFrame: jointModelTransformsCurrent)

                    if let capturedImage = session.currentFrame?.capturedImage {
                        if !recorder.isRecording {
                            recorder.start()
                        }
                        recorder.render(pixelBuffer: capturedImage)
                    }
                }

                if !isTrainingInProgress && isRecording {
                    isRecording.toggle()
                    arRecordingViewModel.exercise.frames = arRecordingDataProcessor.cropOneIteration()
                    arRecordingDataProcessor.clearData()
                }

                if !isTrainingInProgress && recorder.isRecording {
                    recorder.stop()
                }
            }
        }
    }

}
