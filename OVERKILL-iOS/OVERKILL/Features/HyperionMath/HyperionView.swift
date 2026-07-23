import SwiftUI

private struct ChatMessage: Identifiable {
    enum Role { case user, assistant }
    let id = UUID()
    let role: Role
    let text: String
    let date = Date()
}

struct HyperionView: View {
    @State private var query = ""
    @State private var messages: [ChatMessage] = [
        ChatMessage(role: .assistant, text: "Hello. I'm Hyperion — your offline mathematical guide.\n\nI have deep knowledge of calculus, algebra, statistics, trigonometry, linear algebra, and more.\n\nAsk me anything — I work entirely offline, no internet required.")
    ]
    @State private var selectedEntry: MathEntry? = nil
    @State private var showTopics = false
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                scrollArea
                Divider().background(Theme.border)
                inputBar
            }
            .background(.black)
            .navigationTitle("Hyperion Math")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation { showTopics.toggle() }
                    } label: {
                        Image(systemName: "books.vertical")
                            .foregroundStyle(Theme.electric)
                    }
                }
            }
            .sheet(isPresented: $showTopics) {
                TopicBrowserView(onSelect: { entry in
                    showTopics = false
                    sendMessage(entry.question)
                })
            }
            .onAppear { HyperionKnowledge.load() }
        }
    }

    // MARK: - Scroll area

    private var scrollArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(messages) { msg in
                        MessageBubble(message: msg)
                            .id(msg.id)
                    }
                }
                .padding(16)
                .padding(.bottom, 8)
            }
            .onChange(of: messages.count) { _, _ in
                withAnimation(.easeOut(duration: 0.3)) {
                    proxy.scrollTo(messages.last?.id, anchor: .bottom)
                }
            }
        }
    }

    // MARK: - Input bar

    private var inputBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "brain.head.profile")
                .foregroundStyle(Theme.electric)
                .font(.system(size: 16))

            TextField("Ask a math question…", text: $query)
                .font(.system(size: 15))
                .foregroundStyle(Theme.foreground)
                .focused($isFocused)
                .autocorrectionDisabled()
                .submitLabel(.send)
                .onSubmit { submitQuery() }

            Button(action: submitQuery) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(query.trimmingCharacters(in: .whitespaces).isEmpty ? Theme.muted : Theme.electric)
            }
            .disabled(query.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Theme.surface1)
    }

    // MARK: - Actions

    private func submitQuery() {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return }
        sendMessage(q)
    }

    private func sendMessage(_ q: String) {
        query = ""
        isFocused = false

        withAnimation(.spring(response: 0.3)) {
            messages.append(ChatMessage(role: .user, text: q))
        }

        Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            let response = buildResponse(for: q)
            await MainActor.run {
                withAnimation(.spring(response: 0.3)) {
                    messages.append(ChatMessage(role: .assistant, text: response))
                }
            }
        }
    }

    private func buildResponse(for query: String) -> String {
        let results = HyperionKnowledge.search(query: query)
        if let top = results.first {
            return "**\(top.question)**\n\n\(top.answer)"
        }

        // Fallback: try to evaluate if it looks like a math expression
        if let v = try? ExpressionEvaluator.evaluate(query, x: 0) {
            return "Evaluating '\(query)' at x=0:\n\nResult: \(String(format: "%.6g", v))"
        }

        return "I don't have a specific entry for '\(query)', but I can help with:\n\n• Derivatives & integrals\n• Logarithms & exponentials\n• Trigonometric identities\n• Limits & Taylor series\n• Matrix operations\n• Statistics & probability\n• Complex numbers & vectors\n\nTry rephrasing or tap 📚 to browse all topics."
    }
}

// MARK: - MessageBubble
private struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if message.role == .assistant {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.electric)
                    .frame(width: 28, height: 28)
                    .background(Theme.electric.opacity(0.12))
                    .clipShape(Circle())
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.role == .user ? "You" : "Hyperion")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Theme.muted)

                Text(LocalizedStringKey(message.text.replacingOccurrences(of: "**", with: "**")))
                    .font(.system(size: 14, design: message.role == .assistant ? .monospaced : .default))
                    .foregroundStyle(Theme.foreground)
                    .textSelection(.enabled)
                    .padding(12)
                    .background(message.role == .user ? Theme.electric.opacity(0.15) : Theme.surface1)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.r12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.r12, style: .continuous)
                            .strokeBorder(
                                message.role == .user ? Theme.electric.opacity(0.3) : Theme.border.opacity(0.5),
                                lineWidth: 0.5
                            )
                    )
            }

            if message.role == .user {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Theme.muted)
            }
        }
        .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)
    }
}

// MARK: - TopicBrowserView
private struct TopicBrowserView: View {
    let onSelect: (MathEntry) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(HyperionKnowledge.all()) { entry in
                Button {
                    onSelect(entry)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.question)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Theme.foreground)
                        Text(entry.keywords.prefix(3).joined(separator: " · "))
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(Theme.muted)
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(Theme.surface1)
            }
            .scrollContentBackground(.hidden)
            .background(.black)
            .navigationTitle("Math Topics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Theme.electric)
                }
            }
        }
    }
}
