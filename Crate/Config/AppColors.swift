import SwiftUI

extension ShapeStyle where Self == Color {
    /// Slightly darker than `.secondary` for better text contrast.
    /// Adjust the opacity here to tune all secondary text across the app.
    static var secondaryText: Color {
        .primary.opacity(0.7)
    }
}
