//
//  NewExerciseRequest.swift
//  VirtualTrainer
//
//  Created by Anastasia Holovash on 09.06.2022.
//

import Foundation

struct NewExerciseRequest: Encodable {

    var id: String
    var videoURL: URL
    var photoURL: URL
    var newExercise: NewExercise

    enum CodingKeys: String, CodingKey {
        case id
        case videoURL
        case photoURL
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(videoURL, forKey: .videoURL)
        try container.encode(photoURL, forKey: .photoURL)
        try newExercise.encode(to: encoder)
    }

}
