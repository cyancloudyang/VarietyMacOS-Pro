import SwiftUI

struct FlowLayout: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var maxWidth: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > (proposal.width ?? .infinity) {
                currentX = 0
                currentY += lineHeight + 8
                lineHeight = 0
            }
            lineHeight = max(lineHeight, size.height)
            maxWidth = max(maxWidth, currentX + size.width)
            currentX += size.width + 8
        }

        return CGSize(width: maxWidth, height: currentY + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX: CGFloat = bounds.minX
        var currentY: CGFloat = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX {
                currentX = bounds.minX
                currentY += lineHeight + 8
                lineHeight = 0
            }
            lineHeight = max(lineHeight, size.height)
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: .init(size))
            currentX += size.width + 8
        }
    }
}
