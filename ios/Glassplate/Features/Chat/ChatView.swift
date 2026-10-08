import SwiftUI
import AI
import Textual

struct ChatView: View {
    var body: some View {
        NavigationStack {
            ChatScreen()
                .navigationTitle("Chat")
                .navigationBarTitleDisplayMode(.inline)
                .background { AmbientBackground() }
        }
    }
}

private struct ChatScreen: View {
    private static let workerBaseURL: URL = {
        #if DEBUG
        return URL(string: "https://envy.tailc3387.ts.net")!
        #else
        return URL(string: "https://glassplate.nguyenvantri2820.workers.dev")!
        #endif
    }()

    private static let bottomAnchor = "chat-bottom"

    @State private var chat: ChatSession
    @State private var prompt = ""
    @FocusState private var isComposerFocused: Bool

    init() {
        _chat = State(initialValue: Self.makeSession())
    }

    private static func makeSession(seeded: Bool = true) -> ChatSession {
        if LaunchConfiguration.isUITesting {
            return ChatSession(
                transport: ScriptedChatTransport(
                    reply: LaunchConfiguration.scriptedReply,
                    delay: LaunchConfiguration.scriptedDelay
                ),
                id: "uitest",
                messages: seeded ? LaunchConfiguration.seedMessages : []
            )
        }

        let provider = OpenAICompatibleProvider(
            name: "glassplate",
            baseURL: workerBaseURL,
            apiKey: nil
        )
        let model = provider.languageModel("deepseek/deepseek-v4.1-flash")
        return ChatSession(transport: LocalChatTransport(model: model))
    }

    var body: some View {
        transcript
            .contentShape(Rectangle())
            .simultaneousGesture(TapGesture().onEnded { isComposerFocused = false })
            .safeAreaInset(edge: .bottom, spacing: 0) { composerArea }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: startNewChat) {
                        Label("New chat", systemImage: "square.and.pencil")
                    }
                    .accessibilityIdentifier("chat.new")
                }
            }
    }

    private func startNewChat() {
        chat = Self.makeSession(seeded: false)
        prompt = ""
        isComposerFocused = false
    }

    // MARK: - Transcript

    private var transcript: some View {
        messageScroll
            .overlay {
                if chat.messages.isEmpty && !chat.isLoading {
                    emptyState
                }
            }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 44, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.indigo)
                .accessibilityHidden(true)

            Text("Start a conversation")
                .font(.title3.weight(.semibold))

            Text("Ask anything. Replies stream in from the Glassplate Worker.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var messageScroll: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(chat.messages) { message in
                        if message.role == .user || message.hasVisibleContent {
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                    }

                    if showsTypingIndicator {
                        TypingBubble()
                    }

                    Color.clear
                        .frame(height: 1)
                        .id(Self.bottomAnchor)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
            }
            .defaultScrollAnchor(.bottom)
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: chat.messages.count) { _, _ in
                withAnimation(.easeOut(duration: 0.25)) {
                    proxy.scrollTo(Self.bottomAnchor, anchor: .bottom)
                }
            }
            .onChange(of: chat.isLoading) { _, _ in
                withAnimation(.easeOut(duration: 0.25)) {
                    proxy.scrollTo(Self.bottomAnchor, anchor: .bottom)
                }
            }
        }
    }

    // MARK: - Composer

    private var composerArea: some View {
        VStack(spacing: 0) {
            if case .error(let message) = chat.status {
                ErrorBanner(message: message)
            }

            composer
        }
    }

    private var composer: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField("Message", text: $prompt, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.body)
                .lineLimit(1...6)
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                .frame(minHeight: 44)
                .background(
                    Color(uiColor: .tertiarySystemFill),
                    in: RoundedRectangle(cornerRadius: GlassSurfaceRadius.control, style: .continuous)
                )
                .focused($isComposerFocused)
                .submitLabel(.send)
                .onSubmit(send)
                .accessibilityIdentifier("composer.input")

            control
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private var control: some View {
        if chat.isLoading {
            ComposerButton(systemImage: "stop.fill", label: "Stop", identifier: "composer.stop", tint: .red) {
                chat.stop()
            }
        } else {
            ComposerButton(systemImage: "arrow.up", label: "Send", identifier: "composer.send", tint: .indigo, isEnabled: canSend) {
                send()
            }
        }
    }

    // MARK: - State

    private var canSend: Bool {
        !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var showsTypingIndicator: Bool {
        guard chat.isLoading else { return false }
        guard let last = chat.messages.last else { return true }
        return last.role == .user || !last.hasVisibleContent
    }

    private func send() {
        let text = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        chat.send(text)
        // A multi-line TextField ignores a binding cleared in the same update cycle as the
        // send (it is UITextView-backed); clearing on the next runloop makes it re-render empty.
        DispatchQueue.main.async { prompt = "" }
    }
}

// MARK: - Composer control

private struct ComposerButton: View {
    let systemImage: String
    let label: String
    let identifier: String
    let tint: Color
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ComposerButtonGlyph(systemImage: systemImage, tint: tint)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityLabel(label)
        .accessibilityIdentifier(identifier)
    }
}

/// Reads the button's real enabled state from the environment, so the disabled
/// appearance is driven by `.disabled(...)` (including an ancestor's) instead of a
/// hand-rolled opacity.
private struct ComposerButtonGlyph: View {
    @Environment(\.isEnabled) private var isEnabled

    let systemImage: String
    let tint: Color

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: 17, weight: .bold))
            .foregroundStyle(isEnabled ? Color.white : Color.secondary)
            .frame(width: 44, height: 44)
            .background(fill, in: .circle)
    }

    private var fill: AnyShapeStyle {
        isEnabled
            ? AnyShapeStyle(tint.gradient)
            : AnyShapeStyle(Color(uiColor: .tertiarySystemFill))
    }
}

// MARK: - Error

private struct ErrorBanner: View {
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.subheadline)
                .foregroundStyle(.orange)
                .accessibilityHidden(true)

            Text(message)
                .font(.footnote)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.orange.opacity(0.14), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error. \(message)")
    }
}

// MARK: - Typing indicator

private struct TypingBubble: View {
    var body: some View {
        HStack {
            TypingDots()
                .padding(.horizontal, 14)
                .padding(.vertical, 13)
                .background(
                    Color(uiColor: .secondarySystemBackground),
                    in: RoundedRectangle(cornerRadius: GlassSurfaceRadius.control, style: .continuous)
                )

            Spacer(minLength: 48)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Assistant is typing")
        .accessibilityIdentifier("chat.typing")
    }
}

/// Sequentially pulsing dots. Driven by a one-shot state toggle with a repeating
/// SwiftUI animation (a perpetual `TimelineView(.animation)` clock here would keep
/// the app from ever going idle for UI tests).
private struct TypingDots: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { index in
                TypingDot(delay: Double(index) * 0.16, isStatic: reduceMotion)
            }
        }
    }
}

private struct TypingDot: View {
    let delay: Double
    let isStatic: Bool

    @State private var isBright = false

    var body: some View {
        Circle()
            .fill(.secondary)
            .frame(width: 7, height: 7)
            .opacity(isStatic ? 0.6 : (isBright ? 1 : 0.35))
            .animation(
                isStatic
                    ? nil
                    : .easeInOut(duration: 0.45).repeatForever(autoreverses: true).delay(delay),
                value: isBright
            )
            .onAppear { isBright = true }
    }
}

// MARK: - Message

private struct MessageBubble: View {
    let message: UIMessage

    private var isUser: Bool { message.role == .user }

    private var shape: UnevenRoundedRectangle {
        let radius = GlassSurfaceRadius.control
        let tail: CGFloat = 6
        return UnevenRoundedRectangle(
            topLeadingRadius: radius,
            bottomLeadingRadius: isUser ? radius : tail,
            bottomTrailingRadius: isUser ? tail : radius,
            topTrailingRadius: radius,
            style: .continuous
        )
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            if isUser { Spacer(minLength: 48) }
            bubble
            if !isUser { Spacer(minLength: 48) }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var bubble: some View {
        let content = VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(message.parts.enumerated()), id: \.offset) { _, part in
                partView(part)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)

        if isUser {
            content
                .background(Color.indigo.gradient, in: shape)
                .foregroundStyle(.white)
                .textSelection(.enabled)
                .accessibilityElement(children: .combine)
        } else {
            content
                .background(Color(uiColor: .secondarySystemBackground), in: shape)
                .foregroundStyle(.primary)
                .textSelection(.enabled)
                .accessibilityElement(children: .combine)
        }
    }

    @ViewBuilder
    private func partView(_ part: UIPart) -> some View {
        switch part {
        case .text(let text):
            if !text.text.isEmpty {
                if isUser {
                    Text(text.text)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    StructuredText(markdown: text.text)
                        .textual.structuredTextStyle(.default)
                        .textual.textSelection(.enabled)
                }
            }
        case .reasoning(let reasoning):
            if !reasoning.text.isEmpty {
                ReasoningDisclosure(text: reasoning.text)
            }
        case .tool(let tool):
            ToolChip(tool: tool)
        default:
            EmptyView()
        }
    }
}

private struct ReasoningDisclosure: View {
    let text: String

    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            Text(text)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)
        } label: {
            Label("Thinking", systemImage: "brain")
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .tint(.secondary)
    }
}

private struct ToolChip: View {
    let tool: ToolUIPart

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(tint)
                .accessibilityHidden(true)

            Text(tool.toolName)
                .font(.caption.weight(.semibold))
                .lineLimit(1)

            Spacer(minLength: 8)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: GlassSurfaceRadius.chip, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Tool \(tool.toolName), \(label)")
    }

    private var icon: String {
        switch tool.state {
        case .outputAvailable: "checkmark.circle.fill"
        case .outputError, .outputDenied: "xmark.circle.fill"
        case .approvalRequested: "hand.raised.fill"
        default: "bolt.fill"
        }
    }

    private var tint: Color {
        switch tool.state {
        case .outputAvailable: .green
        case .outputError, .outputDenied: .red
        case .approvalRequested: .orange
        default: .indigo
        }
    }

    private var label: String {
        switch tool.state {
        case .inputStreaming, .inputAvailable: "Running"
        case .outputAvailable: "Done"
        case .outputError: "Failed"
        case .approvalRequested: "Approval needed"
        case .approvalResponded: "Approved"
        case .outputDenied: "Denied"
        }
    }
}

private extension UIMessage {
    var hasVisibleContent: Bool {
        parts.contains { part in
            switch part {
            case .text(let text): return !text.text.isEmpty
            case .reasoning(let reasoning): return !reasoning.text.isEmpty
            case .tool, .sourceURL, .sourceDocument, .file, .data: return true
            default: return false
            }
        }
    }
}

#Preview {
    ChatView()
}
