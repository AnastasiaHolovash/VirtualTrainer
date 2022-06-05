//
//  GlobalConstants.swift
//  VirtualTrainer
//
//  Created by Anastasia Holovash on 05.06.2022.
//

import Foundation

enum GlobalConstants {
    static let mode: Mode = .training

    static let startStopMovementRange: ClosedRange<Float> = 0...0.97
    static let closeToEqualRange: ClosedRange<Float> = 0.9...1
    static let veryCloseToEqualRange: ClosedRange<Float> = 0.98...1
    static let characterOffset: SIMD3<Float> = [-0.5, 0, 0]
    static let characterScale: SIMD3<Float> = [1.0, 1.0, 1.0]
    static let framesComparisonAccuracy: Float = 0.2
    static let couldDetectEndOfIterationIndicator: Float = 0.5
    /// Number of frames in static position
    static let staticPositionIndicator: Int = 4
    /// Based on difference between moment of detection and recorded frames
    static let exerciseFramesFirstIndex: Int = 1

    static let trackingJointNames : Set<ARSkeletonJoint> = [
        .root,
        .hips_joint,
        .left_upLeg_joint,
        .left_leg_joint,
        .left_foot_joint,
        .right_upLeg_joint,
        .right_leg_joint,
        .right_foot_joint,
        .spine_1_joint,
        .spine_2_joint,
        .spine_3_joint,
        .spine_4_joint,
        .spine_5_joint,
        .spine_6_joint,
        .spine_7_joint,
        .left_shoulder_1_joint,
        .left_arm_joint,
        .left_forearm_joint,
        .left_hand_joint,
//        .neck_1_joint,
//        .neck_2_joint,
//        .neck_3_joint,
//        .neck_4_joint,
//        .head_joint,
        .right_shoulder_1_joint,
        .right_arm_joint,
        .right_forearm_joint,
        .right_hand_joint
    ]

}

extension GlobalConstants {

    enum Mode {
        case recording
        case training
    }
    
}
