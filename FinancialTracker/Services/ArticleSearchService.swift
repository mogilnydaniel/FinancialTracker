import Foundation

protocol ArticleSearchServiceProtocol {
    func filter(_ query: String, in source: [Category]) async -> [Category]
}

struct ArticleSearchService: ArticleSearchServiceProtocol {
    func filter(_ query: String, in source: [Category]) async -> [Category] {
        guard !query.isEmpty else { return source }
        
        let query = query.lowercased()
        
        let exactMatches = source.filter { $0.name.lowercased().contains(query) }
        if !exactMatches.isEmpty { return exactMatches }
        
        let scoredItems = source.compactMap { item -> (category: Category, score: Double)? in
            let score = fuzzyScore(query: query, in: item.name.lowercased())
            return score > 0 ? (item, score) : nil
        }
        
        return scoredItems
            .sorted { $0.score > $1.score }
            .map { $0.category }
    }
    
    private func fuzzyScore(query: String, in text: String) -> Double {
        let queryChars = Array(query)
        let textChars = Array(text)
        
        var score: Double = 0
        var textIndex = 0
        var consecutiveMatches = 0
        var previousMatchIndex = -1
        
        for queryChar in queryChars {
            var found = false
            
            while textIndex < textChars.count {
                if textChars[textIndex] == queryChar {
                    found = true
                    
                    var bonus: Double = 1
                    
                    if textIndex == 0 || textChars[textIndex - 1] == " " {
                        bonus += 3
                    }
                    
                    if previousMatchIndex >= 0 && textIndex == previousMatchIndex + 1 {
                        consecutiveMatches += 1
                        bonus += Double(consecutiveMatches) * 2
                    } else {
                        consecutiveMatches = 0
                    }
                    
                    score += bonus
                    previousMatchIndex = textIndex
                    textIndex += 1
                    break
                }
                textIndex += 1
            }
            
            if !found {
                return 0
            }
        }
        
        let lengthPenalty = Double(text.count - query.count) * 0.01
        return score - lengthPenalty
    }
} 