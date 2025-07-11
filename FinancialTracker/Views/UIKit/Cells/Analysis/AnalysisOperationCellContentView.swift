import UIKit

final class AnalysisOperationCellContentView: UIView, UIContentView {
    private var currentConfiguration: AnalysisOperationCellContentConfiguration
    
    private lazy var iconContainerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 15
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var iconLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var categoryLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var detailsLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var percentageLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var amountLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    init(configuration: AnalysisOperationCellContentConfiguration) {
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
            guard let newConfiguration = newValue as? AnalysisOperationCellContentConfiguration else { return }
            apply(configuration: newConfiguration)
        }
    }
    
    private func setupViews() {
        addSubview(iconContainerView)
        iconContainerView.addSubview(iconLabel)
        addSubview(categoryLabel)
        addSubview(detailsLabel)
        
        let vStack = UIStackView(arrangedSubviews: [percentageLabel, amountLabel])
        vStack.axis = .vertical
        vStack.alignment = .trailing
        vStack.spacing = 2
        vStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(vStack)
        
        NSLayoutConstraint.activate([
            iconContainerView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            iconContainerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconContainerView.widthAnchor.constraint(equalToConstant: 30),
            iconContainerView.heightAnchor.constraint(equalToConstant: 30),
            
            iconLabel.centerXAnchor.constraint(equalTo: iconContainerView.centerXAnchor),
            iconLabel.centerYAnchor.constraint(equalTo: iconContainerView.centerYAnchor),
            
            categoryLabel.leadingAnchor.constraint(equalTo: iconContainerView.trailingAnchor, constant: 16),
            categoryLabel.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor, constant: 4),
            
            detailsLabel.leadingAnchor.constraint(equalTo: categoryLabel.leadingAnchor),
            detailsLabel.topAnchor.constraint(equalTo: categoryLabel.bottomAnchor, constant: 2),
            detailsLabel.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor, constant: -4),
            
            vStack.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            vStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            categoryLabel.trailingAnchor.constraint(lessThanOrEqualTo: vStack.leadingAnchor, constant: -8)
        ])
    }
    
    private func apply(configuration: AnalysisOperationCellContentConfiguration) {
        self.currentConfiguration = configuration
        
        guard let item = configuration.item else { return }
        
        iconLabel.text = item.category.icon
        iconContainerView.backgroundColor = item.category.uiColor
        categoryLabel.text = item.category.name
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 0
        percentageLabel.text = formatter.string(from: NSNumber(value: item.percentage / 100))
        
        amountLabel.text = item.totalAmount.rubleFormattedNoFraction
        if let comment = item.comment, !comment.isEmpty {
            detailsLabel.text = comment
        } else {
            detailsLabel.text = item.category.name
        }
    }
} 