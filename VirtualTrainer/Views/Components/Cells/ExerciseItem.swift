//
//  CourseItem.swift
//  VirtualTrainer
//
//  Created by Anastasia Holovash on 06.06.2022.
//

import SwiftUI
import AVFoundation

struct ExerciseItem: View {
    var namespace: Namespace.ID
    var exercise: Exercise

    @EnvironmentObject var model: AppModel
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var body: some View {
        VStack {
            LogoView()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(20)
                .matchedGeometryEffect(id: "logo\(exercise.id)", in: namespace)

            Spacer()

            VStack(alignment: .leading, spacing: 8) {
                Text(exercise.name)
                    .font(.title).bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .matchedGeometryEffect(id: "title\(exercise.id)", in: namespace)
                    .foregroundColor(.white)

                Text(exercise.recommendations)
                    .lineLimit(2)
                    .font(.footnote)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(.white.opacity(0.7))
                    .matchedGeometryEffect(id: "description\(exercise.id)", in: namespace)
            }
            .padding(20)
            .background(
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .cornerRadius(30)
                    .blur(radius: 30)
                    .matchedGeometryEffect(id: "blur\(exercise.id)", in: namespace)
            )
        }
        .background(
            Image(uiImage: AVAsset(url: url!).previewImageForLocalVideo ?? UIImage())
                .resizable()
                .aspectRatio(contentMode: .fill)
                .disabled(true)
                .matchedGeometryEffect(id: "background\(exercise.id)", in: namespace)
        )
        .mask(
            RoundedRectangle(cornerRadius: 30)
                .matchedGeometryEffect(id: "mask\(exercise.id)", in: namespace)
        )
        .overlay(
            Image(horizontalSizeClass == .compact ? "Waves 1" : "Waves 2")
                .frame(maxHeight: .infinity, alignment: .bottom)
                .offset(y: 0)
                .opacity(0)
                .matchedGeometryEffect(id: "waves\(exercise.id)", in: namespace)
        )
        .frame(height: 350)
        .onTapGesture {
            withAnimation(.openCard) {
                model.showDetail = true
                model.selectedExercise = exercise.id
            }
        }
    }
}
let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("test.mov")

#if DEBUG
struct CardItem_Previews: PreviewProvider {
    @Namespace static var namespace

    static var previews: some View {
        ExerciseItem(namespace: namespace, exercise: exerciseMock)
            .environmentObject(AppModel())
    }
}
#endif

extension AVAsset {

    var previewImageForLocalVideo: UIImage? {

        let imageGenerator = AVAssetImageGenerator(asset: self)
        imageGenerator.appliesPreferredTrackTransform = true

        var time = duration

        time.value = min(time.value, 2)

        do {
            let imageRef = try imageGenerator.copyCGImage(at: time, actualTime: nil)
            return UIImage(cgImage: imageRef)
        } catch let error as NSError {
            print("Image generation failed with error \(error)")
            return nil
        }
    }
}
