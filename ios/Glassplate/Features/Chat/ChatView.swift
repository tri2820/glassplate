import SwiftUI
import AI

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

    private static func makeSession() -> ChatSession {
        if LaunchConfiguration.isUITesting {
            return ChatSession(
                transport: ScriptedChatTransport(
                    reply: LaunchConfiguration.scriptedReply,
                    delay: LaunchConfiguration.scriptedDelay
                ),
                id: "uitest",
                messages: LaunchConfiguration.seedMessages
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
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(.primary.opacity(0.08), lineWidth: 0.5)
                }
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
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(tint.gradient, in: .circle)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.3)
        .animation(.easeInOut(duration: 0.15), value: isEnabled)
        .accessibilityLabel(label)
        .accessibilityIdentifier(identifier)
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
            PhaseAnimator([0, 1, 2]) { phase in
                HStack(spacing: 5) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(.secondary)
                            .frame(width: 7, height: 7)
                            .opacity(phase == index ? 1 : 0.3)
                    }
                }
            } animation: { _ in
                .easeInOut(duration: 0.3)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(.primary.opacity(0.06), lineWidth: 0.5)
            }

            Spacer(minLength: 48)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Assistant is typing")
        .accessibilityIdentifier("chat.typing")
    }
}

// MARK: - Message

private struct MessageBubble: View {
    let message: UIMessage

    private var isUser: Bool { message.role == .user }

    private var shape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: 20,
            bottomLeadingRadius: isUser ? 20 : 6,
            bottomTrailingRadius: isUser ? 6 : 20,
            topTrailingRadius: 20,
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
                .background(.regularMaterial, in: shape)
                .overlay { shape.strokeBorder(.primary.opacity(0.06), lineWidth: 0.5) }
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
                Text(text.text)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
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
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
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
