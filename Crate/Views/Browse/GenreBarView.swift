import SwiftUI

/// Horizontal scrolling bar of tier-1 super-genre buttons.
///
/// Each genre is a tappable pill/chip with Liquid Glass styling.
/// The first pill is always "Crate" (home), highlighted when no genre is selected.
struct GenreBarView: View {

    let categories: [GenreCategory]
    let selectedCategory: GenreCategory?
    let onSelect: (GenreCategory) -> Void
    var onHome: (() -> Void)? = nil

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            GlassEffectContainer {
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
                        }
                        .buttonStyle(.plain)
                        .glassEffect(.regular.interactive(), in: .capsule)
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
                        }
                        .buttonStyle(.plain)
                        .glassEffect(.regular.interactive(), in: .capsule)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
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
