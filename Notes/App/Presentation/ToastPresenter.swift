import Combine
import SwiftUI

@MainActor
final class ToastPresenter: ObservableObject {
    @Published private(set) var message: String?
    private var dismissalTask: Task<Void, Never>?

    func show(_ message: String) {
        dismissalTask?.cancel()
        withAnimation(.easeOut(duration: 0.2)) {
            self.message = message
        }
        dismissalTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            withAnimation(.easeIn(duration: 0.2)) {
                self?.message = nil
            }
        }
    }
}
