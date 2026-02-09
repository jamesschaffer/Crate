import SwiftUI

/// Horizontal scrolling bar of tier-2 subcategory chips (multi-select).
///
/// Appears below the GenreBarView when a top-level genre is selected.
/// Users can tap multiple subcategories to filter; tapping again deselects.
/// Uses Liquid Glass styling to match the genre bar.
struct SubCategoryBarView: View {

    let subcategories: [SubCategory]
    let selectedIDs: Set<String>
    let onToggle: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            GlassEffectContainer {
                HStack(spacing: 10) {
                    ForEach(subcategories) { sub in
                        Button {
                            onToggle(sub.id)
                        } label: {
                            Text(sub.name)
                                .font(.caption)
                                .fontWeight(isSelected(sub) ? .semibold : .regular)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(.plain)
                        .glassEffect(.regular.interactive(), in: .capsule)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 6)
            }
        }
    }

    private func isSelected(_ sub: SubCategory) -> Bool {
        selectedIDs.contains(sub.id)
    }
}

#Preview {
    SubCategoryBarView(
        subcategories: Genres.rock.subcategories,
        selectedIDs: ["rock-alternative"],
        onToggle: { _ in }
    )
}
