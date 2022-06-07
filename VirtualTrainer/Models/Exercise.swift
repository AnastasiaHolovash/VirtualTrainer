//
//  Exercise.swift
//  VirtualTrainer
//
//  Created by Anastasia Holovash on 03.06.2022.
//

import Foundation
import ARKit

struct Exercise: Identifiable {
    let id: String
    let name: String
    let complexity: Complexity
    let recommendations: String
    let image: String = ""
    let frames: [FirebaseFrame]

    var simdFrames: Frames {
        frames.map { $0.simdArray }
    }
}

struct FirebaseFrame: Codable {
    var values: [FirebaseSIMD4x4]

    var simdArray: Frame {
        values.map { $0.simd }
    }

    init(simdArray: [simd_float4x4]) {
        self.values = simdArray.map(FirebaseSIMD4x4.init(simd:))
    }
}

struct FirebaseSIMD4x4: Codable {
    let column0: [Float]
    let colomn1: [Float]
    let colomn2: [Float]
    let colomn3: [Float]

    init(simd: simd_float4x4) {
        column0 = simd.columns.0.array
        colomn1 = simd.columns.1.array
        colomn2 = simd.columns.2.array
        colomn3 = simd.columns.3.array
    }

    var simd: simd_float4x4 {
        return simd_float4x4.init([column0.simd4, colomn1.simd4, colomn2.simd4, colomn3.simd4])
    }
}

extension Array where Element == Float {
    var simd4: SIMD4<Float> {
        SIMD4(x: self[0], y: self[1], z: self[2], w: self[3])
    }
}

extension SIMD4 where Scalar == Float {
    var array: [Float] {
        [x, y, z, w]
    }

//    var
}

extension Exercise: Codable {

}

enum Complexity: String, Codable {
    case easy
    case normal
    case hard

    var description: String {
        switch self {
        case .easy:
            return "♦ Легко"
        case .normal:
            return "♦♦ Нормально"
        case .hard:
            return "♦♦♦ Важко"
        }
    }
}


let exerciseMock = Exercise(
    id: UUID().uuidString,
    name: "Squatting",
    complexity: .normal,
    recommendations: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.",
//    image: "squatting",
    frames: []
)
