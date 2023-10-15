//
//  TimerObject.swift
//  VirtualTrainer
//
//  Created by Anastasia Holovash on 15.10.2023.
//

import Combine
import Foundation

class TimerObject: ObservableObject {

    @Published var elapsedSeconds = 0
    var cancellables = Set<AnyCancellable>()

    func start() {
        elapsedSeconds = 0

        Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.elapsedSeconds += 1
            }
            .store(in: &cancellables)
    }

    func stop() {
        cancellables.removeAll()
    }

}
