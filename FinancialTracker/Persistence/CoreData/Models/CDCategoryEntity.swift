import Foundation
import CoreData

@objc(CDCategoryEntity)
public class CDCategoryEntity: NSManagedObject {
    
    var direction: Category.Direction {
        get {
            return Category.Direction(rawValue: directionRawValue ?? "outcome") ?? .outcome
        }
        set {
            directionRawValue = newValue.rawValue
        }
    }
    
    convenience init(context: NSManagedObjectContext, from category: Category) {
        self.init(context: context)
        self.id = Int32(category.id)
        self.name = category.name
        self.icon = category.icon
        self.direction = category.direction
    }
    
    func toDomainModel() -> Category {
        Category(
            id: Int(id),
            name: name ?? "",
            icon: icon ?? "",
            direction: direction
        )
    }
    
    func update(from category: Category) {
        self.name = category.name
        self.icon = category.icon
        self.direction = category.direction
    }
}

extension CDCategoryEntity {
    
    @NSManaged public var id: Int32
    @NSManaged public var name: String?
    @NSManaged public var icon: String?
    @NSManaged public var directionRawValue: String?
}

extension CDCategoryEntity {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDCategoryEntity> {
        return NSFetchRequest<CDCategoryEntity>(entityName: "CDCategoryEntity")
    }
}

extension Array where Element == CDCategoryEntity {
    
    func toDomainModels() -> [Category] {
        map { $0.toDomainModel() }
    }
}

extension Array where Element == Category {
    
    func toCoreDataEntities(context: NSManagedObjectContext) -> [CDCategoryEntity] {
        map { CDCategoryEntity(context: context, from: $0) }
    }
} 