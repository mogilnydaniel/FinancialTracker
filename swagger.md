default


GET
/accounts
Получить все счета пользователя

Возвращает список всех счетов текущего пользователя

Parameters
Try it out
No parameters
Responses
Code	Description	Links
200	
Список счетов

Media type

Controls Accept header.
Example Value
Schema
[
  {
    "id": 1,
    "userId": 1,
    "name": "Основной счёт",
    "balance": "1000.00",
    "currency": "RUB",
    "createdAt": "2025-07-15T11:06:40.644Z",
    "updatedAt": "2025-07-15T11:06:40.644Z"
  }
]
No links
401	
Неавторизованный доступ

No links

POST
/accounts
Создать новый счет

Создает новый счет для текущего пользователя

Parameters
Try it out
No parameters
Request body

Example Value
Schema
{
  "name": "Основной счёт",
  "balance": "1000.00",
  "currency": "RUB"
}
Responses
Code	Description	Links
201	
Созданный счет

Media type

Controls Accept header.
Example Value
Schema
{
  "id": 1,
  "userId": 1,
  "name": "Основной счёт",
  "balance": "1000.00",
  "currency": "RUB",
  "createdAt": "2025-07-15T11:06:40.645Z",
  "updatedAt": "2025-07-15T11:06:40.645Z"
}
No links
400	
Некорректные данные

No links
401	
Неавторизованный доступ

No links

GET
/accounts/{id}
Получить счет по ID

Возвращает информацию о конкретном счете, включая статистику

Parameters
Try it out
Name	Description
id *
integer
(path)
ID счета


Responses
Code	Description	Links
200	
Счет

Media type

Controls Accept header.
Example Value
Schema
{
  "id": 1,
  "name": "Основной счёт",
  "balance": "1000.00",
  "currency": "RUB",
  "incomeStats": [
    {
      "categoryId": 1,
      "categoryName": "Зарплата",
      "emoji": "💰",
      "amount": "5000.00"
    }
  ],
  "expenseStats": [
    {
      "categoryId": 1,
      "categoryName": "Зарплата",
      "emoji": "💰",
      "amount": "5000.00"
    }
  ],
  "createdAt": "2025-07-15T11:06:40.646Z",
  "updatedAt": "2025-07-15T11:06:40.646Z"
}
No links
400	
Неверный формат ID

No links
401	
Неавторизованный доступ

No links
404	
Счет не найден

No links

PUT
/accounts/{id}
Обновить счет

Обновляет данные существующего счета

Parameters
Try it out
Name	Description
id *
integer
(path)
ID счета


Request body

Example Value
Schema
{
  "name": "Новое название счёта",
  "balance": "1000.00",
  "currency": "USD"
}
Responses
Code	Description	Links
200	
Обновленный счет

Media type

Controls Accept header.
Example Value
Schema
{
  "id": 1,
  "userId": 1,
  "name": "Основной счёт",
  "balance": "1000.00",
  "currency": "RUB",
  "createdAt": "2025-07-15T11:06:40.647Z",
  "updatedAt": "2025-07-15T11:06:40.647Z"
}
No links
400	
Некорректные данные или неверный формат ID

No links
401	
Неавторизованный доступ

No links
404	
Счет не найден

No links

DELETE
/accounts/{id}
Удалить счет

Удаляет счет пользователя. Счет можно удалить только если у него нет связанных транзакций.

Parameters
Try it out
Name	Description
id *
integer
(path)
ID счета


Responses
Code	Description	Links
204	
Счет успешно удален

No links
400	
Некорректный формат ID

No links
401	
Неавторизованный доступ

No links
404	
Счет не найден

No links
409	
Конфликт - у счета есть транзакции

No links
500	
Внутренняя ошибка сервера

No links

GET
/accounts/{id}/history
Получить историю изменений счета

Возвращает историю изменений баланса и других параметров счета, произведенных вне транзакций (при создании или изменении счета)

Parameters
Try it out
Name	Description
id *
integer
(path)
ID счета


Responses
Code	Description	Links
200	
История изменений счета

Media type

Controls Accept header.
Example Value
Schema
{
  "accountId": 1,
  "accountName": "Основной счет",
  "currency": "USD",
  "currentBalance": "2000.00",
  "history": [
    {
      "id": 1,
      "accountId": 1,
      "changeType": "MODIFICATION",
      "previousState": {
        "id": 1,
        "name": "Основной счет",
        "balance": "1000.00",
        "currency": "USD"
      },
      "newState": {
        "id": 1,
        "name": "Основной счет",
        "balance": "1000.00",
        "currency": "USD"
      },
      "changeTimestamp": "2025-07-15T11:06:40.648Z",
      "createdAt": "2025-07-15T11:06:40.648Z"
    }
  ]
}
No links
400	
Неверный формат ID

No links
401	
Неавторизованный доступ

No links
404	
Счет не найден

No links

GET
/categories
Получить все категории

Возвращает список всех категорий (доходов и расходов)

Parameters
Try it out
No parameters
Responses
Code	Description	Links
200	
Список категорий

Media type

Controls Accept header.
Example Value
Schema
[
  {
    "id": 1,
    "name": "Зарплата",
    "emoji": "💰",
    "isIncome": true
  }
]
No links
401	
Неавторизованный доступ

No links

GET
/categories/type/{isIncome}
Получить категории по типу

Возвращает список категорий доходов или расходов

Parameters
Try it out
Name	Description
isIncome *
boolean
(path)
Тип категорий: true - доходы, false - расходы


Responses
Code	Description	Links
200	
Список категорий

Media type

Controls Accept header.
Example Value
Schema
[
  {
    "id": 1,
    "name": "Зарплата",
    "emoji": "💰",
    "isIncome": true
  }
]
No links
400	
Некорректный параметр

No links
401	
Неавторизованный доступ

No links

POST
/transactions
Создать новую транзакцию

Создает новую транзакцию (доход или расход)

Parameters
Try it out
No parameters
Request body

Example Value
Schema
{
  "accountId": 1,
  "categoryId": 1,
  "amount": "500.00",
  "transactionDate": "2025-07-15T11:06:40.650Z",
  "comment": "Зарплата за месяц"
}
Responses
Code	Description	Links
201	
Созданная транзакция

Media type

Controls Accept header.
Example Value
Schema
{
  "id": 1,
  "accountId": 1,
  "categoryId": 1,
  "amount": "500.00",
  "transactionDate": "2025-07-15T11:06:40.650Z",
  "comment": "Зарплата за месяц",
  "createdAt": "2025-07-15T11:06:40.650Z",
  "updatedAt": "2025-07-15T11:06:40.650Z"
}
No links
400	
Некорректные данные

No links
401	
Неавторизованный доступ

No links
404	
Счет или категория не найдены

No links

GET
/transactions/{id}
Получить транзакцию по ID

Возвращает детальную информацию о транзакции

Parameters
Try it out
Name	Description
id *
integer
(path)
ID транзакции


Responses
Code	Description	Links
200	
Транзакция

Media type

Controls Accept header.
Example Value
Schema
{
  "id": 1,
  "account": {
    "id": 1,
    "name": "Основной счёт",
    "balance": "1000.00",
    "currency": "RUB"
  },
  "category": {
    "id": 1,
    "name": "Зарплата",
    "emoji": "💰",
    "isIncome": true
  },
  "amount": "500.00",
  "transactionDate": "2025-07-15T11:06:40.650Z",
  "comment": "Зарплата за месяц",
  "createdAt": "2025-07-15T11:06:40.650Z",
  "updatedAt": "2025-07-15T11:06:40.650Z"
}
No links
400	
Неверный формат ID

No links
401	
Неавторизованный доступ

No links
404	
Транзакция не найдена

No links

PUT
/transactions/{id}
Обновить транзакцию

Обновляет существующую транзакцию

Parameters
Try it out
Name	Description
id *
integer
(path)
ID транзакции


Request body

Example Value
Schema
{
  "accountId": 1,
  "categoryId": 1,
  "amount": "500.00",
  "transactionDate": "2025-07-15T11:06:40.651Z",
  "comment": "Зарплата за месяц"
}
Responses
Code	Description	Links
200	
Обновленная транзакция

Media type

Controls Accept header.
Example Value
Schema
{
  "id": 1,
  "account": {
    "id": 1,
    "name": "Основной счёт",
    "balance": "1000.00",
    "currency": "RUB"
  },
  "category": {
    "id": 1,
    "name": "Зарплата",
    "emoji": "💰",
    "isIncome": true
  },
  "amount": "500.00",
  "transactionDate": "2025-07-15T11:06:40.652Z",
  "comment": "Зарплата за месяц",
  "createdAt": "2025-07-15T11:06:40.652Z",
  "updatedAt": "2025-07-15T11:06:40.652Z"
}
No links
400	
Некорректные данные или неверный формат ID

No links
401	
Неавторизованный доступ

No links
404	
Транзакция, счет или категория не найдены

No links

DELETE
/transactions/{id}
Удалить транзакцию

Удаляет транзакцию с возможностью возврата средств на счет

Parameters
Try it out
Name	Description
id *
integer
(path)
ID транзакции


Responses
Code	Description	Links
204	
Транзакция успешно удалена

No links
400	
Неверный формат ID

No links
401	
Неавторизованный доступ

No links
404	
Транзакция не найдена

No links

GET
/transactions/account/{accountId}/period
Получить транзакции по счету за период

Возвращает список транзакций для указанного счета за указанный период

Parameters
Try it out
Name	Description
accountId *
integer
(path)
ID счета


startDate
string($date)
(query)
Начальная дата периода (YYYY-MM-DD). Если не указана, используется начало текущего месяца.


endDate
string($date)
(query)
Конечная дата периода (YYYY-MM-DD). Если не указана, используется конец текущего месяца.


Responses
Code	Description	Links
200	
Список транзакций за указанный период

Media type

Controls Accept header.
Example Value
Schema
[
  {
    "id": 1,
    "account": {
      "id": 1,
      "name": "Основной счёт",
      "balance": "1000.00",
      "currency": "RUB"
    },
    "category": {
      "id": 1,
      "name": "Зарплата",
      "emoji": "💰",
      "isIncome": true
    },
    "amount": "500.00",
    "transactionDate": "2025-07-15T11:06:40.656Z",
    "comment": "Зарплата за месяц",
    "createdAt": "2025-07-15T11:06:40.656Z",
    "updatedAt": "2025-07-15T11:06:40.656Z"
  }
]
No links
400	
Неверный формат ID счета или некорректный формат дат

No links
401	
Неавторизованный доступ

No links