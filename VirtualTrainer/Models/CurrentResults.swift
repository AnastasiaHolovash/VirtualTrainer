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
    var startTime: Date = Date()
    var currentTime: Date = Date()
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
        quality = iteration.quality.rawValue
    }

    var currentSecondsFormated: String {
        let timeInterval: TimeInterval = currentTime.timeIntervalSince(startTime)
        return dateFormatter.string(from: timeInterval) ?? ""
    }

    var speedState: SpeedState? {
        print(speed)
        switch speed {
        case 0.01...0.9:
            return .fast

        case 0.9...1.1:
            return .normal

        case 1.1...:
            return .slow

        default:
            return .none
        }
    }

    enum SpeedState {
        case fast
        case normal
        case slow
    }

}


var dateFormatter: DateComponentsFormatter = {
    let formatter = DateComponentsFormatter()
    formatter.unitsStyle = .positional
    formatter.allowedUnits = [ .hour, .minute, .second ]
    formatter.zeroFormattingBehavior = [ .pad ]
    formatter.allowsFractionalUnits = true
    return formatter
}()
