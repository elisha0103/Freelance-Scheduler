import SwiftUI

struct ErrorBanner: ViewModifier {
    let message: String?
    let onDismiss: () -> Void

    func body(content: Content) -> some View {
        content.overlay(alignment: .top) {
            if let message, !message.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.white)
                    Spacer()
                    Button { onDismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                .padding(12)
                .background(Color.red.opacity(0.85))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal)
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4) { onDismiss() }
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: message)
    }
}

extension View {
    func errorBanner(message: String?, onDismiss: @escaping () -> Void) -> some View {
        modifier(ErrorBanner(message: message, onDismiss: onDismiss))
    }
}
