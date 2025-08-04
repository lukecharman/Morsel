import SwiftUI

struct MorselStudio: View {
  @State var shouldOpen = false
  @State var shouldClose = false
  @State var isChoosingDestination = false
  @State var destinationProximity: CGFloat = 0.0
  @State var isLookingUp = false
  @State var morselColor: Color = AppSettings.shared.morselColor

  @State private var debugMode: Bool = false
  @State private var debugIsBlinking: Bool = false
  @State private var debugIsSwallowing: Bool = false
  @State private var debugIdleOffset: CGSize = .zero
  @State private var debugLookaroundOffset: CGFloat = 0

  var body: some View {
    VStack {
      MorselView(
        shouldOpen: $shouldOpen,
        shouldClose: $shouldClose,
        isChoosingDestination: $isChoosingDestination,
        destinationProximity: $destinationProximity,
        isLookingUp: $isLookingUp,
        morselColor: morselColor,
        onAdd: { item in
          print(item)
        },
        debugBindings: .init(
          isBlinking: $debugIsBlinking,
          isSwallowing: $debugIsSwallowing,
          idleOffset: $debugIdleOffset,
          idleLookaroundOffset: $debugLookaroundOffset
        ),
        debugControlMode: debugMode ? .manual : .automatic
      )
      Toggle("Is Looking Up", isOn: Binding(
        get: { isLookingUp },
        set: { newValue in
          withAnimation {
            isLookingUp = newValue
          }
        }
      ))
      .padding(.horizontal)
      Toggle("Is Choosing Destination", isOn: Binding(
        get: { isChoosingDestination },
        set: { newValue in
          withAnimation {
            isChoosingDestination = newValue
          }
        }
      ))
      .padding(.horizontal)
      Slider(value: $destinationProximity, in: -1...1) {
        Text("Destination Proximity")
      }
      .padding()

      Toggle("Manual Debug Mode", isOn: $debugMode)
        .padding()

      if debugMode {
        Button("Blink") {
          withAnimation {
            debugIsBlinking = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
              withAnimation {
                debugIsBlinking = false
              }
            }
          }
        }
        .padding(.horizontal)

        Button("Swallow") {
          withAnimation {
            debugIsSwallowing = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
              withAnimation {
                debugIsSwallowing = false
              }
            }
          }
        }
        .padding(.horizontal)

        VStack {
          Text("Idle Offset Y: \(debugIdleOffset.height, specifier: "%.1f")")
          Slider(value: Binding(
            get: { debugIdleOffset.height },
            set: { debugIdleOffset = CGSize(width: 0, height: $0) }
          ), in: -10...10)
        }.padding()

        VStack {
          Text("Lookaround Offset: \(debugLookaroundOffset, specifier: "%.1f")")
          Slider(value: $debugLookaroundOffset, in: -10...10)
        }.padding()
      }
    }
  }
}
