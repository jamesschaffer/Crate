import Foundation

/// A top-level "super genre" — the first tier in the two-tier genre taxonomy.
/// Example: Rock, Pop, Hip-Hop/Rap, Electronic.
struct GenreCategory: Identifiable, Hashable, Sendable {
    let id: String                 // Stable identifier, e.g. "rock"
    let name: String               // Display name, e.g. "Rock"
    let appleMusicID: String       // Apple Music genre ID, e.g. "21"
    let subcategories: [SubCategory]
}

/// A second-tier sub-category within a super genre.
/// Example: Under Rock -> Alternative, Classic Rock, Indie, Punk.
struct SubCategory: Identifiable, Hashable, Sendable {
    let id: String                 // Stable identifier, e.g. "rock-alternative"
    let name: String               // Display name, e.g. "Alternative"
    let appleMusicID: String       // Apple Music genre ID, e.g. "20"
}
