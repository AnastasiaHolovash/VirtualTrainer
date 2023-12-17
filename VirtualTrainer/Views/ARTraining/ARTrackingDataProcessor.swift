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
    private var exerciseDuration: Float

    private var exerciseIterations: [Frames] = [[]]
    private var numberOfIterations: Int { exerciseIterations.count - 1 }
    private var comparisonFrameValue: Frame = []
    private var exerciseFramesIndex = GlobalConstants.exerciseFramesFirstIndex
    private var currentNumberOfStaticFrames = 0
    private var previousValueOfStaticFrame: Float = 0.0
    private var previous: Frame = []

    // MARK: - Lifecycle

    init(exercise: Exercise) {
        self.exerciseFramesLoaded = exercise.simdFrames
        self.exerciseFramesCount = exerciseFramesLoaded.count
        self.exerciseDuration = exercise.duration ?? 2
    }

    // MARK: - Accessible Methods

    func checkIfExerciseStarted(currentFrame: Frame) -> Bool {
        guard !comparisonFrameValue.isEmpty else {
            comparisonFrameValue = currentFrame
            return false
        }

        return currentFrame
            .compare(to: comparisonFrameValue)
            .isStartStopMovement
    }

    func detectEndOfIteration(currentFrame: Frame) {
        guard let last = exerciseFramesLoaded.last else {
            return
        }

        if currentFrame.compare(to: last).isCloseToEqual {
            updateStaticFramesCount(currentFrame: currentFrame)
        }
    }

    func detectIfNextIterationStarted(
        currentFrame: Frame
    ) -> Bool {
        removeStaticFramesFromLastIteration()
        let shouldBeRecorded = exerciseIterations[numberOfIterations].count > exerciseFramesCount / 2
        prepareDataForNextIteration(
            currentFrame: currentFrame,
            shouldBeRecorded: shouldBeRecorded
        )
        return shouldBeRecorded
    }

    func recordingResults(
        currentFrame: Frame
    ) {
        exerciseIterations[numberOfIterations].append(currentFrame)

        if exerciseFramesIndex < exerciseFramesLoaded.count - 1 {
            exerciseFramesIndex += 1
        }
    }

    func updateCurrentResults(
        shouldBeRecorded: Bool,
        iterationDuration: Float,
        completion: @escaping (IterationResults?) -> Void
    ) {
        guard numberOfIterations > 0,
              shouldBeRecorded else {
            completion(nil)
            return
        }

        let number = exerciseIterations.count - 1
        let exerciseDuration = self.exerciseDuration

        print("--- \(exerciseDuration) / \(iterationDuration) = \(exerciseDuration / iterationDuration)")
        compareIteration(
            target: exerciseFramesLoaded,
            training: exerciseIterations[numberOfIterations - 1]
        ) { iterationScore in
            completion(IterationResults(
                number: number,
                score: iterationScore,
                speed: exerciseDuration / iterationDuration
            ))
        }
    }

    // MARK: - Private Methods

    private func updateStaticFramesCount(currentFrame: Frame) {
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
    }

    private func prepareDataForNextIteration(
        currentFrame: Frame,
        shouldBeRecorded: Bool
    ) {
        if !shouldBeRecorded {
            exerciseIterations.removeLast()
        }
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

    private func compareIteration(target: [Frame], training: [Frame], completion: @escaping (IterationScore) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let smoothedData = ARDataProcessingAlgorithms.applyExponentialSmoothing(frames: training)
            let maxError = Float(min(smoothedData.count, training.count)) * GlobalConstants.maxErrorPossibleСoefficient
            let result2 = ARDataProcessingAlgorithms.dtw(x1: smoothedData, x2: target)
            let reducedResult2 = result2.reduce(0, +)

            print("------- maxError: \(maxError)")
            print("--- DTW2: \(result2)")
            print("--- DTW2: \(reducedResult2)      \((100 - reducedResult2 / maxError) / 100)")

            let iterationScore = IterationScore(
                total: (100 - reducedResult2 / maxError) / 100,
                joints: result2
            )

            DispatchQueue.main.async {
                completion(iterationScore)
            }
        }
    }

}
