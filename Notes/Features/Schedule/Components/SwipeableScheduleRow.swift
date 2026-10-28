import SwiftUI

struct SwipeableScheduleRow: View {
    let item: ScheduleItem
    let onSelect: () -> Void
    let onDelete: () -> Void

    @State private var offset: CGFloat = 0
    @State private var dragStartOffset: CGFloat = 0
    @State private var isDragging = false

    private let actionWidth: CGFloat = 78

    private var isOpen: Bool {
        offset < 0
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            Button {
                withAnimation(.easeOut(duration: 0.18)) {
                    offset = 0
                }
                onDelete()
            } label: {
                Text("Delete")
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(width: actionWidth)
                    .frame(maxHeight: .infinity)
                    .background(Color.red)
            }
            .buttonStyle(.plain)
            .opacity(isOpen ? 1 : 0)
            .disabled(!isOpen)
            .accessibilityHidden(!isOpen)

            HStack(alignment: .top, spacing: 12) {
                Text(ScheduleFormatting.timeText(item))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color(.label))
                .frame(width: 48, alignment: .leading)

                Text(item.title)
                    .font(.callout)
                    .foregroundStyle(Color(.secondaryLabel))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 2)
            .contentShape(Rectangle())
            .background(Color(.systemBackground))
            .offset(x: offset)
            .onTapGesture {
                if isOpen {
                    closeAction()
                } else {
                    onSelect()
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
            .accessibilityHint("Open schedule for editing")
            .accessibilityAction {
                onSelect()
            }
            .accessibilityAction(
                named: "Delete",
                onDelete
            )
            .simultaneousGesture(
                DragGesture(minimumDistance: 12)
                    .onChanged { value in
                        guard abs(value.translation.width)
                            > abs(value.translation.height) else {
                            return
                        }

                        if !isDragging {
                            isDragging = true
                            dragStartOffset = offset
                        }
                        offset = min(
                            0,
                            max(
                                -actionWidth,
                                dragStartOffset + value.translation.width
                            )
                        )
                    }
                    .onEnded { value in
                        let projectedOffset = offset
                            + value.predictedEndTranslation.width * 0.15
                        let shouldOpen = projectedOffset < -actionWidth * 0.5

                        withAnimation(.easeOut(duration: 0.18)) {
                            offset = shouldOpen ? -actionWidth : 0
                        }
                        dragStartOffset = shouldOpen ? -actionWidth : 0
                        isDragging = false
                    }
            )
        }
        .clipped()
    }

    private func closeAction() {
        withAnimation(.easeOut(duration: 0.18)) {
            offset = 0
        }
        dragStartOffset = 0
    }
}
