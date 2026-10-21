//
//  WgerClient.swift
//  GymRank
//
//  Cliente da API pública do wger (REST v2), sem chave de autenticação.
//  Documentação: https://wger.de/api/v2/  ·  dados sob CC-BY-SA 4.0.
//

import Foundation

struct WgerMuscle: Decodable, Hashable {
    let id: Int
    let name: String
    let nameEn: String?

    enum CodingKeys: String, CodingKey {
        case id, name
        case nameEn = "name_en"
    }
}

struct WgerEquipment: Decodable, Hashable {
    let id: Int
    let name: String
}

struct WgerCategory: Decodable, Hashable {
    let id: Int
    let name: String
}

struct WgerTranslation: Decodable, Hashable {
    let name: String
    let language: Int
}

struct WgerExercise: Decodable, Identifiable, Hashable {
    let id: Int
    let category: WgerCategory?
    let muscles: [WgerMuscle]?
    let equipment: [WgerEquipment]?
    let translations: [WgerTranslation]?

    var nome: String {
        if let pt = translations?.first(where: { $0.language == 7 })?.name, !pt.isEmpty { return pt }
        if let en = translations?.first(where: { $0.language == 2 })?.name, !en.isEmpty { return en }
        return translations?.first?.name ?? "Exercício \(id)"
    }

    var musculoPrincipal: String? { muscles?.first?.nameEn ?? muscles?.first?.name }
    var equipamento: String? { equipment?.first?.name }
}

struct WgerPage<T: Decodable>: Decodable {
    let count: Int
    let next: String?
    let results: [T]
}

enum WgerError: LocalizedError {
    case badStatus(Int)
    case invalidURL

    var errorDescription: String? {
        switch self {
        case .badStatus(let code): return "O servidor do wger respondeu \(code)."
        case .invalidURL: return "Endereço inválido do wger."
        }
    }
}

/// Cliente mínimo do catálogo de exercícios.
struct WgerClient {
    static let base = "https://wger.de/api/v2"
    /// Páginas máximas por sincronização (100 exercícios por página).
    static let maxPages = 5

    /// Mapeia a categoria do wger para uma parte do corpo da aplicação.
    static func bodyPart(for categoryName: String?) -> BodyPart {
        switch (categoryName ?? "").lowercased() {
        case "chest": return .chest
        case "back": return .back
        case "shoulders": return .shoulders
        case "arms": return .biceps
        case "legs": return .legs
        case "calves": return .calves
        case "abs": return .core
        default: return .core
        }
    }

    func fetchExercises(language: Int = 2, limit: Int = 100) async throws -> [WgerExercise] {
        var collected: [WgerExercise] = []
        var nextURL = URL(string: "\(Self.base)/exerciseinfo/?language=\(language)&limit=\(limit)")
        var pages = 0

        while let url = nextURL, pages < Self.maxPages {
            let (data, response) = try await URLSession.shared.data(from: url)
            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                throw WgerError.badStatus(http.statusCode)
            }
            let page = try JSONDecoder().decode(WgerPage<WgerExercise>.self, from: data)
            collected.append(contentsOf: page.results)
            nextURL = page.next.flatMap(URL.init(string:))
            pages += 1
        }
        return collected
    }
}
