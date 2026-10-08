import SwiftUI

@main
struct GlassplateApp: App {
    @AppStorage("prefersDarkMode") private var prefersDarkMode = false

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .preferredColorScheme(prefersDarkMode ? .dark : .light)
        }
    }
}
