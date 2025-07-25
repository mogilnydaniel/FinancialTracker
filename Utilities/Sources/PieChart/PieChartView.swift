import SwiftUI
import UIKit

public struct PieChartView: UIViewRepresentable {
    public let entities: [Entity]
    
    public init(entities: [Entity]) {
        self.entities = entities
    }
    
    public func makeUIView(context: Context) -> PieChartUIView {
        let view = PieChartUIView()
        view.entities = entities
        return view
    }
    
    public func updateUIView(_ uiView: PieChartUIView, context: Context) {
        if !entities.elementsEqual(uiView.entities, by: { $0.value == $1.value && $0.label == $1.label }) {
            uiView.entities = entities
        }
    }
}

public class PieChartUIView: UIView {
    public var entities: [Entity] = [] {
        didSet {
            prepareSegments()
            setNeedsDisplay()
        }
    }
    
    public var lineWidth: CGFloat = PieChartConstants.ringWidth
    
    private struct Segment {
        let value: CGFloat
        let percentage: CGFloat
        let color: UIColor
        let label: String
    }
    
    private var segments: [Segment] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        backgroundColor = .clear
    }
    
    public func animateUpdate(to newEntities: [Entity]) {
        guard superview != nil, bounds.width > 0, bounds.height > 0 else {
            entities = newEntities
            return
        }
        
        self.layer.removeAllAnimations()
        
        subviews.filter { $0 is UIImageView }.forEach { $0.removeFromSuperview() }

        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        let snapshot = renderer.image { context in
            layer.render(in: context.cgContext)
        }
        
        let snapshotView = UIImageView(image: snapshot)
        snapshotView.frame = self.bounds
        self.addSubview(snapshotView)
        
        self.segments = []
        self.setNeedsDisplay()

        let duration: TimeInterval = 0.25

        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseIn, animations: {
            snapshotView.transform = CGAffineTransform(rotationAngle: .pi)
            snapshotView.alpha = 0.0
        }, completion: { [weak self] _ in
            guard let self = self, self.superview != nil else { 
                snapshotView.removeFromSuperview()
                return 
            }

            snapshotView.removeFromSuperview()

            self.entities = newEntities
            self.prepareSegments()
            
            self.setNeedsDisplay()

            self.alpha = 0.0
            self.transform = CGAffineTransform(rotationAngle: -.pi)

            UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut, animations: {
                self.transform = .identity
                self.alpha = 1.0
            }, completion: { [weak self] finished in
                guard let self = self, finished else { return }
                self.transform = .identity
                self.alpha = 1.0
            })
        })
    }
    
    private func prepareSegments() {
        let sorted = entities.sorted { $0.value > $1.value }
        let totalDecimal = sorted.reduce(Decimal(0)) { $0 + $1.value }
        guard totalDecimal > 0 else {
            segments = []
            return
        }

        var temp: [(value: Decimal, label: String)] = sorted.map { ($0.value, $0.label) }
        if temp.count > PieChartConstants.maxSegments {
            let othersSum = temp[PieChartConstants.maxSegments...].reduce(Decimal(0)) { $0 + $1.value }
            temp = Array(temp.prefix(PieChartConstants.maxSegments))
            temp.append((othersSum, PieChartConstants.othersLabel))
        }

        let total = CGFloat((totalDecimal as NSDecimalNumber).doubleValue)
        segments = temp.enumerated().map { idx, pair in
            let v = CGFloat((pair.value as NSDecimalNumber).doubleValue)
            let pct = v / total
            let color = PieChartConstants.segmentColors[idx % PieChartConstants.segmentColors.count]
            return Segment(value: v, percentage: pct, color: color, label: pair.label)
        }
    }
    
    public override func draw(_ rect: CGRect) {
        guard !segments.isEmpty, let ctx = UIGraphicsGetCurrentContext() else { 
            drawEmptyState(in: rect)
            return 
        }

        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 - lineWidth / 2

        var startAngle = -CGFloat.pi / 2
        for seg in segments {
            let endAngle = startAngle + 2 * .pi * seg.percentage
            ctx.setStrokeColor(seg.color.cgColor)
            ctx.setLineWidth(lineWidth)
            ctx.addArc(center: center,
                       radius: radius,
                       startAngle: startAngle,
                       endAngle: endAngle,
                       clockwise: false)
            ctx.strokePath()
            startAngle = endAngle
        }

        drawLegend(in: rect, center: center, radius: radius)
    }
    
    private func drawLegend(in rect: CGRect, center: CGPoint, radius: CGFloat) {
        // Рассчитываем доступное пространство внутри кольца
        let innerRadius = radius - lineWidth
        let availableRadius = innerRadius - PieChartConstants.legendInset * 2
        
        // Подготавливаем строки для отображения
        let rawLines = segments.map { seg -> String in
            let p = Int((seg.percentage * 100).rounded())
            return "\(p)% \(seg.label)"
        }
        
        // Определяем оптимальный размер шрифта и обрезаем длинные строки
        let (font, processedLines) = calculateOptimalFontAndLines(
            rawLines: rawLines,
            availableRadius: availableRadius
        )
        
        let circleDiameter: CGFloat = PieChartConstants.legendDotSize
        let circleTextSpacing: CGFloat = PieChartConstants.legendDotSpacing
        let lineHeight = font.lineHeight + PieChartConstants.legendLineSpacing
        let totalHeight = lineHeight * CGFloat(processedLines.count)
        
        // Центрируем легенду в доступном пространстве
        let startY = center.y - totalHeight / 2
        let maxTextWidth = availableRadius * 2 - circleDiameter - circleTextSpacing - PieChartConstants.legendInset * 2
        let startX = center.x - maxTextWidth / 2 - circleDiameter - circleTextSpacing
        
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .left
        paragraph.lineBreakMode = .byTruncatingTail
        
        let textAttrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.label,
            .paragraphStyle: paragraph
        ]
        
        for (idx, line) in processedLines.enumerated() {
            let y = startY + CGFloat(idx) * lineHeight
            
            // Рисуем цветной кружок
            let circleRect = CGRect(
                x: startX,
                y: y + (lineHeight - circleDiameter) / 2,
                width: circleDiameter,
                height: circleDiameter
            )
            
            if let ctx = UIGraphicsGetCurrentContext() {
                ctx.setFillColor(segments[idx].color.cgColor)
                ctx.fillEllipse(in: circleRect)
            }
            
            // Рисуем текст
            let textX = startX + circleDiameter + circleTextSpacing
            let textRect = CGRect(
                x: textX,
                y: y,
                width: maxTextWidth,
                height: lineHeight
            )
            
            (line as NSString).draw(
                in: textRect,
                withAttributes: textAttrs
            )
        }
    }
    
    private func calculateOptimalFontAndLines(
        rawLines: [String], 
        availableRadius: CGFloat
    ) -> (UIFont, [String]) {
        var fontSize = PieChartConstants.legendFontSize
        let minFontSize: CGFloat = 10
        let maxTextWidth = availableRadius * 1.4 - PieChartConstants.legendDotSize - PieChartConstants.legendDotSpacing
        
        // Пытаемся найти подходящий размер шрифта
        while fontSize >= minFontSize {
            let testFont = UIFont.systemFont(ofSize: fontSize, weight: .medium)
            let lineHeight = testFont.lineHeight + PieChartConstants.legendLineSpacing
            let totalHeight = lineHeight * CGFloat(rawLines.count)
            
            // Проверяем, помещается ли по высоте
            if totalHeight <= availableRadius * 2 {
                // Проверяем, помещаются ли строки по ширине
                let processedLines = rawLines.map { line in
                    return fitTextToWidth(line, font: testFont, maxWidth: maxTextWidth)
                }
                
                return (testFont, processedLines)
            }
            
            fontSize -= 1
        }
        
        // Если даже минимальный шрифт не помещается, используем его и обрезаем
        let finalFont = UIFont.systemFont(ofSize: minFontSize, weight: .medium)
        let processedLines = rawLines.map { line in
            return fitTextToWidth(line, font: finalFont, maxWidth: maxTextWidth)
        }
        
        return (finalFont, processedLines)
    }
    
    private func fitTextToWidth(_ text: String, font: UIFont, maxWidth: CGFloat) -> String {
        let attributes = [NSAttributedString.Key.font: font]
        let size = (text as NSString).size(withAttributes: attributes)
        
        if size.width <= maxWidth {
            return text
        }
        
        // Обрезаем текст до подходящей длины
        var truncatedText = text
        while truncatedText.count > 3 {
            truncatedText = String(truncatedText.dropLast())
            let testText = truncatedText + "..."
            let testSize = (testText as NSString).size(withAttributes: attributes)
            
            if testSize.width <= maxWidth {
                return testText
            }
        }
        
        return "..."
    }
    
    private func drawEmptyState(in rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 - lineWidth / 2
        
        ctx.setStrokeColor(UIColor.systemGray4.cgColor)
        ctx.setLineWidth(lineWidth)
        ctx.addArc(center: center, radius: radius, startAngle: 0, endAngle: 2 * .pi, clockwise: false)
        ctx.strokePath()
        
        let text = "Нет данных"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: PieChartConstants.legendFontSize),
            .foregroundColor: UIColor.secondaryLabel
        ]
        
        let attributedText = NSAttributedString(string: text, attributes: attributes)
        let textSize = attributedText.size()
        let textRect = CGRect(
            x: center.x - textSize.width / 2,
            y: center.y - textSize.height / 2,
            width: textSize.width,
            height: textSize.height
        )
        
        attributedText.draw(in: textRect)
    }
} 
