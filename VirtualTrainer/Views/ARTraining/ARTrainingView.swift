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
            ARTrackingViewContainer(arTrainingViewModel: viewModel)
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
            .onChange(of: viewModel.isTrainingInProgress) {
                viewModel.handleRecordingStateChange()
            }
        }
        .onAppear {
            viewModel.currentResults.timer = GlobalConstants.timerStartTime
        }
    }
    
}
