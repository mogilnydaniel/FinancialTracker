import Foundation

protocol ArticlesViewModelFactoryProtocol {
    func makeArticlesViewModel() -> ArticlesViewModel
}

struct ArticlesViewModelFactory: @preconcurrency ArticlesViewModelFactoryProtocol {
    private unowned let di: DIContainer

    init(di: DIContainer) {
        self.di = di
    }

    @MainActor func makeArticlesViewModel() -> ArticlesViewModel {
        ArticlesViewModel(
            articlesService: di.articlesService,
            searchService: ArticleSearchService()
        )
    }
} 
