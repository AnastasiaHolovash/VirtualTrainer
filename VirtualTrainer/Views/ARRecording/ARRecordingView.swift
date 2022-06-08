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
    
    @State var timerValue: Int = GlobalConstants.timerStartTime
    
    @State var timerCancellable: AnyCancellable? = nil
    @State var isRecording: Bool = false
    @State var recordingData = RecordingData()

    @Binding var exercise: NewExercise

    // DEBUG
    @State var isReviewing: Bool = false
    let toPresent = UIHostingController(rootView: AnyView(EmptyView()))
    @State private var vURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("test.mov")
    
    var body: some View {
        ZStack {
            ARViewContainer(
                exercise: $exercise,
                isRecording: $isRecording,
                recordingData: $recordingData
            )
            .edgesIgnoringSafeArea(.all)

//            if isReviewing {
//                AVPlayerView(videoURL: self.$vURL).transition(.move(edge: .bottom)).edgesIgnoringSafeArea(.all)
//            }

            ARRecordingOverlayView(model: $recordingData)
                .onChange(of: recordingData.playPauseButtonState, perform: { newValue in
                    switch newValue {
                    case .play:
                        startTimer()
                        
                    case .pause:
                        isRecording.toggle()
                        stopTimer()
                    }
                })
                .onChange(of: timerValue) { newValue in
                    recordingData.timer = newValue
                }
        }
//        .onChange(of: isReviewing, perform: { newValue in
//            if newValue {
//                model.apiClient.uploadVideoWithPhoto()
//            }
//        })
        .onAppear {
            recordingData.timer = GlobalConstants.timerStartTime
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
