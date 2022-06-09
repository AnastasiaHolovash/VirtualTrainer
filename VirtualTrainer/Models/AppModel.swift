//
//  AppModel.swift
//  VirtualTrainer
//
//  Created by Anastasia Holovash on 05.06.2022.
//

import SwiftUI
import Combine

class AppModel: ObservableObject {

    @Published var apiClient: FirestoreClient = FirestoreClient()

    @Published var showNav: Bool = true

    @Published var showAddExercise: Bool = false

    @Published var showDetail: Bool = false
    @Published var selectedExercise: String?

    @Published var showResults: Bool = false
    @Published var startTraining: Bool = false
    @Published var currentTraining: Training = Training(
        exercise: exerciseMock,
        iterations: [iterationResultsMock1, iterationResultsMock2, iterationResultsMock3, iterationResultsMock4,
                     iterationResultsMock5, iterationResultsMock6, iterationResultsMock7, iterationResultsMock8],
        duration: 48755555
    )

    var apiClientCancellable: AnyCancellable? = nil

    init() {
        apiClientCancellable = apiClient.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }
}

let iterationResultsMock1 = IterationResults(number: 1, score: 0.97, speed: 0.9)
let iterationResultsMock2 = IterationResults(number: 2, score: 0.96, speed: 1.3)
let iterationResultsMock3 = IterationResults(number: 3, score: 0.96, speed: 1.2)
let iterationResultsMock4 = IterationResults(number: 4, score: 0.95, speed: 1.0)
let iterationResultsMock5 = IterationResults(number: 5, score: 0.90, speed: 1.1)
let iterationResultsMock6 = IterationResults(number: 6, score: 0.95, speed: 1.2)
let iterationResultsMock7 = IterationResults(number: 7, score: 0.95, speed: 1.3)
let iterationResultsMock8 = IterationResults(number: 8, score: 0.93, speed: 1.3)
