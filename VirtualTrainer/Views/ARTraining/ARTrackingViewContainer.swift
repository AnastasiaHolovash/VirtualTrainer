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
import Vision

struct ARTrackingViewContainer: UIViewRepresentable {

//    @Binding var jointModelTransforms: Frame
    @Binding var isRecording: Bool
    @Binding var currentResults: CurrentResults
    @Binding var comparisonFrameValue: Frame

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: true)
        arView.session.delegate = context.coordinator

        let configuration = ARBodyTrackingConfiguration()
        arView.session.run(configuration)

        return arView
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
//            jointModelTransforms: $jointModelTransforms,
            isRecording: $isRecording,
            currentResults: $currentResults,
            comparisonFrameValue: $comparisonFrameValue
        )
    }

    func updateUIView(_ uiView: ARView, context: Context) {

    }

    // MARK: - Coordinator

    class Coordinator: NSObject, ARSessionDelegate {

        private var jointModelTransformsCurrent: Frame = []
        @Binding var currentResults: CurrentResults
        @Binding var comparisonFrameValue: Frame
        /// True if timer is out
        @Binding var isTrainingInProgress: Bool

        /// True if recording training/exercise data is started
        private var isRecording: Bool = false
        private var exerciseFramesLoaded: Frames = []
        private var exerciseFramesCount: Int = 0

        private var iterations: [IterationResults] = []

        init(
//            jointModelTransforms: Binding<[simd_float4x4]>,
            isRecording: Binding<Bool>,
            currentResults: Binding<CurrentResults>,
            comparisonFrameValue: Binding<Frame>
        ) {
//            _jointModelTransformsCurrent = jointModelTransforms
            _isTrainingInProgress = isRecording
            _currentResults = currentResults
            _comparisonFrameValue = comparisonFrameValue

            super.init()

            exerciseFramesLoaded = Defaults.shared.getExerciseTargetFrames()
            exerciseFramesCount = exerciseFramesLoaded.count
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
                jointModelTransformsCurrent = trackingJointNamesRawValues.map {  transforms[$0] }

                if isTrainingInProgress && !isRecording {
                    print("\n***** Check If STARTED *****")
                    _ = self.checkIfExerciseStarted()
                }

                if isTrainingInProgress && isRecording {
                    compareTrainingWithTarget()
                }
                if !isTrainingInProgress && isRecording {
                    print("--- STOP Recording ---")
                    isRecording.toggle()

//                    makeTrainingDescription(from: iterationsResults)

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
            print("---- Compare ---- \(resultValue * 100)% ----- \(result)")

            isRecording = result

            return result
        }

        // MARK: - Compare Training With Target

        var exerciseFramesIndex = GlobalConstants.exerciseFramesFirstIndex
        var couldDetectEndOfIteration: Bool {
            let couldDetectEndOfIterationIndex = Float(exerciseFramesCount) * GlobalConstants.couldDetectEndOfIterationIndicator
            return Float(exerciseFramesIndex) >= couldDetectEndOfIterationIndex
        }
        var iterationsResults: [[Float]] = [[]]
        var numberOfIterations = 0

        var currentNumberOfStaticFrames = 0
        var previousValueOfStaticFrame: Float = 0.0

        var previous: Frame = []

        private func compareTrainingWithTarget() {
            let lastTargetFrame = exerciseFramesLoaded.last

            // Detection end of iteration
            if couldDetectEndOfIteration,
               let last = lastTargetFrame {
                let resultValue = jointModelTransformsCurrent.compare(to: last)
                //                print("Could Detect End Of Iteration with --- resultValue: \(resultValue)")

                if resultValue.isCloseToEqual {
                    //                    print("Could Detect End Of Iteration with --- resultValue: \(resultValue)")

                    if previous.isEmpty {
                        previous = jointModelTransformsCurrent
                        currentNumberOfStaticFrames = 1
                    } else {
                        let resultValue2 = jointModelTransformsCurrent.compare(to: previous)
                        print("---- Compare with previous ---- \(resultValue2 * 100)% -----")
                        previous = jointModelTransformsCurrent

                        if resultValue2.isVeryCloseToEqual {
                            currentNumberOfStaticFrames += 1
                        }
                    }

                    print("    currentNumberOfStaticFrames = \(currentNumberOfStaticFrames)")
                }
            }

            if currentNumberOfStaticFrames == GlobalConstants.staticPositionIndicator {
                // Start detection start of iteration
                print("\nNew iteration initiated by User")
                iterationsResults[numberOfIterations].removeLast(GlobalConstants.staticPositionIndicator - 1)
                startDetectionStartOfIteration()
                updateCurrentResults()
            } else {
                // Recording results
                let targetFrame = exerciseFramesLoaded[exerciseFramesIndex]

                let resultValue = jointModelTransformsCurrent.compare(to: targetFrame)
                print("---- Compare With Target ---- \(resultValue * 100)% ----- \(exerciseFramesIndex)")
                iterationsResults[numberOfIterations].append(resultValue)

                if exerciseFramesIndex < exerciseFramesLoaded.count - 1 {
                    exerciseFramesIndex += 1
                }
            }
        }

        private func startDetectionStartOfIteration() {
            iterationsResults.append([])
            numberOfIterations += 1

            exerciseFramesIndex = GlobalConstants.exerciseFramesFirstIndex

            currentNumberOfStaticFrames = 0
            previousValueOfStaticFrame = 0.0

            comparisonFrameValue = jointModelTransformsCurrent
            previous = []

            isRecording = false
        }

        // MARK: - Update results

        private func updateCurrentResults() {
            let iteration = iterationsResults[numberOfIterations - 1]
            if iteration.count > exerciseFramesCount / 3 * 2 {
                let score = iteration.reduce(0.0, +) / Float(iteration.count)
                let iterationResults = IterationResults(
                    number: iterations.count + 1,
                    score: score,
                    speed: Float(iteration.count) / Float(exerciseFramesCount)
                )

                iterations.append(iterationResults)
                currentResults.update(with: numberOfIterations, iteration: iterationResults)
            }
        }

        /**
        func makeTrainingDescription(from results: [[Float]]) {
            //            var iterations: [IterationResults] = []

            results.enumerated().forEach { index, iteration in
                if iteration.count > exerciseFramesCount / 3 * 2 {
                    let score = iteration.reduce(0.0, +) / Float(iteration.count)
                    //                    iterations.append(IterationResults(
                    //                        number: iterations.count + 1,
                    //                        score: score,
                    //                        speed: Float(iteration.count) / Float(exerciseFramesCount)
                    //                    ))

                    print("Score of \(index + 1) Iteration: \(Int(score * 100))%")
                    print(iterations.last!.speedDescription)
                    //                    print(iteration)
                }
            }

            let numberOfIterations = iterations.count
            print("Number Of Iterations: \(numberOfIterations)\n")

            let score = iterations.reduce(0.0) { $0 + $1.score } / Float(numberOfIterations)
            print("\nGeneral score: \(Int(score * 100))%")
        }
        */

    }

}
