import SwiftUI

struct MasonryLayout: Layout {
    let columnWidth: CGFloat
    let spacing: CGFloat

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let arrangement = arrange(subviews)
        return CGSize(width: columnWidth * 2 + spacing, height: arrangement.height)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let arrangement = arrange(subviews)
        for (subview, placement) in zip(subviews, arrangement.placements) {
            subview.place(
                at: CGPoint(
                    x: bounds.minX + placement.origin.x,
                    y: bounds.minY + placement.origin.y
                ),
                anchor: .topLeading,
                proposal: ProposedViewSize(width: columnWidth, height: placement.height)
            )
        }
    }

    private func arrange(_ subviews: Subviews) -> (placements: [Placement], height: CGFloat) {
        var columnHeights: [CGFloat] = [0, 0]
        var placements: [Placement] = []

        for subview in subviews {
            let column = columnHeights[0] <= columnHeights[1] ? 0 : 1
            let size = subview.sizeThatFits(ProposedViewSize(width: columnWidth, height: nil))
            placements.append(Placement(
                origin: CGPoint(
                    x: CGFloat(column) * (columnWidth + spacing),
                    y: columnHeights[column]
                ),
                height: size.height
            ))
            columnHeights[column] += size.height + spacing
        }

        return (placements, max(0, (columnHeights.max() ?? 0) - spacing))
    }

    private struct Placement {
        let origin: CGPoint
        let height: CGFloat
    }
}
