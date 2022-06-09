//
//  ContentView.swift
//  VirtualTrainer
//
//  Created by Anastasia Holovash on 30.05.2022.
//

import SwiftUI
import UIKit
import AVKit

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct AVPlayerView: UIViewControllerRepresentable {

    @Binding var videoURL: URL?

    private var player: AVPlayer {
        let some = AVPlayer.init()
        return AVPlayer(url: videoURL!)
    }

    func updateUIViewController(_ playerController: AVPlayerViewController, context: Context) {
        playerController.modalPresentationStyle = .fullScreen
        playerController.player = player
        playerController.player?.play()
    }

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        return AVPlayerViewController()
    }

}

struct ContentView: View {
    @EnvironmentObject var model: AppModel


    var body: some View {
        NavigationView {
            ZStack {
                HomeView()
                    .safeAreaInset(edge: .bottom) {
                        VStack {}.frame(height: 44)
                    }

                if model.showAddExercise {
                    AddExerciseView()
                        .accessibilityIdentifier("Identifier")
                }
            }
            .dynamicTypeSize(.large ... .xxLarge)
            .navigationBarHidden(true)
        }
    }
}

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//            .environmentObject(AppModel())
//    }
//}
