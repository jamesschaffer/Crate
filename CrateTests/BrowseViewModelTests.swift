import Testing
import MusicKit
import SwiftData
@testable import Crate_iOS

/// Tests for BrowseViewModel's genre selection and state management.
struct BrowseViewModelTests {

    /// Create an in-memory container for testing.
    private func makeContext() throws -> ModelContext {
        let schema = Schema([FavoriteAlbum.self, DislikedAlbum.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }

    @Test("Initial state has no selected category")
    @MainActor
    func initialState() {
        let vm = BrowseViewModel()
        #expect(vm.selectedCategory == nil)
        #expect(vm.albums.isEmpty)
        #expect(vm.isLoading == false)
        #expect(vm.errorMessage == nil)
        #expect(vm.selectedSubcategoryIDs.isEmpty)
    }

    @Test("selectCategory sets state and triggers fetch")
    @MainActor
    func selectCategorySetsState() async throws {
        let mock = MockMusicService()
        mock.chartAlbums = [
            CrateAlbum(id: MusicItemID("1"), title: "A", artistName: "A", artworkURL: nil, releaseDate: nil, genreNames: ["Rock"])
        ]
        mock.newReleaseAlbums = mock.chartAlbums
        mock.recommendationAlbums = mock.chartAlbums

        let vm = BrowseViewModel(musicService: mock)
        vm.configure(modelContext: try makeContext())
        let rock = Genres.all.first { $0.name == "Rock" }!

        await vm.selectCategory(rock)

        #expect(vm.selectedCategory?.id == rock.id)
        #expect(vm.selectedSubcategoryIDs.isEmpty)
    }

    @Test("clearSelection resets all state")
    @MainActor
    func clearSelectionResetsState() async throws {
        let mock = MockMusicService()
        let vm = BrowseViewModel(musicService: mock)
        vm.configure(modelContext: try makeContext())
        let rock = Genres.all.first { $0.name == "Rock" }!

        await vm.selectCategory(rock)
        vm.clearSelection()

        #expect(vm.selectedCategory == nil)
        #expect(vm.selectedSubcategoryIDs.isEmpty)
        #expect(vm.albums.isEmpty)
        #expect(vm.errorMessage == nil)
        #expect(vm.hasMorePages == true)
    }

    @Test("toggleSubcategory adds and removes IDs")
    @MainActor
    func toggleSubcategoryAddsRemoves() async throws {
        let mock = MockMusicService()
        mock.searchResults = [
            CrateAlbum(id: MusicItemID("1"), title: "A", artistName: "A", artworkURL: nil, releaseDate: nil, genreNames: [])
        ]

        let vm = BrowseViewModel(musicService: mock)
        vm.configure(modelContext: try makeContext())
        let subID = "rock-alternative"

        // Toggle on
        await vm.toggleSubcategory(subID)
        #expect(vm.selectedSubcategoryIDs.contains(subID))

        // Toggle off
        await vm.toggleSubcategory(subID)
        #expect(!vm.selectedSubcategoryIDs.contains(subID))
    }
}
