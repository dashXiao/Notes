import SwiftUI

struct ScheduleDateHeader: View {
    let day: Date
    var isCompact = false

    @ScaledMetric(relativeTo: .largeTitle) private var fullHeadingSize = 28.0
    @ScaledMetric(relativeTo: .headline) private var compactHeadingSize = 17.0

    private var headingSize: Double {
        isCompact ? compactHeadingSize : fullHeadingSize
    }

    var body: some View {
        HStack(spacing: isCompact ? 5 : 8) {
            Text(day.formatted(.dateTime.month(isCompact ? .abbreviated : .wide).day()))
                .font(.system(size: headingSize, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)

            if Calendar.current.isDateInToday(day) {
                Text("Today")
                    .font(.system(size: isCompact ? 10 : 12, weight: .semibold))
                    .foregroundStyle(AppTheme.accentInk)
                    .padding(.horizontal, isCompact ? 6 : 9)
                    .padding(.vertical, 5)
                    .background(AppTheme.accentTint, in: Capsule())
            }
        }
        .lineLimit(1)
    }
}
