import UIKit
import SwiftUI
import PieChart

final class PieChartCellContentView: UIView, UIContentView {
    private var currentConfiguration: PieChartCellContentConfiguration
    private var pieChartUIView: PieChartUIView?
    
    init(configuration: PieChartCellContentConfiguration) {
        self.currentConfiguration = configuration
        super.init(frame: .zero)
        apply(configuration: configuration)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var configuration: UIContentConfiguration {
        get { currentConfiguration }
        set {
            guard let newConfiguration = newValue as? PieChartCellContentConfiguration else { return }
            apply(configuration: newConfiguration)
        }
    }
    
    private func apply(configuration: PieChartCellContentConfiguration) {
        self.currentConfiguration = configuration
        
        if let existingPieChartUIView = pieChartUIView {
            existingPieChartUIView.animateUpdate(to: configuration.entities)
        } else {
            let pieChartUIView = PieChartUIView()
            pieChartUIView.entities = configuration.entities
            pieChartUIView.translatesAutoresizingMaskIntoConstraints = false
            
            addSubview(pieChartUIView)
            self.pieChartUIView = pieChartUIView
            
            NSLayoutConstraint.activate([
                pieChartUIView.topAnchor.constraint(equalTo: topAnchor),
                pieChartUIView.leadingAnchor.constraint(equalTo: leadingAnchor),
                pieChartUIView.trailingAnchor.constraint(equalTo: trailingAnchor),
                pieChartUIView.bottomAnchor.constraint(equalTo: bottomAnchor),
                pieChartUIView.heightAnchor.constraint(equalToConstant: 250)
            ])
        }
    }
} 
