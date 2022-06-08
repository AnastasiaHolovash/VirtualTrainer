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
import RealityKit

final class FirestoreClient: ObservableObject {
    static let exercisesCollection = Firestore.firestore().collection("exercises")

    private var addNewExerciseCancellable: Cancellable?

    @Published var exercises: [Exercise] = []
    private var allExercisesCancellable: Cancellable?

    init() {
        subscribeOnAllExercises()
    }

    func subscribeOnAllExercises() { //} -> AnyPublisher<[Exercise], Error> {
        allExercisesCancellable = FirestoreClient.exercisesCollection
            .snapshotPublisher()
            .tryMap { snapshot -> [Exercise] in
                try snapshot.documents.map { document in
                    try document.data(as: Exercise.self)
                }
            }
            .catch { error -> Just<[Exercise]> in
                print(error.localizedDescription)
                return Just([])
            }
            .sink { newExercises in
                print(newExercises.count)
//                print(newExercises[0].videoURL)
                self.exercises = newExercises
            }
    }

    struct UploadPhotoVideoResult {
        var videoURL: String
        var photoURL: String
    }

    var uploadTask: StorageUploadTask?
//
    func uploadVideoWithPhoto(
        id: String,
        for localVideoURL: URL,
        completion: @escaping (_ videoURL: URL, _ photoURL: URL) -> Void
    ) {

        let storageRef = Storage.storage().reference()
        let reference = storageRef.child("exercises").child("\(id)")

        let videoReference = reference.child("video.mov")
        let photoReference = reference.child("photo.jpeg")

        var videoDownloadURL: URL?
        var photoDownloadURL: URL?

        guard
            let image = AVAsset(url: localVideoURL).previewImageForLocalVideo,
            let imageData = image.jpegData(compressionQuality: 0.4)
        else {
            return
        }

        let dispatchGroup = DispatchGroup()

        dispatchGroup.enter()
        uploadTask = videoReference.putFile(from: localVideoURL, metadata: nil) { metadata, error in
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
            guard
                let videoDownloadURL = videoDownloadURL,
                let photoDownloadURL = photoDownloadURL
            else {
                return
            }

            completion(videoDownloadURL, photoDownloadURL)
            print(videoDownloadURL)
            print(photoDownloadURL)
        }
    }

    func addNewExercise(
        newExercise: NewExercise
//        videoURL: String,
//        photoURL: String
    ) { //}-> AnyPublisher<Void, Error> {
        
        let newDocument = FirestoreClient.exercisesCollection
            .document()
        let id = newDocument.documentID

        guard let localVideoURL = newExercise.localVideoURL else {
            return
        }

        uploadVideoWithPhoto(id: id, for: localVideoURL) { videoURL, photoURL in
            let exerciseRequest = NewExerciseRequest(
                id: id,
                videoURL: videoURL,
                photoURL: photoURL,
                newExercise: newExercise
            )
            do {
                try newDocument.setData(from: exerciseRequest) { error in
                    if let error = error {
                        print(error)
                        return
                    }
                    print("SETTTT")
                }
            } catch {
                print(error)
            }
        }



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
    var videoURL: URL
    var photoURL: URL
    var newExercise: NewExercise

//    init(newExercise: NewExercise)

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

    var name: String = ""
    var complexity: Complexity = .easy
    var recommendations: String = ""
    var localVideoURL: URL?
    var frames: Frames = []

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
