import Foundation

enum AppTab: String, CaseIterable, Identifiable {
    case home
    case explore
    case profile

    var id: Self { self }

    var title: String {
        switch self {
        case .home: "Home"
        case .explore: "Explore"
        case .profile: "Profile"
        }
    }

    var systemImage: String {
        switch self {
        case .home: "sparkles"
        case .explore: "safari"
        case .profile: "person.crop.circle"
        }
    }
}

