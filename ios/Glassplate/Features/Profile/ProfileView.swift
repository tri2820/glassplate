import SwiftUI

struct ProfileView: View {
    @AppStorage("prefersHaptics") private var prefersHaptics = true
    @AppStorage("usesCompactCards") private var usesCompactCards = false
    @AppStorage("prefersDarkMode") private var prefersDarkMode = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    Toggle("Dark mode", isOn: $prefersDarkMode)
                }

                Section("Experience") {
                    Toggle("Haptic feedback", isOn: $prefersHaptics)
                    Toggle("Compact cards", isOn: $usesCompactCards)
                }

                Section("Build") {
                    LabeledContent("Version", value: appVersion)
                    LabeledContent("Automation", value: "asc")
                }

                Section {
                    Link(destination: URL(string: "https://asccli.sh/")!) {
                        Label("App Store Connect CLI", systemImage: "arrow.up.right.square")
                    }
                } footer: {
                    Text("Release credentials stay in Keychain or CI secrets, never in the repository.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Profile")
        }
    }

    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        return "\(version ?? "1.0") (\(build ?? "1"))"
    }
}

#Preview {
    ProfileView()
}

