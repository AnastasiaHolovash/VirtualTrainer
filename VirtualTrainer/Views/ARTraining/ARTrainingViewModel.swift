//
//  ARTrainingViewModel.swift
//  VirtualTrainer
//
//  Created by Anastasia Holovash on 17.12.2023.
//

import Foundation
import Combine

class ARTrainingViewModel: ObservableObject {
    @Published var timerValue: Int = GlobalConstants.timerStartTime
    @Published var isTrainingInProgress: Bool = false
    @Published var iterations: [IterationResults] = []
    @Published var currentResults = CurrentResults()
    @Published var currentTraining: Training

    private var timerCancellable: AnyCancellable?
    private var timeCounterCancellable: AnyCancellable?
    let exercise: Exercise

    init(exercise: Exercise) {
        self.exercise = exercise
        self.currentTraining = Training(with: exercise)
    }

    // MARK: - State Handling Methods

    func handlePlayPauseButtonChange() {
        switch currentResults.playPauseButtonState {
        case .play:
            startTimer()

        case .pause:
            stopTimer()
        }
    }

    func handleTimerValueChange() {
        currentResults.timer = timerValue
        if timerValue == 0 {
            isTrainingInProgress = true
            startTimeCounter()
        }
    }

    func handleIterationsChange() {
        currentTraining.iterations = iterations
    }

    func handleRecordingStateChange() {
        if isTrainingInProgress {
            currentTraining.startTime = Date()
            startTimeCounter()
        } else {
            currentTraining.endTime = Date()
            stopTimeCounter()
        }
    }

    // MARK: - Timer Methods

    private func startTimer() {
        timerCancellable = Timer.publish(every: 1, on: .main, in: .default)
            .autoconnect()
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] _ in
                switch self?.timerValue {
                case 0:
                    self?.timerValue = GlobalConstants.timerStartTime + 1
                    self?.stopTimer()

                default:
                    self?.timerValue -= 1
                }
            })
    }

    private func stopTimer() {
        timerCancellable?.cancel()
        isTrainingInProgress.toggle()
    }

    private func startTimeCounter() {
        currentResults.startTime = Date()
        currentResults.currentTime = Date()
        timeCounterCancellable = Timer.publish(every: 1, on: .main, in: .default)
            .autoconnect()
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] _ in
                self?.currentResults.currentTime = Date()
            })
    }

    private func stopTimeCounter() {
        timeCounterCancellable?.cancel()
    }

}
