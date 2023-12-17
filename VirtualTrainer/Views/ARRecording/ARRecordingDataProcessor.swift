//
//  ARRecordingDataProcessor.swift
//  VirtualTrainer
//
//  Created by Anastasia Holovash on 17.12.2023.
//

import Foundation

class ARRecordingDataProcessor {

    private var comparisonFrameValue: Frame = []
    private var exerciseFrames: Frames = []

    func checkIfExerciseStarted(currentFrame: Frame) -> Bool {
        guard !comparisonFrameValue.isEmpty else {
            comparisonFrameValue = currentFrame
            return false
        }

        let result = currentFrame
            .compare(to: comparisonFrameValue)
            .isStartStopMovement

        if result {
            exerciseFrames = [comparisonFrameValue]
        }

        return result
    }

    func updateExerciseFrames(currentFrame: Frame) {
        exerciseFrames.append(currentFrame)
    }

    func cropOneIteration() -> [Frame] {
        let previousChecked = exerciseFrames.last
        let (frameIndex, _) = exerciseFrames.reversed().enumerated().first { index, frame in
            guard index < exerciseFrames.count - 1,
                  let previous = previousChecked
            else {
                return false
            }

            let resultValue = frame.compare(to: previous)
            let result = resultValue.isStartStopMovement

            return result
        } ?? (exerciseFrames.count - 1, exerciseFrames.last)

        let lastFrameIndex = frameIndex > 1 ? exerciseFrames.count - (frameIndex - 1) : exerciseFrames.count - 1
        let croppedFrames: Frames = Array(exerciseFrames[0...lastFrameIndex])

        let smoothedData = ARDataProcessingAlgorithms.applyExponentialSmoothing(frames: croppedFrames)
        return smoothedData
    }

    func clearData() {
        exerciseFrames = []
    }

}
