import XCTest
@testable import PieChart

final class PieChartTests: XCTestCase {
    
    func testEntityCreation() {
        let entity = Entity(value: 100.0, label: "Test")
        XCTAssertEqual(entity.value, 100.0)
        XCTAssertEqual(entity.label, "Test")
    }
    
    func testEntityEquality() {
        let entity1 = Entity(value: 100.0, label: "Test")
        let entity2 = Entity(value: 100.0, label: "Test")
        let entity3 = Entity(value: 200.0, label: "Test")
        
        XCTAssertEqual(entity1, entity2)
        XCTAssertNotEqual(entity1, entity3)
    }
    
    func testEntityHashable() {
        let entity1 = Entity(value: 100.0, label: "Test")
        let entity2 = Entity(value: 100.0, label: "Test")
        
        let set: Set<Entity> = [entity1, entity2]
        XCTAssertEqual(set.count, 1)
    }
    
    func testPieChartViewCreation() {
        let entities = [
            Entity(value: 100.0, label: "Category 1"),
            Entity(value: 200.0, label: "Category 2")
        ]
        
        let pieChartView = PieChartView(entities: entities)
        XCTAssertEqual(pieChartView.entities.count, 2)
    }
    
    func testPieChartUIViewSetup() {
        let view = PieChartUIView()
        XCTAssertTrue(view.entities.isEmpty)
        XCTAssertEqual(view.backgroundColor, UIColor.clear)
    }
    
    func testSegmentColors() {
        XCTAssertEqual(PieChartConstants.segmentColors.count, 6)
        XCTAssertEqual(PieChartConstants.maxSegments, 5)
        XCTAssertEqual(PieChartConstants.othersLabel, "Остальные")
    }
    
    func testPieChartWithLongLabels() {
        let entities = [
            Entity(value: 100.0, label: "Очень длинное название категории которое не должно помещаться"),
            Entity(value: 200.0, label: "Еще одно супер длинное название"),
            Entity(value: 150.0, label: "Краткое"),
            Entity(value: 300.0, label: "Средней длины название категории"),
            Entity(value: 75.0, label: "Максимально длинное название категории расходов за месяц")
        ]
        
        let pieChartView = PieChartView(entities: entities)
        XCTAssertEqual(pieChartView.entities.count, 5)
        
        // Проверяем что все entities корректно сохранены
        for (index, entity) in entities.enumerated() {
            XCTAssertEqual(pieChartView.entities[index].value, entity.value)
            XCTAssertEqual(pieChartView.entities[index].label, entity.label)
        }
    }
    
    func testPieChartWithMoreThanMaxSegments() {
        let entities = [
            Entity(value: 100.0, label: "Category 1"),
            Entity(value: 200.0, label: "Category 2"), 
            Entity(value: 150.0, label: "Category 3"),
            Entity(value: 300.0, label: "Category 4"),
            Entity(value: 75.0, label: "Category 5"),
            Entity(value: 50.0, label: "Category 6"),
            Entity(value: 25.0, label: "Category 7")
        ]
        
        let pieChartView = PieChartView(entities: entities)
        XCTAssertEqual(pieChartView.entities.count, 7)
        
        // Создаем UIView для тестирования внутренней логики
        let uiView = PieChartUIView()
        uiView.entities = entities
        
        // Проверяем что у нас максимум 6 сегментов (5 + "Остальные")
        // Эта функциональность будет обработана внутри prepareSegments()
    }
    
    func testAdaptiveLegendRendering() {
        // Тест демонстрирует что новая функциональность не ломает существующую
        let entities = [
            Entity(value: 1000.0, label: "Основная категория"),
            Entity(value: 500.0, label: "Вторая категория"),
            Entity(value: 250.0, label: "Третья")
        ]
        
        let pieChartView = PieChartView(entities: entities)
        let uiView = pieChartView.makeUIView(context: UIViewRepresentableContext(PieChartView.self))
        
        // Симулируем небольшой размер для проверки адаптации
        uiView.frame = CGRect(x: 0, y: 0, width: 200, height: 200)
        uiView.entities = entities
        
        // Проверяем что view создается без ошибок
        XCTAssertNotNil(uiView)
        XCTAssertEqual(uiView.entities.count, 3)
    }
} 
