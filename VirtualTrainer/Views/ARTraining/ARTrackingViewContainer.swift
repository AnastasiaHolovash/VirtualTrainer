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
        private let arDataProcessor: ARDataProcessor

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

            arDataProcessor = ARDataProcessor(exercise: exercise)

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
                    print("--- STOP Recording ---")
                    isRecording.toggle()
                }
            }
        }

        private func compareTrainingWithTarget(currentFrame: Frame) {
            if arDataProcessor.couldDetectEndOfIteration {
                arDataProcessor.detectEndOfIteration(currentFrame: currentFrame)
            }

            if arDataProcessor.couldDetectStartOfIteration {
                print("--- couldDetectStartOfIteration")
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

class ARDataProcessor {

    var exerciseFramesLoaded: Frames
    var exerciseFramesCount: Int

    init(exercise: Exercise) {
        self.exerciseFramesLoaded = exercise.simdFrames
        self.exerciseFramesCount = exerciseFramesLoaded.count
    }

    private var exerciseIterations: [Frames] = [[]]
    private var comparisonFrameValue: Frame = []

    // MARK: - Check If Started

    func checkIfExerciseStarted(currentFrame: Frame) -> Bool {
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

    func detectEndOfIteration(currentFrame: Frame) {
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

    func detectIfNextIterationStarted(
        currentFrame: Frame
    ) -> Bool {
        print("\n--- New iteration initiated by User")
        removeStaticFramesFromLastIteration()
        let shouldBeRecorded = isShouldBeRecorded
        startDetectionStartOfIteration(
            currentFrame: currentFrame,
            shouldBeRecorded: shouldBeRecorded
        )
        return shouldBeRecorded
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


    func recordingResults(
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

    func updateCurrentResults(
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
            number: exerciseIterations.count - 1,
            score: iterationScore,
            speed: Float(2 / iterationDuration)
        )
        print("---- N = \(numberOfIterations - 1)     NEN RESULT: \(iterationScore)")
        return iterationResults
    }

}
