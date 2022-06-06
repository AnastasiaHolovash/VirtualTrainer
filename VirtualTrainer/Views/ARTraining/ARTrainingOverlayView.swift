//
//  ARTrainingOverlayView.swift
//  VirtualTrainer
//
//  Created by Anastasia Holovash on 06.06.2022.
//

import SwiftUI

struct ARTrainingOverlayView: View {
    @Binding var model: CurrentResults

    var body: some View {
        ZStack {
            if model.timer < GlobalConstants.timerStartTime + 1 {
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

                HStack(spacing: 8) {
                    VStack(spacing: 6) {
                        Text(model.quality)
                            .font(.system(size: 16))
                        HStack {
                            Image(systemName: "tortoise.fill")
                                .font(.system(size: 15))
                            Rectangle()
                                .frame(width: 40, height: 3)
                                .cornerRadius(1.5)
                            Image(systemName: "hare.fill")
                                .font(.system(size: 15))
                        }
                    }
                    .padding(8)
                    .frame(width: 120, height: 60)
                    .background(
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .backgroundStyle(cornerRadius: 20)
                    )

                    PlayPauseButton(state: $model.playPauseButtonState)
                        .onTapGesture {
                            model.playPauseButtonState = model.playPauseButtonState.toggle()
                        }

                    VStack(spacing: 6) {
                        Text("\(model.iterationCount) разів")
                            .font(.system(size: 16, weight: .bold))
                        Text(model.seconds.durationDescription)
                            .font(.system(size: 16))
                    }
                    .padding(8)
                    .frame(width: 120, height: 60)
                    .background(
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .backgroundStyle(cornerRadius: 20)
                    )
                }
            }
        }
    }
}

//struct ARTrainingOverlayView_Previews: PreviewProvider {
//    static var previews: some View {
//        ARTrainingOverlayView(model: .constant(.init(quality: "Нормально", speed: 0.9, iterationCount: 5, seconds: 1990028, timer: 0, playPauseButtonState: .play)))
//    }
//}
