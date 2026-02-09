import SwiftUI

// MARK: - Conditional Modifier

extension View {
    /// Apply a modifier only when a condition is true.
    /// Avoids awkward if/else in view builders.
    ///
    /// Usage:
    /// ```swift
    /// Text("Hello")
    ///     .if(isHighlighted) { view in
    ///         view.foregroundStyle(.red)
    ///     }
    /// ```
    @ViewBuilder
    func `if`<Content: View>(
        _ condition: Bool,
        transform: (Self) -> Content
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Placeholder Shimmer

extension View {
    /// Apply a subtle shimmer effect, useful for loading placeholders.
    func shimmer() -> some View {
        self
            .redacted(reason: .placeholder)
            .allowsHitTesting(false)
    }
}

// MARK: - Hide Keyboard (iOS)

#if os(iOS)
extension View {
    /// Dismiss the keyboard when tapping outside of a text field.
    func hideKeyboardOnTap() -> some View {
        self.onTapGesture {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil, from: nil, for: nil
            )
        }
    }
}
#endif
