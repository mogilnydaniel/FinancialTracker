import Foundation

struct MockTransactionsData {
    static func generateMockTransactions() -> [Int: Transaction] {
        let now = Date()
        let calendar = Calendar.current
        
        return [
            1: Transaction(
                id: 1,
                accountId: 1,
                categoryId: 1,
                amount: 75000.00,
                transactionDate: calendar.date(byAdding: .day, value: -5, to: now)!,
                comment: "Зарплата за июнь",
                creationDate: now,
                modificationDate: now
            ),
            2: Transaction(
                id: 2,
                accountId: 1,
                categoryId: 3,
                amount: -2500.50,
                transactionDate: now,
                comment: "Продукты в супермаркете",
                creationDate: now,
                modificationDate: now
            ),
            3: Transaction(
                id: 3,
                accountId: 1,
                categoryId: 4,
                amount: -450.00,
                transactionDate: calendar.date(byAdding: .hour, value: -3, to: now)!,
                comment: "Метро",
                creationDate: now,
                modificationDate: now
            ),
            4: Transaction(
                id: 4,
                accountId: 1,
                categoryId: 5,
                amount: -1200.00,
                transactionDate: calendar.date(byAdding: .day, value: -12, to: now)!,
                comment: "Кино с друзьями",
                creationDate: now,
                modificationDate: now
            ),
            5: Transaction(
                id: 5,
                accountId: 1,
                categoryId: 6,
                amount: -4500.00,
                transactionDate: calendar.date(byAdding: .day, value: -8, to: now)!,
                comment: "Электричество",
                creationDate: now,
                modificationDate: now
            ),
            6: Transaction(
                id: 6,
                accountId: 1,
                categoryId: 2,
                amount: 5000.00,
                transactionDate: calendar.date(byAdding: .day, value: -14, to: now)!,
                comment: "День рождения",
                creationDate: now,
                modificationDate: now
            ),
            7: Transaction(
                id: 7,
                accountId: 1,
                categoryId: 3,
                amount: -890.00,
                transactionDate: calendar.date(byAdding: .hour, value: -5, to: now)!,
                comment: "Продукты для ужина",
                creationDate: now,
                modificationDate: now
            ),
            8: Transaction(
                id: 8,
                accountId: 1,
                categoryId: 4,
                amount: -200.00,
                transactionDate: calendar.date(byAdding: .minute, value: -45, to: now)!,
                comment: "Такси домой",
                creationDate: now,
                modificationDate: now
            ),
            9: Transaction(
                id: 9,
                accountId: 1,
                categoryId: 6,
                amount: -3500.00,
                transactionDate: calendar.date(byAdding: .day, value: -3, to: now)!,
                comment: "Коммунальные платежи",
                creationDate: now,
                modificationDate: now
            ),
            10: Transaction(
                id: 10,
                accountId: 1,
                categoryId: 5,
                amount: -2800.00,
                transactionDate: calendar.date(byAdding: .day, value: -6, to: now)!,
                comment: "Театр",
                creationDate: now,
                modificationDate: now
            ),
            11: Transaction(
                id: 11,
                accountId: 1,
                categoryId: 1,
                amount: 2500.00,
                transactionDate: calendar.date(byAdding: .day, value: -11, to: now)!,
                comment: "Возврат долга",
                creationDate: now,
                modificationDate: now
            ),
            12: Transaction(
                id: 12,
                accountId: 1,
                categoryId: 3,
                amount: -1250.00,
                transactionDate: calendar.date(byAdding: .day, value: -4, to: now)!,
                comment: "Аптека",
                creationDate: now,
                modificationDate: now
            ),
            13: Transaction(
                id: 13,
                accountId: 1,
                categoryId: 4,
                amount: -150.00,
                transactionDate: calendar.date(byAdding: .day, value: -9, to: now)!,
                comment: "Автобус",
                creationDate: now,
                modificationDate: now
            ),
            14: Transaction(
                id: 14,
                accountId: 1,
                categoryId: 5,
                amount: -3200.00,
                transactionDate: calendar.date(byAdding: .day, value: -15, to: now)!,
                comment: "Концерт любимой группы",
                creationDate: now,
                modificationDate: now
            ),
            15: Transaction(
                id: 15,
                accountId: 1,
                categoryId: 6,
                amount: -2200.00,
                transactionDate: calendar.date(byAdding: .day, value: -19, to: now)!,
                comment: "Газ",
                creationDate: now,
                modificationDate: now
            ),
            16: Transaction(
                id: 16,
                accountId: 1,
                categoryId: 1,
                amount: 120000.00,
                transactionDate: calendar.date(byAdding: .day, value: -60, to: now)!,
                comment: "Зарплата за май",
                creationDate: now,
                modificationDate: now
            ),
            17: Transaction(
                id: 17,
                accountId: 1,
                categoryId: 3,
                amount: -4200.75,
                transactionDate: calendar.date(byAdding: .day, value: -22, to: now)!,
                comment: "Продукты на неделю",
                creationDate: now,
                modificationDate: now
            ),
            18: Transaction(
                id: 18,
                accountId: 1,
                categoryId: 4,
                amount: -850.00,
                transactionDate: calendar.date(byAdding: .day, value: -7, to: now)!,
                comment: "Заправка",
                creationDate: now,
                modificationDate: now
            ),
            19: Transaction(
                id: 19,
                accountId: 1,
                categoryId: 5,
                amount: -3200.00,
                transactionDate: calendar.date(byAdding: .day, value: -16, to: now)!,
                comment: "Ресторан с коллегами",
                creationDate: now,
                modificationDate: now
            ),
            20: Transaction(
                id: 20,
                accountId: 1,
                categoryId: 6,
                amount: -1800.00,
                transactionDate: calendar.date(byAdding: .day, value: -13, to: now)!,
                comment: "Интернет",
                creationDate: now,
                modificationDate: now
            ),
            21: Transaction(
                id: 21,
                accountId: 1,
                categoryId: 2,
                amount: 8500.00,
                transactionDate: calendar.date(byAdding: .day, value: -20, to: now)!,
                comment: "Подарок от родителей",
                creationDate: now,
                modificationDate: now
            ),
            22: Transaction(
                id: 22,
                accountId: 1,
                categoryId: 3,
                amount: -670.25,
                transactionDate: calendar.date(byAdding: .hour, value: -2, to: now)!,
                comment: "Кофе и завтрак",
                creationDate: now,
                modificationDate: now
            ),
            23: Transaction(
                id: 23,
                accountId: 1,
                categoryId: 4,
                amount: -320.00,
                transactionDate: calendar.date(byAdding: .day, value: -17, to: now)!,
                comment: "Парковка",
                creationDate: now,
                modificationDate: now
            ),
            24: Transaction(
                id: 24,
                accountId: 1,
                categoryId: 5,
                amount: -5600.00,
                transactionDate: calendar.date(byAdding: .day, value: -23, to: now)!,
                comment: "Концерт",
                creationDate: now,
                modificationDate: now
            ),
            25: Transaction(
                id: 25,
                accountId: 1,
                categoryId: 1,
                amount: 45000.00,
                transactionDate: calendar.date(byAdding: .day, value: -27, to: now)!,
                comment: "Фриланс проект",
                creationDate: now,
                modificationDate: now
            ),
            26: Transaction(
                id: 26,
                accountId: 1,
                categoryId: 3,
                amount: -2100.00,
                transactionDate: calendar.date(byAdding: .day, value: -21, to: now)!,
                comment: "Доставка еды",
                creationDate: now,
                modificationDate: now
            ),
            27: Transaction(
                id: 27,
                accountId: 1,
                categoryId: 4,
                amount: -95.00,
                transactionDate: calendar.date(byAdding: .day, value: -24, to: now)!,
                comment: "Автобус до аэропорта",
                creationDate: now,
                modificationDate: now
            ),
            28: Transaction(
                id: 28,
                accountId: 1,
                categoryId: 6,
                amount: -7200.00,
                transactionDate: calendar.date(byAdding: .day, value: -26, to: now)!,
                comment: "Мобильная связь",
                creationDate: now,
                modificationDate: now
            ),
            29: Transaction(
                id: 29,
                accountId: 1,
                categoryId: 2,
                amount: 3200.00,
                transactionDate: calendar.date(byAdding: .day, value: -28, to: now)!,
                comment: "Возврат за покупку",
                creationDate: now,
                modificationDate: now
            ),
            30: Transaction(
                id: 30,
                accountId: 1,
                categoryId: 5,
                amount: -1450.00,
                transactionDate: now,
                comment: "Спортзал",
                creationDate: now,
                modificationDate: now
            ),
            31: Transaction(
                id: 31,
                accountId: 1,
                categoryId: 2,
                amount: 15000.00,
                transactionDate: calendar.date(byAdding: .day, value: -55, to: now)!,
                comment: "Премия за проект",
                creationDate: now,
                modificationDate: now
            ),
            32: Transaction(
                id: 32,
                accountId: 1,
                categoryId: 3,
                amount: -350.00,
                transactionDate: calendar.date(byAdding: .minute, value: -20, to: now)!,
                comment: "Обед в кафе",
                creationDate: now,
                modificationDate: now
            ),
            33: Transaction(
                id: 33,
                accountId: 1,
                categoryId: 4,
                amount: -1200.00,
                transactionDate: now,
                comment: "Заправка автомобиля",
                creationDate: now,
                modificationDate: now
            ),
            34: Transaction(
                id: 34,
                accountId: 1,
                categoryId: 5,
                amount: -4500.00,
                transactionDate: calendar.date(byAdding: .day, value: -58, to: now)!,
                comment: "Поход в театр",
                creationDate: now,
                modificationDate: now
            ),
            35: Transaction(
                id: 35,
                accountId: 1,
                categoryId: 3,
                amount: -125.00,
                transactionDate: calendar.date(byAdding: .hour, value: -1, to: now)!,
                comment: "Мороженое",
                creationDate: now,
                modificationDate: now
            ),
            36: Transaction(
                id: 36,
                accountId: 1,
                categoryId: 1,
                amount: 3500.00,
                transactionDate: calendar.date(byAdding: .hour, value: -4, to: now)!,
                comment: "Фриланс задача",
                creationDate: now,
                modificationDate: now
            ),
            37: Transaction(
                id: 37,
                accountId: 1,
                categoryId: 2,
                amount: 1200.00,
                transactionDate: calendar.date(byAdding: .minute, value: -90, to: now)!,
                comment: "Возврат за товар",
                creationDate: now,
                modificationDate: now
            ),
            38: Transaction(
                id: 38,
                accountId: 1,
                categoryId: 1,
                amount: 850.00,
                transactionDate: now,
                comment: "Консультация",
                creationDate: now,
                modificationDate: now
            ),
            39: Transaction(
                id: 39,
                accountId: 1,
                categoryId: 2,
                amount: 500.00,
                transactionDate: now,
                comment: "Кэшбэк с карты",
                creationDate: now,
                modificationDate: now
            )
        ]
    }
} 
