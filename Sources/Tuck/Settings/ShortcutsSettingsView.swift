import KeyboardShortcuts
import SwiftUI

struct ShortcutsSettingsView: View {
    var body: some View {
        Form {
            Section("Global shortcuts") {
                KeyboardShortcuts.Recorder("Toggle hidden items", name: .toggleHidden)
                KeyboardShortcuts.Recorder("Peek at always-hidden items", name: .peekAlwaysHidden)
            }
            Section {
                Text("Shortcuts work system-wide and require no privacy permissions.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}
