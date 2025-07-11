import UIKit

final class SortCellContentView: UIView, UIContentView {
    private var currentConfiguration: SortCellContentConfiguration

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.textColor = .label
        label.text = "Сортировка"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var segmentedControl: UISegmentedControl = {
        let items = AnalysisScreenItem.SortType.allCases.map { $0.rawValue }
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = AnalysisScreenItem.SortType.allCases.firstIndex(of: currentConfiguration.selected) ?? 0
        control.addTarget(self, action: #selector(selectionChanged), for: .valueChanged)
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()

    init(configuration: SortCellContentConfiguration) {
        self.currentConfiguration = configuration
        super.init(frame: .zero)
        setupViews()
        apply(configuration: configuration)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var configuration: UIContentConfiguration {
        get { currentConfiguration }
        set {
            guard let newConfig = newValue as? SortCellContentConfiguration else { return }
            apply(configuration: newConfig)
        }
    }

    private func setupViews() {
        addSubview(titleLabel)
        addSubview(segmentedControl)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            titleLabel.centerYAnchor.constraint(equalTo: segmentedControl.centerYAnchor),

            segmentedControl.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 8),
            segmentedControl.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            segmentedControl.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor, constant: 8),
            segmentedControl.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor, constant: -8)
        ])
    }

    private func apply(configuration: SortCellContentConfiguration) {
        currentConfiguration = configuration
        segmentedControl.selectedSegmentIndex = AnalysisScreenItem.SortType.allCases.firstIndex(of: configuration.selected) ?? 0
    }

    @objc private func selectionChanged() {
        let selectedIndex = segmentedControl.selectedSegmentIndex
        let selectedType = AnalysisScreenItem.SortType.allCases[selectedIndex]
        currentConfiguration.onSelectionChanged?(selectedType)
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 44)
    }
} 