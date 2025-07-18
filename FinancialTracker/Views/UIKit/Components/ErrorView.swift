import UIKit

final class ErrorView: UIView {
    private var contentView: UIContentUnavailableView!
    private var retryAction: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = .clear
        
        let config = UIContentUnavailableConfiguration.empty()
        contentView = UIContentUnavailableView(configuration: config)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
        
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    func configure(
        title: String = "Ошибка загрузки",
        message: String = "Неизвестная ошибка",
        systemImage: String = "exclamationmark.triangle.fill",
        retryButtonTitle: String = "Повторить",
        onRetry: @escaping () -> Void
    ) {
        var config = UIContentUnavailableConfiguration.empty()
        
        config.image = UIImage(systemName: systemImage)
        config.imageProperties.tintColor = .systemRed
        config.imageProperties.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 48)
        
        config.text = title
        config.textProperties.font = .preferredFont(forTextStyle: .headline)
        config.textProperties.color = .label
        
        config.secondaryText = message
        config.secondaryTextProperties.font = .preferredFont(forTextStyle: .body)
        config.secondaryTextProperties.color = .secondaryLabel
        
        config.button = UIButton.Configuration.filled()
        config.button.title = retryButtonTitle
        config.button.cornerStyle = .medium
        config.buttonProperties.primaryAction = UIAction { [weak self] _ in
            self?.retryAction?()
        }
        
        self.retryAction = onRetry
        contentView.configuration = config
    }
} 
