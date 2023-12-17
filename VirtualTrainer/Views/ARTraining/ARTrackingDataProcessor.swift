//
//  ARTrackingDataProcessor.swift
//  VirtualTrainer
//
//  Created by Anastasia Holovash on 17.12.2023.
//

import Foundation

class ARTrackingDataProcessor {

    // MARK: - Accessible Properties

    var couldDetectStartOfIteration: Bool {
        currentNumberOfStaticFrames == GlobalConstants.staticPositionIndicator
    }

    var couldDetectEndOfIteration: Bool {
        let couldDetectEndOfIterationIndex = Float(exerciseFramesCount) * GlobalConstants.couldDetectEndOfIterationIndicator
        return Float(exerciseFramesIndex) >= couldDetectEndOfIterationIndex
    }

    // MARK: - Private Properties

    private var exerciseFramesLoaded: Frames
    private var exerciseFramesCount: Int

    private var exerciseIterations: [Frames] = [[]]
//    private var exerciseIterationsResults: [[Float]] = [[]]

    private var comparisonFrameValue: Frame = []
    private var exerciseFramesIndex = GlobalConstants.exerciseFramesFirstIndex
    private var numberOfIterations = 0
    private var currentNumberOfStaticFrames = 0
    private var previousValueOfStaticFrame: Float = 0.0
    private var previous: Frame = []

    // MARK: - Lifecycle

    init(exercise: Exercise) {
        self.exerciseFramesLoaded = exercise.simdFrames
        self.exerciseFramesCount = exerciseFramesLoaded.count
    }

    // MARK: - Accessible Methods

    func checkIfExerciseStarted(currentFrame: Frame) -> Bool {
        guard !comparisonFrameValue.isEmpty else {
            comparisonFrameValue = currentFrame
            return false
        }

        let resultValue = currentFrame.compare(to: comparisonFrameValue)
        let result = resultValue.isStartStopMovement

        return result
    }

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

    func detectIfNextIterationStarted(
        currentFrame: Frame
    ) -> Bool {
        print("\n--- New iteration initiated by User")
        removeStaticFramesFromLastIteration()
        let shouldBeRecorded = exerciseIterations[numberOfIterations].count > exerciseFramesCount / 2
        startDetectionStartOfIteration(
            currentFrame: currentFrame,
            shouldBeRecorded: shouldBeRecorded
        )
        return shouldBeRecorded
    }

    func recordingResults(
        currentFrame: Frame
    ) {
        let targetFrame = exerciseFramesLoaded[exerciseFramesIndex]

//        let resultValue = currentFrame.compare(to: targetFrame)
//        exerciseIterationsResults[numberOfIterations].append(resultValue)
        exerciseIterations[numberOfIterations].append(currentFrame)

        if exerciseFramesIndex < exerciseFramesLoaded.count - 1 {
            exerciseFramesIndex += 1
        }
    }

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

    // MARK: - Private Methods

    private func startDetectionStartOfIteration(
        currentFrame: Frame,
        shouldBeRecorded: Bool
    ) {
        if !shouldBeRecorded {
//            exerciseIterationsResults.removeLast()
            exerciseIterations.removeLast()
        } else {
            print("---- numberOfIterations APDATED to: \(numberOfIterations + 1)")
            numberOfIterations += 1
        }
//        exerciseIterationsResults.append([])
        exerciseIterations.append([])

        exerciseFramesIndex = GlobalConstants.exerciseFramesFirstIndex

        currentNumberOfStaticFrames = 0
        previousValueOfStaticFrame = 0.0

        comparisonFrameValue = currentFrame
        previous = []
    }

    private func removeStaticFramesFromLastIteration() {
        exerciseIterations[numberOfIterations].removeLast(GlobalConstants.staticPositionIndicator - 1)
    }

}
