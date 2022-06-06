//
//  Training.swift
//  VirtualTrainer
//
//  Created by Anastasia Holovash on 06.06.2022.
//

import Foundation

struct Training {
    let id = UUID()
    let exercise: Exercise
    let iterations: [IterationResults]
    let duration: Int
}

extension Training {

    var iterationsNumber: Int {
        iterations.count
    }

    var score: Float {
        iterations.reduce(0.0) { $0 + $1.normalisedScore } / Float(iterationsNumber)
    }

    var scoreDescription: String {
        return "\(Int(score.roundedToTwoDigits * 100))%"
    }
}

extension Int {

    var durationDescription: String {
        let date = Date(timeIntervalSince1970: TimeInterval(self / 1000))

        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}
