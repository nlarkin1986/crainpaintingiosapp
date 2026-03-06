import SwiftUI

@MainActor
@Observable
final class FavoritesViewModel {
    var searchText = ""
    var favorites: [PaintColor] = [
        PaintColor(number: "2163-10", name: "Hale Navy", family: "Blue", hex: "3C4659", brand: .benjaminMoore),
        PaintColor(number: "OC-45", name: "Swiss Coffee", family: "White", hex: "E9E1D1", brand: .benjaminMoore),
        PaintColor(number: "AF-70", name: "Sea Salt", family: "Green", hex: "B8C9C0", brand: .benjaminMoore),
        PaintColor(number: "2050-10", name: "Backwoods", family: "Green", hex: "3C5241", brand: .benjaminMoore),
        PaintColor(number: "OC-17", name: "White Dove", family: "White", hex: "F3EDE1", brand: .benjaminMoore),
        PaintColor(number: "SW 6244", name: "Naval", family: "Blue", hex: "2E384D", brand: .sherwinWilliams),
        PaintColor(number: "SW 7029", name: "Agreeable Gray", family: "Gray", hex: "CFC6B8", brand: .sherwinWilliams),
        PaintColor(number: "HC-173", name: "Edgecomb Gray", family: "Neutral", hex: "C5BEAD", brand: .benjaminMoore),
    ]

    var filteredFavorites: [PaintColor] {
        guard !searchText.isEmpty else { return favorites }
        return favorites.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.number.localizedCaseInsensitiveContains(searchText)
        }
    }

    func toggleFavorite(_ color: PaintColor) {
        if let index = favorites.firstIndex(of: color) {
            favorites.remove(at: index)
        } else {
            favorites.append(color)
        }
    }

    func isFavorite(_ color: PaintColor) -> Bool {
        favorites.contains(color)
    }
}
