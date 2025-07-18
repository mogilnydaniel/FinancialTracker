import Foundation

struct CategoryDTOToDomainConverter {
    static func convert(_ dto: CategoryDTO) -> Category? {
        guard let id = dto.id,
              let name = dto.name,
              let emoji = dto.emoji,
              let isIncome = dto.isIncome else {
            return nil
        }
        
        let direction: Category.Direction = isIncome ? .income : .outcome
        
        return Category(
            id: id,
            name: name,
            icon: emoji,
            direction: direction
        )
    }
} 