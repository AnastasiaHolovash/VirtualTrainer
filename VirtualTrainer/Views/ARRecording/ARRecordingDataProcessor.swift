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
            print("index", index)

            let resultValue = frame.compare(to: previous)
            let result = resultValue.isStartStopMovement

            print("\n---- Compare ---- \(resultValue)% ----- \(result)")

            return result
        } ?? (exerciseFrames.count - 1, exerciseFrames.last)

        let lastFrameIndex = frameIndex > 1 ? exerciseFrames.count - (frameIndex - 1) : exerciseFrames.count - 1
        let croppedFrames: Frames = Array(exerciseFrames[0...lastFrameIndex])

        print("Size: \(croppedFrames.count)")
        let smoothedData = applyExponentialSmoothing(frames: croppedFrames)

        // Saving new frames to model
        return smoothedData
    }

    func clearData() {
        exerciseFrames = []
    }

}
