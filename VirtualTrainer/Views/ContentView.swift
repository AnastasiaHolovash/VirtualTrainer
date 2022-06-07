//
//  ContentView.swift
//  VirtualTrainer
//
//  Created by Anastasia Holovash on 30.05.2022.
//

import SwiftUI

//import SwiftUI
import UIKit
import AVKit
//
//struct ContentView: View {
//
//    let toPresent = UIHostingController(rootView: AnyView(EmptyView()))
//    @State private var vURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("test.mov")
//
//    var body: some View {
//        AVPlayerView(videoURL: self.$vURL).transition(.move(edge: .bottom)).edgesIgnoringSafeArea(.all)
//    }
//}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


struct AVPlayerView: UIViewControllerRepresentable {

    @Binding var videoURL: URL?

    private var player: AVPlayer {
        let some = AVPlayer.init()
//        some.
        return AVPlayer(url: videoURL!)
    }

    func updateUIViewController(_ playerController: AVPlayerViewController, context: Context) {
        playerController.modalPresentationStyle = .fullScreen
//        playerController.videoGravity = .
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
