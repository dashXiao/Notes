import Combine
import SwiftUI

@MainActor
final class ToastPresenter: ObservableObject {
    struct Toast: Identifiable, Equatable {
        enum Content: Equatable {
            case message(String)
            case schedule(InferredScheduleChange)
        }

        let id = UUID()
        let content: Content
    }

    @Published private(set) var toast: Toast?
    private var dismissalTask: Task<Void, Never>?

    func show(_ message: String) {
        present(Toast(content: .message(message)), duration: .seconds(2))
    }

    func showSchedule(_ change: InferredScheduleChange) {
        present(Toast(content: .schedule(change)), duration: .seconds(3))
    }

    @discardableResult
    func dismiss(id: UUID) -> Bool {
        guard toast?.id == id else { return false }
        dismissalTask?.cancel()
        withAnimation(.easeOut(duration: 0.2)) {
            toast = nil
        }
        return true
    }

    private func present(_ toast: Toast, duration: Duration) {
        dismissalTask?.cancel()
        withAnimation(.easeOut(duration: 0.2)) {
            self.toast = toast
        }
        let id = toast.id
        dismissalTask = Task { [weak self] in
            try? await Task.sleep(for: duration)
            guard !Task.isCancelled else { return }
            self?.dismiss(id: id)
        }
    }
}
