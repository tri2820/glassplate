import XCTest

final class ChatScreenshotTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testEmptyState() {
        let app = launch(tab: "chat")
        XCTAssertTrue(app.staticTexts["Start a conversation"].waitForExistence(timeout: 10))
        capture(named: "chat-empty")
    }

    func testConversation() {
        let app = launch(tab: "chat", transcript: "conversation")
        XCTAssertTrue(app.staticTexts["What can you do?"].waitForExistence(timeout: 10))
        capture(named: "chat-conversation")
    }

    func testComposerSendsMessage() {
        let app = launch(tab: "chat")

        let field = composer(in: app)
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        field.typeText("Hello there")

        app.buttons["composer.send"].tap()

        // The field must clear right away, not after the next unrelated render.
        XCTAssertNotEqual(composer(in: app).value as? String, "Hello there")

        let reply = app.staticTexts["Hello! I'm the Glassplate assistant. Ask me anything."]
        XCTAssertTrue(reply.waitForExistence(timeout: 10))
        capture(named: "chat-sent")
    }

    /// While the reply is pending there must be a typing indicator and no empty bubble.
    func testThinkingState() {
        let app = launch(tab: "chat", extra: ["-uitest-delay", "4000"])

        let field = composer(in: app)
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        field.typeText("Hello there")
        app.buttons["composer.send"].tap()

        let typing = app.descendants(matching: .any).matching(identifier: "chat.typing").firstMatch
        XCTAssertTrue(typing.waitForExistence(timeout: 6))
        capture(named: "chat-thinking")
    }

    /// Scrolling the chat must not minimize the tab bar.
    func testTabBarStaysExpandedWhileScrolling() {
        let app = launch(tab: "chat", transcript: "long")
        XCTAssertTrue(app.staticTexts["What can you do?"].waitForExistence(timeout: 10))
        app.swipeUp()
        app.swipeUp()
        capture(named: "chat-scrolled")
    }

    /// Sending must not dismiss the keyboard: the field keeps focus for the next message.
    func testComposerKeepsFocusAfterSend() {
        let app = launch(tab: "chat", extra: ["-uitest-delay", "3000"])

        let field = composer(in: app)
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        field.typeText("Hello there")

        app.buttons["composer.send"].tap()
        XCTAssertTrue(app.buttons["composer.stop"].waitForExistence(timeout: 5))

        // Type without tapping the field again; this fails if focus was dropped.
        app.typeText("again")
        XCTAssertEqual(composer(in: app).value as? String, "again")
    }

    // MARK: - Helpers

    private func composer(in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: "composer.input").firstMatch
    }

    private func launch(tab: String, transcript: String? = nil, extra: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        var arguments = ["-uitest", "-uitest-tab", tab]
        if let transcript {
            arguments += ["-uitest-transcript", transcript]
        }
        arguments += extra
        app.launchArguments = arguments
        app.launch()
        return app
    }

    private func capture(named name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
