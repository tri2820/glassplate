import XCTest
@testable import Glassplate

final class AppTabTests: XCTestCase {
    func testEveryTabHasDisplayMetadata() {
        XCTAssertEqual(AppTab.allCases.count, 3)

        for tab in AppTab.allCases {
            XCTAssertFalse(tab.title.isEmpty)
            XCTAssertFalse(tab.systemImage.isEmpty)
        }
    }

    func testRawValuesAreStable() {
        XCTAssertEqual(AppTab.home.rawValue, "home")
        XCTAssertEqual(AppTab.explore.rawValue, "explore")
        XCTAssertEqual(AppTab.profile.rawValue, "profile")
    }
}

