import SwiftUI

/// Horizontal scrolling bar of tier-1 super-genre buttons.
///
/// Each genre is a tappable pill/chip. The selected genre is visually highlighted.
/// The first pill is always "Crate" (home), highlighted when no genre is selected.
struct GenreBarView: View {

    let categories: [GenreCategory]
    let selectedCategory: GenreCategory?
    let onSelect: (GenreCategory) -> Void
    var onHome: (() -> Void)? = nil

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // "Crate" home pill
                if let onHome {
                    Button {
                        onHome()
                    } label: {
                        Text("Crate")
                            .font(.subheadline)
                            .fontWeight(selectedCategory == nil ? .bold : .medium)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(selectedCategory == nil
                                          ? Color.accentColor
                                          : Color.secondary.opacity(0.15))
                            )
                            .foregroundStyle(selectedCategory == nil
                                             ? Color.white
                                             : Color.primary)
                    }
                    .buttonStyle(.plain)
                }

                ForEach(categories) { category in
                    Button {
                        onSelect(category)
                    } label: {
                        Text(category.name)
                            .font(.subheadline)
                            .fontWeight(isSelected(category) ? .bold : .medium)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(isSelected(category)
                                          ? Color.accentColor
                                          : Color.secondary.opacity(0.15))
                            )
                            .foregroundStyle(isSelected(category)
                                             ? Color.white
                                             : Color.primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    private func isSelected(_ category: GenreCategory) -> Bool {
        selectedCategory?.id == category.id
    }
}

#Preview {
    GenreBarView(
        categories: GenreTaxonomy.categories,
        selectedCategory: GenreTaxonomy.categories.first,
        onSelect: { _ in }
    )
}
