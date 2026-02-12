import SwiftUI

extension ShapeStyle where Self == Color {
    /// Slightly darker than `.secondary` for better text contrast.
    /// Adjust the opacity here to tune all secondary text across the app.
    static var secondaryText: Color {
        .primary.opacity(0.7)
    }

    /// Brand magenta (#df00b6) — used for accent UI throughout the app.
    static var brandPink: Color {
        Color(red: 0.875, green: 0.0, blue: 0.714)
    }
}
