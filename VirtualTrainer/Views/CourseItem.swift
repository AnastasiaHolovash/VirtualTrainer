//
//  CourseItem.swift
//  VirtualTrainer
//
//  Created by Anastasia Holovash on 06.06.2022.
//

import SwiftUI

struct CourseItem: View {
    var namespace: Namespace.ID
    var exercise: Exercise

    @EnvironmentObject var model: AppModel
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var body: some View {
        VStack {
            LogoView()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(20)
                .matchedGeometryEffect(id: "logo\(exercise.index)", in: namespace)

            Spacer()

            VStack(alignment: .leading, spacing: 8) {
                Text(exercise.name)
                    .font(.title).bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .matchedGeometryEffect(id: "title\(exercise.index)", in: namespace)
                    .foregroundColor(.white)

                Text(exercise.recommendations)
                    .lineLimit(2)
                    .font(.footnote)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(.white.opacity(0.7))
                    .matchedGeometryEffect(id: "description\(exercise.index)", in: namespace)
            }
            .padding(20)
            .background(
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .cornerRadius(30)
                    .blur(radius: 30)
                    .matchedGeometryEffect(id: "blur\(exercise.index)", in: namespace)
            )
        }
        .background(
            Image(exercise.image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .disabled(true)
                .matchedGeometryEffect(id: "background\(exercise.index)", in: namespace)
        )
        .mask(
            RoundedRectangle(cornerRadius: 30)
                .matchedGeometryEffect(id: "mask\(exercise.index)", in: namespace)
        )
        .overlay(
            Image(horizontalSizeClass == .compact ? "Waves 1" : "Waves 2")
                .frame(maxHeight: .infinity, alignment: .bottom)
                .offset(y: 0)
                .opacity(0)
                .matchedGeometryEffect(id: "waves\(exercise.index)", in: namespace)
        )
        .frame(height: 350)
        .onTapGesture {
            withAnimation(.openCard) {
                model.showDetail = true
                model.selectedExercise = exercise.index
            }
        }
    }
}

#if DEBUG
struct CardItem_Previews: PreviewProvider {
    @Namespace static var namespace

    static var previews: some View {
        CourseItem(namespace: namespace, exercise: exerciseMock)
            .environmentObject(AppModel())
    }
}
#endif
