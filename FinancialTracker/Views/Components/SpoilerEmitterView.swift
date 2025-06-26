import SwiftUI
import UIKit
import QuartzCore

final class SpoilerEmitterUIView: UIView {
    override class var layerClass: AnyClass { CAEmitterLayer.self }
    private var emitter: CAEmitterLayer {
        let e = layer as! CAEmitterLayer
        e.emitterShape = .rectangle
        e.renderMode = .additive
        return e
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        emitter.emitterPosition = CGPoint(x: bounds.midX, y: bounds.midY)
        emitter.emitterSize = bounds.size
    }

    func configure(active: Bool) {
        emitter.emitterCells = active ? [Self.makeCell()] : nil
        emitter.birthRate = active ? 1 : 0
    }

    private static func makeCell() -> CAEmitterCell {
        let cell = CAEmitterCell()
        let square = UIImage(systemName: "square.fill")!
            .withTintColor(.accent, renderingMode: .alwaysOriginal)
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 6))
            .cgImage!
        cell.contents = square

        cell.birthRate     = 900
        cell.lifetime      = 1.0
        cell.lifetimeRange = 0.3

        cell.velocity      = 15
        cell.velocityRange = 10

        cell.scale         = 0.06
        cell.scaleRange    = 0.02

        cell.alphaSpeed    = -1
        cell.emissionRange = .pi * 1.5
        cell.spin          = 1.5
        cell.spinRange     = 3
        return cell
    }
}

struct SpoilerEmitterView: UIViewRepresentable {
    var active: Bool

    func makeUIView(context: Context) -> SpoilerEmitterUIView {
        let view = SpoilerEmitterUIView()
        view.isUserInteractionEnabled = false
        view.configure(active: active)
        return view
    }

    func updateUIView(_ uiView: SpoilerEmitterUIView, context: Context) {
        uiView.configure(active: active)
    }
} 
