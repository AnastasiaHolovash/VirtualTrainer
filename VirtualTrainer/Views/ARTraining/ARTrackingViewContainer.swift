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
        let arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: true)
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

    func updateUIView(_ uiView: ARView, context: Context) {

    }

    // MARK: - Coordinator

    class Coordinator: NSObject, ARSessionDelegate {

        private var jointModelTransformsCurrent: Frame = []
        @Binding var currentResults: CurrentResults

        /// True if timer is out
        @Binding var isTrainingInProgress: Bool
        @Binding var iterations: [IterationResults]

        /// True if recording training/exercise data is started
        private var isRecording: Bool = false
        private var exerciseFramesLoaded: Frames = []
        private var exerciseFramesCount: Int = 0
        private var comparisonFrameValue: Frame = []


        init(
            exercise: Exercise,
            isRecording: Binding<Bool>,
            currentResults: Binding<CurrentResults>,
            iterations: Binding<[IterationResults]>
        ) {
            _isTrainingInProgress = isRecording
            _currentResults = currentResults
            _iterations = iterations

            super.init()

            exerciseFramesLoaded = exercise.simdFrames
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
                print("! Compare with last exercise frame \(resultValue * 100)% ")

                if resultValue.isCloseToEqual {
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

            print("\nN = ", numberOfIterations, "        count = ", iterationsResults[iterationsResults.count - 2].count)

            isRecording = false
        }

        // MARK: - Update results

        private func updateCurrentResults() {
            let iteration = iterationsResults[numberOfIterations - 1]
            if iteration.count > exerciseFramesCount / 2 {
                let score = iteration.reduce(0.0, +) / Float(iteration.count)
                let iterationResults = IterationResults(
                    number: iterations.count + 1,
                    score: score,
                    speed: Float(exerciseFramesCount) / Float(iteration.count)
                )

                iterations.append(iterationResults)
                currentResults.update(with: numberOfIterations, iteration: iterationResults)
            }
        }
    }

}
