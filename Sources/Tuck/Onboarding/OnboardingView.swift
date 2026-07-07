import SwiftUI

struct OnboardingView: View {
    var onFinished: () -> Void

    @State private var step = 0
    private let lastStep = 2

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                switch step {
                case 0: StepMeetTheChevron()
                case 1: StepCommandDrag()
                default: StepAlwaysHidden()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.smooth(duration: 0.3), value: step)

            HStack {
                if step > 0 {
                    Button("Back") { step -= 1 }
                        .buttonStyle(.glass)
                }
                Spacer()
                HStack(spacing: 6) {
                    ForEach(0...lastStep, id: \.self) { index in
                        Circle()
                            .fill(index == step ? Color.primary : Color.secondary.opacity(0.3))
                            .frame(width: 7, height: 7)
                    }
                }
                Spacer()
                if step < lastStep {
                    Button("Continue") { step += 1 }
                        .buttonStyle(.glassProminent)
                        .tint(.indigo)
                } else {
                    Button("Get Started") { onFinished() }
                        .buttonStyle(.glassProminent)
                        .tint(.indigo)
                }
            }
            .padding(20)
        }
        .frame(width: 580, height: 460)
    }
}

// MARK: - Step 1

private struct StepMeetTheChevron: View {
    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "chevron.left")
                .font(.system(size: 40, weight: .bold))
                .frame(width: 100, height: 100)
                .glassEffect(.regular.tint(.indigo.opacity(0.5)).interactive(), in: .circle)
            Text("Welcome to Tuck")
                .font(.largeTitle.bold())
            Text("Tuck lives in your menu bar as a small chevron (‹).\nClick it to tuck extra icons away — click again to bring them back.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 40)
            Spacer()
        }
    }
}

// MARK: - Step 2

private struct StepCommandDrag: View {
    @State private var dragged = false

    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            GlassEffectContainer(spacing: 8) {
                HStack(spacing: 8) {
                    mockIcon("wifi", tint: .gray)
                    Text("│")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.secondary)
                    mockIcon("chevron.left", tint: .indigo)
                    mockIcon("battery.75percent", tint: dragged ? .clear : .gray)
                        .offset(x: dragged ? -128 : 0)
                        .opacity(dragged ? 0.35 : 1)
                    mockIcon("clock", tint: .gray)
                }
            }
            .frame(height: 60)
            Text("Arrange with ⌘-drag")
                .font(.largeTitle.bold())
            Text("Hold ⌘ (Command) and drag any menu bar icon to the LEFT of Tuck's divider (│). Icons on that side disappear when you tuck — and anything you want visible at all times goes to the right of the chevron.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 40)
            Spacer()
        }
        .onAppear {
            withAnimation(.smooth(duration: 1.4).repeatForever(autoreverses: true).delay(0.5)) {
                dragged = true
            }
        }
    }

    private func mockIcon(_ symbol: String, tint: Color) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 14, weight: .semibold))
            .frame(width: 34, height: 34)
            .glassEffect(.regular.tint(tint.opacity(0.3)), in: .circle)
    }
}

// MARK: - Step 3

private struct StepAlwaysHidden: View {
    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            GlassEffectContainer(spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 26, weight: .semibold))
                        .frame(width: 64, height: 64)
                        .glassEffect(.regular.tint(.purple.opacity(0.4)), in: .circle)
                    Image(systemName: "command")
                        .font(.system(size: 26, weight: .semibold))
                        .frame(width: 64, height: 64)
                        .glassEffect(.regular.tint(.indigo.opacity(0.4)), in: .circle)
                }
            }
            Text("Go further")
                .font(.largeTitle.bold())
            VStack(alignment: .leading, spacing: 10) {
                Label("Want a second, deeper level of hiding? Turn on the always-hidden section in Settings → Sections, then option-click the chevron to peek at it.", systemImage: "moon.zzz")
                Label("Toggle from anywhere with the global shortcut ⌥⌘\\ — change it in Settings.", systemImage: "keyboard")
                Label("Right-click the chevron for Settings and more.", systemImage: "cursorarrow.click.2")
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 48)
            Spacer()
        }
    }
}
