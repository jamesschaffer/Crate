import Foundation

/// Namespace for accessing the static genre taxonomy.
/// The actual data lives in Config/Genres.swift — this file provides
/// convenience lookups used by the rest of the app.
enum GenreTaxonomy {

    /// All top-level genre categories.
    static var categories: [GenreCategory] {
        Genres.all
    }

    /// Look up a category by its stable ID.
    static func category(withID id: String) -> GenreCategory? {
        Genres.all.first { $0.id == id }
    }

    /// Look up a subcategory by its stable ID across all categories.
    static func subcategory(withID id: String) -> SubCategory? {
        Genres.all.flatMap(\.subcategories).first { $0.id == id }
    }

    /// Look up a category or subcategory's Apple Music genre ID by stable ID.
    static func appleMusicID(for id: String) -> String? {
        if let cat = category(withID: id) {
            return cat.appleMusicID
        }
        return subcategory(withID: id)?.appleMusicID
    }
}
