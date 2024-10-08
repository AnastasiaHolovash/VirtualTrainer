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
    
    @State private var timerValue: Int = GlobalConstants.timerStartTime
    @State private var timerCancellable: AnyCancellable? = nil

    @State var isRecording: Bool = false
    @State var recordingData = RecordingData()
    @Binding var exercise: NewExercise
    
    var body: some View {
        ZStack {
            ARRecordingViewContainer(
                exercise: $exercise,
                isRecording: $isRecording,
                recordingData: $recordingData
            )
            .edgesIgnoringSafeArea(.all)

            ARRecordingOverlayView(model: $recordingData)
                .onChange(of: recordingData.playPauseButtonState, { _, newValue in
                    switch newValue {
                    case .play:
                        startTimer()

                    case .pause:
                        isRecording.toggle()
                        stopTimer()
                    }
                })
                .onChange(of: timerValue) { _, newValue in
                    recordingData.timer = newValue
                }
        }
        .onAppear {
            recordingData.timer = GlobalConstants.timerStartTime
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
                    isRecording.toggle()
                    
                default:
                    timerValue -= 1
                }
            })
    }
    
    private func stopTimer() {
        timerCancellable?.cancel()
    }
}
