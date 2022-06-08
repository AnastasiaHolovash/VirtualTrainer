//
//  NewExercise.swift
//  VirtualTrainer
//
//  Created by Anastasia Holovash on 09.06.2022.
//

import Foundation

struct NewExercise: Encodable {

    var name: String = ""
    var complexity: Complexity = .easy
    var recommendations: String = ""
    var localVideoURL: URL?
    var frames: Frames = []

    enum CodingKeys: String, CodingKey {
        case name
        case complexity
        case recommendations
        case frames
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try  container.encode(complexity, forKey: .complexity)
        try container.encode(recommendations, forKey: .recommendations)
        let firebaseFrames = frames.map { FirebaseFrame(simdArray: $0) }
        try  container.encode(firebaseFrames, forKey: .frames)
    }
}
