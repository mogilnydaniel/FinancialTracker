import Foundation

struct Empty: Codable {}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
    case delete = "DELETE"
}

struct Endpoint {
    let path: String
    let method: HTTPMethod
    var query: [URLQueryItem] = []
    var headers: [String: String] = [:]
}

enum NetworkError: LocalizedError {
    case invalidURL
    case http(code: Int, data: Data)
    case encoding
    case decoding
    case noConnection
    case serverNotFound
    case timeout
    case cancelled
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Некорректный адрес сервера"
        case .http(let code, let data):
            if let errorResponse = String(data: data, encoding: .utf8) {
                return "Ошибка сервера \(code): \(errorResponse)"
            }
            return "Ошибка сервера \(code)"
        case .encoding:
            return "Не удалось подготовить запрос"
        case .decoding:
            return "Не удалось обработать ответ сервера"
        case .noConnection:
            return "Нет подключения к интернету"
        case .serverNotFound:
            return "Сервер не найден или недоступен"
        case .timeout:
            return "Превышено время ожидания ответа"
        case .cancelled:
            return "Запрос отменён"
        case .unknown:
            return "Неизвестная ошибка"
        }
    }
}

final actor NetworkClient {
    private let baseURL: URL
    private var token: String
    private let session: URLSession
    private let decoder: JSONDecoder
    
    init(baseURL: URL = URL(string: "https://shmr-finance.ru/api/v1")!, token: String, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.token = token
        self.session = session
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601withFractionalSeconds
        self.decoder = decoder
    }
    
    func updateToken(_ token: String) {
        self.token = token
    }
    
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        return try await request(endpoint, body: Empty())
    }
    
    func request<T: Decodable, B: Encodable>(_ endpoint: Endpoint, body: B, encoder: JSONEncoder = JSONEncoder()) async throws -> T {
        #if DEBUG
        let startTime = Date()
        print("Starting request: \(endpoint.method.rawValue) \(endpoint.path)")
        #endif
        
        guard await NetworkConnectionDetector.shared.isConnected else {
            throw NetworkError.noConnection
        }
        
        guard var urlComponents = URLComponents(url: baseURL.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: false) else {
            throw NetworkError.invalidURL
        }
        
        if !endpoint.query.isEmpty {
            urlComponents.queryItems = endpoint.query
        }
        guard let url = urlComponents.url else { throw NetworkError.invalidURL }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 60
        request.httpMethod = endpoint.method.rawValue
        
        if endpoint.method != .get, !(body is Empty) {
            request.httpBody = try encoder.encode(body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        #if DEBUG
        let elapsed = Date().timeIntervalSince(startTime)
        print("Response received for \(endpoint.path) in \(String(format: "%.2f", elapsed))s")
        #endif
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown
        }
        
        guard 200..<300 ~= httpResponse.statusCode else {
            throw NetworkError.http(code: httpResponse.statusCode, data: data)
        }
        
        if T.self == Empty.self {
            return Empty() as! T
        }
        
        do {
            let decoder = JSONCoding.decoder
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decoding
        }
    }
} 
