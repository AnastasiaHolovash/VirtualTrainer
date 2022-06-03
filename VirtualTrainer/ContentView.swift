//
//  ContentView.swift
//  VirtualTrainer
//
//  Created by Anastasia Holovash on 30.05.2022.
//

import SwiftUI
import RealityKit
import ARKit
import Combine

struct ContentView : View {

    enum Constants {
        static let timetStartTime = 2
    }

    @State var jointModelTransforms: Frame = []
    @State var timerValue: Int = Constants.timetStartTime

    @State var timerCancellable: AnyCancellable? = nil
    @State var isRecording: Bool = false
    @State var buttonState: ButtonState = .start

    var body: some View {
        ZStack {
            ARViewContainer(
                jointModelTransforms: $jointModelTransforms,
                isRecording: $isRecording
            )
            .edgesIgnoringSafeArea(.all)

            Text(timerValue < Constants.timetStartTime + 1 ? "\(timerValue)" : "")
                .font(.system(size: 100))

            VStack {
                Spacer()

                HStack {
                    Button {
                        switch buttonState {
                        case .start:
                            startTimer()

                        case .stop:
                            isRecording.toggle()
                            stopTimer()
                        }
                        buttonState.toggle()
                    } label: {
                        Text(buttonState.rawValue.capitalized)
                            .font(.system(size: 20, weight: .bold))
                    }
                    .padding()
                    .background(.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)

                    Button {
                        let frames = Defaults.shared.getExerciseTargetFrames()
                        print("--- First 5 ---")
                        print(frames[0..<5])
                        print("--- Last 5 ---")
                        print(frames[(frames.count - 5)..<frames.count])
                    } label: {
                        Text("Show")
                            .font(.system(size: 20, weight: .bold))
                    }
                    .padding()
                    .background(.purple)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
        }
        // FOR debug
        .onAppear {
//            startTimer()
        }
    }

    func startTimer() {
        timerCancellable = Timer.publish(every: 1, on: .main, in: .default)
            .autoconnect()
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { somee in
                switch timerValue {
                case 0:
                    timerValue = Constants.timetStartTime + 1
                    stopTimer()
                    isRecording.toggle()

                default:
                    timerValue -= 1
                }
            })
    }

    func stopTimer() {
        timerCancellable?.cancel()
    }
}

// MARK: - AR ViewContainer

struct ARViewContainer: UIViewRepresentable {

    @Binding var jointModelTransforms: Frame
    @Binding var isRecording: Bool

    func makeUIView(context: Context) -> ARView {
        
        let arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: true)
        arView.session.delegate = context.coordinator

        let configuration = ARBodyTrackingConfiguration()
        arView.session.run(configuration)
        arView.scene.addAnchor(context.coordinator.characterAnchor)


        return arView
        
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            jointModelTransforms: $jointModelTransforms,
            isRecording: $isRecording
        )
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {

    }

    // MARK: - Coordinator

    class Coordinator: NSObject, ARSessionDelegate {

        let characterAnchor = AnchorEntity()
        var character: BodyTrackedEntity?

        var cancellable: AnyCancellable? = nil
        var cancellables: Set<AnyCancellable> = Set()

        @Binding var jointModelTransformsCurrent: Frame
        @Binding var isTrainingInProgress: Bool
        var isRecording: Bool = false

        var exerciseFrames: Frames = []
        var comparisonValue: Frame = []

        init(
            jointModelTransforms: Binding<[simd_float4x4]>,
            isRecording: Binding<Bool>
        ) {
            _jointModelTransformsCurrent = jointModelTransforms
            _isTrainingInProgress = isRecording
            super.init()

            cancellable = Entity.loadBodyTrackedAsync(named: "robot").sink(
                receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        print("Error: Unable to load model: \(error.localizedDescription)")
                    }
                    self.cancellable?.cancel()
                }, receiveValue: { character in
                    character.scale = [1.0, 1.0, 1.0]
                    self.character = character
                    self.cancellable?.cancel()
                })

            setupFramesCheckingTimer()
        }

        func setupFramesCheckingTimer() {
            Timer.publish(every: 0.1, on: .main, in: .default)
                .autoconnect()
                .receive(on: DispatchQueue.main)
                .sink(receiveValue: { [weak self] _ in
                    guard let self = self,
                          self.isTrainingInProgress,
                          !self.isRecording else {
                        return
                    }

                    _ = self.checkIfExerciseStarted()
                })
                .store(in: &cancellables)
        }

        func checkIfExerciseStarted() -> Bool {
            guard !self.comparisonValue.isEmpty else {
                self.comparisonValue = self.jointModelTransformsCurrent
                return false
            }

            let resultValue = self.jointModelTransformsCurrent.compare(to: self.comparisonValue)

            let result = resultValue.isStartStopMovement
            print("\n---- Compare ---- \(resultValue * 100)% ----- \(result)")

            self.comparisonValue = self.jointModelTransformsCurrent

            if result {
                exerciseFrames.append(self.comparisonValue)
                exerciseFrames.append(self.jointModelTransformsCurrent)
            }

            self.isRecording = result

            return result
        }

        func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
            for anchor in anchors {
                guard let bodyAnchor = anchor as? ARBodyAnchor else { continue }

                jointModelTransformsCurrent = bodyAnchor.skeleton.jointModelTransforms

                if isTrainingInProgress && isRecording {
                    print("--- Recording ---")
                    exerciseFrames.append(bodyAnchor.skeleton.jointModelTransforms)
                }
                if !isTrainingInProgress && isRecording {
                    print("--- STOP Recording ---")
                    isRecording.toggle()

                    if GlobalConstants.mode == .recording {
                        cropOneIteration()
                    }
                }

                let bodyPosition = simd_make_float3(bodyAnchor.transform.columns.3)
                characterAnchor.position = bodyPosition + GlobalConstants.characterOffset
                characterAnchor.orientation = Transform(matrix: bodyAnchor.transform).rotation

                if let character = character, character.parent == nil {
                    characterAnchor.addChild(character)
                }
            }
        }

        func cropOneIteration() {
            var previousChecked = exerciseFrames.last
            let (frameIndex, _) = exerciseFrames.reversed().enumerated().first { index, frame in
                guard index < exerciseFrames.count - 1,
                      let previous = previousChecked
                else {
                    return false
                }

                let resultValue = frame.compare(to: previous)
                let result = resultValue.isStartStopMovement

                print("\n---- Compare ---- \(resultValue * 100)% ----- \(result)")

                previousChecked = frame

                return result
            } ?? (exerciseFrames.count - 1, exerciseFrames.last)

            let lastFrameIndex = frameIndex > 0 ? exerciseFrames.count - frameIndex : exerciseFrames.count
            let croppedFrames: Frames = Array(exerciseFrames[0...lastFrameIndex])

            Defaults.shared.setExerciseTargetFrames(croppedFrames)
        }
    }

}

enum GlobalConstants {
    static let mode: Mode = .recording
    static let startStopMovementRange: ClosedRange<Float> = 0...0.95
    static let characterOffset: SIMD3<Float> = [-0.5, 0, 0]

    enum Mode {
        case recording
        case training
    }
}

extension Float {

    var isStartStopMovement: Bool {
        GlobalConstants.startStopMovementRange.contains(self)
    }

}

extension Array where Element == simd_float4x4 {

    func compare(to array: Frame) -> Float {
        let resultArray = self.enumerated().map { index, simd4x4 -> Bool in
            return simd_almost_equal_elements(simd4x4, array[index], 0.1)
        }

        return Float(resultArray.filter { $0 }.count) / Float(resultArray.count)
    }

}

extension ContentView {

    enum ButtonState: String {
        case start
        case stop

        mutating func toggle() {
            switch self {
            case .start:
                self = .stop

            case .stop:
                self = .start
            }
        }
    }

}

/**
 Timer.publish(every: 3, on: .main, in: .default)
     .autoconnect()
     .receive(on: DispatchQueue.main)
     .sink(receiveValue: { [weak self] _ in
         guard let self = self else {
             return
         }
         guard !self.jointModelTransformsPrevious.isEmpty else {
             self.jointModelTransformsPrevious = self.jointModelTransforms
             return
         }

         print("--- Body Position ---\n")
         let resultArray = self.jointModelTransforms.enumerated().map { index, simd4x4 -> Bool in
             print("\(index) - ", simd4x4.debugDescription, "\n")
             return simd_almost_equal_elements(simd4x4, self.jointModelTransformsPrevious[index], 0.1)
         }

         let resultResents = Float(resultArray.filter { $0 }.count) / Float(resultArray.count) * 100
         print("\n--- Result ---")
         print("\(resultResents)")
         print("Result array - \(resultArray)")
         print("Filtered array - \(resultArray.filter { $0 })")


         self.jointModelTransformsPrevious = self.jointModelTransforms
     })
 //                .assign(to: \.lastUpdated, on: myDataModel)
     .store(in: &cancellable)
 */

#if DEBUG
//struct ContentView_Previews : PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}
#endif
