import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
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
    
    func request<Req: Encodable, Res: Decodable>(
        _ endpoint: Endpoint,
        body: Req? = nil,
        encoder: JSONEncoder = JSONEncoder()
    ) async throws -> Res {
        guard var urlComponents = URLComponents(url: baseURL.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: false) else {
            throw NetworkError.invalidURL
        }
        if !endpoint.query.isEmpty {
            urlComponents.queryItems = endpoint.query
        }
        guard let url = urlComponents.url else { throw NetworkError.invalidURL }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.allHTTPHeaderFields = endpoint.headers
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        if let body = body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            do {
                let data = try await Task.detached(priority: .utility) { try encoder.encode(body) }.value
                request.httpBody = data
            } catch {
                throw NetworkError.encoding
            }
        }
        
        do {
            let (data, response) = try await session.data(for: request, delegate: nil)
            guard let httpResponse = response as? HTTPURLResponse else { throw NetworkError.unknown }
            let status = httpResponse.statusCode
            
            guard (200..<300).contains(status) else { throw NetworkError.http(code: status, data: data) }
            do {
                return try await Task.detached(priority: .utility) { try self.decoder.decode(Res.self, from: data) }.value
            } catch {
                throw NetworkError.decoding
            }
        } catch {
            if let urlError = error as? URLError {
                switch urlError.code {
                case .notConnectedToInternet:
                    throw NetworkError.noConnection
                case .cannotFindHost, .cannotConnectToHost:
                    throw NetworkError.serverNotFound
                case .timedOut:
                    throw NetworkError.timeout
                case .cancelled:
                    throw NetworkError.cancelled
                default:
                    throw NetworkError.unknown
                }
            }
            if let networkError = error as? NetworkError { throw networkError }
            throw NetworkError.unknown
        }
    }
} 
