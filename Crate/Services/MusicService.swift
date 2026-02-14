import Foundation
import MusicKit

// MARK: - Protocol

/// Abstraction over Apple Music API calls, enabling dependency injection and testing.
protocol MusicServiceProtocol: Sendable {

    /// Fetch chart albums for a given Apple Music genre ID.
    /// - Parameters:
    ///   - genreID: Apple Music genre ID string (e.g. "21" for Rock).
    ///   - limit: Number of albums per page.
    ///   - offset: Pagination offset.
    /// - Returns: Array of CrateAlbum wrappers.
    func fetchChartAlbums(genreID: String, limit: Int, offset: Int) async throws -> [CrateAlbum]

    /// Fetch new-release chart albums for a genre.
    func fetchNewReleaseChartAlbums(genreID: String, limit: Int, offset: Int) async throws -> [CrateAlbum]

    /// Fetch the user's recently played albums.
    func fetchRecentlyPlayed(limit: Int) async throws -> [CrateAlbum]

    /// Fetch personalized album recommendations.
    func fetchRecommendations(limit: Int) async throws -> [CrateAlbum]

    /// Search for albums by term (used for sub-genre browsing).
    func searchAlbums(term: String, limit: Int, offset: Int) async throws -> [CrateAlbum]

    /// Fetch a single album's full details by its MusicItemID.
    func fetchAlbumDetail(id: MusicItemID) async throws -> Album?

    /// Fetch the tracks for an album.
    func fetchAlbumTracks(albumID: MusicItemID) async throws -> MusicItemCollection<Track>

    /// Add an album to the user's Apple Music library.
    func addToLibrary(albumID: MusicItemID) async throws

    /// Rate an album (love or dislike) in Apple Music.
    func rateAlbum(id: MusicItemID, rating: LibraryRating) async throws

    /// Mark an album as a Favorite in Apple Music (star icon, iOS 17.1+).
    func favoriteAlbum(id: MusicItemID) async throws

    /// Fetch the user's heavy rotation albums.
    func fetchHeavyRotation(limit: Int) async throws -> [CrateAlbum]

    /// Fetch albums from the user's library.
    func fetchLibraryAlbums(limit: Int, offset: Int) async throws -> [CrateAlbum]

    /// Fetch related albums for a given album ID.
    func fetchRelatedAlbums(for albumID: MusicItemID) async throws -> [CrateAlbum]

    /// Fetch albums by an artist (via search).
    func fetchAlbumsByArtist(name: String, limit: Int) async throws -> [CrateAlbum]

    /// Look up the artist ID from an album's catalog entry.
    func fetchArtistID(forAlbumID albumID: MusicItemID) async throws -> MusicItemID?

    /// Fetch all albums by an artist from the catalog.
    func fetchArtistAlbums(artistID: MusicItemID) async throws -> [CrateAlbum]
}

/// Rating to apply to a library item.
enum LibraryRating: Int, Sendable {
    case love = 1
    case dislike = -1
}

// MARK: - Implementation

/// Production implementation using MusicDataRequest for genre-filtered charts
/// and MusicCatalogResourceRequest for album detail/tracks.
struct MusicService: MusicServiceProtocol {

    func fetchChartAlbums(genreID: String, limit: Int, offset: Int) async throws -> [CrateAlbum] {
        try await fetchCharts(genreID: genreID, chartType: "most-played", limit: limit, offset: offset)
    }

    func fetchNewReleaseChartAlbums(genreID: String, limit: Int, offset: Int) async throws -> [CrateAlbum] {
        try await fetchCharts(genreID: genreID, chartType: "new-releases", limit: limit, offset: offset)
    }

    func fetchRecentlyPlayed(limit: Int) async throws -> [CrateAlbum] {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "api.music.apple.com"
        urlComponents.path = "/v1/me/recent/played"
        urlComponents.queryItems = [
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "types", value: "albums"),
        ]

        guard let url = urlComponents.url else {
            print("[Crate] URL construction failed for \(urlComponents.path)")
            return []
        }

        let request = MusicDataRequest(urlRequest: URLRequest(url: url))
        let response = try await request.response()

        let decoded = try JSONDecoder().decode(RecentlyPlayedResponse.self, from: response.data)
        return decoded.data.compactMap { item -> CrateAlbum? in
            guard item.type == "albums", let attrs = item.attributes else { return nil }
            return CrateAlbum(
                id: MusicItemID(item.id),
                title: attrs.name,
                artistName: attrs.artistName,
                artworkURL: attrs.artwork?.url,
                releaseDate: nil,
                genreNames: attrs.genreNames ?? []
            )
        }
    }

    func fetchRecommendations(limit: Int) async throws -> [CrateAlbum] {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "api.music.apple.com"
        urlComponents.path = "/v1/me/recommendations"
        urlComponents.queryItems = [
            URLQueryItem(name: "limit", value: "\(limit)"),
        ]

        guard let url = urlComponents.url else {
            print("[Crate] URL construction failed for \(urlComponents.path)")
            return []
        }

        let request = MusicDataRequest(urlRequest: URLRequest(url: url))
        let response = try await request.response()

        let decoded = try JSONDecoder().decode(RecommendationResponse.self, from: response.data)

        // Extract album items from all recommendation groups.
        var albums: [CrateAlbum] = []
        for group in decoded.data {
            guard let relationships = group.relationships else { continue }
            for item in relationships.contents.data {
                guard item.type == "albums" else { continue }
                guard let attrs = item.attributes else { continue }
                albums.append(CrateAlbum(
                    id: MusicItemID(item.id),
                    title: attrs.name,
                    artistName: attrs.artistName,
                    artworkURL: attrs.artwork?.url,
                    releaseDate: nil,
                    genreNames: attrs.genreNames ?? []
                ))
            }
        }
        return albums
    }

    func searchAlbums(term: String, limit: Int, offset: Int) async throws -> [CrateAlbum] {
        let countryCode = try await MusicDataRequest.currentCountryCode

        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "api.music.apple.com"
        urlComponents.path = "/v1/catalog/\(countryCode)/search"
        urlComponents.queryItems = [
            URLQueryItem(name: "term", value: term),
            URLQueryItem(name: "types", value: "albums"),
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "offset", value: "\(offset)"),
        ]

        guard let url = urlComponents.url else {
            print("[Crate] URL construction failed for \(urlComponents.path)")
            return []
        }

        let request = MusicDataRequest(urlRequest: URLRequest(url: url))
        let response = try await request.response()

        let decoded = try JSONDecoder().decode(SearchResponse.self, from: response.data)
        let items = decoded.results.albums?.data ?? []

        return items.map { item in
            CrateAlbum(
                id: MusicItemID(item.id),
                title: item.attributes.name,
                artistName: item.attributes.artistName,
                artworkURL: item.attributes.artwork?.url,
                releaseDate: nil,
                genreNames: item.attributes.genreNames ?? []
            )
        }
    }

    func fetchAlbumDetail(id: MusicItemID) async throws -> Album? {
        let request = MusicCatalogResourceRequest<Album>(matching: \.id, equalTo: id)
        let response = try await request.response()
        return response.items.first
    }

    func fetchAlbumTracks(albumID: MusicItemID) async throws -> MusicItemCollection<Track> {
        var request = MusicCatalogResourceRequest<Album>(matching: \.id, equalTo: albumID)
        request.properties = [.tracks]
        let response = try await request.response()

        guard let album = response.items.first,
              let tracks = album.tracks else {
            return MusicItemCollection<Track>([])
        }

        return tracks
    }

    func addToLibrary(albumID: MusicItemID) async throws {
        #if os(iOS)
        let request = MusicCatalogResourceRequest<Album>(matching: \.id, equalTo: albumID)
        let response = try await request.response()
        guard let album = response.items.first else { return }
        try await MusicLibrary.shared.add(album)
        #else
        // MusicLibrary.shared.add() is iOS-only. Use the REST API on macOS.
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "api.music.apple.com"
        urlComponents.path = "/v1/me/library"
        urlComponents.queryItems = [
            URLQueryItem(name: "ids[albums]", value: albumID.rawValue),
        ]

        guard let url = urlComponents.url else {
            print("[Crate] URL construction failed for \(urlComponents.path)")
            return
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"

        let dataRequest = MusicDataRequest(urlRequest: urlRequest)
        _ = try await dataRequest.response()
        #endif
    }

    func rateAlbum(id: MusicItemID, rating: LibraryRating) async throws {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "api.music.apple.com"
        urlComponents.path = "/v1/me/ratings/albums/\(id.rawValue)"

        guard let url = urlComponents.url else {
            print("[Crate] URL construction failed for \(urlComponents.path)")
            return
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "PUT"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "type": "rating",
            "attributes": ["value": rating.rawValue]
        ]
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)

        let request = MusicDataRequest(urlRequest: urlRequest)
        _ = try await request.response()
    }

    func favoriteAlbum(id: MusicItemID) async throws {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "api.music.apple.com"
        urlComponents.path = "/v1/me/favorites"
        urlComponents.queryItems = [
            URLQueryItem(name: "ids[albums]", value: id.rawValue),
        ]

        guard let url = urlComponents.url else {
            print("[Crate] URL construction failed for \(urlComponents.path)")
            return
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"

        let request = MusicDataRequest(urlRequest: urlRequest)
        _ = try await request.response()
    }

    func fetchHeavyRotation(limit: Int) async throws -> [CrateAlbum] {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "api.music.apple.com"
        urlComponents.path = "/v1/me/history/heavy-rotation"
        urlComponents.queryItems = [
            URLQueryItem(name: "limit", value: "\(limit)"),
        ]

        guard let url = urlComponents.url else {
            print("[Crate] URL construction failed for \(urlComponents.path)")
            return []
        }

        let request = MusicDataRequest(urlRequest: URLRequest(url: url))
        let response = try await request.response()

        let decoded = try JSONDecoder().decode(RecentlyPlayedResponse.self, from: response.data)
        return decoded.data.compactMap { item -> CrateAlbum? in
            guard item.type == "albums", let attrs = item.attributes else { return nil }
            return CrateAlbum(
                id: MusicItemID(item.id),
                title: attrs.name,
                artistName: attrs.artistName,
                artworkURL: attrs.artwork?.url,
                releaseDate: nil,
                genreNames: attrs.genreNames ?? []
            )
        }
    }

    func fetchLibraryAlbums(limit: Int, offset: Int) async throws -> [CrateAlbum] {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "api.music.apple.com"
        urlComponents.path = "/v1/me/library/albums"
        urlComponents.queryItems = [
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "offset", value: "\(offset)"),
            URLQueryItem(name: "include", value: "catalog"),
        ]

        guard let url = urlComponents.url else {
            print("[Crate] URL construction failed for \(urlComponents.path)")
            return []
        }

        let request = MusicDataRequest(urlRequest: URLRequest(url: url))
        let response = try await request.response()

        let decoded = try JSONDecoder().decode(LibraryAlbumsResponse.self, from: response.data)
        return decoded.data.compactMap { item -> CrateAlbum? in
            guard let attrs = item.attributes else { return nil }
            // Prefer catalog ID if available, otherwise use library ID.
            let catalogID = item.relationships?.catalog?.data?.first?.id
            let albumID = catalogID ?? item.id
            let catalogAttrs = item.relationships?.catalog?.data?.first?.attributes
            return CrateAlbum(
                id: MusicItemID(albumID),
                title: attrs.name,
                artistName: attrs.artistName,
                artworkURL: attrs.artwork?.url,
                releaseDate: nil,
                genreNames: catalogAttrs?.genreNames ?? attrs.genreNames ?? []
            )
        }
    }

    func fetchRelatedAlbums(for albumID: MusicItemID) async throws -> [CrateAlbum] {
        var request = MusicCatalogResourceRequest<Album>(matching: \.id, equalTo: albumID)
        request.properties = [.relatedAlbums]
        let response = try await request.response()

        guard let album = response.items.first,
              let related = album.relatedAlbums else {
            return []
        }

        return related.map { CrateAlbum(from: $0) }
    }

    func fetchAlbumsByArtist(name: String, limit: Int) async throws -> [CrateAlbum] {
        try await searchAlbums(term: name, limit: limit, offset: 0)
    }

    func fetchArtistID(forAlbumID albumID: MusicItemID) async throws -> MusicItemID? {
        var request = MusicCatalogResourceRequest<Album>(matching: \.id, equalTo: albumID)
        request.properties = [.artists]
        let response = try await request.response()
        return response.items.first?.artists?.first?.id
    }

    func fetchArtistAlbums(artistID: MusicItemID) async throws -> [CrateAlbum] {
        let countryCode = try await MusicDataRequest.currentCountryCode

        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "api.music.apple.com"
        urlComponents.path = "/v1/catalog/\(countryCode)/artists/\(artistID.rawValue)/albums"
        urlComponents.queryItems = [
            URLQueryItem(name: "limit", value: "100"),
        ]

        guard let url = urlComponents.url else {
            print("[Crate] URL construction failed for \(urlComponents.path)")
            return []
        }

        let request = MusicDataRequest(urlRequest: URLRequest(url: url))
        let response = try await request.response()

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")

        let decoded = try JSONDecoder().decode(ArtistAlbumsResponse.self, from: response.data)
        return decoded.data.map { item in
            let releaseDate = item.attributes.releaseDate.flatMap { dateFormatter.date(from: $0) }
            return CrateAlbum(
                id: MusicItemID(item.id),
                title: item.attributes.name,
                artistName: item.attributes.artistName,
                artworkURL: item.attributes.artwork?.url,
                releaseDate: releaseDate,
                genreNames: item.attributes.genreNames ?? []
            )
        }
    }

    // MARK: - Private Helpers

    /// Shared chart-fetching logic for both most-played and new-releases.
    ///
    /// Uses the charts endpoint for popularity ordering, then batch-fetches
    /// full Album objects from the catalog to get reliable genreNames
    /// (the chart response often omits sub-genre detail).
    private func fetchCharts(genreID: String, chartType: String, limit: Int, offset: Int) async throws -> [CrateAlbum] {
        let countryCode = try await MusicDataRequest.currentCountryCode

        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "api.music.apple.com"
        urlComponents.path = "/v1/catalog/\(countryCode)/charts"
        urlComponents.queryItems = [
            URLQueryItem(name: "types", value: "albums"),
            URLQueryItem(name: "genre", value: genreID),
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "offset", value: "\(offset)"),
            URLQueryItem(name: "chart", value: chartType),
        ]

        guard let url = urlComponents.url else {
            print("[Crate] URL construction failed for \(urlComponents.path)")
            return []
        }

        let request = MusicDataRequest(urlRequest: URLRequest(url: url))
        let response = try await request.response()

        let decoded = try JSONDecoder().decode(ChartResponse.self, from: response.data)
        guard let albumChart = decoded.results.albums?.first else {
            return []
        }

        let chartIDs = albumChart.data.map { MusicItemID($0.id) }
        guard !chartIDs.isEmpty else { return [] }

        // Batch-fetch full catalog data for reliable genreNames.
        let catalogAlbums = try await fetchCatalogAlbums(ids: chartIDs)
        let catalogByID = Dictionary(uniqueKeysWithValues: catalogAlbums.map { ($0.id, $0) })

        // Map in chart order, preferring catalog data for richer metadata.
        return chartIDs.compactMap { id -> CrateAlbum? in
            if let album = catalogByID[id] {
                return CrateAlbum(from: album)
            }
            // Fall back to chart data if album missing from catalog.
            guard let item = albumChart.data.first(where: { MusicItemID($0.id) == id }) else {
                return nil
            }
            return CrateAlbum(
                id: id,
                title: item.attributes.name,
                artistName: item.attributes.artistName,
                artworkURL: item.attributes.artwork?.url,
                releaseDate: nil,
                genreNames: item.attributes.genreNames ?? []
            )
        }
    }

    /// Batch-fetch full Album objects from the catalog by ID.
    private func fetchCatalogAlbums(ids: [MusicItemID]) async throws -> [Album] {
        let request = MusicCatalogResourceRequest<Album>(matching: \.id, memberOf: ids)
        let response = try await request.response()
        return Array(response.items)
    }
}

// MARK: - Chart Response Decoding

/// Lightweight Codable types for decoding the charts REST response.
/// We use these instead of MusicKit's built-in types because we're
/// making a raw MusicDataRequest for genre-filtered charts.
private struct ChartResponse: Codable {
    let results: ChartResults
}

private struct ChartResults: Codable {
    let albums: [ChartAlbumGroup]?
}

private struct ChartAlbumGroup: Codable {
    let data: [ChartAlbumItem]
}

private struct ChartAlbumItem: Codable {
    let id: String
    let attributes: ChartAlbumAttributes
}

private struct ChartAlbumAttributes: Codable {
    let name: String
    let artistName: String
    let artwork: ChartArtwork?
    let genreNames: [String]?
}

private struct ChartArtwork: Codable {
    let url: String?
}

// MARK: - Recently Played Response Decoding

private struct RecentlyPlayedResponse: Codable {
    let data: [RecentlyPlayedItem]
}

private struct RecentlyPlayedItem: Codable {
    let id: String
    let type: String
    let attributes: RecentlyPlayedAttributes?
}

private struct RecentlyPlayedAttributes: Codable {
    let name: String
    let artistName: String
    let artwork: ChartArtwork?
    let genreNames: [String]?
}

// MARK: - Recommendation Response Decoding

private struct RecommendationResponse: Codable {
    let data: [RecommendationGroup]
}

private struct RecommendationGroup: Codable {
    let id: String
    let relationships: RecommendationRelationships?
}

private struct RecommendationRelationships: Codable {
    let contents: RecommendationContents
}

private struct RecommendationContents: Codable {
    let data: [RecommendationItem]
}

private struct RecommendationItem: Codable {
    let id: String
    let type: String
    let attributes: RecommendationItemAttributes?
}

private struct RecommendationItemAttributes: Codable {
    let name: String
    let artistName: String
    let artwork: ChartArtwork?
    let genreNames: [String]?
}

// MARK: - Search Response Decoding

private struct SearchResponse: Codable {
    let results: SearchResultsContainer
}

private struct SearchResultsContainer: Codable {
    let albums: SearchAlbumResults?
}

private struct SearchAlbumResults: Codable {
    let data: [ChartAlbumItem]   // Same structure as chart album items
}

// MARK: - Library Albums Response Decoding

private struct LibraryAlbumsResponse: Codable {
    let data: [LibraryAlbumItem]
}

private struct LibraryAlbumItem: Codable {
    let id: String
    let attributes: LibraryAlbumAttributes?
    let relationships: LibraryAlbumRelationships?
}

private struct LibraryAlbumAttributes: Codable {
    let name: String
    let artistName: String
    let artwork: ChartArtwork?
    let genreNames: [String]?
}

private struct LibraryAlbumRelationships: Codable {
    let catalog: LibraryCatalogRelationship?
}

private struct LibraryCatalogRelationship: Codable {
    let data: [LibraryCatalogItem]?
}

private struct LibraryCatalogItem: Codable {
    let id: String
    let attributes: ChartAlbumAttributes?
}

// MARK: - Artist Albums Response Decoding

private struct ArtistAlbumsResponse: Codable {
    let data: [ArtistAlbumItem]
}

private struct ArtistAlbumItem: Codable {
    let id: String
    let attributes: ArtistAlbumAttributes
}

private struct ArtistAlbumAttributes: Codable {
    let name: String
    let artistName: String
    let artwork: ChartArtwork?
    let releaseDate: String?
    let genreNames: [String]?
}
