//
//  AppModel.swift
//  VirtualTrainer
//
//  Created by Anastasia Holovash on 05.06.2022.
//

import SwiftUI
import Combine

class AppModel: ObservableObject {

    @Published var showNav: Bool = true

    @Published var showAddExercise: Bool = false

    @Published var showDetail: Bool = false
    @Published var selectedExercise: Int = 0

    @Published var showResults: Bool = false
    @Published var currentTraining: Training = Training(
        exercise: exerciseMock,
        iterations: [iterationResultsMock, iterationResultsMock,iterationResultsMock],
        duration: 4855
    )

    @Published var exercises: [Exercise] = [
        Exercise(
            index: 1,
            name: "Squatting",
            complexity: .normal,
            recommendations: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.",
            image: "squatting",
            frames: []
        ),
        Exercise(
            index: 2,
            name: "Other Exercise",
            complexity: .normal,
            recommendations: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.",
            image: "squatting",
            frames: []
        )
    ]
}
