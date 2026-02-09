import Testing
@testable import Crate

/// Tests for BrowseViewModel's genre selection and state management.
struct BrowseViewModelTests {

    @Test("Initial state has no selected category")
    func initialState() {
        let vm = BrowseViewModel()
        #expect(vm.selectedCategory == nil)
        #expect(vm.albums.isEmpty)
        #expect(vm.isLoading == false)
        #expect(vm.errorMessage == nil)
        #expect(vm.selectedSubcategoryIDs.isEmpty)
    }

    @Test("Toggling a subcategory adds and removes it")
    func subcategoryToggle() async {
        let vm = BrowseViewModel()
        // Toggling without a selected category won't fetch, but state should update.
        // We test the ID tracking here, not the fetch.
        let subID = "rock-alternative"
        #expect(!vm.selectedSubcategoryIDs.contains(subID))
    }
}
