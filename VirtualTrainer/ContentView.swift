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

    @State var jointModelTransforms: [simd_float4x4] = []
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
                .foregroundColor(.white)
//                .animation(.easeInOut(duration: 1).speed(1), value: timerValue)

            VStack {
                Spacer()

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
                    Text(buttonState.rawValue)
                        .font(.system(size: 20, weight: .bold))
                }
                .padding()
                .background(.green)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
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

    @Binding var jointModelTransforms: [simd_float4x4]
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

        let characterOffset: SIMD3<Float> = [-0.5, 0, 0]
        let characterAnchor = AnchorEntity()
        var character: BodyTrackedEntity?

        var cancellable: AnyCancellable? = nil
        var cancellables: Set<AnyCancellable> = Set()

        @Binding var jointModelTransformsCurrent: [simd_float4x4]
        @Binding var isRecording: Bool

        var exerciseFrames: [[simd_float4x4]] = []
        var comparisonValue: [simd_float4x4] = []

        init(
            jointModelTransforms: Binding<[simd_float4x4]>,
            isRecording: Binding<Bool>
        ) {
            _jointModelTransformsCurrent = jointModelTransforms
            _isRecording = isRecording
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
                          self.isRecording else {
                        return
                    }
                    self.compare()
                    self.comparisonValue = self.jointModelTransformsCurrent
                })
                .store(in: &cancellables)
        }

        func compare() {
            guard !self.comparisonValue.isEmpty else {
                self.comparisonValue = self.jointModelTransformsCurrent
                return
            }

            let resultArray = self.jointModelTransformsCurrent.enumerated().map { index, simd4x4 -> Bool in
//                print("\(index) - ", simd4x4.debugDescription, "\n")
                return simd_almost_equal_elements(simd4x4, self.comparisonValue[index], 0.1)
            }

            let resultResents = Float(resultArray.filter { $0 }.count) / Float(resultArray.count) * 100
            print("\n--- Compare with previous ---")
            print("\(resultResents) %")
        }

        func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
            for anchor in anchors {
                guard let bodyAnchor = anchor as? ARBodyAnchor else { continue }

            jointModelTransformsCurrent = bodyAnchor.skeleton.jointModelTransforms
                // Update the position of the character anchor's position.
                let bodyPosition = simd_make_float3(bodyAnchor.transform.columns.3)
                characterAnchor.position = bodyPosition + characterOffset
                // Also copy over the rotation of the body anchor, because the skeleton's pose
                // in the world is relative to the body anchor's rotation.
                characterAnchor.orientation = Transform(matrix: bodyAnchor.transform).rotation

                if let character = character, character.parent == nil {
                    // Attach the character to its anchor as soon as
                    // 1. the body anchor was detected and
                    // 2. the character was loaded.
                    characterAnchor.addChild(character)
                }
            }
        }

    }

}

extension Array where Element == simd_float4x4 {

    func compare(to array: [simd_float4x4]) -> Float {
        let resultArray = self.enumerated().map { index, simd4x4 -> Bool in
            return simd_almost_equal_elements(simd4x4, array[index], 0.1)
        }

        return Float(resultArray.filter { $0 }.count) / Float(resultArray.count)
    }
    
}

extension ContentView {

    enum ButtonState: String {
        case start = "Start"
        case stop = "Stop"

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
