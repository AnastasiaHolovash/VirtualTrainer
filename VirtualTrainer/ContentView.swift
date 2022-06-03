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
//                        let frames = Defaults.shared.getExerciseTargetFrames()
//                        print("--- First 5 ---")
//                        print(frames[0..<5])
//                        print("--- Last 5 ---")
//                        print(frames[(frames.count - 5)..<frames.count])
                        print("\nShow")
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

        /// True if timer is out
        @Binding var isTrainingInProgress: Bool
        /// True if recording training/exercise data is started
        var isRecording: Bool = false

        // Recording
        var exerciseFrames: Frames = []
        var comparisonFrameValue: Frame = []
        // Training
        var exerciseFramesLoaded: Frames = []
        var exerciseFramesCount: Int = 0

        init(
            jointModelTransforms: Binding<[simd_float4x4]>,
            isRecording: Binding<Bool>
        ) {
            _jointModelTransformsCurrent = jointModelTransforms
            _isTrainingInProgress = isRecording
            super.init()

            cancellable = Entity.loadBodyTrackedAsync(named: "robot")
                .sink(
                    receiveCompletion: { completion in
                        if case let .failure(error) = completion {
                            print("Error: Unable to load model: \(error.localizedDescription)")
                        }
                        self.cancellable?.cancel()
                    },
                    receiveValue: { character in
                        character.scale = GlobalConstants.characterScale
                        self.character = character
//                        character.characterControllerState?.
//                        character.motion = .init
                        self.cancellable?.cancel()
                    }
                )

//            setupFramesCheckingTimer()

            if GlobalConstants.mode == .training {
                exerciseFramesLoaded = Defaults.shared.getExerciseTargetFrames()
            }

            exerciseFramesCount = exerciseFramesLoaded.count
        }

//        func setupFramesCheckingTimer() {
//            Timer.publish(every: 0.1, on: .main, in: .default)
//                .autoconnect()
//                .receive(on: DispatchQueue.main)
//                .sink(receiveValue: { [weak self] _ in
//                    guard let self = self,
//                          self.isTrainingInProgress,
//                          !self.isRecording else {
//                        return
//                    }
//
//                    _ = self.checkIfExerciseStarted()
//                })
//                .store(in: &cancellables)
//        }

        // MARK: - Delegate method

        func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
            for anchor in anchors {
                guard let bodyAnchor = anchor as? ARBodyAnchor else { continue }

                jointModelTransformsCurrent = bodyAnchor.skeleton.jointModelTransforms

//                if GlobalConstants.mode == .recording && isTrainingInProgress {
//                    exerciseFrames.append(jointModelTransformsCurrent)
//                }

                if isTrainingInProgress && !isRecording {
                    _ = self.checkIfExerciseStarted()
                }

                if isTrainingInProgress && isRecording {
                    switch GlobalConstants.mode {
                    case .recording:
                        exerciseFrames.append(jointModelTransformsCurrent)
                        print(exerciseFrames.count)

                    case .training:
                        compareTrainingWithTarget()
                    }
                }
                if !isTrainingInProgress && isRecording {
                    print("--- STOP Recording ---")
                    isRecording.toggle()

                    if GlobalConstants.mode == .recording {
                        cropOneIteration()
                        exerciseFrames = []
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

        func checkIfExerciseStarted() -> Bool {
            guard !self.comparisonFrameValue.isEmpty else {
                self.comparisonFrameValue = self.jointModelTransformsCurrent
                return false
            }

            let resultValue = self.jointModelTransformsCurrent.compare(to: self.comparisonFrameValue)

            let result = resultValue.isStartStopMovement
            print("\n---- Compare ---- \(resultValue * 100)% ----- \(result)")

            if GlobalConstants.mode == .recording && result {
//                print("Clear exerciseFrames   from: \(exerciseFrames.count)")
                exerciseFrames = [self.comparisonFrameValue]
//                print("                       to: \(exerciseFrames.count)")
            }

            self.isRecording = result

            self.comparisonFrameValue = self.jointModelTransformsCurrent

            return result
        }

        // MARK: Compare Training WithTarget
        var exerciseFramesIndex = GlobalConstants.exerciseFramesFirstIndex
        var couldDetectEndOfIteration: Bool {
            let couldDetectEndOfIterationIndex = Float(exerciseFramesCount) * GlobalConstants.couldDetectEndOfIterationIndicator
            return Float(exerciseFramesIndex) >= couldDetectEndOfIterationIndex
        }
        var iterationsResults: [[Float]] = [[]]
        var numberOfIterations = 0

        var currentNumberOfStaticFrames = 0
        var previousValueOfStaticFrame: Float = 0.0

        func compareTrainingWithTarget() {
            let lastTargetFrame = exerciseFramesLoaded.last

            // Detection of end of iteration
            if couldDetectEndOfIteration,
               let last = lastTargetFrame {
                let resultValue = jointModelTransformsCurrent.compare(to: last)

                if previousValueOfStaticFrame == resultValue {
                    currentNumberOfStaticFrames += 1
                } else if resultValue.isCloseToEqual {
                    previousValueOfStaticFrame = resultValue
                    currentNumberOfStaticFrames = 1
                }
            }

            // Start detection of start of iteration
            if currentNumberOfStaticFrames == GlobalConstants.staticPositionIndicator {
                iterationsResults.append([])
                numberOfIterations += 1

                exerciseFramesIndex = GlobalConstants.exerciseFramesFirstIndex

                currentNumberOfStaticFrames = 0
                previousValueOfStaticFrame = 0.0

                isRecording = false
            }

            // Recording results
            let targetFrame = exerciseFramesLoaded[exerciseFramesIndex]

            let resultValue = jointModelTransformsCurrent.compare(to: targetFrame)
            print("---- Compare With Target ---- \(resultValue * 100)% ----- \(exerciseFramesIndex)")
            iterationsResults[numberOfIterations].append(resultValue)

            exerciseFramesIndex = exerciseFramesIndex < exerciseFramesLoaded.count - 1
                ? exerciseFramesIndex + 1
                : 0

            if exerciseFramesIndex == 0 {
                print("\nNew target iteration")
            }
        }

        /// For exercise recording process
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

            print("Size: \(croppedFrames.count)")

            Defaults.shared.setExerciseTargetFrames(croppedFrames)
        }


    }

}

enum GlobalConstants {
    static let mode: Mode = .training
    static let startStopMovementRange: ClosedRange<Float> = 0...0.97
    static let closeToEqualRange: ClosedRange<Float> = 0.9...1
    static let characterOffset: SIMD3<Float> = [-0.5, 0, 0]
    static let characterScale: SIMD3<Float> = [1.0, 1.0, 1.0]
    static let framesComparisonAccuracy: Float = 0.1
    static let couldDetectEndOfIterationIndicator: Float = 0.5
    /// Number of frames in static position
    static let staticPositionIndicator: Int = 6
    /// Based on difference between moment of detection and recorded frames
    static let exerciseFramesFirstIndex: Int = 1

    enum Mode {
        case recording
        case training
    }
}

extension Float {

    var isStartStopMovement: Bool {
        GlobalConstants.startStopMovementRange.contains(self)
    }

    var isCloseToEqual: Bool {
        GlobalConstants.closeToEqualRange.contains(self)
    }

}

extension Array where Element == simd_float4x4 {

    func compare(to array: Frame) -> Float {
        let resultArray = self.enumerated().map { index, simd4x4 -> Bool in
            return simd_almost_equal_elements(simd4x4, array[index], GlobalConstants.framesComparisonAccuracy)
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

#if DEBUG
//struct ContentView_Previews : PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}
#endif
