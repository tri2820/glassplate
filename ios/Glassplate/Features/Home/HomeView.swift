import SwiftUI

struct HomeView: View {
    @State private var showingInfo = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    hero

                    GlassCard {
                        Label("Native by default", systemImage: "checkmark.seal.fill")
                            .font(.headline)
                            .foregroundStyle(.indigo)

                        Text("System navigation and toolbar controls automatically gain Liquid Glass on iOS 26, while older systems receive a graceful material fallback.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.top, 6)
                    }

                    GlassCard {
                        Label("Ready to ship", systemImage: "paperplane.fill")
                            .font(.headline)
                            .foregroundStyle(.purple)

                        Text("The included asc workflows cover simulator builds, signed archives, TestFlight distribution, and an App Store dry run.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.top, 6)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .background {
                AmbientBackground()
            }
            .navigationTitle("Glassplate")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    GlassToolbarButton(title: "About", systemImage: "info") {
                        showingInfo = true
                    }
                }
            }
            .sheet(isPresented: $showingInfo) {
                AboutView()
            }
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: "circle.hexagongrid.fill")
                .font(.system(size: 46, weight: .semibold))
                .symbolRenderingMode(.hierarchical)

            Text("A clear place to start.")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))

            Text("SwiftUI structure, adaptive glass surfaces, and a release path that lives beside the code.")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 28)
    }
}

private struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Glassplate",
                systemImage: "circle.hexagongrid.fill",
                description: Text("A compact iOS boilerplate for building and shipping with native Liquid Glass and asc.")
            )
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

struct AmbientBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color.indigo.opacity(0.20),
                Color.cyan.opacity(0.10),
                Color(uiColor: .systemBackground)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

#Preview {
    HomeView()
}

