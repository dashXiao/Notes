import SwiftUI

struct ScheduleDateHeader: View {
    let day: Date
    var isCompact = false

    @ScaledMetric(relativeTo: .largeTitle) private var fullHeadingSize = 34.0
    @ScaledMetric(relativeTo: .headline) private var compactHeadingSize = 18.0

    private var headingSize: Double {
        isCompact ? compactHeadingSize : fullHeadingSize
    }

    var body: some View {
        HStack(spacing: isCompact ? 5 : 8) {
            Text(day.formatted(.dateTime.month(isCompact ? .abbreviated : .wide).day()))
                .font(.system(size: headingSize, weight: .bold))
                .foregroundStyle(Color(.label))

            if Calendar.current.isDateInToday(day) {
                Text("Today")
                    .font(.system(size: headingSize, weight: .medium, design: .serif).italic())
                    .foregroundStyle(AppTheme.todayHighlight)
            }
        }
        .lineLimit(1)
    }
}
