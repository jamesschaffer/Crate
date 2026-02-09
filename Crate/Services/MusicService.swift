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

    /// Fetch a single album's full details by its MusicItemID.
    func fetchAlbumDetail(id: MusicItemID) async throws -> Album?

    /// Fetch the tracks for an album.
    func fetchAlbumTracks(albumID: MusicItemID) async throws -> MusicItemCollection<Track>
}

// MARK: - Implementation

/// Production implementation using MusicDataRequest for genre-filtered charts
/// and MusicCatalogResourceRequest for album detail/tracks.
struct MusicService: MusicServiceProtocol {

    func fetchChartAlbums(genreID: String, limit: Int, offset: Int) async throws -> [CrateAlbum] {
        // Use MusicDataRequest for the charts endpoint with genre filtering.
        // This gives us full control over query parameters.
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
            URLQueryItem(name: "chart", value: "most-played"),
        ]

        guard let url = urlComponents.url else {
            return []
        }

        let request = MusicDataRequest(urlRequest: URLRequest(url: url))
        let response = try await request.response()

        // Decode the chart response
        let decoded = try JSONDecoder().decode(ChartResponse.self, from: response.data)
        guard let albumChart = decoded.results.albums?.first else {
            return []
        }

        return albumChart.data.map { chartAlbum in
            CrateAlbum(
                id: MusicItemID(chartAlbum.id),
                title: chartAlbum.attributes.name,
                artistName: chartAlbum.attributes.artistName,
                artworkURL: chartAlbum.attributes.artwork?.url,
                releaseDate: nil,
                genreNames: chartAlbum.attributes.genreNames ?? []
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
