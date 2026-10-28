import SwiftUI

struct ListeningPulse: View {
    var body: some View {
        TimelineView(.animation) { context in
            let duration = 1.25
            let elapsed = context.date.timeIntervalSinceReferenceDate
                .truncatingRemainder(dividingBy: duration)
            let progress = elapsed / duration

            Circle()
                .stroke(
                    AppTheme.accent.opacity(0.7 * (1 - progress)),
                    lineWidth: 3
                )
                .scaleEffect(1 + progress * 0.36)
        }
        .frame(width: 161, height: 161)
        .allowsHitTesting(false)
    }
}
