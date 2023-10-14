//
//  AVPlayerView.swift
//  VirtualTrainer
//
//  Created by Anastasia Holovash on 19.06.2022.
//

import SwiftUI
import UIKit
import AVKit

struct AVPlayerView: UIViewControllerRepresentable {

    let videoURL: URL?

    private var player: AVPlayer {
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
