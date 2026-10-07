import SwiftUI

struct RootTabView: View {
    @State private var selection: AppTab = .home

    var body: some View {
        TabView(selection: $selection) {
            Tab(AppTab.home.title, systemImage: AppTab.home.systemImage, value: AppTab.home) {
                HomeView()
            }

            Tab(AppTab.explore.title, systemImage: AppTab.explore.systemImage, value: AppTab.explore) {
                ExploreView()
            }

            Tab(AppTab.profile.title, systemImage: AppTab.profile.systemImage, value: AppTab.profile) {
                ProfileView()
            }
        }
        .tint(.indigo)
        .glassplateTabBarBehavior()
    }
}

private extension View {
    @ViewBuilder
    func glassplateTabBarBehavior() -> some View {
        if #available(iOS 26.0, *) {
            tabBarMinimizeBehavior(.onScrollDown)
        } else {
            self
        }
    }
}

#Preview {
    RootTabView()
}

