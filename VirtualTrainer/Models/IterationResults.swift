//
//  IterationResults.swift
//  VirtualTrainer
//
//  Created by Anastasia Holovash on 05.06.2022.
//

import Foundation

struct IterationResults: Equatable {
    let number: Int
    let score: IterationScore
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

    var normalisedQuality: Float {
        score.total > 0 ? score.total : 0
    }

    var scoreDescription: String {
        return "\(Int(normalisedQuality * 100))%"
    }

    var quality: Quality {
        switch normalisedQuality {
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

    var errorsDescription: String? {
        let joints = score.joints.enumerated().compactMap { index, jointScore in
            jointScore > 100 ? BodyJoint.allCases[index] : nil
        }

        var jointGroupCounts = [String: [BodyJoint]]()
        for joint in joints {
            for (groupLabel, groupJoints) in IterationResults.jointGroups {
                if groupJoints.contains(joint) {
                    jointGroupCounts[groupLabel, default: []].append(joint)
                    break
                }
            }
        }

        var textJoints = [String]()
        textJoints += jointGroupCounts.filter { $1.count >= 2 }.keys

        let individualJoints = jointGroupCounts
            .filter { $1.count < 2 }
            .values
            .flatMap { $0 }
            .map { $0.rawValue }

        textJoints += individualJoints

        guard !textJoints.isEmpty else {
            return nil
        }

        var fullResult = textJoints.reduce("Неправильне положення:") { partialResult, jointResult in
            partialResult + " \(jointResult),"
        }
        fullResult.removeLast()
        return fullResult
    }

}

extension IterationResults {

    enum BodyJoint: String, CaseIterable {
        case hips = "стегон"
        case leftUpLeg = "стегна лівої ноги"
        case leftLeg = "коліна лівої ноги"
        case leftFoot = "стопи лівої ноги"
        case rightUpLeg = "стегна правої ноги"
        case rightLeg = "коліна правої ноги"
        case rightFoot = "стопи правої ноги"
        case lowerSpine = "нижньої частини спини"
        case middleSpine = "середньої частини спини"
        case upperSpine = "верхньої частини спини"
        case leftShoulder = "плеча лівої руки"
        case leftElbow = "ліктя лівої руки"
        case leftForearm = "передпліччя лівої руки"
        case leftHand = "кисті лівої руки"
        case rightShoulder = "плеча правої руки"
        case rightElbow = "ліктя правої руки"
        case rightForearm = "передпліччя правої руки"
        case rightHand = "кисті правої руки"
    }

    static let jointGroups: [String: [BodyJoint]] = [
        "лівої ноги": leftLeg,
        "правої ноги": rightLeg,
        "спини": spine,
        "лівої руки": leftArm,
        "правої руки": rightArm,
        "стегон": hips
    ]

    static let leftLeg: [BodyJoint] = [
        .leftUpLeg,
        .leftLeg,
        .leftFoot
    ]

    static let rightLeg: [BodyJoint] = [
        .rightUpLeg,
        .rightLeg,
        .rightFoot
    ]

    static let spine: [BodyJoint] = [
        .lowerSpine,
        .middleSpine,
        .upperSpine
    ]

    static let leftArm: [BodyJoint] = [
        .leftShoulder,
        .leftElbow,
        .leftForearm,
        .leftHand
    ]

    static let rightArm: [BodyJoint] = [
        .rightShoulder,
        .rightElbow,
        .rightForearm,
        .rightHand
    ]

    static let hips: [BodyJoint] = [
        .hips
    ]

    enum Quality: String {
        case veryGood = "Чудово"
        case good = "Добре"
        case normal = "Нормально"
        case notGood = "Погано"
    }

}
