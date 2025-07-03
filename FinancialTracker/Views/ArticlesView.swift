import SwiftUI

struct ArticlesView: View {
    @State private var viewModel: ArticlesViewModel?
    @Environment(\.di) private var di

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel = viewModel {
                    articlesList(viewModel: viewModel)
                } else {
                    ProgressView()
                        .task {
                            viewModel = di.articlesVMFactory.makeArticlesViewModel()
                        }
                }
            }
            .navigationTitle("Мои статьи")
            .navigationBarTitleDisplayMode(.large)
            .searchable(
                text: Binding(
                    get: { viewModel?.searchText ?? "" },
                    set: { viewModel?.searchText = $0 }
                ),
                isPresented: Binding(
                    get: { viewModel?.isSearchActive ?? false },
                    set: { viewModel?.isSearchActive = $0 }
                ),
                prompt: "Search"
            )
        }
        .tint(.accentColor)
    }
    
    @ViewBuilder
    private func articlesList(viewModel: ArticlesViewModel) -> some View {
        List {
            if !viewModel.filtered.isEmpty {
                Section {
                    ForEach(viewModel.filtered) { article in
                        ArticleRow(article: article)
                            .redacted(reason: viewModel.state == .loading ? .placeholder : [])
                    }
                } header: {
                    Text("СТАТЬИ")
                }
            } else if !viewModel.searchText.isEmpty {
                ContentUnavailableView(
                    "Ничего не найдено",
                    systemImage: "magnifyingglass",
                    description: Text("Попробуйте изменить запрос")
                )
                .listRowBackground(Color.clear)
            } else if case .failed(let error) = viewModel.state {
                ContentUnavailableView {
                    Label("Ошибка загрузки", systemImage: "exclamationmark.triangle.fill")
                } description: {
                    Text(error.localizedDescription)
                } actions: {
                    Button("Повторить") {
                        Task { await viewModel.load() }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .listRowBackground(Color.clear)
            } else if viewModel.state == .loaded && viewModel.articles.isEmpty {
                ContentUnavailableView(
                    "Нет категорий",
                    systemImage: "folder",
                    description: Text("Категории ещё не добавлены")
                )
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
        .animation(.default, value: viewModel.filtered)
        .task { 
            if viewModel.state == .idle {
                await viewModel.load() 
            }
        }
    }
}

struct ArticleRow: View {
    let article: Category
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.4))
                    .frame(width: 22, height: 22)
                
                Text(article.icon)
                    .font(.system(size: 12))
            }
            
            Text(article.name)
                .foregroundStyle(.primary)
            
            Spacer()
        }
        .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Статья \(article.name)")
    }
} 
