import SwiftUI

struct SectionsSettingsView: View {
    @EnvironmentObject private var preferences: Preferences

    var body: some View {
        Form {
            Section {
                MenuBarDiagram(showAlwaysHidden: preferences.alwaysHiddenEnabled)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                Text("Hold ⌘ and drag any menu bar icon across Tuck's dividers to choose its section. Icons left of the solid divider (│) hide when you tuck; icons left of the dashed divider (┆) stay hidden even when you expand.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Section("Always-hidden section") {
                Toggle("Enable an always-hidden section", isOn: $preferences.alwaysHiddenEnabled)
                if preferences.alwaysHiddenEnabled {
                    LabeledContent("Peek by option-clicking the chevron") {
                        Button("Peek Now") {
                            AppDelegate.shared?.statusBarController?.expand(peekAlwaysHidden: true)
                        }
                        .buttonStyle(.glass)
                    }
                }
            }

            Section {
                LabeledContent("New to Tuck?") {
                    Button("Show Tutorial") {
                        AppDelegate.shared?.showOnboarding()
                    }
                    .buttonStyle(.glass)
                }
            }
        }
        .formStyle(.grouped)
    }
}

/// A schematic of the menu bar sections, drawn with Liquid Glass capsules.
struct MenuBarDiagram: View {
    var showAlwaysHidden: Bool
    var highlightHidden: Bool = true

    var body: some View {
        GlassEffectContainer(spacing: 6) {
            HStack(spacing: 6) {
                if showAlwaysHidden {
                    diagramDot("moon.zzz.fill", tint: .purple)
                    Text("┆")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.secondary)
                }
                diagramDot("wifi", tint: highlightHidden ? .indigo : .gray)
                diagramDot("battery.75percent", tint: highlightHidden ? .indigo : .gray)
                Text("│")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .bold))
                    .frame(width: 28, height: 28)
                    .glassEffect(.regular.tint(.indigo.opacity(0.4)).interactive(), in: .circle)
                diagramDot("clock", tint: .gray)
            }
            .padding(.horizontal, 4)
        }
    }

    private func diagramDot(_ symbol: String, tint: Color) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 12, weight: .medium))
            .frame(width: 28, height: 28)
            .glassEffect(.regular.tint(tint.opacity(0.25)), in: .circle)
    }
}
