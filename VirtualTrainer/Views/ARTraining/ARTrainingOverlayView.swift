//
//  ARTrainingOverlayView.swift
//  VirtualTrainer
//
//  Created by Anastasia Holovash on 06.06.2022.
//

import SwiftUI

struct ARTrainingOverlayView: View {
    @Binding var currentResults: CurrentResults
    let currentTraining: Training

    var body: some View {
        ZStack {
            TimerView(currentResults: currentResults)

            ControlPanelView(
                currentResults: $currentResults,
                currentTraining: currentTraining
            )
        }
    }
}

struct TimerView: View {
    let currentResults: CurrentResults

    var body: some View {
        if currentResults.timer <= GlobalConstants.timerStartTime && currentResults.playPauseButtonState == .play {
            Text("\(currentResults.timer)")
                .animatableFont(size: 100, weight: .semibold)
                .timerStyle()
        }
    }
}

struct ControlPanelView: View {
    @Binding var currentResults: CurrentResults
    let currentTraining: Training

    var body: some View {
        VStack {
            HStack {
                Spacer()

                NavigationLink(
                    destination: TrainingResultView(training: currentTraining)
                        .navigationBarHidden(true),
                    label: {
                        DoneButton(currentTraining: currentTraining)
                    }
                )
            }

            Spacer()

            HStack(spacing: 8) {
                SpeedQualityView(currentResults: currentResults)

                PlayPauseButton(state: currentResults.playPauseButtonState)
                    .onTapGesture {
                        currentResults.playPauseButtonState = currentResults.playPauseButtonState.toggle()
                    }

                IterationCountView(currentResults: currentResults)
            }
        }
    }
}

struct DoneButton: View {
    let currentTraining: Training

    var body: some View {
        Text("Готово")
            .font(.system(size: 18, weight: .bold))
            .frame(width: 100, height: 50, alignment: .center)
            .foregroundColor(Color.white.opacity(0.8))
            .panelStyle()
            .padding(.horizontal, 20)
    }
}

struct SpeedQualityView: View {
    var currentResults: CurrentResults

    var body: some View {
        VStack(spacing: 6) {
            Text(currentResults.quality)
                .font(.system(size: 16))

            HStack {
                Image(systemName: "tortoise.fill")
                    .font(.system(size: 15))

                SpeedIndicator(currentResults: currentResults)

                Image(systemName: "hare.fill")
                    .font(.system(size: 15))
            }
        }
        .panelStyle()
    }

    private struct SpeedIndicator: View {
        var currentResults: CurrentResults

        var body: some View {
            ZStack(alignment: currentResults.speedState?.speedAlignment ?? .center) {
                Rectangle()
                    .frame(width: 40, height: 3)
                    .cornerRadius(1.5)

                if let speedState = currentResults.speedState {
                    Circle()
                        .frame(width: 10, height: 10)
                        .foregroundColor(.purple)
                }
            }
        }
    }
}

private extension CurrentResults.SpeedState {
    var speedAlignment: Alignment {
        switch self {
        case .fast:
            return .leading

        case .normal:
            return .center

        case .slow:
            return .trailing
        }
    }
}

struct IterationCountView: View {
    let currentResults: CurrentResults

    var body: some View {
        VStack(spacing: 6) {
            Text("\(currentResults.iterationCount) разів")
                .font(.system(size: 16, weight: .bold))
            Text(currentResults.currentSecondsFormated)
                .font(.system(size: 16))
        }
        .padding(8)
        .frame(width: 120, height: 60)
        .panelStyle()
    }
}

extension View {

    func panelStyle() -> some View {
        self
            .padding(8)
            .frame(width: 120, height: 60)
            .background(
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .backgroundStyle(cornerRadius: 20)
            )
    }

    func timerStyle() -> some View {
        self
            .background(
                PlayShape()
                    .fill(
                        .angularGradient(
                            colors: [.blue, .red, .blue],
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360)
                        )
                    )
                    .blur(radius: 12)
            )
            .frame(width: 200, height: 200)
            .background(.ultraThinMaterial)
            .cornerRadius(100)
            .modifier(OutlineOverlay(cornerRadius: 100))
    }

}
