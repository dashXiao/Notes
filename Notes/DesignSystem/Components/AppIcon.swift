import SwiftUI

struct AppIcon: View {
    let systemName: String
    var size: CGFloat = 24
    var weight: Font.Weight = .semibold

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size, weight: weight))
            .symbolRenderingMode(.hierarchical)
            .accessibilityHidden(true)
    }
}
