import Foundation
import AI

/// Launch-argument hooks so XCUITest can drive the app into a deterministic state.
/// Every hook is inert unless `-uitest` is passed, and `isUITesting` is always
/// false in Release builds.
enum LaunchConfiguration {
    static var isUITesting: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("-uitest")
        #else
        false
        #endif
    }

    /// `-uitest-tab <home|chat|explore|profile>` selects the starting tab.
    static var initialTab: AppTab? {
        guard isUITesting else { return nil }
        return value(for: "-uitest-tab").flatMap(AppTab.init(rawValue:))
    }

    /// `-uitest-transcript conversation` seeds the chat with a fixture.
    static var seedMessages: [UIMessage] {
        guard isUITesting, let name = value(for: "-uitest-transcript") else { return [] }
        switch name {
        case "conversation":
            return [
                .user("What can you do?"),
                .assistant("""
                I render **Markdown** replies:

                1. Headings and *emphasis*
                2. Lists, `inline code`, and [links](https://example.com)
                3. Fenced code blocks:

                ```swift
                print("Hello, world!")
                ```
                """)
            ]
        case "long":
            return [
                .user("What can you do?"),
                .assistant("I stream replies through the Glassplate Worker."),
                .user("Show me a longer conversation."),
                .assistant("Here is a longer reply so the transcript has enough to scroll through while the tab bar stays in place."),
                .user("Another message."),
                .assistant("And another reply that fills more vertical space in the transcript."),
                .user("Keep going."),
                .assistant("This is the final message in the fixture, long enough to push the content well past the fold.")
            ]
        default:
            return []
        }
    }

    /// `-uitest-reply "<text>"` overrides the canned assistant reply.
    static var scriptedReply: String {
        (isUITesting ? value(for: "-uitest-reply") : nil)
            ?? "Hello! I'm the Glassplate assistant. Ask me anything."
    }

    /// `-uitest-delay <ms>` holds the reply so the thinking state can be captured.
    static var scriptedDelay: Duration {
        guard isUITesting, let milliseconds = value(for: "-uitest-delay").flatMap(Int.init) else {
            return .zero
        }
        return .milliseconds(milliseconds)
    }

    private static func value(for flag: String) -> String? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: flag),
              arguments.indices.contains(index + 1) else { return nil }
        return arguments[index + 1]
    }
}

/// Streams a canned reply so UI tests never touch the network.
struct ScriptedChatTransport: ChatTransport {
    var reply: String
    var delay: Duration = .zero

    func sendMessages(_ request: ChatRequest) async throws -> AsyncThrowingStream<UIMessageChunk, Error> {
        AsyncThrowingStream { continuation in
            let textID = "scripted-text"
            Task {
                if delay > .zero {
                    try? await Task.sleep(for: delay)
                }
                continuation.yield(.textStart(id: textID))
                for (offset, word) in reply.split(separator: " ").enumerated() {
                    continuation.yield(.textDelta(id: textID, delta: offset == 0 ? String(word) : " \(word)"))
                }
                continuation.yield(.textEnd(id: textID))
                continuation.yield(.finish(finishReason: .stop))
                continuation.finish()
            }
        }
    }
}
