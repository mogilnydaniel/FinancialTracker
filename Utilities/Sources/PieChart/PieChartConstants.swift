import UIKit

enum PieChartConstants {
    static let maxSegments = 5
    
    static let segmentColors: [UIColor] = [
        UIColor.systemGreen,
        UIColor.systemBlue,
        UIColor.systemOrange,
        UIColor.systemPurple,
        UIColor.systemRed,
        UIColor.systemGray
    ]
    
    static let othersLabel = "Остальные"
    
    static let ringWidth: CGFloat = 20
    
        static let legendInset: CGFloat = 8

    static let legendFontSize: CGFloat = 12

    static let legendDotSize: CGFloat = 8

    static let legendDotSpacing: CGFloat = 8

    static let legendLineSpacing: CGFloat = 6
}

struct DrawingSegment {
    let startAngle: CGFloat
    let endAngle: CGFloat
    let color: UIColor
    let label: String
    let percentage: Double
    let value: Decimal
}

extension Decimal {
    var doubleValue: Double {
        return NSDecimalNumber(decimal: self).doubleValue
    }
}

extension CGFloat {
    static func degreesToRadians(_ degrees: CGFloat) -> CGFloat {
        return degrees * .pi / 180
    }
} 
