//
//  ARRecordingView.swift
//  VirtualTrainer
//
//  Created by Anastasia Holovash on 06.06.2022.
//

import SwiftUI
import RealityKit
import ARKit
import Combine
import Vision

struct ARRecordingView: View {
    @StateObject private var viewModel = ARRecordingViewModel()
    @Binding var exercise: NewExercise

    var body: some View {
        ZStack {
            ARRecordingViewContainer(
                arRecordingViewModel: viewModel,
                exercise: $exercise
            )
            .edgesIgnoringSafeArea(.all)

            ARRecordingOverlayView(model: $viewModel.recordingData)
                .onChange(of: viewModel.recordingData.playPauseButtonState) {
                    viewModel.handlePlayPauseButtonChange()
                }
                .onChange(of: viewModel.timerValue) {
                    viewModel.recordingData.timer = viewModel.timerValue
                }
        }
        .onAppear {
            viewModel.recordingData.timer = GlobalConstants.timerStartTime
        }
    }
}

class ARRecordingViewModel: ObservableObject {
    @Published var timerValue: Int = GlobalConstants.timerStartTime
    @Published var isTrainingInProgress: Bool = false
    @Published var recordingData = RecordingData()

    private var timerCancellable: AnyCancellable?

    // MARK: - Timer Methods

    func startTimer() {
        timerCancellable = Timer.publish(every: 1, on: .main, in: .default)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateTimer()
            }
    }

    func stopTimer() {
        timerCancellable?.cancel()
    }

    func handlePlayPauseButtonChange() {
        switch recordingData.playPauseButtonState {
        case .play:
            startTimer()
       
        case .pause:
            isTrainingInProgress.toggle()
            stopTimer()
        }
    }

    // MARK: - Private Methods

    private func updateTimer() {
        if timerValue == 0 {
            timerValue = GlobalConstants.timerStartTime + 1
            stopTimer()
            isTrainingInProgress.toggle()
        } else {
            timerValue -= 1
        }
    }
}

