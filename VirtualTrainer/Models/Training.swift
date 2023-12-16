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
    var iterations: [IterationResults]
    var startTime: Date
    var endTime: Date
}

extension Training {

    var iterationsNumber: Int {
        iterations.count
    }

    var score: Float {
        iterations.reduce(0.0) { $0 + $1.normalisedQuality } / Float(iterationsNumber)
    }

    var scoreDescription: String {
        guard !iterations.isEmpty else {
            return "0%"
        }
        return "\(Int(score.roundedToTwoDigits * 100))%"
    }

    var duration: String {
        let differenceInSeconds = endTime.timeIntervalSince(startTime)
        return dateFormatter.string(from: differenceInSeconds) ?? ""
    }

    init(with exercise: Exercise) {
        self.exercise = exercise
        self.iterations = []
        self.startTime = Date()
        self.endTime = Date()
    }

    mutating func update(with iterations: [IterationResults]) {
        self.iterations = iterations
    }

}

private extension Float {

    var roundedToTwoDigits: Float {
        (self * 100).rounded() / 100
    }

}
