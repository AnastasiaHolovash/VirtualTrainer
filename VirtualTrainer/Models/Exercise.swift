//
//  Exercise.swift
//  VirtualTrainer
//
//  Created by Anastasia Holovash on 03.06.2022.
//

import Foundation

struct Exercise: Identifiable {
    let id = UUID()
    let index: Int
    let name: String
    let complexity: Complexity
    let recommendations: String
    let image: String
    let frames: Frames
}

enum Complexity {
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
    index: 0,
    name: "Squatting",
    complexity: .normal,
    recommendations: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.",
    image: "squatting",
    frames: []
)
