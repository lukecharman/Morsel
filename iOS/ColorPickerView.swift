import SwiftUI

struct ColorPickerView: View {
  @EnvironmentObject var appSettings: AppSettings

  @State private var rotation: Double = 0
  @State private var pendingColor: UIColor?

  @State private var particleTrigger = UUID()
  @State private var currentParticleColor: Color = .clear

  var body: some View {
    VStack {
      Spacer()

      ZStack {
        MorselView(
          shouldOpen: .constant(false),
          shouldClose: .constant(false),
          isChoosingDestination: .constant(true),
          destinationProximity: .constant(0.5),
          onAdd: { _ in }
        )
        .scaleEffect(2)
        .rotation3DEffect(
          .degrees(rotation),
          axis: (x: 0, y: 1, z: 0),
          perspective: 0.5
        )
        .animation(.easeInOut(duration: 0.6), value: rotation)

        ParticleView(colour: currentParticleColor)
          .id(particleTrigger)
      }

      Spacer()

      ScrollView(.horizontal) {
        HStack(spacing: 42) {
          colorButton("Orange", .orange)
          colorButton("Blue", .blue)
          colorButton("Red", .red)
          colorButton("Green", .green)
          colorButton("Pink", .pink)
          colorButton("White", .white)
        }
      }
      .padding(.bottom, 32)
      .scrollIndicators(.hidden)
    }
  }

  @ViewBuilder
  private func colorButton(_ label: String, _ swiftUIColor: Color) -> some View {
    Button {
      let newColor = UIColor(swiftUIColor)
      if newColor != appSettings.morselColor {
        pendingColor = newColor
        withAnimation(.easeInOut(duration: 0.6)) {
          rotation += 360
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
          if let colour = pendingColor {
            appSettings.morselColor = colour
            currentParticleColor = swiftUIColor
            particleTrigger = UUID()
            pendingColor = nil
          }
        }
      }
    } label: {
      Text(label)
    }
  }
}

struct Particle: Identifiable {
  let id = UUID()
  let xOffset: CGFloat
  let yOffset: CGFloat
  let size: CGFloat
  let colour: Color
  let lifetime: Double
}

struct ParticleView: View {
  let colour: Color
  @State private var particles: [Particle] = []
  @State private var animate = false

  var body: some View {
    ZStack {
      ForEach(particles) { particle in
        Circle()
          .fill(particle.colour)
          .frame(width: particle.size, height: particle.size)
          .offset(
            x: animate ? particle.xOffset : 0,
            y: animate ? particle.yOffset : 0
          )
          .opacity(animate ? 0 : 1)
          .scaleEffect(animate ? 1.0 : 0.5)
          .animation(.easeOut(duration: particle.lifetime), value: animate)
      }
    }
    .onAppear {
      generateParticles()
      // Animate on next runloop to allow initial state to render
      DispatchQueue.main.async {
        animate = true
      }

      // Clear them after they're done
      DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
        particles.removeAll()
        animate = false
      }
    }
  }

  private func generateParticles() {
    let count = Int.random(in: 200...300)
    particles = (0..<count).map { _ in
      let angle = Double.random(in: 0...2 * .pi)
      let speed = CGFloat.random(in: 500...600)
      let size = CGFloat.random(in: 16...24)
      let lifetime = Double.random(in: 3...5)

      return Particle(
        xOffset: cos(angle) * speed,
        yOffset: sin(angle) * speed,
        size: size,
        colour: colour.opacity(0.8),
        lifetime: lifetime
      )
    }
  }
}
