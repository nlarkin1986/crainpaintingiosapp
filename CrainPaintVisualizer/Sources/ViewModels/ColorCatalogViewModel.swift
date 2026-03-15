import Foundation
import OSLog
import SwiftUI

struct ColorCatalogFamilyCount: Hashable, Sendable {
    let family: String
    let count: Int
}

struct ColorCatalogSearchEntry: Sendable {
    let color: PaintColor
    let lowercaseName: String
    let lowercaseNumber: String
    let lowercaseHex: String
    let normalizedName: String
    let normalizedNumber: String

    init(color: PaintColor) {
        self.color = color
        self.lowercaseName = color.name.lowercased()
        self.lowercaseNumber = color.number.lowercased()
        self.lowercaseHex = color.hex.lowercased()
        self.normalizedName = ColorCatalogViewModel.normalizeSearchText(color.name)
        self.normalizedNumber = ColorCatalogViewModel.normalizeSearchText(color.number)
    }
}

struct ColorCatalogBrandIndex: Sendable {
    static let empty = ColorCatalogBrandIndex(
        allColors: [],
        searchEntries: [],
        popularColors: [],
        familyCounts: []
    )

    let allColors: [PaintColor]
    let searchEntries: [ColorCatalogSearchEntry]
    let popularColors: [PaintColor]
    let familyCounts: [ColorCatalogFamilyCount]
}

protocol ColorCatalogProviding: Sendable {
    func loadBrandIndex(for brand: PaintBrand) async throws -> ColorCatalogBrandIndex
    func prewarm(brand: PaintBrand) async
}

private struct ImmediateColorCatalogProvider: ColorCatalogProviding {
    let brandIndices: [PaintBrand: ColorCatalogBrandIndex]

    func loadBrandIndex(for brand: PaintBrand) async throws -> ColorCatalogBrandIndex {
        brandIndices[brand] ?? .empty
    }

    func prewarm(brand: PaintBrand) async {}
}

actor SharedColorCatalogStore: ColorCatalogProviding {
    static let shared = SharedColorCatalogStore()

    private var cachedIndices: [PaintBrand: ColorCatalogBrandIndex] = [:]
    private var loadTasks: [PaintBrand: Task<ColorCatalogBrandIndex, Error>] = [:]

    func loadBrandIndex(for brand: PaintBrand) async throws -> ColorCatalogBrandIndex {
        if let cachedIndex = cachedIndices[brand] {
            return cachedIndex
        }

        let task = loadTasks[brand] ?? makeLoadTask(for: brand, priority: .userInitiated)
        loadTasks[brand] = task

        do {
            let index = try await task.value
            cachedIndices[brand] = index
            loadTasks[brand] = nil
            return index
        } catch {
            loadTasks[brand] = nil
            throw error
        }
    }

    func prewarm(brand: PaintBrand) async {
        _ = try? await loadBrandIndex(for: brand)
    }

    private func makeLoadTask(
        for brand: PaintBrand,
        priority: TaskPriority
    ) -> Task<ColorCatalogBrandIndex, Error> {
        Task.detached(priority: priority) {
            let start = ProcessInfo.processInfo.systemUptime
            let index = try ColorCatalogViewModel.buildBrandIndex(for: brand)
            let elapsedMs = Int((ProcessInfo.processInfo.systemUptime - start) * 1_000)
            ColorCatalogViewModel.logger.debug(
                "Loaded \(brand.rawValue, privacy: .public) catalog with \(index.allColors.count, privacy: .public) colors in \(elapsedMs, privacy: .public) ms"
            )
            return index
        }
    }
}

@MainActor
@Observable
final class ColorCatalogViewModel {
    static let availableBrands: [PaintBrand] = PaintBrand.supportedCases
    static let pageSize = 60
    private static let maxSearchResults = 120
    static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "CrainPaintVisualizer",
        category: "ColorCatalog"
    )

    static let catalogResourceNames: [PaintBrand: String] = [
        .benjaminMoore: "bm-colors",
        .sherwinWilliams: "sw-colors",
        .farrowBall: "fb-colors",
    ]

    private static let popularCatalogResourceNames: [PaintBrand: String] = [
        .benjaminMoore: "bm-popular-colors",
        .sherwinWilliams: "sw-popular-colors",
        .farrowBall: "fb-popular-colors",
    ]

    private static let popularColorNames: [PaintBrand: [String]] = [
        .benjaminMoore: [
            "White Dove",
            "Simply White",
            "Chantilly Lace",
            "Swiss Coffee",
            "Revere Pewter",
            "Hale Navy",
            "Kendall Charcoal",
            "Classic Gray",
            "Palladian Blue",
            "Sea Salt",
            "Edgecomb Gray",
            "Balboa Mist",
            "Chelsea Gray",
            "Wrought Iron",
            "Stone Hearth",
            "Newburyport Blue",
            "White Heron",
            "Collingwood",
            "Manchester Tan",
            "Healing Aloe",
            "Gray Owl",
            "Super White",
            "Paper White",
            "Dove Wing",
        ],
        .sherwinWilliams: [
            "Agreeable Gray",
            "Accessible Beige",
            "Repose Gray",
            "Alabaster",
            "Sea Salt",
            "Naval",
            "Colonnade Gray",
            "Snowbound",
            "Pure White",
            "White Duck",
            "Mindful Gray",
            "Dovetail",
            "Urbane Bronze",
            "Rainwashed",
            "Pewter Cast",
            "Greek Villa",
            "Peppercorn",
            "Jogging Path",
            "Worldly Gray",
            "Intellectual Gray",
            "Wool Skein",
            "Antique White",
            "Canvas Tan",
            "Kilim Beige",
        ],
        .farrowBall: [
            "All White",
            "School House White",
            "Strong White",
            "Slipper Satin",
            "Skimming Stone",
            "Ammonite",
            "Cornforth White",
            "Elephant's Breath",
            "Drop Cloth",
            "Joa's White",
            "Pointing",
            "Dimity",
            "Wimborne White",
            "Setting Plaster",
            "Sulking Room Pink",
            "Hague Blue",
            "Stiffkey Blue",
            "De Nimes",
            "Parma Gray",
            "French Gray",
            "Green Smoke",
            "Card Room Green",
            "Railings",
            "Down Pipe",
        ],
    ]

    private struct BundledCatalogColor: Decodable {
        let number: String
        let name: String
        let family: String
        let hex: String
    }

    private final class CatalogBundleToken {}

    var searchText = "" {
        didSet { scheduleFilter() }
    }
    var selectedBrand: PaintBrand = .benjaminMoore {
        didSet { scheduleFilter(debounce: false) }
    }
    var selectedFilter: ColorFilter = .popular {
        didSet { scheduleFilter(debounce: false) }
    }

    private(set) var filteredColors: [PaintColor] = []
    private(set) var totalResultCount = 0
    private(set) var isLoading = false
    private(set) var hasLoadedCatalog = false
    private(set) var familyCounts: [ColorCatalogFamilyCount] = []

    var shouldShowGridLoadingState: Bool {
        guard !hasLoadedCatalog else { return false }
        return isLoading && filteredColors.isEmpty && Self.requiresLoadedCatalog(
            for: selectedFilter,
            query: searchText
        )
    }

    enum ColorFilter: String, CaseIterable {
        case popular = "Popular"
        case all = "All Colors"
        case match = "Match"
    }

    private let catalogProvider: any ColorCatalogProviding
    private let popularColorsByBrand: [PaintBrand: [PaintColor]]
    private var loadedBrandIndices: [PaintBrand: ColorCatalogBrandIndex] = [:]
    private var loadingBrands = Set<PaintBrand>()
    private var matchingColors: [PaintColor] = []
    private var visibleLimit = pageSize
    private var filterTask: Task<Void, Never>?
    private var backgroundLoadTasks: [PaintBrand: Task<Void, Never>] = [:]

    init(catalogProvider: any ColorCatalogProviding = SharedColorCatalogStore.shared) {
        self.catalogProvider = catalogProvider
        self.popularColorsByBrand = Self.loadBundledPopularColors()
        refreshPresentationForCurrentState()
    }

    init(
        catalogProvider: any ColorCatalogProviding,
        popularColorsByBrand: [PaintBrand: [PaintColor]]
    ) {
        self.catalogProvider = catalogProvider
        self.popularColorsByBrand = popularColorsByBrand
        refreshPresentationForCurrentState()
    }

    init(allColors: [PaintColor]) {
        let pairs: [(PaintBrand, ColorCatalogBrandIndex)] = Self.availableBrands.compactMap { brand in
            let brandColors = allColors.filter { $0.brand == brand }
            guard !brandColors.isEmpty else { return nil }
            return (brand, Self.makeBrandIndex(from: brandColors))
        }
        let brandIndices = Dictionary(uniqueKeysWithValues: pairs)

        self.catalogProvider = ImmediateColorCatalogProvider(brandIndices: brandIndices)
        self.popularColorsByBrand = Dictionary(uniqueKeysWithValues: Self.availableBrands.map { brand in
            let brandColors = allColors.filter { $0.brand == brand }
            return (brand, Self.popularColors(in: brandColors, for: brand))
        })
        self.loadedBrandIndices = brandIndices
        refreshPresentationForCurrentState()
    }

    var canLoadMoreResults: Bool {
        filteredColors.count < matchingColors.count
    }

    func loadIfNeeded() async {
        refreshPresentationForCurrentState()
        await ensureBrandLoadedIfNeeded(for: selectedBrand)
    }

    func loadNextPageIfNeeded(currentItem: PaintColor?) {
        guard canLoadMoreResults else { return }
        guard currentItem == nil || filteredColors.last == currentItem else { return }

        visibleLimit = min(visibleLimit + Self.pageSize, matchingColors.count)
        applyVisibleWindow()
    }

    private func scheduleFilter(debounce: Bool = true) {
        filterTask?.cancel()
        let requestedBrand = selectedBrand

        filterTask = Task {
            if debounce {
                try? await Task.sleep(for: .milliseconds(180))
                guard !Task.isCancelled else { return }
            }

            refreshPresentationForCurrentState()
            startBackgroundLoadIfNeeded(for: requestedBrand)
        }
    }

    private func refreshPresentationForCurrentState() {
        let brand = selectedBrand
        let brandIndex = loadedBrandIndices[brand]
        let needsLoadedCatalog = Self.requiresLoadedCatalog(for: selectedFilter, query: searchText)

        hasLoadedCatalog = brandIndex != nil
        isLoading = loadingBrands.contains(brand) || (brandIndex == nil && needsLoadedCatalog)

        if let brandIndex {
            familyCounts = brandIndex.familyCounts
            let matches = Self.makeMatches(
                in: brandIndex,
                filter: selectedFilter,
                query: searchText,
                popularFallback: popularColorsByBrand[brand] ?? []
            )
            applyMatches(matches)
            return
        }

        familyCounts = []

        if needsLoadedCatalog {
            applyMatches([])
            return
        }

        applyMatches(popularColorsByBrand[brand] ?? [])
    }

    private func applyMatches(_ matches: [PaintColor]) {
        matchingColors = matches
        totalResultCount = matches.count
        visibleLimit = min(Self.pageSize, matches.count)

        if selectedFilter == .popular && searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            visibleLimit = matches.count
        }

        applyVisibleWindow()
    }

    private func applyVisibleWindow() {
        filteredColors = Array(matchingColors.prefix(visibleLimit))
    }

    private func ensureBrandLoadedIfNeeded(for brand: PaintBrand) async {
        guard loadedBrandIndices[brand] == nil else { return }
        guard !loadingBrands.contains(brand) else { return }

        loadingBrands.insert(brand)
        if brand == selectedBrand {
            refreshPresentationForCurrentState()
        }

        do {
            let index = try await catalogProvider.loadBrandIndex(for: brand)
            loadedBrandIndices[brand] = index
        } catch {
            Self.logger.error(
                "Failed to load \(brand.rawValue, privacy: .public) catalog: \(String(describing: error), privacy: .public)"
            )
            let fallbackPopular = popularColorsByBrand[brand] ?? Self.popularColors(
                in: Self.fallbackColors(for: brand),
                for: brand
            )
            loadedBrandIndices[brand] = Self.fallbackBrandIndex(
                for: brand,
                popularSeed: fallbackPopular
            )
        }

        loadingBrands.remove(brand)

        if brand == selectedBrand {
            refreshPresentationForCurrentState()
        }
    }

    private func startBackgroundLoadIfNeeded(for brand: PaintBrand) {
        guard loadedBrandIndices[brand] == nil else { return }
        guard !loadingBrands.contains(brand) else { return }
        guard backgroundLoadTasks[brand] == nil else { return }

        backgroundLoadTasks[brand] = Task { [weak self] in
            guard let self else { return }
            await self.ensureBrandLoadedIfNeeded(for: brand)
            await MainActor.run {
                self.backgroundLoadTasks[brand] = nil
            }
        }
    }

    private nonisolated static func makeMatches(
        in index: ColorCatalogBrandIndex,
        filter: ColorFilter,
        query: String,
        popularFallback: [PaintColor]
    ) -> [PaintColor] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)

        if !trimmedQuery.isEmpty {
            let loweredQuery = trimmedQuery.lowercased()
            let normalizedQuery = normalizeSearchText(trimmedQuery)
            let normalizedHexQuery = loweredQuery.replacingOccurrences(of: "#", with: "")

            var results: [PaintColor] = []
            results.reserveCapacity(min(maxSearchResults, index.searchEntries.count))

            for entry in index.searchEntries {
                if results.count >= maxSearchResults {
                    break
                }

                if entry.lowercaseName.contains(loweredQuery) ||
                    entry.lowercaseNumber.contains(loweredQuery) ||
                    entry.lowercaseHex.contains(normalizedHexQuery) ||
                    entry.normalizedName.contains(normalizedQuery) ||
                    entry.normalizedNumber.contains(normalizedQuery) {
                    results.append(entry.color)
                }
            }

            return results
        }

        switch filter {
        case .popular:
            return index.popularColors.isEmpty ? popularFallback : index.popularColors
        case .all, .match:
            return index.allColors
        }
    }

    private nonisolated static func requiresLoadedCatalog(
        for filter: ColorFilter,
        query: String
    ) -> Bool {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedQuery.isEmpty || filter == .all || filter == .match
    }

    nonisolated static func buildBrandIndex(for brand: PaintBrand) throws -> ColorCatalogBrandIndex {
        let colors = try loadBundledColors(for: brand)
        let popularSeed = (try? loadBundledPopularColors(for: brand)) ?? popularColors(in: colors, for: brand)
        return makeBrandIndex(from: colors, popularOverride: popularSeed)
    }

    private nonisolated static func makeBrandIndex(
        from colors: [PaintColor],
        popularOverride: [PaintColor]? = nil
    ) -> ColorCatalogBrandIndex {
        ColorCatalogBrandIndex(
            allColors: colors,
            searchEntries: colors.map(ColorCatalogSearchEntry.init),
            popularColors: popularOverride ?? popularColors(in: colors, for: colors.first?.brand ?? .benjaminMoore),
            familyCounts: familyCounts(in: colors)
        )
    }

    private nonisolated static func fallbackBrandIndex(
        for brand: PaintBrand,
        popularSeed: [PaintColor]
    ) -> ColorCatalogBrandIndex {
        let colors = fallbackColors(for: brand)
        return makeBrandIndex(from: colors, popularOverride: popularSeed.isEmpty ? popularColors(in: colors, for: brand) : popularSeed)
    }

    private nonisolated static func loadBundledColors(for brand: PaintBrand) throws -> [PaintColor] {
        guard let resourceName = catalogResourceNames[brand] else {
            return []
        }
        guard let url = bundledCatalogURL(resourceName: resourceName) else {
            throw NSError(domain: "ColorCatalog", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Missing bundled catalog resource: \(resourceName).json",
            ])
        }
        return try loadCatalog(from: url, brand: brand)
    }

    private nonisolated static func loadBundledPopularColors() -> [PaintBrand: [PaintColor]] {
        Dictionary(uniqueKeysWithValues: availableBrands.map { brand in
            let popularColors = (try? loadBundledPopularColors(for: brand))
                ?? popularColors(in: fallbackColors(for: brand), for: brand)
            return (brand, popularColors)
        })
    }

    private nonisolated static func loadBundledPopularColors(for brand: PaintBrand) throws -> [PaintColor] {
        guard let resourceName = popularCatalogResourceNames[brand] else {
            return []
        }
        guard let url = bundledCatalogURL(resourceName: resourceName) else {
            throw NSError(domain: "ColorCatalog", code: 2, userInfo: [
                NSLocalizedDescriptionKey: "Missing bundled popular catalog resource: \(resourceName).json",
            ])
        }
        return try loadCatalog(from: url, brand: brand)
    }

    nonisolated static func loadCatalog(from url: URL, brand: PaintBrand) throws -> [PaintColor] {
        let data = try Data(contentsOf: url)
        let rawColors = try JSONDecoder().decode([BundledCatalogColor].self, from: data)
        return rawColors.map {
            PaintColor(number: $0.number, name: $0.name, family: $0.family, hex: $0.hex, brand: brand)
        }
    }

    private nonisolated static func bundledCatalogURL(resourceName: String) -> URL? {
        if let url = Bundle.main.url(forResource: resourceName, withExtension: "json") {
            return url
        }
        if let url = Bundle.main.url(forResource: resourceName, withExtension: "json", subdirectory: "ColorCatalog") {
            return url
        }

        let fallbackBundle = Bundle(for: CatalogBundleToken.self)
        guard fallbackBundle.bundleURL != Bundle.main.bundleURL else {
            return nil
        }

        if let url = fallbackBundle.url(forResource: resourceName, withExtension: "json") {
            return url
        }
        if let url = fallbackBundle.url(forResource: resourceName, withExtension: "json", subdirectory: "ColorCatalog") {
            return url
        }

        return nil
    }

    private nonisolated static func popularColors(in colors: [PaintColor], for brand: PaintBrand) -> [PaintColor] {
        guard let names = popularColorNames[brand] else {
            return Array(colors.prefix(24))
        }

        let colorsByName = Dictionary(grouping: colors, by: { $0.name.lowercased() })
        let popular = names.compactMap { name in
            colorsByName[name.lowercased()]?.first
        }
        return popular.isEmpty ? Array(colors.prefix(24)) : popular
    }

    private nonisolated static func familyCounts(in colors: [PaintColor]) -> [ColorCatalogFamilyCount] {
        Dictionary(grouping: colors, by: \.family)
            .map { ColorCatalogFamilyCount(family: $0.key, count: $0.value.count) }
            .sorted { lhs, rhs in
                if lhs.count == rhs.count {
                    return lhs.family < rhs.family
                }
                return lhs.count > rhs.count
            }
    }

    nonisolated static func normalizeSearchText(_ value: String) -> String {
        value
            .lowercased()
            .unicodeScalars
            .filter { CharacterSet.alphanumerics.contains($0) }
            .map(String.init)
            .joined()
    }

    private nonisolated static func fallbackColors(for brand: PaintBrand) -> [PaintColor] {
        switch brand {
        case .benjaminMoore:
            return [
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
            ].map {
                PaintColor(number: $0.0, name: $0.1, family: $0.2, hex: $0.3, brand: .benjaminMoore)
            }
        case .sherwinWilliams:
            return [
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
            ].map {
                PaintColor(number: $0.0, name: $0.1, family: $0.2, hex: $0.3, brand: .sherwinWilliams)
            }
        case .farrowBall:
            return [
                ("No. 2005", "All White", "White", "F6F6F2"),
                ("No. 274", "Ammonite", "Gray", "D8D6CF"),
                ("No. 228", "Cornforth White", "Gray", "CFCBC4"),
                ("No. 229", "Elephant's Breath", "Beige", "C7BEB3"),
                ("No. 283", "Drop Cloth", "Beige", "C5BDAC"),
                ("No. 231", "Setting Plaster", "Brown", "D9C0AE"),
                ("No. 295", "Sulking Room Pink", "Neutral", "AA8D87"),
                ("No. 30", "Hague Blue", "Blue", "3F4D57"),
                ("No. 281", "Stiffkey Blue", "Blue", "4A5B6B"),
                ("No. 299", "De Nimes", "Gray", "748284"),
                ("No. 88", "Lamp Room Gray", "Gray", "B1B1AA"),
                ("No. 26", "Down Pipe", "Gray", "606565"),
            ].map {
                PaintColor(number: $0.0, name: $0.1, family: $0.2, hex: $0.3, brand: .farrowBall)
            }
        case .behr:
            return []
        }
    }
}
