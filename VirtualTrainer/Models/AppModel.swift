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
        iterations: [iterationResultsMock, iterationResultsMock,iterationResultsMock],
        duration: 4855
    )

    var apiClientCancellable: AnyCancellable? = nil

    init() {
        apiClientCancellable = apiClient.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }
}
