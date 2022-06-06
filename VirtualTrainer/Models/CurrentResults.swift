//
//  CurrentResults.swift
//  VirtualTrainer
//
//  Created by Anastasia Holovash on 06.06.2022.
//

import Foundation

struct CurrentResults {
    var quality: String = ""
    var speed: Float = 0.0
    var iterationCount: Int = 0
    var seconds: Int = 0
    var timer: Int = 0
    var playPauseButtonState: PlayPauseButtonState = .pause
}

extension CurrentResults {

    mutating func update(
        with numberOfIteration: Int,
        iteration: IterationResults
    ) {
        iterationCount = numberOfIteration
        speed = iteration.speed
        quality = iteration.quality
    }

}
