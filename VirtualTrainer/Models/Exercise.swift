//
//  Exercise.swift
//  VirtualTrainer
//
//  Created by Anastasia Holovash on 03.06.2022.
//

import Foundation

struct Exercise: Identifiable {
    let id: String
    let name: String
    let complexity: Complexity
    let recommendations: String
    let image: String
    let frames: [Frame]

    struct Frame: Codable {
        var values: [SIMD4x4]
    }

    struct SIMD4x4: Codable {
        let column0: [Float]
        let colomn1: [Float]
        let colomn2: [Float]
        let colomn3: [Float]
    }

    struct SIMD4: Codable {
        let values: [Float]
    }
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

struct NewExercise: Identifiable {
    let id = UUID()
    var name: String = ""
    var complexity: Complexity?
    var recommendations: String = ""
    var image: String?
    var frames: Frames = []
}

let exerciseMock = Exercise(
    id: UUID().uuidString,
    name: "Squatting",
    complexity: .normal,
    recommendations: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.",
    image: "squatting",
    frames: []
)
