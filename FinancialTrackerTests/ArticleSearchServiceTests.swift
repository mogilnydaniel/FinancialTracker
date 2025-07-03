import XCTest
@testable import FinancialTracker

final class ArticleSearchServiceTests: XCTestCase {
    private let searchService: ArticleSearchService = .init()
    private let articles: [Category] = [
        Category(id: 1, name: "Продукты", icon: "🛒", direction: .outcome),
        Category(id: 2, name: "Машина", icon: "🚗", direction: .outcome),
        Category(id: 3, name: "Спортзал", icon: "🏋🏻‍♂️", direction: .outcome)
    ]

    func testExactMatch() async {
        let result = await searchService.filter("Машина", in: articles)
        XCTAssertEqual(result.first?.name, "Машина")
    }

    func testFuzzyMatch() async {
        let result = await searchService.filter("машн", in: articles)
        XCTAssertEqual(result.first?.name, "Машина")
    }
} 