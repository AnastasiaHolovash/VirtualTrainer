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
            .tryMap { [self] snapshot -> [Exercise] in
                let exercises = try snapshot.documents.map { document -> Exercise in
                    print(document.metadata)
                    let ex = try document.data(as: Exercise.self)
                    let data = try JSONEncoder().encode(ex)
                    print(data.count)
                    print("Float = ", MemoryLayout<Float>.size)
                    return try document.data(as: Exercise.self)
                }

//                let imageURLs = exercises.map(\.photoURL)

//                Task {
//                    print("\n")
//                    let startDate = Date()
//                    print("Start loading asynchronously: \(startDate)")
//                    let allImages = await withTaskGroup(of: UIImage.self) { group -> [UIImage] in
//                        for (i, url) in imageURLs.enumerated() {
//                            group.addTask {
//                                let imageURL = URL(string: url)!
//                                let request = URLRequest(url: imageURL)
//                                let (data, _) = try! await URLSession.shared.data(for: request, delegate: nil)
//                                print("Finished loading image \(i)")
//                                return UIImage(data: data)!
//                            }
//                        }
//                        var collected = [UIImage]()
//                        for await value in group {
//                            collected.append(value)
//                        }
//                        return collected
//                    }
//                    print("All items loaded: \(Date())")
//                    print("Total time in seconds: \(Date().timeIntervalSince1970 - startDate.timeIntervalSince1970)")
//                    print("\n \(allImages)")
//                }


//                Task {
//                    func loadImage(index: Int, url: String) async -> UIImage {
//                        print("Started loading image \(index) \(Date())")
//                        let imageURL = URL(string: url)!
//                        let request = URLRequest(url: imageURL)
//                        let (data, _) = try! await URLSession.shared.data(for: request, delegate: nil)
//                        print("Finished loading image \(index) \(Date())")
//                        return UIImage(data: data)!
//                    }
//
//                    print("\n")
//                    let startDate = Date()
//                    print("Start loading synchronously: \(startDate)")
//                    let iImage0 = await loadImage(index: 0, url: imageURLs[0])
//                    let iImage1 = await loadImage(index: 1, url: imageURLs[1])
//                    let iImage2 = await loadImage(index: 2, url: imageURLs[2])
//                    let iImage3 = await loadImage(index: 3, url: imageURLs[3])
//                    let iImage4 = await loadImage(index: 4, url: imageURLs[4])
//                    let iImage5 = await loadImage(index: 5, url: imageURLs[5])
//                    let iImage6 = await loadImage(index: 6, url: imageURLs[6])
//                    print("All items loaded: \(Date())")
//                    print("Total time in seconds: \(Date().timeIntervalSince1970 - startDate.timeIntervalSince1970)")
//                    print("\n")
//                }

                print(exercises.map { $0.sentAt })
                return exercises
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
