//
//  PlayPauseButton.swift
//  VirtualTrainer
//
//  Created by Anastasia Holovash on 06.06.2022.
//

import SwiftUI

struct PlayPauseButton: View {
    @State var state: PlayPauseButtonState = .pause

    var body: some View {
        VStack {
            VStack {
                switch state {
                case .play:
                    Image(systemName: "pause.fill")
                        .animatableFont(size: 40, weight: .semibold, design: .rounded)
                        .foregroundColor(Color(hex: "281B5A").opacity(0.8))

                case .pause:
                    PlayShape()
                        .fill(Color(hex: "281B5A").opacity(0.8))
                        .overlay(
                            PlayShape()
                                .stroke(.white)
                        )
                        .offset(x: 6)
                }
            }
            .frame(width: 36, height: 36)
            .background(
                PlayShape()
                    .fill(
                        .angularGradient(colors: [.blue, .red, .blue], center: .center, startAngle: .degrees(0), endAngle: .degrees(360))
                    )
                    .blur(radius: 12)
            )

        }
        .frame(width: 100, height: 100)
        .background(.ultraThinMaterial)
        .cornerRadius(60)
        .modifier(OutlineOverlay(cornerRadius: 60))
        //        .overlay(CircularView(value: 0.25, lineWidth: 8))
        .shadow(color: Color("Shadow").opacity(0.2), radius: 30, x: 0, y: 30)
    }
}

enum PlayPauseButtonState {
    case play
    case pause
}

#if DEBUG
struct PlayPauseButton_Previews: PreviewProvider {
    static var previews: some View {
        PlayPauseButton(state: .play)
    }
}
#endif

