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

        @Binding var currentResults: CurrentResults

        /// True if timer is out
        @Binding var isTrainingInProgress: Bool
        @Binding var iterations: [IterationResults]

        /// True if recording training/exercise data is started
        private var isRecording: Bool = false
        @ObservedObject var timerObject = TimerObject()

        private var exerciseFramesLoaded: Frames = []

        private var exerciseIterations: [Frames] = [[]]
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

        func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
            for anchor in anchors {
                guard let bodyAnchor = anchor as? ARBodyAnchor else { continue }

                let transforms = bodyAnchor.skeleton.jointModelTransforms
                let jointModelTransformsCurrent = trackingJointNamesRawValues.map {  transforms[$0] }

                if isTrainingInProgress && !isRecording {
                    isRecording = checkIfExerciseStarted(currentFrame: jointModelTransformsCurrent)
                    if isRecording {
                        timerObject.start()
                    }
                }

                if isTrainingInProgress && isRecording {
                    compareTrainingWithTarget(currentFrame: jointModelTransformsCurrent)
                }

                if !isTrainingInProgress && isRecording {
                    print("--- STOP Recording ---")
                    isRecording.toggle()
                }
            }
        }

        // MARK: - Check If Started

        private func checkIfExerciseStarted(currentFrame: Frame) -> Bool {
            guard !comparisonFrameValue.isEmpty else {
                comparisonFrameValue = currentFrame
                return false
            }

            let resultValue = currentFrame.compare(to: comparisonFrameValue)
            let result = resultValue.isStartStopMovement

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

        private func detectEndOfIteration(currentFrame: Frame) {
            guard let last = exerciseFramesLoaded.last else {
                return
            }
            let resultValue = currentFrame.compare(to: last)
            print("! Compare with last exercise frame \(resultValue * 100)% ")

            if resultValue.isCloseToEqual {
                if previous.isEmpty {
                    previous = currentFrame
                    currentNumberOfStaticFrames = 1
                } else {
                    let resultValue2 = currentFrame.compare(to: previous)
                    previous = currentFrame

                    if resultValue2.isVeryCloseToEqual {
                        currentNumberOfStaticFrames += 1
                    }
                }
                print("    currentNumberOfStaticFrames = \(currentNumberOfStaticFrames)")
            }
        }

        var couldDetectStartOfIteration: Bool {
            currentNumberOfStaticFrames == GlobalConstants.staticPositionIndicator
        }

        private func detectIfNextIterationStarted(
            currentFrame: Frame,
            shouldBeRecorded: Bool
        ) {
            print("\n--- New iteration initiated by User")
            startDetectionStartOfIteration(
                currentFrame: currentFrame,
                shouldBeRecorded: shouldBeRecorded
            )
        }

        private func removeStaticFramesFromLastIteration() {
            iterationsResults[numberOfIterations].removeLast(GlobalConstants.staticPositionIndicator - 1)
        }

        var isShouldBeRecorded: Bool {
            let result = iterationsResults[numberOfIterations].count > exerciseFramesCount / 2
            print("---- isShouldBeRecorded: \(result)    iterationCount: \(iterationsResults[numberOfIterations].count)")
            print("---- iterationsCount: \(iterationsResults.count)")
            return result
        }

        private func compareTrainingWithTarget(currentFrame: Frame) {
            // Detecting end of iteration
            if couldDetectEndOfIteration {
                detectEndOfIteration(currentFrame: currentFrame)
            }

            if couldDetectStartOfIteration {
                // Start detection start of iteration
                print("--- couldDetectStartOfIteration")
                removeStaticFramesFromLastIteration()
                let shouldBeRecorded = isShouldBeRecorded
                detectIfNextIterationStarted(currentFrame: currentFrame, shouldBeRecorded: shouldBeRecorded)
                isRecording = false
                timerObject.stop()
                if let iterationResults = updateCurrentResults(
                    shouldBeRecorded: shouldBeRecorded,
                    iterationDuration: timerObject.elapsedSeconds
                ) {
                    iterations.append(iterationResults)
                    currentResults.update(with: numberOfIterations, iteration: iterationResults)
                }
            } else {
                recordingResults(currentFrame: currentFrame)
            }
        }

        private func recordingResults(
            currentFrame: Frame
        ) {
            let targetFrame = exerciseFramesLoaded[exerciseFramesIndex]

            let resultValue = currentFrame.compare(to: targetFrame)
            iterationsResults[numberOfIterations].append(resultValue)
            exerciseIterations[numberOfIterations].append(currentFrame)

            if exerciseFramesIndex < exerciseFramesLoaded.count - 1 {
                exerciseFramesIndex += 1
            }
        }

        private func startDetectionStartOfIteration(
            currentFrame: Frame,
            shouldBeRecorded: Bool
        ) {
            if !shouldBeRecorded {
                iterationsResults.removeLast()
                exerciseIterations.removeLast()
            } else {
                print("---- numberOfIterations APDATED to: \(numberOfIterations + 1)")
                numberOfIterations += 1
            }
            iterationsResults.append([])
            exerciseIterations.append([])

            exerciseFramesIndex = GlobalConstants.exerciseFramesFirstIndex

            currentNumberOfStaticFrames = 0
            previousValueOfStaticFrame = 0.0

            comparisonFrameValue = currentFrame
            previous = []
        }

        // MARK: - Update results

        private func updateCurrentResults(
            shouldBeRecorded: Bool,
            iterationDuration: Int
        ) -> IterationResults? {
            print("---- updateCurrentResults shouldBeRecorded: \(shouldBeRecorded) numberOfIterations: \(numberOfIterations)")
            guard numberOfIterations > 0,
                  shouldBeRecorded else {
                return nil
            }
            print("---- updateCurrentResults 2")
            let iterationScore = compareIteration(
                target: exerciseFramesLoaded,
                training: exerciseIterations[numberOfIterations - 1]
            )
            let iterationResults = IterationResults(
                number: iterations.count + 1,
                score: iterationScore,
                speed: Float(2 / iterationDuration)
            )
            print("---- N = \(numberOfIterations - 1)     NEN RESULT: \(iterationScore)")
            return iterationResults
        }
    }

}

class ARDataProcessor {

    var exerciseFramesLoaded: Frames
    var exerciseFramesCount: Int

    init(exercise: Exercise) {
        self.exerciseFramesLoaded = exercise.simdFrames
        self.exerciseFramesCount = exerciseFramesLoaded.count
    }

}
