//
//  IterationResults.swift
//  VirtualTrainer
//
//  Created by Anastasia Holovash on 05.06.2022.
//

import Foundation

struct IterationResults {
    let number: Int
    let score: Float
    let speed: Float

    var speedDescription: String {
        switch speed {
        case 0.9...1.1:
            return "Нормальна швидкість"

        case ...0.9:
            return "Швидше у \((1 / speed).roundedToTwoDigits) разів"

        case 1.1...:
            return "Повільніше у \(speed.roundedToTwoDigits) разів"

        default:
            return ""
        }
    }

    var normalisedScore: Float {
        (score - 0.5) / 0.5
    }

    var scoreDescription: String {
        return "\(Int(normalisedScore * 100))%"
    }

    var quality: String {
        return "Чудово"
    }
}

extension Float {

    var roundedToTwoDigits: Float {
        (self * 100).rounded() / 100
    }

}

let iterationResultsMock = IterationResults(number: 3, score: 0.9, speed: 0.9)
