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

final class FirestoreClient {
    static let chats = Firestore.firestore().collection("exercises")

    var exercises: [Exercise] = []

    init() {
        getAllExercises()
    }

    private var cancellable: Cancellable?

    func getAllExercises() { //} -> AnyPublisher<[Exercise], Error> {
        cancellable = FirestoreClient.chats.getDocuments()
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

    func addNewExercise() {

    }
}
//
//struct GetAllExercises {
//    let name: String
//    let complexity:
//}
