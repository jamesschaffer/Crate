import Testing
@testable import Crate

/// Tests for the static genre taxonomy data.
struct GenreTaxonomyTests {

    @Test("Taxonomy has at least 4 categories")
    func categoryCount() {
        #expect(GenreTaxonomy.categories.count >= 4)
    }

    @Test("Each category has a non-empty Apple Music ID")
    func categoryIDs() {
        for category in GenreTaxonomy.categories {
            #expect(!category.appleMusicID.isEmpty, "Category '\(category.name)' has empty Apple Music ID")
        }
    }

    @Test("Each subcategory has a non-empty Apple Music ID")
    func subcategoryIDs() {
        for category in GenreTaxonomy.categories {
            for sub in category.subcategories {
                #expect(!sub.appleMusicID.isEmpty,
                        "Subcategory '\(sub.name)' in '\(category.name)' has empty Apple Music ID")
            }
        }
    }

    @Test("Category lookup by ID works")
    func categoryLookup() {
        let rock = GenreTaxonomy.category(withID: "rock")
        #expect(rock != nil)
        #expect(rock?.name == "Rock")
        #expect(rock?.appleMusicID == "21")
    }

    @Test("Subcategory lookup by ID works")
    func subcategoryLookup() {
        let alt = GenreTaxonomy.subcategory(withID: "rock-alternative")
        #expect(alt != nil)
        #expect(alt?.name == "Alternative")
        #expect(alt?.appleMusicID == "20")
    }

    @Test("Apple Music ID lookup works for both tiers")
    func appleMusicIDLookup() {
        #expect(GenreTaxonomy.appleMusicID(for: "rock") == "21")
        #expect(GenreTaxonomy.appleMusicID(for: "rock-alternative") == "20")
        #expect(GenreTaxonomy.appleMusicID(for: "nonexistent") == nil)
    }

    @Test("All category IDs are unique")
    func uniqueCategoryIDs() {
        let ids = GenreTaxonomy.categories.map(\.id)
        #expect(Set(ids).count == ids.count, "Duplicate category IDs found")
    }

    @Test("All subcategory IDs are globally unique")
    func uniqueSubcategoryIDs() {
        let allSubIDs = GenreTaxonomy.categories.flatMap(\.subcategories).map(\.id)
        #expect(Set(allSubIDs).count == allSubIDs.count, "Duplicate subcategory IDs found")
    }
}
