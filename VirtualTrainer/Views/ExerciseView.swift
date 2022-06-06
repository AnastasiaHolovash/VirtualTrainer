//
//  ExerciseView.swift
//  VirtualTrainer
//
//  Created by Anastasia Holovash on 06.06.2022.
//

import SwiftUI

struct ExerciseView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var model: AppModel

    var namespace: Namespace.ID
    var exercise: Exercise

    var body: some View {
        ZStack {
            ScrollView {
                cover
                    .overlay(PlayButton())
                content
                    .padding(.vertical, 80)
            }
            .coordinateSpace(name: "scroll")
            .background(Color("Background"))
            .ignoresSafeArea()

            Button {
                close()
            } label: {
                CloseButton()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .padding(20)
            .ignoresSafeArea()
        }
        .zIndex(1)
    }

    var cover: some View {
        VStack {
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .frame(height: 500)
        .background(
            Image(exercise.image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .accessibility(hidden: true)
        )
        .mask(
            RoundedRectangle(cornerRadius: 0)
        )
        .overlay(
            Image(horizontalSizeClass == .compact ? "Waves 1" : "Waves 2")
                .frame(maxHeight: .infinity, alignment: .bottom)
                .accessibility(hidden: true)
        )
        .overlay(
            VStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 8) {

                    Text(exercise.name)
                        .font(.title).bold()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundColor(.primary)

                    Text("Complexity ♦ Low")
                        .font(.title3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundColor(.primary.opacity(0.5))


                }
                .padding(20)
                .background(
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .backgroundStyle(cornerRadius: 30)
                )
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(20)


                Button {

                } label: {
                    Text("Почати")
                        .font(.title2).bold()
                }
                .padding()
                .frame(width: 340)
                .foregroundColor(.white)
                .background(.ultraThinMaterial)
                .background(
                    Image("Background 4")
                        .resizable()
                )
                .cornerRadius(20)
            }
            .offset(y: 100)
        )

    }

    func close() {
        withAnimation(.closeCard.delay(0.2)) {
            model.showDetail = false
            model.selectedExercise = 0
        }
    }

    var content: some View {
        VStack(alignment: .leading, spacing: 30) {
            Text("Рекомендації")
                .font(.title).bold()
            Text(exercise.recommendations)
        }
        .padding(20)
    }
}

#if DEBUG
struct ExerciseView_Previews: PreviewProvider {
    @Namespace static var namespace

    static var previews: some View {
        ExerciseView(namespace: namespace, exercise: exerciseMock)
    }
}
#endif
