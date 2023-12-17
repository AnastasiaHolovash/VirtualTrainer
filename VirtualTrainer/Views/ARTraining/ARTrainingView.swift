//
//  ARTrainingView.swift
//  VirtualTrainer
//
//  Created by Anastasia Holovash on 06.06.2022.
//

import SwiftUI
import RealityKit
import ARKit
import Combine
import Vision

struct ARTrainingView: View {
    @StateObject private var viewModel: ARTrainingViewModel

    init(with exercise: Exercise) {
        _viewModel = StateObject(wrappedValue: ARTrainingViewModel(exercise: exercise))
    }

    var body: some View {
        ZStack {
            ARTrackingViewContainer(
                exercise: viewModel.exercise,
                isRecording: $viewModel.isRecording,
                currentResults: $viewModel.currentResults,
                iterations: $viewModel.iterations
            )
            .edgesIgnoringSafeArea(.all)

            ARTrainingOverlayView(
                currentResults: $viewModel.currentResults,
                currentTraining: viewModel.currentTraining
            )
            .onChange(of: viewModel.currentResults.playPauseButtonState) {
                viewModel.handlePlayPauseButtonChange()
            }
            .onChange(of: viewModel.timerValue) {
                viewModel.handleTimerValueChange()
            }
            .onChange(of: viewModel.iterations) {
                viewModel.handleIterationsChange()
            }
            .onChange(of: viewModel.isRecording) {
                viewModel.handleRecordingStateChange()
            }
        }
        .onAppear {
            viewModel.currentResults.timer = GlobalConstants.timerStartTime
        }
    }
}



class ARTrainingViewModel: ObservableObject {
    @Published var timerValue: Int = GlobalConstants.timerStartTime
    @Published var isRecording: Bool = false
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
            // Logic for what should happen when the timer reaches 0
            // e.g., automatically start recording
            isRecording = true
            startTimeCounter()
        }
    }

    func handleIterationsChange() {
        currentTraining.iterations = iterations
        // Add any additional logic needed when iterations change
    }

    func handleRecordingStateChange() {
        if isRecording {
            currentTraining.startTime = Date()
            startTimeCounter()
        } else {
            currentTraining.endTime = Date()
            stopTimeCounter()
            // Logic for what should happen when recording stops
            // e.g., process the recorded data
        }
    }

    // MARK: - Timer and State Handling Methods

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
        isRecording.toggle()
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
