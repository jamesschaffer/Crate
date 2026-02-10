import SwiftUI

/// Horizontal scrolling bar that transforms between two states:
///
/// **No genre selected:** Dial label pill + genre category pills.
/// **Genre selected:** `[Genre ✕]` pill + subcategory pills.
///
/// Always renders a single row at a constant height — no layout jumps.
struct GenreBarView: View {

    let dialLabel: String
    let categories: [GenreCategory]
    let selectedCategory: GenreCategory?
    let onSelect: (GenreCategory) -> Void
    var onDialTap: () -> Void = {}
    var onHome: (() -> Void)? = nil
    var selectedSubcategoryIDs: Set<String> = []
    var onToggleSubcategory: ((String) -> Void)? = nil

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            GlassEffectContainer {
                HStack(spacing: 12) {
                    if let category = selectedCategory {
                        // MARK: Genre-selected state

                        // Selected genre dismiss pill
                        Button {
                            onHome?()
                        } label: {
                            HStack(spacing: 4) {
                                Text(category.name)
                                Image(systemName: "xmark")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                            }
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.accentColor)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                        .glassEffect(.regular.interactive(), in: .capsule)

                        // Subcategory pills
                        ForEach(category.subcategories) { sub in
                            Button {
                                onToggleSubcategory?(sub.id)
                            } label: {
                                Text(sub.name)
                                    .font(.subheadline)
                                    .fontWeight(selectedSubcategoryIDs.contains(sub.id) ? .semibold : .medium)
                                    .foregroundStyle(selectedSubcategoryIDs.contains(sub.id) ? Color.accentColor : .primary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                            }
                            .buttonStyle(.plain)
                            .glassEffect(.regular.interactive(), in: .capsule)
                        }
                    } else {
                        // MARK: Home state

                        // Dial position pill — opens settings
                        Button {
                            onDialTap()
                        } label: {
                            Text(dialLabel)
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.accentColor)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                        .glassEffect(.regular.interactive(), in: .capsule)

                        // Genre category pills
                        ForEach(categories) { category in
                            Button {
                                onSelect(category)
                            } label: {
                                Text(category.name)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                            }
                            .buttonStyle(.plain)
                            .glassEffect(.regular.interactive(), in: .capsule)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .animation(.easeInOut(duration: 0.2), value: selectedCategory?.id)
            }
        }
    }
}

#Preview {
    GenreBarView(
        dialLabel: "My Crate",
        categories: GenreTaxonomy.categories,
        selectedCategory: GenreTaxonomy.categories.first,
        onSelect: { _ in }
    )
}
