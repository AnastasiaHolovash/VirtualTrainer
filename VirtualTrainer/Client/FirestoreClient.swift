//
//  FirestoreClient.swift
//  VirtualTrainer
//
//  Created by Anastasia Holovash on 07.06.2022.
//

import Foundation
import Combine
import Firebase
import FirebaseFirestoreCombineSwift
import FirebaseStorage
import FirebaseStorageCombineSwift
import AVFoundation

final class FirestoreClient {
    static let exercisesCollection = Firestore.firestore().collection("exercises")

    private var getAllExercisesCancellable: Cancellable?
    private var addNewExerciseCancellable: Cancellable?

    var exercises: [Exercise] = []

    init() {
        getAllExercises()
    }

    func getAllExercises() { //} -> AnyPublisher<[Exercise], Error> {
        getAllExercisesCancellable = FirestoreClient.exercisesCollection.getDocuments()
            .tryMap { snapshot -> [Exercise] in
                try snapshot.documents.map { document in
                    try document.data(as: Exercise.self)
                }
            }
            .sink(receiveCompletion: { completion in
                print("\(completion)")
            }, receiveValue: { [weak self] value in
                self?.exercises = value
            })
    }

    struct UploadPhotoVideoResult {
        var videoURL: String
        var photoURL: String
    }

    var uploadTask: StorageUploadTask?
//
    func uploadVideoWithPhoto() { //} -> AnyPublisher<UploadPhotoVideoResult, Error> {

        let storageRef = Storage.storage().reference()
        let reference = storageRef.child("exercises").child("\(UUID())")

        guard let videoURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("test.mov") else {
            return
        }

        let videoReference = reference.child("video.mov")
        let photoReference = reference.child("photo.jpeg")

        var videoDownloadURL: URL?
        var photoDownloadURL: URL?


        guard
            let image = AVAsset(url: videoURL).previewImageForLocalVideo,
            let imageData = image.jpegData(compressionQuality: 0.4)
        else {
            return
        }

        let dispatchGroup = DispatchGroup()

        dispatchGroup.enter()
        uploadTask = videoReference.putFile(from: videoURL, metadata: nil) { metadata, error in
            print(error)
            videoReference.downloadURL { (url, error) in
                guard let downloadURL = url else {
                    // Uh-oh, an error occurred!
                    return
                }
                print(downloadURL)
                videoDownloadURL = downloadURL
                dispatchGroup.leave()
            }
        }

        dispatchGroup.enter()
        let uploadTask = photoReference.putData(imageData) { metadata, error in
            print(error)
            photoReference.downloadURL { (url, error) in
                guard let downloadURL = url else {
                    // Uh-oh, an error occurred!
                    return
                }
                photoDownloadURL = downloadURL
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) {
            print(videoDownloadURL)
            print(photoDownloadURL)
        }
    }

    func addNewExercise(
        newExercise: NewExercise,
        videoURL: String,
        photoURL: String
    ) { //}-> AnyPublisher<Void, Error> {
        
        let newDocument = FirestoreClient.exercisesCollection
            .document()
        var exerciseRequest = NewExerciseRequest(
            id: newDocument.documentID,
            videoURL: videoURL,
            photoURL: photoURL,
            newExercise: newExercise
        )

//        return newDocument.setData(from: newDocument)
//        exercise.id = newDocument.documentID

//        return newDocument
//            .setData(from: newDocument)
//            .flatMap { _ in newDocument.getDocument().eraseToAnyPublisher() }
//            .on(
//                value: { response in
//                    do {
//                        let exercise = try response.data(as: Exercise.self)
//                        return exercise
//                    } catch let error {
//                        return error
//                    }
//                },
//                error: { return $0 }
//            )

    }
}

import ARKit

struct NewExerciseRequest: Encodable {

    var id: String
    var videoURL: String
    var photoURL: String
    var newExercise: NewExercise

    enum CodingKeys: String, CodingKey {
        case id
        case videoURL
        case photoURL
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(videoURL, forKey: .videoURL)
        try container.encode(photoURL, forKey: .photoURL)
        try newExercise.encode(to: encoder)
    }

}


struct NewExercise: Encodable {
//    var id: String?
    var name: String = ""
    var complexity: Complexity?
    var recommendations: String = ""
    var frames: Frames = []

//    let

    enum CodingKeys: String, CodingKey {
        case name
        case complexity
        case recommendations
        case frames
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try  container.encode(complexity, forKey: .complexity)
        try container.encode(recommendations, forKey: .recommendations)
        let firebaseFrames = frames.map { FirebaseFrame(simdArray: $0) }
        try  container.encode(firebaseFrames, forKey: .frames)
    }

//    var frames: [FirebaseFrame] = []

//    init(
//        name: String,
//        complexity: Complexity,
//        recommendations: String,
//        frames: Frames
//    ) {
//        self.name = name
//        self.complexity = complexity
//        self.recommendations = recommendations
//        self.frames = frames.map { FirebaseFrame(simdArray: $0) }
//    }
}


//
//struct GetAllExercises {
//    let name: String
//    let complexity:
//}
