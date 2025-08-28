import CoreMorsel
import SwiftUI

struct MorselStudio: View {
  @State var shouldOpen = false
  @State var shouldClose = false
  @State var isChoosingDestination = false
  @State var destinationProximity: CGFloat = 0.0
  @State var isLookingUp = false
  @State var morselColor: Color = AppSettings.shared.morselColor
  @State private var anchor: MorselAnchor? = .init(edge: .bottom, padding: 16)
  @StateObject private var speaker = MorselSpeaker()

  @State private var debugMode: Bool = false
  @State private var debugIsBlinking: Bool = false
  @State private var debugIsSwallowing: Bool = false
  @State private var debugIdleOffset: CGSize = .zero
  @State private var debugLookaroundOffset: CGFloat = 0
  @State private var messageText: String = ""

  var body: some View {
    VStack {
      MorselView(
        shouldOpen: $shouldOpen,
        shouldClose: $shouldClose,
        isChoosingDestination: $isChoosingDestination,
        destinationProximity: $destinationProximity,
        isLookingUp: $isLookingUp,
        speaker: speaker,
        anchor: $anchor,
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
      // Anchor controls
      VStack(alignment: .leading, spacing: 12) {
        Toggle("Center (nil anchor)", isOn: Binding(
          get: { anchor == nil },
          set: { useCenter in
            withAnimation {
              if useCenter {
                anchor = nil
              } else {
                anchor = anchor ?? .init(edge: .bottom, padding: 16)
              }
            }
          }
        ))
        .padding(.horizontal)

        if anchor != nil {
          HStack {
            Text("Edge")
            Spacer()
            Picker("Edge", selection: Binding(
              get: { anchor?.edge ?? .bottom },
              set: { newEdge in anchor = .init(edge: newEdge, padding: anchor?.padding ?? 16) }
            )) {
              Text("Top").tag(MorselAnchor.Edge.top)
              Text("Bottom").tag(MorselAnchor.Edge.bottom)
              Text("Left").tag(MorselAnchor.Edge.left)
              Text("Right").tag(MorselAnchor.Edge.right)
            }
            .pickerStyle(.segmented)
          }
          .padding(.horizontal)

          VStack(alignment: .leading) {
            Text("Padding: \(Int(anchor?.padding ?? 16))")
            Slider(value: Binding(
              get: { anchor?.padding ?? 16 },
              set: { newVal in anchor = .init(edge: anchor?.edge ?? .bottom, padding: newVal) }
            ), in: 0...80)
          }
          .padding(.horizontal)
        }
      }
      .padding(.bottom, 8)
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

      // Quick speech test
      HStack {
        TextField("Say...", text: $messageText)
          .textFieldStyle(.roundedBorder)
        Button("Speak") {
          speaker.speak(messageText)
          messageText = ""
        }
      }
      .padding(.horizontal)
      .padding(.bottom, 8)

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
