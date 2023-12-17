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

struct ARTrainingView : View {

    @State private var timerValue: Int = GlobalConstants.timerStartTime

    @State private var timerCancellable: AnyCancellable? = nil
    @State private var timeCounterCancellable: AnyCancellable? = nil
    @State var isRecording: Bool = false
    @State var iterations: [IterationResults] = []

    @State var currentResults = CurrentResults()
    @State var currentTraining: Training

    let exercise: Exercise

    init(with exercise: Exercise) {
        self.exercise = exercise
        self._currentTraining = .init(wrappedValue: Training(with: exercise))
    }

    var body: some View {
        ZStack {
            ARTrackingViewContainer(
                exercise: exercise,
                isRecording: $isRecording,
                currentResults: $currentResults,
                iterations: $iterations
            )
            .edgesIgnoringSafeArea(.all)

            ARTrainingOverlayView(
                currentResults: $currentResults,
                currentTraining: currentTraining
            )
            .onChange(of: currentResults.playPauseButtonState) { _, newValue in
                switch newValue {
                case .play:
                    startTimer()

                case .pause:
                    stopTimer()
                }
            }
            .onChange(of: timerValue) { _, newValue in
                currentResults.timer = newValue
            }
            .onChange(of: iterations) { _, newValue in
                currentTraining.iterations = newValue
            }
            .onChange(of: isRecording) { _, newValue in
                switch isRecording {
                case true:
                    currentTraining.startTime = Date()
                    startTimeCounter()

                case false:
                    currentTraining.endTime = Date()
                    stopTimeCounter()
                }
            }
        }
        .onAppear {
            currentResults.timer = GlobalConstants.timerStartTime
        }
    }

    private func startTimer() {
        timerCancellable = Timer.publish(every: 1, on: .main, in: .default)
            .autoconnect()
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { _ in
                switch timerValue {
                case 0:
                    timerValue = GlobalConstants.timerStartTime + 1
                    stopTimer()

                default:
                    timerValue -= 1
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
            .sink(receiveValue: { _ in
                currentResults.currentTime = Date()
            })
    }

    private func stopTimeCounter() {
        timeCounterCancellable?.cancel()
    }

}
