import UIKit

final class DateCellContentView: UIView, UIContentView {
    private var currentConfiguration: DateCellContentConfiguration
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .compact
        picker.locale = Locale(identifier: "ru_RU")
        picker.calendar = .autoupdatingCurrent
        picker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
        picker.translatesAutoresizingMaskIntoConstraints = false
        return picker
    }()

    private lazy var datePickerBackground: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.15)
        view.layer.cornerRadius = 6
        view.layer.masksToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    init(configuration: DateCellContentConfiguration) {
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
            guard let newConfiguration = newValue as? DateCellContentConfiguration else { return }
            apply(configuration: newConfiguration)
        }
    }
    
    private func setupViews() {
        addSubview(titleLabel)
        addSubview(datePickerBackground)
        addSubview(datePicker)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            titleLabel.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor, constant: 8),
            titleLabel.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor, constant: -8),
            
            datePicker.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            datePicker.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            
            datePickerBackground.leadingAnchor.constraint(equalTo: datePicker.leadingAnchor),
            datePickerBackground.trailingAnchor.constraint(equalTo: datePicker.trailingAnchor),
            datePickerBackground.topAnchor.constraint(equalTo: datePicker.topAnchor),
            datePickerBackground.bottomAnchor.constraint(equalTo: datePicker.bottomAnchor)
        ])
    }
    
    private func apply(configuration: DateCellContentConfiguration) {
        self.currentConfiguration = configuration
        
        titleLabel.text = configuration.title
        if let date = configuration.date {
            datePicker.setDate(date, animated: false)
        }
    }
    
    @objc private func dateChanged() {
        currentConfiguration.onDateChanged?(datePicker.date)
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 44)
    }
} 