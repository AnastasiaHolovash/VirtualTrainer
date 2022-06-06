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

    @State var jointModelTransforms: Frame = []
    @State var timerValue: Int = GlobalConstants.timerStartTime

    @State var timerCancellable: AnyCancellable? = nil
    @State var isRecording: Bool = false
    @State var buttonState: ButtonState = .start
    @State var comparisonFrameValue: Frame = []

    @State var currentResults: CurrentResults

    var body: some View {
        ZStack {
            ARViewContainer(
                jointModelTransforms: $jointModelTransforms,
                isRecording: $isRecording,
                currentResults: $currentResults,
                comparisonFrameValue: $comparisonFrameValue
            )
            .edgesIgnoringSafeArea(.all)

            ARTrainingOverlayView(model: $currentResults)
                .onChange(of: currentResults.playPauseButtonState, perform: { newValue in
                    switch newValue {
                    case .play:
                        startTimer()

                    case .pause:
                        isRecording.toggle()
                        stopTimer()
                    }
                })
                .onChange(of: timerValue) { newValue in
                    currentResults.timer = newValue
                }
        }
        .onAppear {
            currentResults.timer = GlobalConstants.timerStartTime
        }
    }

    func startTimer() {
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

    func stopTimer() {
        timerCancellable?.cancel()
    }
}

extension ARTrainingView {

    enum ButtonState: String {
        case start
        case stop

        mutating func toggle() {
            switch self {
            case .start:
                self = .stop

            case .stop:
                self = .start
            }
        }
    }

}
