import Foundation
import Testing
@testable import FinancialTracker

@Suite("Transaction Serialization Tests")
struct TransactionSerializationTests {

    private let validDateString = "2024-06-12T15:45:00Z"
    private var validTestDate: Date {
        try! Date(validDateString, strategy: .iso8601)
    }

    private var baseJSONObject: [String: Any] {
        [
            "id": 1,
            "accountId": 10,
            "categoryId": 20,
            "amount": "123.45",
            "transactionDate": validDateString,
            "comment": "Test comment",
            "createdAt": validDateString,
            "updatedAt": validDateString
        ]
    }


    @Test("jsonObject serialization correctness")
    func testJSONObjectSerialization() throws {
        let transaction = Transaction(
            id: 1,
            accountId: 10,
            categoryId: 20,
            amount: Decimal(string: "123.45")!,
            transactionDate: validTestDate,
            comment: "Test comment",
            creationDate: validTestDate,
            modificationDate: validTestDate
        )
        
        let jsonObject = transaction.jsonObject
        
        let dict = try #require(jsonObject as? [String: Any])
        
        #expect(dict["id"] as? Int == 1)
        #expect(dict["accountId"] as? Int == 10)
        #expect(dict["categoryId"] as? Int == 20)
        #expect(dict["amount"] as? String == "123.45")
        #expect(dict["comment"] as? String == "Test comment")
        #expect(dict["transactionDate"] as? String == validDateString)
        #expect(dict["createdAt"] as? String == validDateString)
        #expect(dict["updatedAt"] as? String == validDateString)
    }

    @Test("jsonObject omits nil comment")
    func testJSONObjectOmitsNilComment() throws {
        let transaction = Transaction(
            id: 1,
            accountId: 10,
            categoryId: 20,
            amount: 123.45,
            transactionDate: validTestDate,
            comment: nil,
            creationDate: validTestDate,
            modificationDate: validTestDate
        )
        
        let dict = try #require(transaction.jsonObject as? [String: Any])
        
        #expect(dict["comment"] == nil)
    }
    

    struct ParseTestCase {
        let name: String
        let modification: ([String: Any]) -> [String: Any]
        let shouldBeNil: Bool

        static let all: [ParseTestCase] = [
            .init(name: "Valid Full JSON", modification: { $0 }, shouldBeNil: false),
            .init(name: "Missing Optional Comment", modification: {
                var json = $0; json["comment"] = nil; return json
            }, shouldBeNil: false),
            .init(name: "NSNull Comment", modification: {
                var json = $0; json["comment"] = NSNull(); return json
            }, shouldBeNil: false),
            .init(name: "Missing Required Field (amount)", modification: {
                var json = $0; json.removeValue(forKey: "amount"); return json
            }, shouldBeNil: true),
            .init(name: "Invalid Data Type (id)", modification: {
                var json = $0; json["id"] = "not_a_number"; return json
            }, shouldBeNil: true),
            .init(name: "Invalid Date Format", modification: {
                var json = $0; json["transactionDate"] = "not_a_date"; return json
            }, shouldBeNil: true),
            .init(name: "Invalid Amount Format", modification: {
                var json = $0; json["amount"] = "not_a_decimal"; return json
            }, shouldBeNil: true)
        ]
    }

    @Test(arguments: ParseTestCase.all)
    func testJSONParsingScenarios(testCase: ParseTestCase) {
        let modifiedJSON = testCase.modification(baseJSONObject)
        let transaction = Transaction.parse(jsonObject: modifiedJSON)

        if testCase.shouldBeNil {
            #expect(transaction == nil, "Expected parsing to fail for test: \(testCase.name)")
        } else {
            #expect(transaction != nil, "Expected parsing to succeed for test: \(testCase.name)")
        }
    }
    

    @Test("JSON round-trip preserves data")
    func testJSONRoundTrip() {
        let originalTransaction = Transaction(
            id: 99,
            accountId: 1,
            categoryId: 2,
            amount: Decimal(string: "-987.65")!,
            transactionDate: validTestDate,
            comment: "Round-trip test",
            creationDate: validTestDate,
            modificationDate: validTestDate
        )
        
        let json = originalTransaction.jsonObject
        let parsedTransaction = Transaction.parse(jsonObject: json)
        
        #expect(parsedTransaction != nil)
        #expect(originalTransaction == parsedTransaction)
    }
}
