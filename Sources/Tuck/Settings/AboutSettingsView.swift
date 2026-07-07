import SwiftUI

struct AboutSettingsView: View {
    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev"
    }

    var body: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "chevron.left.circle.fill")
                .font(.system(size: 56, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 96, height: 96)
                .glassEffect(.regular.tint(.indigo).interactive(), in: .rect(cornerRadius: 24))
            Text("Tuck")
                .font(.largeTitle.bold())
            Text("Version \(version)")
                .foregroundStyle(.secondary)
            Text("A free, open-source menu bar organizer.\nNo permissions. No tracking. GPL-3.0.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            HStack(spacing: 12) {
                Link(destination: URL(string: "https://github.com/TonmoyBishwas/Tuck")!) {
                    Label("GitHub", systemImage: "curlybraces")
                }
                .buttonStyle(.glass)
                Link(destination: URL(string: "https://github.com/TonmoyBishwas/Tuck/releases")!) {
                    Label("Releases", systemImage: "arrow.down.circle")
                }
                .buttonStyle(.glass)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
