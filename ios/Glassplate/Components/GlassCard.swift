import SwiftUI

/// Corner-radius scale for app-owned glass surfaces.
enum GlassSurfaceRadius {
    static let chip: CGFloat = 12
    static let control: CGFloat = 22
    static let card: CGFloat = 24
}

extension View {
    /// The single surface recipe for app-owned glass: real Liquid Glass on iOS 26,
    /// one material fallback below it.
    @ViewBuilder
    func glassSurface<S: InsettableShape>(_ shape: S) -> some View {
        if #available(iOS 26.0, *) {
            glassEffect(.regular, in: shape)
        } else {
            background(.regularMaterial, in: shape)
                .overlay {
                    shape.strokeBorder(.primary.opacity(0.08), lineWidth: 0.5)
                }
        }
    }

    @ViewBuilder
    func glassSurface(cornerRadius: CGFloat) -> some View {
        glassSurface(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

struct GlassCard<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassSurface(cornerRadius: GlassSurfaceRadius.card)
    }
}
