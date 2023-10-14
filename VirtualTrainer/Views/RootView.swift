//
//  ContentView.swift
//  VirtualTrainer
//
//  Created by Anastasia Holovash on 30.05.2022.
//

import SwiftUI
import UIKit
import AVKit

struct RootView: View {
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
