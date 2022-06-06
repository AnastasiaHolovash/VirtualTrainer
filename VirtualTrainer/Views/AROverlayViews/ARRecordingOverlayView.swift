//
//  ARRecordingOverlayView.swift
//  VirtualTrainer
//
//  Created by Anastasia Holovash on 06.06.2022.
//

import SwiftUI

struct ARRecordingOverlayView: View {
    @State var model: RecordingData

    var body: some View {
        ZStack {
            if model.timer > 0 {
                Text("\(model.timer)")
                    .animatableFont(size: 100, weight: .semibold)
                    .background(
                        PlayShape()
                            .fill(
                                .angularGradient(colors: [.blue, .red, .blue], center: .center, startAngle: .degrees(0), endAngle: .degrees(360))
                            )
                            .blur(radius: 12)
                    )
                    .frame(width: 200, height: 200)
                    .background(.ultraThinMaterial)
                    .cornerRadius(100)
                    .modifier(OutlineOverlay(cornerRadius: 60))
            }

            VStack {
                HStack {
                    Spacer()

                    ZStack {
                        ZStack {
                            angularGradient
                            LinearGradient(gradient: Gradient(
                                colors: [Color(.systemBackground).opacity(1), Color(.systemBackground).opacity(0.6)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .cornerRadius(20)
                            .blendMode(.softLight)

                            Button {

                            } label: {
                                Text("Готово")
                                    .font(.body).bold()
                            }
                            .padding()
                            .foregroundColor(Color(hex: "281B5A").opacity(0.8))
                            .cornerRadius(20)
                        }
                        .frame(width: 100, height: 50, alignment: .center)
                        .padding(.horizontal, 20)
                    }

                }

                Spacer()

                PlayPauseButton()
            }
        }
    }
}

struct RecordingData {
    var playPauseButtonState: PlayPauseButtonState
    var timer: Int
}

struct ARRecordingOverlayView_Previews: PreviewProvider {
    static var previews: some View {
        ARRecordingOverlayView(model: .init(playPauseButtonState: .pause, timer: 2))
    }
}
