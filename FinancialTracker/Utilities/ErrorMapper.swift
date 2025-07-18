import Foundation

struct ErrorMapper {
    static func message(for error: Error) -> String {
        if let net = error as? NetworkError {
            return net.localizedDescription
        }
        if let err = error as? LocalizedError, let desc = err.errorDescription {
            return desc
        }
        return "Неизвестная ошибка"
    }

    static func wrap(_ error: Error) -> Error {
        struct Wrapped: LocalizedError {
            let description: String
            var errorDescription: String? { description }
        }
        return Wrapped(description: message(for: error))
    }
} 