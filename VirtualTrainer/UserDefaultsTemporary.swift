//
//  UserDefaultsTemporary.swift
//  VirtualTrainer
//
//  Created by Anastasia Holovash on 01.06.2022.
//

import Foundation
import ARKit

class Defaults {

    public static let shared = Defaults()

    private init () { }

    let defaults = UserDefaults.standard

    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    func setExerciseFrames(_ frames: Frames) {
        guard let encoded = try? encoder.encode(frames) else {
            return
        }
        defaults.set(encoded, forKey: Key.exerciseFrames.rawValue)
    }

    func getExerciseFrames() -> Frames {
        guard let framesData = defaults.object(forKey: Key.exerciseFrames.rawValue) as? Data,
              let frames = try? decoder.decode(Frames.self, from: framesData)
        else {
            return []
        }
        return frames
    }

    enum Key: String {
        case exerciseFrames
    }
}
