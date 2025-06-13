import Foundation

struct Category: Identifiable {
    enum Direction {
        case income
        case outcome
    }
    
    let id: Int
    let name: String
    let icon: Character
    let direction: Direction
}
