import XCTest
@testable import FinancialTracker

final class NetworkClientTests: XCTestCase {
    private var client: NetworkClient!
    private var session: URLSession!

    override func setUp() {
        super.setUp()
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        session = URLSession(configuration: config)
        client = NetworkClient(baseURL: URL(string: "https://example.com")!, token: "token", session: session)
    }

    func testRequestSuccess() async throws {
        struct Dummy: Codable, Equatable { let value: String }
        let expected = Dummy(value: "ok")
        MockURLProtocol.requestHandler = { _ in
            let data = try JSONEncoder().encode(expected)
            let response = HTTPURLResponse(url: URL(string: "https://example.com/test")!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }
        let endpoint = Endpoint(path: "/test", method: .get)
        let result: Dummy = try await client.request(endpoint, body: Optional<Int>.none)
        XCTAssertEqual(result, expected)
    }

    func testRequestHTTPError() async {
        MockURLProtocol.requestHandler = { _ in
            let response = HTTPURLResponse(url: URL(string: "https://example.com/test")!, statusCode: 404, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }
        let endpoint = Endpoint(path: "/test", method: .get)
        do {
            let _: String = try await client.request(endpoint, body: Optional<Int>.none)
            XCTFail("Expected error")
        } catch {
            guard case NetworkError.http(let code, _) = error else { return XCTFail() }
            XCTAssertEqual(code, 404)
        }
    }
}

final class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else { fatalError() }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    override func stopLoading() {}
} 