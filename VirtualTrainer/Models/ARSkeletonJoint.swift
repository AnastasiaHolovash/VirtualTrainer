//
//  ARSkeletonJointName.swift
//  VirtualTrainer
//
//  Created by Anastasia Holovash on 05.06.2022.
//

import Foundation

///ARSkeleton.JointName only contains 8 of these but this includes all of them :)
///
///Includes 91 joints total, 28 tracked.
///- Use ThreeDBodyJoint.allCases to access an array of all joints
public enum ARSkeletonJoint: Int, CaseIterable {

//Not-indented joints are tracked (their transforms follow the person's body).
//Indented joints are untracked (they always maintain the same transform relative to their parent joint).
    case root = 0
    case hips_joint = 1 //Could be redundant with root since root is at the hip.
    case left_upLeg_joint = 2
    case left_leg_joint = 3
    case left_foot_joint = 4
        case left_toes_joint = 5
        case left_toesEnd_joint = 6
    case right_upLeg_joint = 7
    case right_leg_joint = 8
    case right_foot_joint = 9
        case right_toes_joint = 10
        case right_toesEnd_joint = 11
    case spine_1_joint = 12
    case spine_2_joint = 13
    case spine_3_joint = 14
    case spine_4_joint = 15
    case spine_5_joint = 16
    case spine_6_joint = 17
    case spine_7_joint = 18
    case left_shoulder_1_joint = 19
    case left_arm_joint = 20
    case left_forearm_joint = 21
    case left_hand_joint = 22
        case left_handIndexStart_joint = 23
        case left_handIndex_1_joint = 24
        case left_handIndex_2_joint = 25
        case left_handIndex_3_joint = 26
        case left_handIndexEnd_joint = 27
        case left_handMidStart_joint = 28
        case left_handMid_1_joint = 29
        case left_handMid_2_joint = 30
        case left_handMid_3_joint = 31
        case left_handMidEnd_joint = 32
        case left_handPinkyStart_joint = 33
        case left_handPinky_1_joint = 34
        case left_handPinky_2_joint = 35
        case left_handPinky_3_joint = 36
        case left_handPinkyEnd_joint = 37
        case left_handRingStart_joint = 38
        case left_handRing_1_joint = 39
        case left_handRing_2_joint = 40
        case left_handRing_3_joint = 41
        case left_handRingEnd_joint = 42
        case left_handThumbStart_joint = 43
        case left_handThumb_1_joint = 44
        case left_handThumb_2_joint = 45
        case left_handThumbEnd_joint = 46
    case neck_1_joint = 47
    case neck_2_joint = 48
    case neck_3_joint = 49
    case neck_4_joint = 50
    case head_joint = 51
        case jaw_joint = 52
        case chin_joint = 53
        case left_eye_joint = 54
        case left_eyeLowerLid_joint = 55
        case left_eyeUpperLid_joint = 56
        case left_eyeball_joint = 57
        case nose_joint = 58
        case right_eye_joint = 59
        case right_eyeLowerLid_joint = 60
        case right_eyeUpperLid_joint = 61
        case right_eyeball_joint = 62
    case right_shoulder_1_joint = 63
    case right_arm_joint = 64
    case right_forearm_joint = 65
    case right_hand_joint = 66
        case right_handIndexStart_joint = 67
        case right_handIndex_1_joint = 68
        case right_handIndex_2_joint = 69
        case right_handIndex_3_joint = 70
        case right_handIndexEnd_joint = 71
        case right_handMidStart_joint = 72
        case right_handMid_1_joint = 73
        case right_handMid_2_joint = 74
        case right_handMid_3_joint = 75
        case right_handMidEnd_joint = 76
        case right_handPinkyStart_joint = 77
        case right_handPinky_1_joint = 78
        case right_handPinky_2_joint = 79
        case right_handPinky_3_joint = 80
        case right_handPinkyEnd_joint = 81
        case right_handRingStart_joint = 82
        case right_handRing_1_joint = 83
        case right_handRing_2_joint = 84
        case right_handRing_3_joint = 85
        case right_handRingEnd_joint = 86
        case right_handThumbStart_joint = 87
        case right_handThumb_1_joint = 88
        case right_handThumb_2_joint = 89
        case right_handThumbEnd_joint = 90

    ///Use this function to determine if a particular joint is tracked or untracked.
    public func isTracked() -> Bool {
        return GlobalConstants.trackingJointNames.contains(self)
    }
}
