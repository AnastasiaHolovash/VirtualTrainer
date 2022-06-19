//
//  GlobalConstants.swift
//  VirtualTrainer
//
//  Created by Anastasia Holovash on 05.06.2022.
//

import Foundation

enum GlobalConstants {
    static let timerStartTime: Int = 3
    static let startStopMovementRange: ClosedRange<Float> = 0...0.995
    static let closeToEqualRange: ClosedRange<Float> = 0.9...1
    static let veryCloseToEqualRange: ClosedRange<Float> = 0.999...1
    static let characterOffset: SIMD3<Float> = [-0.5, 0, 0]
    static let characterScale: SIMD3<Float> = [1.0, 1.0, 1.0]
    static let framesComparisonAccuracy: Float = 0.2
    static let couldDetectEndOfIterationIndicator: Float = 0.5
    /// Number of frames in static position
    static let staticPositionIndicator: Int = 4
    /// Based on difference between moment of detection and recorded frames
    static let exerciseFramesFirstIndex: Int = 1

    static let trackingJointNames : [ARSkeletonJoint] = [
        .hips_joint,
        .left_upLeg_joint,
        .left_leg_joint,
        .left_foot_joint,
        .right_upLeg_joint,
        .right_leg_joint,
        .right_foot_joint,
        .spine_1_joint,
        .spine_4_joint,
        .spine_7_joint,
        .left_shoulder_1_joint,
        .left_arm_joint,
        .left_forearm_joint,
        .left_hand_joint,
        .right_shoulder_1_joint,
        .right_arm_joint,
        .right_forearm_joint,
        .right_hand_joint
    ]

}
