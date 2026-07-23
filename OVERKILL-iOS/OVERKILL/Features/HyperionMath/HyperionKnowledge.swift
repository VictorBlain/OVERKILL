import Foundation

struct MathEntry: Identifiable, Codable {
    let id: String
    let question: String
    let keywords: [String]
    let answer: String
}

struct HyperionKnowledge {
    private static var entries: [MathEntry] = []

    static func load() {
        guard entries.isEmpty,
              let url = Bundle.main.url(forResource: "HyperionKnowledge", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([MathEntry].self, from: data) else { return }
        entries = decoded
    }

    static func search(query: String) -> [MathEntry] {
        let q = query.lowercased()
        guard !q.isEmpty else { return [] }

        return entries
            .compactMap { entry -> (MathEntry, Int)? in
                var score = 0
                if entry.question.lowercased().contains(q) { score += 10 }
                for kw in entry.keywords {
                    if q.contains(kw.lowercased()) || kw.lowercased().contains(q) { score += 5 }
                }
                let words = q.split(separator: " ").map(String.init)
                for word in words where word.count > 2 {
                    if entry.answer.lowercased().contains(word) { score += 1 }
                    if entry.question.lowercased().contains(word) { score += 3 }
                }
                return score > 0 ? (entry, score) : nil
            }
            .sorted { $0.1 > $1.1 }
            .map(\.0)
    }

    static func all() -> [MathEntry] { entries }
}
