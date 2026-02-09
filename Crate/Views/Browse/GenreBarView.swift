import SwiftUI

/// Horizontal scrolling bar of tier-1 super-genre buttons.
///
/// Each genre is a tappable pill/chip. The selected genre is visually highlighted.
struct GenreBarView: View {

    let categories: [GenreCategory]
    let selectedCategory: GenreCategory?
    let onSelect: (GenreCategory) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
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
