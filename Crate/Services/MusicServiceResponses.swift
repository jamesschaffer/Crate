import Foundation

// MARK: - Chart Response Decoding

/// Lightweight Codable types for decoding the charts REST response.
/// We use these instead of MusicKit's built-in types because we're
/// making a raw MusicDataRequest for genre-filtered charts.
struct ChartResponse: Codable {
    let results: ChartResults
}

struct ChartResults: Codable {
    let albums: [ChartAlbumGroup]?
}

struct ChartAlbumGroup: Codable {
    let data: [ChartAlbumItem]
}

struct ChartAlbumItem: Codable {
    let id: String
    let attributes: ChartAlbumAttributes
}

struct ChartAlbumAttributes: Codable {
    let name: String
    let artistName: String
    let artwork: ChartArtwork?
    let genreNames: [String]?
}

struct ChartArtwork: Codable {
    let url: String?
}

// MARK: - Recently Played Response Decoding

struct RecentlyPlayedResponse: Codable {
    let data: [RecentlyPlayedItem]
}

struct RecentlyPlayedItem: Codable {
    let id: String
    let type: String
    let attributes: RecentlyPlayedAttributes?
}

struct RecentlyPlayedAttributes: Codable {
    let name: String
    let artistName: String
    let artwork: ChartArtwork?
    let genreNames: [String]?
}

// MARK: - Recommendation Response Decoding

struct RecommendationResponse: Codable {
    let data: [RecommendationGroup]
}

struct RecommendationGroup: Codable {
    let id: String
    let relationships: RecommendationRelationships?
}

struct RecommendationRelationships: Codable {
    let contents: RecommendationContents
}

struct RecommendationContents: Codable {
    let data: [RecommendationItem]
}

struct RecommendationItem: Codable {
    let id: String
    let type: String
    let attributes: RecommendationItemAttributes?
}

struct RecommendationItemAttributes: Codable {
    let name: String
    let artistName: String
    let artwork: ChartArtwork?
    let genreNames: [String]?
}

// MARK: - Search Response Decoding

struct SearchResponse: Codable {
    let results: SearchResultsContainer
}

struct SearchResultsContainer: Codable {
    let albums: SearchAlbumResults?
}

struct SearchAlbumResults: Codable {
    let data: [ChartAlbumItem]   // Same structure as chart album items
}

// MARK: - Library Albums Response Decoding

struct LibraryAlbumsResponse: Codable {
    let data: [LibraryAlbumItem]
}

struct LibraryAlbumItem: Codable {
    let id: String
    let attributes: LibraryAlbumAttributes?
    let relationships: LibraryAlbumRelationships?
}

struct LibraryAlbumAttributes: Codable {
    let name: String
    let artistName: String
    let artwork: ChartArtwork?
    let genreNames: [String]?
}

struct LibraryAlbumRelationships: Codable {
    let catalog: LibraryCatalogRelationship?
}

struct LibraryCatalogRelationship: Codable {
    let data: [LibraryCatalogItem]?
}

struct LibraryCatalogItem: Codable {
    let id: String
    let attributes: ChartAlbumAttributes?
}

// MARK: - Artist Albums Response Decoding

struct ArtistAlbumsResponse: Codable {
    let data: [ArtistAlbumItem]
}

struct ArtistAlbumItem: Codable {
    let id: String
    let attributes: ArtistAlbumAttributes
}

struct ArtistAlbumAttributes: Codable {
    let name: String
    let artistName: String
    let artwork: ChartArtwork?
    let releaseDate: String?
    let genreNames: [String]?
}
