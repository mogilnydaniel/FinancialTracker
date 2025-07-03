import Foundation
import SwiftUI

@Observable
@MainActor
final class ArticlesViewModel {
    private(set) var articles: [Category] = []
    var searchText: String = "" {
        didSet { search() }
    }
    private(set) var filtered: [Category] = []
    var isSearchActive: Bool = false
    private(set) var state: LoadingState = .idle

    private let articlesService: any ArticlesServiceProtocol
    private let searchService: any ArticleSearchServiceProtocol
    private var searchTask: Task<Void, Never>?

    init(articlesService: any ArticlesServiceProtocol, searchService: any ArticleSearchServiceProtocol) {
        self.articlesService = articlesService
        self.searchService = searchService
    }

    func load() async {
        guard state != .loading else { return }
        
        state = .loading
        showPlaceholderData()
        
        do {
            articles = try await articlesService.getArticles()
            filtered = articles
            state = .loaded
        } catch {
            state = .failed(error)
            articles = []
            filtered = []
        }
    }
    
    private func showPlaceholderData() {
        articles = (1...9).map { 
            Category(
                id: $0, 
                name: "Загрузка...", 
                icon: "⏳", 
                direction: $0 % 2 == 0 ? .income : .outcome
            )
        }
        filtered = articles
    }

    private func search() {
        guard state == .loaded else { return }
        
        searchTask?.cancel()
        let currentQuery = searchText
        let currentArticles = articles
        
        searchTask = Task { [weak self] in
            let result = await self?.searchService.filter(currentQuery, in: currentArticles) ?? []
            
            await MainActor.run { [weak self] in
                guard let self, self.searchText == currentQuery else { return }
                self.filtered = result
            }
        }
    }
} 