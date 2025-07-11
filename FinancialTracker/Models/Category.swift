import Foundation
import SwiftUI
import UIKit

struct Category: Identifiable, Codable, Equatable, Hashable {
    let id: Int
    let name: String
    let icon: String
    let direction: Direction
}

extension Category {
    enum Direction: String, Codable, Equatable {
        case income
        case outcome
    }
}

extension Category {
    static let colors: [Color] = [
        .red, .green, .blue, .orange, .purple, .pink, .yellow, .teal, .indigo, .cyan
    ]
    
    var color: Color {
        let index = abs(id) % Self.colors.count
        return Self.colors[index].opacity(0.3)
    }
    
    var uiColor: UIColor {
        UIColor(color)
    }
}
