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
    @Binding var exercise: NewExercise

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: true)
        arView.session.delegate = context.coordinator

        let configuration = ARBodyTrackingConfiguration()
        arView.session.run(configuration)

        return arView
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            arRecordingViewModel: arRecordingViewModel,
            exercise: $exercise
        )
    }

    func updateUIView(_ uiView: ARView, context: Context) {

    }

    // MARK: - Coordinator

    class Coordinator: NSObject, ARSessionDelegate {

        @ObservedObject var arRecordingViewModel: ARRecordingViewModel
        @Binding var exercise: NewExercise
        private let recorder = Recorder()
        private let arRecordingDataProcessor = ARRecordingDataProcessor()
        private var isRecording: Bool = false
        private let trackingJointNamesRawValues: [Int] = {
            GlobalConstants.trackingJointNames.map { $0.rawValue }
        }()
        private var cancellable = Set<AnyCancellable>()

        init(
            arRecordingViewModel: ARRecordingViewModel,
            exercise: Binding<NewExercise>
        ) {
            self.arRecordingViewModel = arRecordingViewModel
            _exercise = exercise

            super.init()

            recorder.setup { [weak self] url in
                self?.exercise.localVideoURL = url
                self?.writeExerciseResult()
            }

            arRecordingViewModel.$isTrainingInProgress
                .sink { [weak self] value in
                    print("--- isTrainingInProgress: \(value)")
                    if value {
                        self?.recorder.start()
                    }
                }
                .store(in: &cancellable)
        }

        // MARK: - Delegate method

        func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
            for anchor in anchors {
                guard let bodyAnchor = anchor as? ARBodyAnchor else { continue }

                let transforms = bodyAnchor.skeleton.jointModelTransforms
                let jointModelTransformsCurrent = trackingJointNamesRawValues.map { transforms[$0] }

                if arRecordingViewModel.isTrainingInProgress && !isRecording {
                    print("\n----- Check If STARTED -----")
                    isRecording = arRecordingDataProcessor.checkIfExerciseStarted(
                        currentFrame: jointModelTransformsCurrent
                    )
                }

                if arRecordingViewModel.isTrainingInProgress && isRecording {
                    print("\n----- recording -----")
                    arRecordingDataProcessor.updateExerciseFrames(currentFrame: jointModelTransformsCurrent)

                    if let capturedImage = session.currentFrame?.capturedImage {
                        if !recorder.isRecording {
                            recorder.start()
                        }
                        recorder.render(pixelBuffer: capturedImage)
                    }
                }

                if !arRecordingViewModel.isTrainingInProgress && isRecording {
                    print("--- STOP Recording ---")
                    isRecording.toggle()
//                    exercise.frames = arRecordingDataProcessor.cropOneIteration()

//                    print("---- arRecordingViewModel.exercise.frames ----- \n \(exercise.frames)")
//                    arRecordingDataProcessor.clearData()
                }

                if !arRecordingViewModel.isTrainingInProgress && recorder.isRecording {
                    print("--- recorder.stop() ---")
                    recorder.stop()
                }
            }
        }

        private func writeExerciseResult() {
            exercise.frames = arRecordingDataProcessor.cropOneIteration()
            arRecordingDataProcessor.clearData()
        }
    }

}
