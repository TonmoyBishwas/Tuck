import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var selection: SettingsTabSelection

    var body: some View {
        TabView(selection: $selection.tab) {
            GeneralSettingsView()
                .tabItem { Label("General", systemImage: "gearshape") }
                .tag(SettingsTab.general)
            SectionsSettingsView()
                .tabItem { Label("Sections", systemImage: "menubar.rectangle") }
                .tag(SettingsTab.sections)
            ShortcutsSettingsView()
                .tabItem { Label("Shortcuts", systemImage: "keyboard") }
                .tag(SettingsTab.shortcuts)
            AboutSettingsView()
                .tabItem { Label("About", systemImage: "info.circle") }
                .tag(SettingsTab.about)
        }
        .frame(width: 520, height: 420)
    }
}
