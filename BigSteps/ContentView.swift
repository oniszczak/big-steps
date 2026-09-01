import SwiftUI

struct ContentView: View {
    @StateObject private var pedometer = PedometerManager()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.indigo.opacity(0.95), Color.blue.opacity(0.72)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                VStack(spacing: 6) {
                    Image(systemName: "figure.walk.motion")
                        .font(.system(size: 44, weight: .semibold))
                        .symbolEffect(.pulse, options: .repeating, isActive: pedometer.isTracking)

                    Text("BIG STEPS")
                        .font(.headline)
                        .tracking(3)
                }
                .foregroundStyle(.white)

                StepCard(
                    title: "TODAY",
                    steps: pedometer.todaySteps,
                    symbol: "sun.max.fill"
                )

                StepCard(
                    title: "THIS SESSION",
                    steps: pedometer.sessionSteps,
                    symbol: "stopwatch.fill"
                )

                if let message = pedometer.statusMessage {
                    Text(message)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(.horizontal)
                }

                Button {
                    pedometer.resetSession()
                } label: {
                    Label("Reset Session", systemImage: "arrow.counterclockwise")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(.white)
                        .foregroundStyle(.indigo)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(24)
        }
        .onAppear {
            pedometer.start()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                pedometer.refresh()
            }
        }
    }
}

private struct StepCard: View {
    let title: String
    let steps: Int
    let symbol: String

    var body: some View {
        VStack(spacing: 10) {
            Label(title, systemImage: symbol)
                .font(.subheadline.bold())
                .tracking(1.2)
                .foregroundStyle(.secondary)

            Text(steps.formatted())
                .font(.system(size: 58, weight: .bold, design: .rounded))
                .contentTransition(.numericText(value: Double(steps)))
                .animation(.snappy, value: steps)

            Text(steps == 1 ? "step" : "steps")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 16, y: 8)
    }
}

#Preview {
    ContentView()
}
