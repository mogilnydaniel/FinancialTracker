import Foundation

actor GenericFileCache<T: Codable> {
    private let fileName: String
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(fileName: String, decoder: JSONDecoder = JSONDecoder(), encoder: JSONEncoder = JSONEncoder()) {
        self.fileName = fileName
        self.decoder = decoder
        self.encoder = encoder
    }

    func save(_ value: T) throws {
        let url = try fileURL()
        let data = try encoder.encode(value)
        try data.write(to: url, options: .atomic)
    }

    func load() throws -> T? {
        let url = try fileURL()
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let data = try Data(contentsOf: url)
        return try decoder.decode(T.self, from: data)
    }

    private func fileURL() throws -> URL {
        try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent(fileName)
    }
} 