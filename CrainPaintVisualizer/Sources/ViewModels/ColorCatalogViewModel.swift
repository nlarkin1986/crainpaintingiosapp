import SwiftUI

@MainActor
@Observable
final class ColorCatalogViewModel {
    static let availableBrands: [PaintBrand] = [.benjaminMoore, .sherwinWilliams, .behr]

    var searchText = "" {
        didSet { scheduleFilter() }
    }
    var selectedBrand: PaintBrand = .benjaminMoore {
        didSet { updateFilteredColors() }
    }
    var selectedFilter: ColorFilter = .popular {
        didSet { updateFilteredColors() }
    }

    private(set) var filteredColors: [PaintColor] = []

    enum ColorFilter: String, CaseIterable {
        case popular = "Popular"
        case all = "All Colors"
        case match = "Match"
    }

    private var filterTask: Task<Void, Never>?

    init() {
        updateFilteredColors()
    }

    private func scheduleFilter() {
        filterTask?.cancel()
        filterTask = Task {
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled else { return }
            updateFilteredColors()
        }
    }

    private func updateFilteredColors() {
        let branded = allColors.filter { $0.brand == selectedBrand }
        let filtered: [PaintColor]
        switch selectedFilter {
        case .popular:
            filtered = Array(branded.prefix(24))
        case .all, .match:
            filtered = branded
        }
        guard !searchText.isEmpty else {
            filteredColors = filtered
            return
        }
        filteredColors = filtered.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.number.localizedCaseInsensitiveContains(searchText)
        }
    }

    // Mock data for development
    let allColors: [PaintColor] = {
        let bmColors: [(String, String, String, String)] = [
            ("OC-17", "White Dove", "White", "F3EDE1"),
            ("HC-172", "Revere Pewter", "Neutral", "CCC1AE"),
            ("2163-10", "Hale Navy", "Blue", "3C4659"),
            ("HC-85", "Wyoming Trail", "Brown", "5C4E3B"),
            ("OC-130", "Cloud White", "White", "F2EDE3"),
            ("HC-80", "Bleeker Beige", "Neutral", "C9B99A"),
            ("AF-70", "Sea Salt", "Green", "B8C9C0"),
            ("2160-50", "Pashmina", "Neutral", "B5A896"),
            ("OC-65", "Chantilly Lace", "White", "F5F0E7"),
            ("HC-173", "Edgecomb Gray", "Neutral", "C5BEAD"),
            ("2144-40", "Palladian Blue", "Blue", "B5CED0"),
            ("2163-20", "Naval", "Blue", "2D3A4E"),
            ("OC-45", "Swiss Coffee", "White", "E9E1D1"),
            ("2163-30", "Van Deusen Blue", "Blue", "3F5268"),
            ("HC-166", "Kendall Charcoal", "Gray", "5C5C5B"),
            ("2153-40", "Gray Owl", "Gray", "C1C0BA"),
            ("AF-685", "Thunder", "Gray", "9E9A94"),
            ("HC-170", "Stonington Gray", "Gray", "B0ADA5"),
            ("2050-10", "Backwoods", "Green", "3C5241"),
            ("2145-10", "Deep Royal", "Blue", "2E4F6E"),
            ("OC-1", "Natural Wicker", "Neutral", "DDD3C0"),
            ("HC-158", "Newburyport Blue", "Blue", "3F5B73"),
            ("2163-40", "Normandy", "Blue", "6B8AA0"),
            ("OC-57", "White Heron", "White", "F3EDE5"),
        ]
        let swColors: [(String, String, String, String)] = [
            ("SW 7015", "Repose Gray", "Gray", "B6AFA5"),
            ("SW 7043", "Worldly Gray", "Gray", "B6AEA3"),
            ("SW 7029", "Agreeable Gray", "Gray", "CFC6B8"),
            ("SW 6119", "Antique White", "White", "F2E5D0"),
            ("SW 7006", "Extra White", "White", "EFECE7"),
            ("SW 6990", "Caviar", "Black", "2E2E2E"),
            ("SW 6258", "Tricorn Black", "Black", "2D2C2B"),
            ("SW 7016", "Mindful Gray", "Gray", "ACA69E"),
            ("SW 6244", "Naval", "Blue", "2E384D"),
            ("SW 7036", "Accessible Beige", "Neutral", "C8BDAC"),
            ("SW 7012", "Creamy", "White", "F0E4CE"),
            ("SW 7035", "Aesthetic White", "White", "E8E0D0"),
        ]
        let behrColors: [(String, String, String, String)] = [
            ("PPU18-12", "Swiss Coffee", "White", "F0E8DA"),
            ("PPU7-12", "Blank Canvas", "White", "ECE6D8"),
            ("PPU24-11", "Silver Drop", "Gray", "D1CCC3"),
            ("N320-2", "Whisper White", "White", "F2EEE7"),
            ("S390-5", "Juniper Ash", "Green", "7E8A79"),
            ("MQ5-32", "Breezeway", "Green", "B7C8C2"),
            ("PPU15-16", "Cracked Pepper", "Black", "4A4B49"),
            ("MQ3-28", "Cameo White", "Neutral", "E6D8C2"),
            ("S470-6", "Blueprint", "Blue", "56708A"),
            ("PPU5-12", "Almond Wisp", "Neutral", "D6C7B2"),
            ("PPU25-07", "Ultra Pure White", "White", "F7F5EF"),
            ("PPU18-17", "Toasty Gray", "Gray", "A79D93"),
        ]
        var colors: [PaintColor] = []
        for (num, name, family, hex) in bmColors {
            colors.append(PaintColor(number: num, name: name, family: family, hex: hex, brand: .benjaminMoore))
        }
        for (num, name, family, hex) in swColors {
            colors.append(PaintColor(number: num, name: name, family: family, hex: hex, brand: .sherwinWilliams))
        }
        for (num, name, family, hex) in behrColors {
            colors.append(PaintColor(number: num, name: name, family: family, hex: hex, brand: .behr))
        }
        return colors
    }()
}
