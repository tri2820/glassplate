import Foundation

enum AppTab: String, CaseIterable, Identifiable {
    case home
    case chat
    case explore
    case profile

    var id: Self { self }

    var title: String {
        switch self {
        case .home: "Home"
        case .chat: "Chat"
        case .explore: "Explore"
        case .profile: "Profile"
        }
    }

    var systemImage: String {
        switch self {
        case .home: "sparkles"
        case .chat: "bubble.left.and.bubble.right"
        case .explore: "safari"
        case .profile: "person.crop.circle"
        }
    }
}

