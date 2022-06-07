//
//  AddExerciseView.swift
//  VirtualTrainer
//
//  Created by Anastasia Holovash on 06.06.2022.
//

import SwiftUI

struct AddExerciseView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var model: AppModel

    @State var exercise = NewExercise()

    var body: some View {
        ZStack {
            ScrollView {
                cover
                    .overlay(NavigationLink(
                        destination: {
                            ARRecordingView(exercise: $exercise)
                                .navigationBarHidden(true)
                        },
                        label: {
                            AddButton()
                        }
                    ))
                content
                    .padding(.vertical, 30)
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
            Image(uiImage: exercise.localVideoURL?.previewImageForLocalVideo ?? UIImage(named: "Background 2")!)
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
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {

                    TextField("Назва", text: $exercise.name)
                        .font(.title.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundColor(.primary)

                    HStack {
                        Text("Складність")

                        Menu {
                            Button(
                                action: { exercise.complexity = .hard },
                                label: { Text(Complexity.hard.description) }
                            )
                            Button(
                                action: { exercise.complexity = .normal },
                                label: { Text(Complexity.normal.description) }
                            )
                            Button(
                                action: { exercise.complexity = .easy },
                                label: { Text(Complexity.easy.description) }
                            )
                        } label: {
                            Text(exercise.complexity.description)
                        }
                    }
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

            }
            .offset(y: 50)
        )

    }

    func close() {
        withAnimation(.closeCard.delay(0.2)) {
            model.showAddExercise = false
        }
    }

    var content: some View {
        VStack(alignment: .leading, spacing: 30) {
            Text("Рекомендації")
                .font(.title).bold()

            TextEditor(text: $exercise.recommendations)
                .frame(height: 100)
                .cornerRadius(20)

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
                    // Perform request
                    print(exercise)
                    model.apiClient.addNewExercise(newExercise: exercise)
//                    model.apiClient.addNewExercise(newExercise: <#T##NewExercise#>, videoURL: <#T##String#>, photoURL: <#T##String#>)
//                    let exerciseRequest = NewExerciseRequest(

                } label: {
                    Text("Готово")
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
        }
        .padding(20)
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
}

//#if DEBUG
//struct AddExerciseView_Previews: PreviewProvider {
//    @Namespace static var namespace
//
//    static var previews: some View {
//        AddExerciseView(exercise: .constant(NewExercise(name: "", complexity: .easy, recommendations: "", image: "", frames: [])))
//    }
//}
//#endif

