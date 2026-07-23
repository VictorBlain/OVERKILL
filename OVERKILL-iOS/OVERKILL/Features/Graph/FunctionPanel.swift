import SwiftUI

struct FunctionPanel: View {
    @EnvironmentObject var appState: AppState
    @State private var input: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Function chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(appState.graphFunctions) { fn in
                        FunctionChip(fn: fn)
                            .environmentObject(appState)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .frame(height: 52)

            Divider().background(Theme.border)

            // Input row
            HStack(spacing: 10) {
                Text("f(x) =")
                    .font(.system(size: 15, weight: .medium, design: .monospaced))
                    .foregroundStyle(Theme.muted)

                TextField("sin(x), x^2, e^x …", text: $input)
                    .font(.system(size: 16, design: .monospaced))
                    .foregroundStyle(Theme.foreground)
                    .focused($isFocused)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .submitLabel(.done)
                    .onSubmit(addFunction)

                Button(action: addFunction) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(Theme.electric)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(Theme.surface1)
        .overlay(alignment: .top) {
            Divider().background(Theme.border)
        }
    }

    private func addFunction() {
        let expr = input.trimmingCharacters(in: .whitespaces)
        guard !expr.isEmpty else { return }
        appState.addFunction(expr)
        input = ""
        isFocused = false
    }
}

private struct FunctionChip: View {
    @EnvironmentObject var appState: AppState
    let fn: GraphFunction

    var body: some View {
        HStack(spacing: 6) {
            Button {
                appState.toggleFunction(id: fn.id)
            } label: {
                Circle()
                    .fill(fn.isVisible ? fn.color : Theme.surface3)
                    .frame(width: 8, height: 8)
                    .animation(.easeInOut(duration: 0.15), value: fn.isVisible)
            }

            Text(fn.expression)
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(fn.isVisible ? Theme.foreground : Theme.muted)
                .lineLimit(1)
                .frame(maxWidth: 120, alignment: .leading)

            Button {
                withAnimation(.spring(response: 0.3)) {
                    appState.removeFunction(id: fn.id)
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.muted)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Theme.surface2)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(fn.color.opacity(fn.isVisible ? 0.6 : 0.2), lineWidth: 1.5)
                )
        )
        .opacity(fn.isVisible ? 1 : 0.5)
        .animation(.easeInOut(duration: 0.15), value: fn.isVisible)
    }
}
