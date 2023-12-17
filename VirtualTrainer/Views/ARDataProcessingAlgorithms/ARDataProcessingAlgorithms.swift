//
//  ARDataProcessingAlgorithms.swift
//  VirtualTrainer
//
//  Created by Anastasia Holovash on 17.12.2023.
//

import Foundation
import ARKit
import Vision

enum ARDataProcessingAlgorithms {}

extension ARDataProcessingAlgorithms {

    static func calculateFrameDistance(frame1: Frame, frame2: Frame) -> Float {
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

    static func applyExponentialSmoothing(frames: [Frame], alpha: Float = 0.8) -> [Frame] {
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

    private static func jointDistance(joint1: simd_float4x4, joint2: simd_float4x4) -> Float {
        var totalDistance: Float = 0.0

        // Calculate translational distance
        let translation1 = joint1.columns.3
        let translation2 = joint2.columns.3

        let dx = Float(translation1.x - translation2.x)
        let dy = Float(translation1.y - translation2.y)
        let dz = Float(translation1.z - translation2.z)

        totalDistance += sqrt(max(0, dx*dx + dy*dy + dz*dz)) // Ensure non-negative inside sqrt

        // Calculate rotational distance (angle between two rotation matrices)
        let rotation1 = simd_quatf(joint1)
        let rotation2 = simd_quatf(joint2)
        let dotProduct = dot(rotation1.vector, rotation2.vector)
        let clampedDotProduct = min(max(dotProduct, -1), 1) // Clamp between -1 and 1
        let angleBetweenQuaternions = 2 * acos(abs(clampedDotProduct))
        totalDistance += Float(angleBetweenQuaternions)

        return totalDistance
    }

    static func dtw(x1: [Frame], x2: [Frame]) -> [Float] {
        let n1 = x1.count
        let n2 = x2.count
        let jointCount = x1.first?.count ?? 0

        var dtwResults = Array(repeating: Float(0), count: jointCount)

        for jointIndex in 0..<jointCount {
            var row0 = Array(repeating: Float.infinity, count: n2 + 1)
            row0[0] = 0
            var row1 = Array(repeating: Float(0), count: n2 + 1)

            for i in 0..<n1 {
                row1[0] = .infinity

                var lastValue = Float.infinity

                for j in 0..<n2 {
                    let cost = jointDistance(joint1: x1[i][jointIndex], joint2: x2[j][jointIndex])

                    let minimum = min(min(row0[j] + cost, row0[j + 1] + cost), lastValue + cost)
                    lastValue = minimum
                    row1[j + 1] = lastValue
                }

                swap(&row0, &row1)
            }

            dtwResults[jointIndex] = row0[n2]
        }

        return dtwResults
    }

}
