import SwiftUI

struct ExploreView: View {
    @State private var query = ""

    private let ideas = [
        Idea(title: "Adaptive navigation", detail: "Use system containers first", icon: "rectangle.3.group"),
        Idea(title: "Focused glass", detail: "Reserve custom effects for hierarchy", icon: "circle.lefthalf.filled"),
        Idea(title: "Release automation", detail: "Keep repeatable steps in .asc", icon: "shippingbox"),
        Idea(title: "Accessible motion", detail: "Let platform controls carry semantics", icon: "figure.wave")
    ]

    fileprivate var filteredIdeas: [Idea] {
        guard !query.isEmpty else { return ideas }
        return ideas.filter {
            $0.title.localizedCaseInsensitiveContains(query) ||
            $0.detail.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        NavigationStack {
            List(filteredIdeas) { idea in
                HStack(spacing: 14) {
                    Image(systemName: idea.icon)
                        .frame(width: 38, height: 38)
                        .foregroundStyle(.indigo)
                        .background(.indigo.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 3) {
                        Text(idea.title)
                            .font(.headline)
                        Text(idea.detail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 5)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Explore")
            .searchable(text: $query, prompt: "Search patterns")
        }
    }
}

private struct Idea: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let icon: String
}

#Preview {
    ExploreView()
}

