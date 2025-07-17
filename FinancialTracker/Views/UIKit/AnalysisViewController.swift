import UIKit
import Combine

final class AnalysisViewController: UIViewController {
    private let viewModel: AnalysisViewModel
    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<AnalysisScreenSection, AnalysisScreenItem>!
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let errorView = ErrorView()
    private var cancellables = Set<AnyCancellable>()

    init(viewModel: AnalysisViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Анализ"
        view.backgroundColor = .systemGroupedBackground
        
        navigationController?.navigationBar.tintColor = UIColor(named: "SecondaryAccentColor")

        if let navigationBar = navigationController?.navigationBar {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .systemGroupedBackground
            appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
            navigationBar.standardAppearance = appearance
            navigationBar.scrollEdgeAppearance = appearance
        }
        
        configureNavigation()
        configureCollectionView()
        configureDataSource()
        configureActivityIndicator()
        configureErrorView()
        bindViewModel()
        viewModel.load()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.backgroundColor = .systemGroupedBackground
        navigationController?.navigationBar.backgroundColor = .systemGroupedBackground
        tabBarController?.tabBar.backgroundColor = .systemGroupedBackground
        
        navigationController?.navigationBar.tintColor = UIColor(named: "SecondaryAccentColor")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.navigationBar.tintColor = UIColor(named: "SecondaryAccentColor")
    }

    private func configureCollectionView() {
        var config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        config.headerTopPadding = 0
        config.headerMode = .supplementary
        let layout = UICollectionViewCompositionalLayout.list(using: config)
        layout.configuration.interSectionSpacing = 0
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .systemGroupedBackground
        collectionView.contentInset.top = -12
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func configureActivityIndicator() {
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func configureErrorView() {
        errorView.translatesAutoresizingMaskIntoConstraints = false
        errorView.isHidden = true
        view.addSubview(errorView)
        
        NSLayoutConstraint.activate([
            errorView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            errorView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            errorView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            errorView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func configureDataSource() {
        let dateCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, AnalysisScreenItem.DateType> { [weak self] cell, indexPath, dateType in
            guard let self = self else { return }
            var config = DateCellContentConfiguration()
            
            switch dateType {
            case .start:
                config.title = "Период: начало"
                config.date = self.viewModel.startDate
                config.onDateChanged = { [weak self] newDate in
                    self?.viewModel.startDate = newDate
                }
            case .end:
                config.title = "Период: конец"
                config.date = self.viewModel.endDate
                config.onDateChanged = { [weak self] newDate in
                    self?.viewModel.endDate = newDate
                }
            }
            cell.contentConfiguration = config
        }
        
        let sortCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, AnalysisScreenItem.SortType> { [weak self] cell, indexPath, sortType in
            let config = SortCellContentConfiguration(selected: sortType) { [weak self] newType in
                switch newType {
                case .date:
                    self?.viewModel.sortOption = .date
                case .amount:
                    self?.viewModel.sortOption = .amount
                }
            }
            cell.contentConfiguration = config
        }

        let sumCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Decimal> { cell, indexPath, totalAmount in
            var config = UIListContentConfiguration.valueCell()
            config.text = "Сумма"
            config.secondaryText = totalAmount.magnitude.rubleFormattedNoFraction
            cell.contentConfiguration = config
        }
        
        let operationCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, AnalysisOperationItem> { cell, indexPath, item in
            cell.contentConfiguration = AnalysisOperationCellContentConfiguration(item: item)
            cell.accessories = [.disclosureIndicator()]
        }
        
        dataSource = UICollectionViewDiffableDataSource<AnalysisScreenSection, AnalysisScreenItem>(collectionView: collectionView) { collectionView, indexPath, item in
            switch item {
            case .date(let type, _):
                return collectionView.dequeueConfiguredReusableCell(using: dateCellRegistration, for: indexPath, item: type)
            case .sum(let amount):
                return collectionView.dequeueConfiguredReusableCell(using: sumCellRegistration, for: indexPath, item: amount)
            case .sort(let sortType):
                return collectionView.dequeueConfiguredReusableCell(using: sortCellRegistration, for: indexPath, item: sortType)
            case .operation(let operationItem):
                return collectionView.dequeueConfiguredReusableCell(using: operationCellRegistration, for: indexPath, item: operationItem)
            }
        }

        let headerRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewListCell>(elementKind: UICollectionView.elementKindSectionHeader) { supplementaryView, elementKind, indexPath in
            var config = UIListContentConfiguration.header()
            config.text = "Операции"
            supplementaryView.contentConfiguration = config
        }

        dataSource.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
            guard kind == UICollectionView.elementKindSectionHeader else { return nil }
            guard let sectionIdentifier = self?.dataSource.sectionIdentifier(for: indexPath.section) else {
                return collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
            }

            let view = collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
            if sectionIdentifier == .operations {
                view.isHidden = false
            } else {
                view.isHidden = true
            }
            return view
        }
    }
    
    private func bindViewModel() {
        viewModel.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.render(state: state)
            }
            .store(in: &cancellables)

        let dataPublisher = Publishers.CombineLatest3(
            viewModel.$operations,
            viewModel.$total,
            Publishers.CombineLatest(viewModel.$startDate, viewModel.$endDate)
        )
        
        dataPublisher
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (operations, total, dates) in
                let (startDate, endDate) = dates
                self?.applySnapshot(operations: operations, total: total, startDate: startDate, endDate: endDate)
            }
            .store(in: &cancellables)
    }

    private func render(state: LoadingState) {
        switch state {
        case .idle:
            break
        case .loading:
            let shouldShowLoading = dataSource.snapshot().numberOfItems == 0
            if shouldShowLoading {
                activityIndicator.startAnimating()
                collectionView.isHidden = true
                errorView.isHidden = true
            }
        case .loaded:
            activityIndicator.stopAnimating()
            collectionView.isHidden = false
            errorView.isHidden = true
        case .failed(let error):
            activityIndicator.stopAnimating()
            collectionView.isHidden = true
            showError(error)
        }
    }
    
    private func showError(_ error: Error) {
        errorView.configure(
            title: "Ошибка загрузки",
            message: error.localizedDescription,
            systemImage: "exclamationmark.triangle.fill",
            retryButtonTitle: "Повторить"
        ) { [weak self] in
            self?.viewModel.load()
        }
        errorView.isHidden = false
    }

    private func applySnapshot(operations: [AnalysisOperationItem], total: Decimal, startDate: Date, endDate: Date) {
        var snapshot = NSDiffableDataSourceSnapshot<AnalysisScreenSection, AnalysisScreenItem>()
        
        snapshot.appendSections([.info])
        let infoItems: [AnalysisScreenItem] = [
            .date(type: .start, date: startDate),
            .date(type: .end, date: endDate),
            .sort(viewModel.sortOption == .date ? .date : .amount),
            .sum(total)
        ]
        snapshot.appendItems(infoItems, toSection: .info)
        
        if !operations.isEmpty {
            snapshot.appendSections([.operations])
            snapshot.appendItems(operations.map { .operation($0) }, toSection: .operations)
        }
        
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    private func configureNavigation() {
        navigationItem.largeTitleDisplayMode = .always
        
        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.backward"),
            style: .plain,
            target: self,
            action: #selector(goBack)
        )
        
        let backTitle = UIBarButtonItem(
            title: "Назад",
            style: .plain,
            target: self,
            action: #selector(goBack)
        )
        
        navigationItem.leftBarButtonItems = [backButton, backTitle]
        
        let sortMenu = UIMenu(title: "Сортировка", children: [
            UIAction(title: TransactionSortOption.amount.rawValue, state: viewModel.sortOption == .amount ? .on : .off) { [weak self] _ in
                self?.viewModel.sortOption = .amount
            },
            UIAction(title: TransactionSortOption.date.rawValue, state: viewModel.sortOption == .date ? .on : .off) { [weak self] _ in
                self?.viewModel.sortOption = .date
            }
        ])
        
        let sortButton = UIBarButtonItem(
            image: UIImage(systemName: "arrow.up.arrow.down.circle"),
            menu: sortMenu
        )
        
        navigationItem.rightBarButtonItem = sortButton
    }
    
    @objc private func goBack() {
        navigationController?.popViewController(animated: true)
    }
} 

extension AnalysisViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}
