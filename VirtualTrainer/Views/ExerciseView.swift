//
//  ExerciseView.swift
//  VirtualTrainer
//
//  Created by Anastasia Holovash on 06.06.2022.
//

import SwiftUI
import SDWebImageSwiftUI

struct ExerciseView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var model: AppModel

    var namespace: Namespace.ID
    var exercise: Exercise
    @State var isPresented: Bool = false

    var body: some View {
        ZStack {
            ScrollView {
                cover
                    .overlay(
                        NavigationLink(destination: {
                            AVPlayerView(videoURL: URL(string: exercise.videoURL)!)
                                .navigationBarHidden(true)
                                .background(Color.black)
                        }, label: {
                            PlayButton()
                        })
                    )
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

    private var cover: some View {
        VStack {
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .frame(height: 500)
        .background(
            WebImage(url: URL(string: exercise.photoURL))
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

                    Text("Складність " + exercise.complexity.description)
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

                ZStack {
                    angularGradient
                    LinearGradient(gradient: Gradient(
                        colors: [Color(.systemBackground).opacity(1), Color(.systemBackground).opacity(0.6)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .cornerRadius(20)
                    .blendMode(.softLight)

                    NavigationLink {
                        ARTrainingView(with: self.exercise)
                            .navigationBarHidden(true)
                    } label: {
                        Text("Почати")
                            .font(.title2).bold()
                            .frame(maxWidth: .infinity)
                    }
                    .padding()
                    .foregroundColor(.white)
                    .background(.ultraThinMaterial)
                    .background(
                        ZStack {
                            Image("Background 4")
                                .resizable()
                        }
                    )
                    .cornerRadius(20)
                }
                .frame(height: 60, alignment: .center)
                .padding(.horizontal, 20)
            }
            .offset(y: 100)
        )

    }

    private func close() {
        withAnimation(.closeCard.delay(0.2)) {
            model.showDetail = false
            model.selectedExercise = nil
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 30) {
            Text("Рекомендації")
                .font(.title).bold()
            Text(exercise.recommendations)
        }
        .padding(20)
    }
}

var angularGradient: some View {
    RoundedRectangle(cornerRadius: 20)
        .fill(.clear)
        .overlay(AngularGradient(
            gradient: Gradient(stops: [
                .init(color: Color(#colorLiteral(red: 0, green: 0.5199999809265137, blue: 1, alpha: 1)), location: 0.0),
                .init(color: Color(#colorLiteral(red: 0.2156862745, green: 1, blue: 0.8588235294, alpha: 1)), location: 0.4),
                .init(color: Color(#colorLiteral(red: 1, green: 0.4196078431, blue: 0.4196078431, alpha: 1)), location: 0.5),
                .init(color: Color(#colorLiteral(red: 1, green: 0.1843137255, blue: 0.6745098039, alpha: 1)), location: 0.8)]),
            center: .center
        ))
        .padding(6)
        .blur(radius: 20)
}
