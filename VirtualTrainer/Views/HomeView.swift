//
//  HomeView.swift
//  VirtualTrainer
//
//  Created by Anastasia Holovash on 05.06.2022.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore

struct HomeView: View {
    var columns = [GridItem(.adaptive(minimum: 300), spacing: 20)]

    @State var show = false
    @State var showStatusBar = true
    @State var showCourse = false
    @State var contentHasScrolled = false

    @EnvironmentObject var model: AppModel
    @Namespace var namespace

    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()

            if model.showDetail {
                detail
            }

            ScrollView {
                scrollDetection

                Rectangle()
                    .frame(width: 100, height: 150)
                    .opacity(0)

                if model.showDetail {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(model.apiClient.exercises) { course in
                            Rectangle()
                                .fill(.white)
                                .frame(height: 360)
                                .cornerRadius(30)
                                .shadow(color: Color("Shadow").opacity(0.2), radius: 20, x: 0, y: 10)
                                .opacity(0.3)
                        }
                    }
                    .padding(.horizontal, 20)
                    .offset(y: -80)
                } else {
                    LazyVGrid(columns: columns, spacing: 20) {
                        course.frame(height: 360)
                    }
                    .padding(.horizontal, 20)
                    .offset(y: -80)
                }
            }
            .coordinateSpace(name: "scroll")
            .background(
                VStack {
                    Image("Blob 1")
                        .offset(x: 250, y: 100)
                        .accessibility(hidden: true)

                    Image("Blob 1")
                        .offset(x: -230, y: 100)
                        .accessibility(hidden: true)
                }
            )
        }
        .onChange(of: model.showDetail) { value in
            withAnimation {
                model.showNav.toggle()
                showStatusBar.toggle()
            }
        }
        .onAppear {
//            task {
//                try await Firestore.firestore().collection("exercises")
//                    .getDocuments()
//                    .tryMap { snapshot -> [Exercise] in
//                        try snapshot.documents.map { document in
//                            try document.data(as: Exercise.self)
//                        }
//                    }
//            }
//            model.apiClient.getAllExercises()
        }
        .overlay(NavigationBar(title: "Тренування", contentHasScrolled: $contentHasScrolled))
        .statusBar(hidden: !showStatusBar)
    }

    var detail: some View {
        ForEach(model.exercises) { exercise in
            if exercise.id == model.selectedExercise {
                ExerciseView(namespace: namespace, exercise: exercise)
            }
        }
    }

    var course: some View {
        ForEach(model.exercises) { exercise in
            ExerciseItem(namespace: namespace, exercise: exercise)
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isButton)
        }
    }

    var scrollDetection: some View {
        GeometryReader { proxy in
            let offset = proxy.frame(in: .named("scroll")).minY
            Color.clear.preference(key: ScrollPreferenceKey.self, value: offset)
        }
        .onPreferenceChange(ScrollPreferenceKey.self) { value in
            withAnimation(.easeInOut) {
                if value < 0 {
                    contentHasScrolled = true
                } else {
                    contentHasScrolled = false
                }
            }
        }
    }
}

#if DEBUG
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(AppModel())
    }
}
#endif
