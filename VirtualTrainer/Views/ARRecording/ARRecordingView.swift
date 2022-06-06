//
//  ARRecordingView.swift
//  VirtualTrainer
//
//  Created by Anastasia Holovash on 06.06.2022.
//

import SwiftUI
import RealityKit
import ARKit
import Combine
import Vision

//struct ContentView : View {
//
//    enum Constants {
//        static let timetStartTime = 2
//    }
//
//    @State var jointModelTransforms: Frame = []
//    @State var timerValue: Int = Constants.timetStartTime
//
//    @State var timerCancellable: AnyCancellable? = nil
//    @State var isRecording: Bool = false
//    @State var buttonState: ButtonState = .start
//    @State var some: String = ""
//    @State var comparisonFrameValue: Frame = []
//
//
//    var body: some View {
//        ZStack {
//            ARViewContainer(
//                jointModelTransforms: $jointModelTransforms,
//                isRecording: $isRecording,
//                some: $some,
//                comparisonFrameValue: $comparisonFrameValue
//            )
//            .edgesIgnoringSafeArea(.all)
//
//            Text(timerValue < Constants.timetStartTime + 1 ? "\(timerValue)" : "")
//                .font(.system(size: 100))
//
//            VStack(spacing: 16) {
//                Spacer()
//
//                Text("\(some)")
//                    .font(.system(size: 20, weight: .bold))
//                .padding()
//                .background(.purple)
//                .foregroundColor(.white)
//                .cornerRadius(10)
//
//                HStack {
//                    Button {
//                        switch buttonState {
//                        case .start:
//                            startTimer()
//
//                        case .stop:
//                            isRecording.toggle()
//                            stopTimer()
//                        }
//                        buttonState.toggle()
//                    } label: {
//                        Text(buttonState.rawValue.capitalized)
//                            .font(.system(size: 20, weight: .bold))
//                    }
//                    .padding()
//                    .background(.green)
//                    .foregroundColor(.white)
//                    .cornerRadius(10)
//
//                    Button {
////                        print("\nFix")
////                        print(jointModelTransforms, "\n")
////                        comparisonFrameValue = jointModelTransforms
//                        let frames = Defaults.shared.getExerciseTargetFrames()
//                        frames.enumerated().forEach { i, value in
//                            print("i")
//                            value.printf()
//                        }
//                    } label: {
//                        Text("Fix")
//                            .font(.system(size: 20, weight: .bold))
//                    }
//                    .padding()
//                    .background(.purple)
//                    .foregroundColor(.white)
//                    .cornerRadius(10)
//                }
//            }
//        }
//        // FOR debug
//        .onAppear {
////            startTimer()
//        }
//    }
//
//    func startTimer() {
//        timerCancellable = Timer.publish(every: 1, on: .main, in: .default)
//            .autoconnect()
//            .receive(on: DispatchQueue.main)
//            .sink(receiveValue: { somee in
//                switch timerValue {
//                case 0:
//                    timerValue = Constants.timetStartTime + 1
//                    stopTimer()
//                    isRecording.toggle()
//
//                default:
//                    timerValue -= 1
//                }
//            })
//    }
//
//    func stopTimer() {
//        timerCancellable?.cancel()
//    }
//}

// MARK: - AR ViewContainer

//struct ARViewContainer: UIViewRepresentable {
//
//    @Binding var jointModelTransforms: Frame
//    @Binding var isRecording: Bool
//    @Binding var some: String
//    @Binding var comparisonFrameValue: Frame
//
//    func makeUIView(context: Context) -> ARView {
//
//        let arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: true)
//        arView.session.delegate = context.coordinator
//
//        let configuration = ARBodyTrackingConfiguration()
//        arView.session.run(configuration)
//        arView.scene.addAnchor(context.coordinator.characterAnchor)
//
//
//        return arView
//
//    }
//
//    func makeCoordinator() -> Coordinator {
//        Coordinator(
//            jointModelTransforms: $jointModelTransforms,
//            isRecording: $isRecording,
//            some: $some,
//            comparisonFrameValue: $comparisonFrameValue
//        )
//    }
//
//    func updateUIView(_ uiView: ARView, context: Context) {
//
//    }
//
//    // MARK: - Coordinator
//
//    class Coordinator: NSObject, ARSessionDelegate {
//
//        let characterAnchor = AnchorEntity()
//        var character: BodyTrackedEntity?
//
//        var cancellable: AnyCancellable? = nil
//        var cancellables: Set<AnyCancellable> = Set()
//
//        @Binding var jointModelTransformsCurrent: Frame
//        @Binding var some: String
//
//        /// True if timer is out
//        @Binding var isTrainingInProgress: Bool
//        /// True if recording training/exercise data is started
//        var isRecording: Bool = false
//
//        // Recording
//        var exerciseFrames: Frames = []
//        @Binding var comparisonFrameValue: Frame
//        // Training
//        var exerciseFramesLoaded: Frames = []
//        var exerciseFramesCount: Int = 0
//
//        init(
//            jointModelTransforms: Binding<[simd_float4x4]>,
//            isRecording: Binding<Bool>,
//            some: Binding<String>,
//            comparisonFrameValue: Binding<Frame>
//        ) {
//            _jointModelTransformsCurrent = jointModelTransforms
//            _isTrainingInProgress = isRecording
//            _some = some
//            _comparisonFrameValue = comparisonFrameValue
//            super.init()
//
//            cancellable = Entity.loadBodyTrackedAsync(named: "robot")
//                .sink(
//                    receiveCompletion: { completion in
//                        if case let .failure(error) = completion {
//                            print("Error: Unable to load model: \(error.localizedDescription)")
//                        }
//                        self.cancellable?.cancel()
//                    },
//                    receiveValue: { character in
//                        character.scale = GlobalConstants.characterScale
//                        self.character = character
//                        self.cancellable?.cancel()
//                    }
//                )
//
//            if GlobalConstants.mode == .training {
//                exerciseFramesLoaded = Defaults.shared.getExerciseTargetFrames()
//                exerciseFramesCount = exerciseFramesLoaded.count
//            }
//        }
//
//        // MARK: - Delegate method
//
//        let trackingJointNamesRawValues: [Int] = {
//            GlobalConstants.trackingJointNames.map { $0.rawValue }
//        }()
//
//        var wasRecorded = false
//
//        func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
//            for anchor in anchors {
//                guard let bodyAnchor = anchor as? ARBodyAnchor else { continue }
//
//                let transforms = bodyAnchor.skeleton.jointModelTransforms
//                jointModelTransformsCurrent = trackingJointNamesRawValues.map {  transforms[$0] }
//
//                if isTrainingInProgress && !isRecording {
//                    print("\n***** Check If STARTED *****")
//                    _ = self.checkIfExerciseStarted()
//                }
//
//                if isTrainingInProgress && isRecording {
//                    wasRecorded = true
//                    switch GlobalConstants.mode {
//                    case .recording:
//                        exerciseFrames.append(jointModelTransformsCurrent)
//                        print(exerciseFrames.count)
//
//                    case .training:
//                        compareTrainingWithTarget()
//                    }
//                }
//                if !isTrainingInProgress && isRecording {
//                    print("--- STOP Recording ---")
//                    isRecording.toggle()
//
//                    if GlobalConstants.mode == .recording {
//                        cropOneIteration()
//                        exerciseFrames = []
//                    }
//                }
//                if GlobalConstants.mode == .training && !isTrainingInProgress && wasRecorded {
//                    print("\n ---- Iterations Results ----")
//                    makeTrainingDescription(from: iterationsResults)
//                }
//
//                let bodyPosition = simd_make_float3(bodyAnchor.transform.columns.3)
//                characterAnchor.position = bodyPosition + GlobalConstants.characterOffset
//                characterAnchor.orientation = Transform(matrix: bodyAnchor.transform).rotation
//
//                if let character = character, character.parent == nil {
//                    characterAnchor.addChild(character)
//                }
//            }
//        }
//
//        // MARK: - Check If Started
//
//        func checkIfExerciseStarted() -> Bool {
//            guard !comparisonFrameValue.isEmpty else {
//                comparisonFrameValue = jointModelTransformsCurrent
//                return false
//            }
//
//            let resultValue = jointModelTransformsCurrent.compare(to: comparisonFrameValue)
//
//            let result = resultValue.isStartStopMovement
//            print("---- Compare ---- \(resultValue * 100)% ----- \(result)")
//            some = "\(round(resultValue * 10000) / 100)%"
//
//            // ------ Matrix Printing  ------
////            print("\nComparison Value:")
////            comparisonFrameValue.printf()
////            print("\nCurrent Value:")
////            jointModelTransformsCurrent.printf()
////            print("\nDifference:")
////            let diff = jointModelTransformsCurrent.enumerated().map { index, simd_4x4 in
////                simd_4x4 - comparisonFrameValue[index]
////            }
////            diff.printf()
//            // ------------------------------
//
//            if GlobalConstants.mode == .recording && result {
////                print("Clear exerciseFrames   from: \(exerciseFrames.count)")
//                exerciseFrames = [comparisonFrameValue]
////                print("                       to: \(exerciseFrames.count)")
//            }
//
//            isRecording = result
//
//            return result
//        }
//
//        // MARK: - Compare Training With Target
//
//        var exerciseFramesIndex = GlobalConstants.exerciseFramesFirstIndex
//        var couldDetectEndOfIteration: Bool {
//            let couldDetectEndOfIterationIndex = Float(exerciseFramesCount) * GlobalConstants.couldDetectEndOfIterationIndicator
//            return Float(exerciseFramesIndex) >= couldDetectEndOfIterationIndex
//        }
//        var iterationsResults: [[Float]] = [[]]
//        var numberOfIterations = 0
//
//        var currentNumberOfStaticFrames = 0
//        var previousValueOfStaticFrame: Float = 0.0
//
//        var previous: Frame = []
//
//        func compareTrainingWithTarget() {
//            let lastTargetFrame = exerciseFramesLoaded.last
//
//            // Detection end of iteration
//            if couldDetectEndOfIteration,
//               let last = lastTargetFrame {
//                let resultValue = jointModelTransformsCurrent.compare(to: last)
////                print("Could Detect End Of Iteration with --- resultValue: \(resultValue)")
//
//                if resultValue.isCloseToEqual {
////                    print("Could Detect End Of Iteration with --- resultValue: \(resultValue)")
//
//                    if previous.isEmpty {
//                        previous = jointModelTransformsCurrent
//                        currentNumberOfStaticFrames = 1
//                    } else {
//                        let resultValue2 = jointModelTransformsCurrent.compare(to: previous)
//                        print("---- Compare with previous ---- \(resultValue2 * 100)% -----")
//                        previous = jointModelTransformsCurrent
//
//                        if resultValue2.isVeryCloseToEqual {
//                            currentNumberOfStaticFrames += 1
//                        }
//                    }
//
//                    print("    currentNumberOfStaticFrames = \(currentNumberOfStaticFrames)")
//                }
//            }
//
//
//            if currentNumberOfStaticFrames == GlobalConstants.staticPositionIndicator {
//                // Start detection start of iteration
//                print("\nNew iteration initiated by User")
//                iterationsResults[numberOfIterations].removeLast(GlobalConstants.staticPositionIndicator - 1)
//                startDetectionStartOfIteration()
//            } else {
//                // Recording results
//                let targetFrame = exerciseFramesLoaded[exerciseFramesIndex]
//
//                let resultValue = jointModelTransformsCurrent.compare(to: targetFrame)
//                print("---- Compare With Target ---- \(resultValue * 100)% ----- \(exerciseFramesIndex)")
//                iterationsResults[numberOfIterations].append(resultValue)
//
//                some = "-\(currentNumberOfStaticFrames)- \(iterationsResults.count): \(iterationsResults[numberOfIterations].count)"
//
//                if exerciseFramesIndex < exerciseFramesLoaded.count - 1 {
//                    exerciseFramesIndex += 1
//                }
//            }
//        }
//
//        func startDetectionStartOfIteration() {
//            iterationsResults.append([])
//            numberOfIterations += 1
//
//            exerciseFramesIndex = GlobalConstants.exerciseFramesFirstIndex
//
//            currentNumberOfStaticFrames = 0
//            previousValueOfStaticFrame = 0.0
//
//            comparisonFrameValue = jointModelTransformsCurrent
//            previous = []
//
//            isRecording = false
//        }
//
//        /// For exercise recording process
//        func cropOneIteration() {
//            let previousChecked = exerciseFrames.last
//            let (frameIndex, _) = exerciseFrames.reversed().enumerated().first { index, frame in
//                guard index < exerciseFrames.count - 1,
//                      let previous = previousChecked
//                else {
//                    return false
//                }
//
//                let resultValue = frame.compare(to: previous)
//                let result = resultValue.isStartStopMovement
//
//                print("\n---- Compare ---- \(resultValue * 100)% ----- \(result)")
//
//                return result
//            } ?? (exerciseFrames.count - 1, exerciseFrames.last)
//
//            let lastFrameIndex = frameIndex > 0 ? exerciseFrames.count - (frameIndex - 1) : exerciseFrames.count - 1
//            let croppedFrames: Frames = Array(exerciseFrames[0...lastFrameIndex])
//
//            print("Size: \(croppedFrames.count)")
//
//            Defaults.shared.setExerciseTargetFrames(croppedFrames)
//        }
//
//        func makeTrainingDescription(from results: [[Float]]) {
//            var iterations: [IterationResults] = []
//
//            results.enumerated().forEach { index, iteration in
//                if iteration.count > exerciseFramesCount / 3 * 2 {
//                    let score = iteration.reduce(0.0, +) / Float(iteration.count)
//                    iterations.append(IterationResults(
//                        score: score,
//                        speed: Float(iteration.count) / Float(exerciseFramesCount)
//                    ))
//
//                    print("Score of \(index + 1) Iteration: \(Int(score * 100))%")
//                    print(iterations.last!.speedDescription)
////                    print(iteration)
//                }
//            }
//
//            let numberOfIterations = iterations.count
//            print("Number Of Iterations: \(numberOfIterations)\n")
//
//            let score = iterations.reduce(0.0) { $0 + $1.score } / Float(numberOfIterations)
//            print("\nGeneral score: \(Int(score * 100))%")
//        }
//
//    }
//
//}
