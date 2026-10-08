import SwiftUI

struct RootTabView: View {
    @State private var selection: AppTab = LaunchConfiguration.initialTab ?? .home

    var body: some View {
        TabView(selection: $selection) {
            Tab(AppTab.home.title, systemImage: AppTab.home.systemImage, value: AppTab.home) {
                HomeView()
            }

            Tab(AppTab.chat.title, systemImage: AppTab.chat.systemImage, value: AppTab.chat) {
                ChatView()
            }

            Tab(AppTab.explore.title, systemImage: AppTab.explore.systemImage, value: AppTab.explore) {
                ExploreView()
            }

            Tab(AppTab.profile.title, systemImage: AppTab.profile.systemImage, value: AppTab.profile) {
                ProfileView()
            }
        }
        .tint(.indigo)
        .glassplateTabBarBehavior(for: selection)
    }
}

private extension View {
    @ViewBuilder
    func glassplateTabBarBehavior(for tab: AppTab) -> some View {
        if #available(iOS 26.0, *) {
            tabBarMinimizeBehavior(tab == .chat ? .never : .onScrollDown)
        } else {
            self
        }
    }
}

#Preview {
    RootTabView()
}

