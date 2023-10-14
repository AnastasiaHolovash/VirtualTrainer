//
//  ProcessingARDataExtension.swift
//  VirtualTrainer
//
//  Created by Anastasia Holovash on 06.06.2022.
//

import SwiftUI
import RealityKit
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
        let resultArray = self.enumerated().map { index, simd4x4 -> Float in
            let difference = simd4x4 - arraySimd4x4[index]
            let simd4x4ResultArray = difference.allValues.map { value in
                1 - abs(value) / 2
            }

//             ------ Matrix Printing  ------
//            print("\nComparison Value:")
//            comparisonFrameValue.printf()
//            print("\nCurrent Value:")
//            jointModelTransformsCurrent.printf()
//            print("\nDifference:")
//            difference.printf()
//             ------------------------------

            return simd4x4ResultArray.averageValue
        }
        return resultArray.averageValue
    }

    func printf() {
        self.forEach { $0.printf() }
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
