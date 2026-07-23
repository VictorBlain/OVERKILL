import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                // MARK: Appearance
                Section {
                    Picker("Color Scheme", selection: Binding(
                        get: { appState.appearanceMode },
                        set: { appState.appearanceMode = $0 }
                    )) {
                        ForEach(AppearanceMode.allCases, id: \.self) { mode in
                            Text(mode.label).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    SectionHeader(icon: "paintpalette", label: "APPEARANCE")
                }

                // MARK: Accessibility
                Section {
                    ToggleRow(icon: "textformat.size", label: "Large Text",   isOn: $appState.largeText)
                    ToggleRow(icon: "circle.lefthalf.filled", label: "High Contrast", isOn: $appState.highContrast)
                    ToggleRow(icon: "hare.fill", label: "Reduce Motion", isOn: $appState.reduceMotion)
                } header: {
                    SectionHeader(icon: "accessibility", label: "ACCESSIBILITY")
                }

                // MARK: Tutorial
                Section {
                    Button {
                        appState.resetTutorial()
                        dismiss()
                    } label: {
                        Label("Replay Tutorial", systemImage: "play.circle.fill")
                            .foregroundStyle(Theme.electric)
                    }
                } header: {
                    SectionHeader(icon: "book", label: "TUTORIAL")
                } footer: {
                    Text("Resets the onboarding flow — you'll see it the next time you open the app.")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.muted)
                }

                // MARK: Info
                Section {
                    NavigationLink {
                        AboutView()
                    } label: {
                        Label("About OVERKILL", systemImage: "info.circle")
                    }
                    NavigationLink {
                        CreditsView()
                    } label: {
                        Label("Credits", systemImage: "heart.fill")
                    }
                    NavigationLink {
                        VersionView()
                    } label: {
                        Label("Version", systemImage: "tag.fill")
                    }
                } header: {
                    SectionHeader(icon: "info.circle", label: "INFORMATION")
                }

                // MARK: Future
                Section {
                    Label("iCloud Sync", systemImage: "icloud")
                        .foregroundStyle(Theme.muted)
                        .badge(Text("Soon").foregroundStyle(Theme.amber))
                    Label("Custom Themes", systemImage: "swatchpalette")
                        .foregroundStyle(Theme.muted)
                        .badge(Text("Soon").foregroundStyle(Theme.amber))
                    Label("3D Graphing", systemImage: "cube")
                        .foregroundStyle(Theme.muted)
                        .badge(Text("Soon").foregroundStyle(Theme.amber))
                    Label("Physics Simulations", systemImage: "atom")
                        .foregroundStyle(Theme.muted)
                        .badge(Text("Soon").foregroundStyle(Theme.amber))
                } header: {
                    SectionHeader(icon: "sparkles", label: "COMING SOON")
                }
            }
            .scrollContentBackground(.hidden)
            .background(.black)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Theme.electric)
                        .fontWeight(.semibold)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

private struct SectionHeader: View {
    let icon: String
    let label: String

    var body: some View {
        Label(label, systemImage: icon)
            .font(.system(size: 11, weight: .semibold, design: .monospaced))
            .foregroundStyle(Theme.muted)
    }
}

private struct ToggleRow: View {
    let icon: String
    let label: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            Label(label, systemImage: icon)
        }
        .tint(Theme.electric)
    }
}
