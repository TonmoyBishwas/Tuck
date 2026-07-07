import SwiftUI

struct GeneralSettingsView: View {
    @EnvironmentObject private var preferences: Preferences
    @EnvironmentObject private var loginItems: LoginItemManager

    var body: some View {
        Form {
            Section {
                Toggle("Launch Tuck at login", isOn: Binding(
                    get: { loginItems.isEnabled },
                    set: { loginItems.setEnabled($0) }
                ))
                if loginItems.requiresApproval {
                    Text("Approval needed: enable Tuck in System Settings → General → Login Items.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                Picker("At launch", selection: $preferences.startBehavior) {
                    ForEach(StartBehavior.allCases) { behavior in
                        Text(behavior.label).tag(behavior)
                    }
                }
            }

            Section("Tucking away") {
                Toggle("Automatically re-hide items", isOn: $preferences.autoRehideEnabled)
                if preferences.autoRehideEnabled {
                    LabeledContent("Re-hide after \(Int(preferences.autoRehideDelay)) seconds") {
                        Slider(value: $preferences.autoRehideDelay, in: 2...120, step: 1)
                            .frame(width: 180)
                    }
                }
                Toggle("Hide items when clicking elsewhere", isOn: $preferences.collapseOnOutsideClick)
            }

            Section("Revealing") {
                Toggle("Show hidden items when hovering over the menu bar", isOn: $preferences.hoverToReveal)
            }
        }
        .formStyle(.grouped)
    }
}
