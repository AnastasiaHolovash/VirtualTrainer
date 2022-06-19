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

    @Published var exercises: [Exercise] = []

    private var addNewExerciseCancellable: Cancellable?
    private var allExercisesCancellable: Cancellable?

    var uploadTask: StorageUploadTask?
    
    init() {
        subscribeOnAllExercises()
    }

    func subscribeOnAllExercises() {
        allExercisesCancellable = FirestoreClient.exercisesCollection
            .order(by: "sentAt", descending: true)
            .snapshotPublisher()
            .tryMap { snapshot -> [Exercise] in
                let exersises = try snapshot.documents.map { document in
                    return try document.data(as: Exercise.self)
                }
                print(exersises.map { $0.sentAt })
                return exersises
            }
            .catch { error -> Just<[Exercise]> in
                print(error.localizedDescription)
                return Just([])
            }
            .sink { newExercises in
                print(newExercises.count)
                self.exercises = newExercises
            }
    }

    func addNewExercise(newExercise: NewExercise, completion: @escaping () -> Void) {
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
                    completion()
                }
            } catch {
                print(error)
            }
        }
    }

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

    func deleteExercise(exercise: Exercise) {
        FirestoreClient.exercisesCollection
            .document(exercise.id)
            .delete() { error in
                print(error?.localizedDescription ?? "Deleted")
            }
    }

}
