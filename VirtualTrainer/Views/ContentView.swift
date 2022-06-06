//
//  ContentView.swift
//  VirtualTrainer
//
//  Created by Anastasia Holovash on 30.05.2022.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var model: AppModel
    @State var newExercise = NewExercise()

    var body: some View {
        NavigationView {
            ZStack {
                HomeView()
                    .safeAreaInset(edge: .bottom) {
                        VStack {}.frame(height: 44)
                    }

                if model.showAddExercise {
                    AddExerciseView(exercise: $newExercise)
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
        ContentView()
            .environmentObject(AppModel())
    }
}
