//
//  ProcessingARDataExtension.swift
//  VirtualTrainer
//
//  Created by Anastasia Holovash on 06.06.2022.
//

import SwiftUI
import ARKit
import Combine
import Vision

extension Float {

    var isStartStopMovement: Bool {
        GlobalConstants.startStopMovementRange.contains(self)
    }

    var isCloseToEqual: Bool {
        GlobalConstants.closeToEqualRange.contains(self)
    }

    var isVeryCloseToEqual: Bool {
        GlobalConstants.veryCloseToEqualRange.contains(self)
    }

}


extension Array where Element == simd_float4x4 {

//    func compare(to arraySimd4x4: Frame) -> Float {
//        let resultArray = self.enumerated().map { index, simd4x4 -> Float in
//            let difference = simd4x4 - arraySimd4x4[index]
//            let simd4x4ResultArray = difference.allValues.map { value in
//                1 - abs(value) / 2
//            }
//            return simd4x4ResultArray.averageValue
//        }
//
//        return resultArray.averageValue
//    }

//    func newValue(arraySimd4x4: Frame) {
//        let new = 1 - abs(calculateFrameDistance(frame1: self, frame2: arraySimd4x4)) / 2
//        print("--- new: \(new)")
//    }

//    func printf() {
//        self.forEach { $0.printf() }
//    }

    func compare(to arraySimd4x4: Frame) -> Float {
        (100 - calculateFrameDistance(frame1: self, frame2: arraySimd4x4) / GlobalConstants.maxErrorPossible) / 100
    }

}

extension Array where Element == Float {

    var averageValue: Float {
        self.reduce(0, +) / Float(self.count)
    }

}

extension simd_float4x4 {

    var allValues: [Float] {
        [
            self.columns.0.x,
            self.columns.0.y,
            self.columns.0.z,

            self.columns.1.x,
            self.columns.1.y,
            self.columns.1.z,

            self.columns.2.x,
            self.columns.2.y,
            self.columns.2.z,

            self.columns.3.x,
            self.columns.3.y,
            self.columns.3.z,
        ]
    }

    func printf() {
        print(round(self.columns.0 * 100) / 100.0)
        print(round(self.columns.1 * 100) / 100.0)
        print(round(self.columns.2 * 100) / 100.0)
        print(round(self.columns.3 * 100) / 100.0)
    }

}

func calculateFrameDistance(frame1: Frame, frame2: Frame) -> Float {
    var totalDistance: Float = 0.0

    let jointCount = Swift.min(frame1.count, frame2.count)

    for j in 0..<jointCount {
        let translation1 = frame1[j].columns.3
        let translation2 = frame2[j].columns.3

        let dx = translation1.x - translation2.x
        let dy = translation1.y - translation2.y
        let dz = translation1.z - translation2.z

        totalDistance += sqrt(dx*dx + dy*dy + dz*dz)
    }

    return totalDistance
}

private func calculateTranslationAndRotationDistance(frame1: Frame, frame2: Frame) -> Float {
    var totalDistance: Float = 0.0

    let jointCount = Swift.min(frame1.count, frame2.count)

    for j in 0..<jointCount {
        // Calculate translational distance
        let translation1 = frame1[j].columns.3
        let translation2 = frame2[j].columns.3

        let dx = Float(translation1.x - translation2.x)
        let dy = Float(translation1.y - translation2.y)
        let dz = Float(translation1.z - translation2.z)

        totalDistance += sqrt(max(0, dx*dx + dy*dy + dz*dz)) // Ensure non-negative inside sqrt

        // Calculate rotational distance (angle between two rotation matrices)
        let rotation1 = simd_quatf(frame1[j])
        let rotation2 = simd_quatf(frame2[j])
        let dotProduct = dot(rotation1.vector, rotation2.vector)
        let clampedDotProduct = min(max(dotProduct, -1), 1) // Clamp between -1 and 1
        let angleBetweenQuaternions = 2 * acos(abs(clampedDotProduct))
        totalDistance += Float(angleBetweenQuaternions)
    }

    print("--- totalDistance \(totalDistance)")
    return totalDistance
}



func applyExponentialSmoothing(frames: [Frame], alpha: Float = 0.8) -> [Frame] {
    var smoothedFrames: [Frame] = []
    guard let firstFrame = frames.first else {
        return smoothedFrames
    }

    var previousSmoothedFrame = firstFrame
    smoothedFrames.append(previousSmoothedFrame)

    for frame in frames.dropFirst() {
        var newSmoothedFrame: Frame = []

        for matrixIndex in 0..<frame.count {
            var newSmoothedMatrix = simd_float4x4()

            for row in 0..<4 {
                for column in 0..<4 {
                    let previousValue = previousSmoothedFrame[matrixIndex][row][column]
                    let currentValue = frame[matrixIndex][row][column]
                    let smoothedValue = alpha * currentValue + (1 - alpha) * previousValue

                    newSmoothedMatrix[row][column] = smoothedValue
                }
            }

            newSmoothedFrame.append(newSmoothedMatrix)
        }

        previousSmoothedFrame = newSmoothedFrame
        smoothedFrames.append(previousSmoothedFrame)
    }

    return smoothedFrames
}

private func dtw(x1: [Frame], x2: [Frame]) -> Float {
    let n1 = x1.count
    let n2 = x2.count

    var row0 = Array(repeating: Float.infinity, count: n2 + 1)
    row0[0] = 0

    var row1 = Array(repeating: Float(0), count: n2 + 1)

    for i in 0..<n1 {
        row1[0] = .infinity

        var lastValue = Float.infinity

        for j in 0..<n2 {
            let cost = calculateTranslationAndRotationDistance(frame1: x1[i], frame2: x2[j])

            let minimum = min(min(row0[j] + cost, row0[j + 1] + cost), lastValue + cost)
            lastValue = minimum
            row1[j + 1] = lastValue
        }

        swap(&row0, &row1)
    }

    return row0[n2]
}


func compareIteration(target: [Frame], training: [Frame]) -> Float {
    let smoothedData = applyExponentialSmoothing(frames: training)
//    let smoothedData = training
    let maxError = Float(min(smoothedData.count, training.count)) * GlobalConstants.maxErrorPossibleСoefficient
    print("------- maxError: \(maxError)")
    let result = dtw(x1: smoothedData, x2: target)
    print("--- DTW: \(result)")
    return (100 - result / maxError) / 100
}
