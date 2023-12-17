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

    func compare(to arraySimd4x4: Frame) -> Float {
        (
            100
            - ARDataProcessingAlgorithms.calculateFrameDistance(frame1: self, frame2: arraySimd4x4)
            / GlobalConstants.maxErrorPossible
        )
        / 100
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

extension Collection {

    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }

}
