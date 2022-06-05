//
//  IterationResults.swift
//  VirtualTrainer
//
//  Created by Anastasia Holovash on 05.06.2022.
//

import Foundation

struct IterationResults {
    let score: Float
    let speed: Float

    var speedDescription: String {
        switch speed {
        case 0.9...1.1:
            return "Good"

        case ...0.9:
            return "Faster on \(round(1 / speed * 100) / 100) times"

        case 1.1...:
            return "Slower on \(round(speed * 100) / 100) times"

        default:
            return ""
        }
    }
}
