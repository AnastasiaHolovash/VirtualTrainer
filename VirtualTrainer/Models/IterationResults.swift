//
//  IterationResults.swift
//  VirtualTrainer
//
//  Created by Anastasia Holovash on 05.06.2022.
//

import Foundation

struct IterationResults: Equatable {
    let number: Int
    let score: Float
    let speed: Float

    var speedDescription: String {
        switch speed {
        case 0.9...1.1:
            return "Нормальна швидкість"

        case 1.1...:
            return "Швидше на \(Int((speed - 1) * 100))%"

        case ...0.9:
            return "Повільніше на \(Int((1 - speed) * 100))%"

        default:
            return ""
        }
    }

//    var persent

    var normalisedScore: Float {
        (score - 0.5) / 0.5
    }

    var scoreDescription: String {
        return "\(Int(normalisedScore * 100))%"
    }

    var quality: Quality {
        let some = abs(speed - 1.0)
        let resultValue = normalisedScore - some

        switch resultValue {
        case 0.9...1.0:
            return .veryGood

        case 0.8...0.9:
            return .good

        case 0.7...0.8:
            return .normal

        default:
            return .notGood
        }
    }
}

extension IterationResults {

    enum Quality: String {
        case veryGood = "Чудово"
        case good = "Добре"
        case normal = "Нормально"
        case notGood = "Погано"
    }

}

extension Float {

    var roundedToTwoDigits: Float {
        (self * 100).rounded() / 100
    }

}
