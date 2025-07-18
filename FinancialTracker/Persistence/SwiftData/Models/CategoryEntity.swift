import Foundation
import SwiftData

@Model
final class CategoryEntity {
    
    @Attribute(.unique) var id: Int
    var name: String
    var icon: String
    private var directionRawValue: String
    
    var direction: Category.Direction {
        get {
            return Category.Direction(rawValue: directionRawValue) ?? .outcome
        }
        set {
            directionRawValue = newValue.rawValue
        }
    }
    
    init(
        id: Int,
        name: String,
        icon: String,
        direction: Category.Direction
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.directionRawValue = direction.rawValue
    }
    
    convenience init(from category: Category) {
        self.init(
            id: category.id,
            name: category.name,
            icon: category.icon,
            direction: category.direction
        )
    }

    func toDomainModel() -> Category {
        Category(
            id: id,
            name: name,
            icon: icon,
            direction: direction
        )
    }
    
    func toDomain() -> Category {
        return toDomainModel()
    }
    
    static func fromDomain(_ category: Category) -> CategoryEntity {
        return CategoryEntity(from: category)
    }
    
    func update(from category: Category) {
        self.name = category.name
        self.icon = category.icon
        self.direction = category.direction
    }
}


extension Array where Element == CategoryEntity {
    
    func toDomainModels() -> [Category] {
        map { $0.toDomainModel() }
    }
}

extension Array where Element == Category {
    
    func toEntities() -> [CategoryEntity] {
        map { CategoryEntity(from: $0) }
    }
} 
