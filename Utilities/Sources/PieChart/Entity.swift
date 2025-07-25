import Foundation

public struct Entity {
    public let value: Decimal
    
    public let label: String
    
    public init(value: Decimal, label: String) {
        self.value = value
        self.label = label
    }
}

extension Entity: Equatable {
    public static func == (lhs: Entity, rhs: Entity) -> Bool {
        return lhs.value == rhs.value && lhs.label == rhs.label
    }
}

extension Entity: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(value)
        hasher.combine(label)
    }
} 
