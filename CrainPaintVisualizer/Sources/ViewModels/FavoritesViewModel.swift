import SwiftUI

@MainActor
@Observable
final class FavoritesViewModel {
    var searchText = ""
    var selectedBrandFilter: PaintBrand?
    var sort: FavoriteSort = .latest
    var favorites: [PaintColor] = []

    private let store: FavoritesStore
    private var persistTask: Task<Void, Never>?
    private var lastRemoved: (color: PaintColor, index: Int)?

    private static let seedFavorites: [PaintColor] = [
        PaintColor(number: "2163-10", name: "Hale Navy", family: "Blue", hex: "3C4659", brand: .benjaminMoore),
        PaintColor(number: "OC-45", name: "Swiss Coffee", family: "White", hex: "E9E1D1", brand: .benjaminMoore),
        PaintColor(number: "AF-70", name: "Sea Salt", family: "Green", hex: "B8C9C0", brand: .benjaminMoore),
        PaintColor(number: "2050-10", name: "Backwoods", family: "Green", hex: "3C5241", brand: .benjaminMoore),
        PaintColor(number: "OC-17", name: "White Dove", family: "White", hex: "F3EDE1", brand: .benjaminMoore),
        PaintColor(number: "SW 6244", name: "Naval", family: "Blue", hex: "2E384D", brand: .sherwinWilliams),
        PaintColor(number: "SW 7029", name: "Agreeable Gray", family: "Gray", hex: "CFC6B8", brand: .sherwinWilliams),
        PaintColor(number: "HC-173", name: "Edgecomb Gray", family: "Neutral", hex: "C5BEAD", brand: .benjaminMoore),
    ]

    enum FavoriteSort: String, CaseIterable {
        case latest = "Latest"
        case name = "Name"
    }

    init(store: FavoritesStore = FileFavoritesStore()) {
        self.store = store
        Task { await loadFavorites() }
    }

    var filteredFavorites: [PaintColor] {
        var items = favorites

        if let selectedBrandFilter {
            items = items.filter { $0.brand == selectedBrandFilter }
        }

        if !searchText.isEmpty {
            items = items.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.number.localizedCaseInsensitiveContains(searchText)
            }
        }

        switch sort {
        case .latest:
            return items
        case .name:
            return items.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
    }

    func toggleFavorite(_ color: PaintColor) {
        if !removeFavorite(color) {
            _ = addFavorite(color)
        }
    }

    @discardableResult
    func addFavorite(_ color: PaintColor) -> Bool {
        guard !favorites.contains(color) else { return false }
        favorites.insert(color, at: 0)
        schedulePersist()
        return true
    }

    @discardableResult
    func removeFavorite(_ color: PaintColor) -> Bool {
        guard let index = favorites.firstIndex(of: color) else { return false }
        lastRemoved = (color, index)
        favorites.remove(at: index)
        schedulePersist()
        return true
    }

    func undoLastRemoval() {
        guard let removed = lastRemoved else { return }
        let insertIndex = min(removed.index, favorites.count)
        favorites.insert(removed.color, at: insertIndex)
        lastRemoved = nil
        schedulePersist()
    }

    var canUndo: Bool { lastRemoved != nil }

    func isFavorite(_ color: PaintColor) -> Bool {
        favorites.contains(color)
    }

    private func loadFavorites() async {
        do {
            let saved = try await store.loadFavorites()
            favorites = saved.isEmpty ? Self.seedFavorites : saved
            if saved.isEmpty {
                schedulePersist()
            }
        } catch {
            favorites = Self.seedFavorites
        }
    }

    private func schedulePersist() {
        persistTask?.cancel()
        let snapshot = favorites
        persistTask = Task {
            try? await Task.sleep(for: .milliseconds(150))
            try? await store.saveFavorites(snapshot)
        }
    }
}
