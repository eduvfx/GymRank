//
//  RankEngine.swift
//  GymRank
//
//  Motor de ranks. A escada tem 22 níveis:
//    • Bronze 1-3 · Prata 1-3 · Ouro 1-3 · Platina 1-3 · Diamante 1-3 · Campeão 1-3 · Titã 1-3
//    • Olympia — nível único, sem divisões, com um sistema de PONTOS INFINITOS
//      (quanto mais levanta acima do limiar de Elite, mais pontos acumula, sem tecto).
//
//  Código puro, sem SwiftData nem SwiftUI, para poder ser testado com os valores reais.
//

import Foundation

// MARK: - Tipos base

enum Sex: String, Codable, CaseIterable, Identifiable {
    case masculino
    case feminino
    var id: String { rawValue }
    var nome: String { self == .masculino ? "Masculino" : "Feminino" }
}

enum BodyPart: String, Codable, CaseIterable, Identifiable {
    case chest, back, shoulders, biceps, triceps, legs, calves, core
    var id: String { rawValue }
    var nome: String {
        switch self {
        case .chest: return "Peito"
        case .back: return "Costas"
        case .shoulders: return "Ombros"
        case .biceps: return "Bíceps"
        case .triceps: return "Tríceps"
        case .legs: return "Pernas"
        case .calves: return "Gémeos"
        case .core: return "Core"
        }
    }
    var icon: String {
        switch self {
        case .chest: return "figure.strengthtraining.traditional"
        case .back: return "figure.rower"
        case .shoulders: return "figure.arms.open"
        case .biceps: return "figure.strengthtraining.functional"
        case .triceps: return "figure.cooldown"
        case .legs: return "figure.step.training"
        case .calves: return "figure.walk"
        case .core: return "figure.core.training"
        }
    }
}

/// Os oito ranks. Os sete primeiros têm três divisões; o Olympia é um nível único.
enum Rank: Int, Codable, CaseIterable, Comparable, Identifiable {
    case bronze = 0
    case prata
    case ouro
    case platina
    case diamante
    case campeao
    case tita
    case olympia

    var id: Int { rawValue }

    var nome: String {
        switch self {
        case .bronze: return "Bronze"
        case .prata: return "Prata"
        case .ouro: return "Ouro"
        case .platina: return "Platina"
        case .diamante: return "Diamante"
        case .campeao: return "Campeão"
        case .tita: return "Titã"
        case .olympia: return "Olympia"
        }
    }

    var hex: String {
        switch self {
        case .bronze: return "CD7F32"
        case .prata: return "BFC7CE"
        case .ouro: return "F5C518"
        case .platina: return "8FE3E8"
        case .diamante: return "7FD1FF"
        case .campeao: return "A46BFF"
        case .tita: return "FF6B4A"
        case .olympia: return "FFD84D"
        }
    }

    /// Quantas divisões este rank tem (Olympia: 1).
    var divisoes: Int { self == .olympia ? 1 : 3 }

    /// Percentil publicado a que corresponde o início deste rank.
    var percentil: String {
        switch self {
        case .bronze: return "abaixo de 5%"
        case .prata: return "mais forte que 5%"
        case .ouro: return "mais forte que 20%"
        case .platina: return "mais forte que 35% (ponto médio)"
        case .diamante: return "mais forte que 50%"
        case .campeao: return "mais forte que 65% (ponto médio)"
        case .tita: return "mais forte que 80%"
        case .olympia: return "mais forte que 95% (Elite) — sem tecto"
        }
    }

    static func < (lhs: Rank, rhs: Rank) -> Bool { lhs.rawValue < rhs.rawValue }
}

/// Posição na escada: rank + divisão. São 22 níveis (21 divisões + Olympia).
struct RankPosition: Equatable, Comparable, Codable, Identifiable {
    let rank: Rank
    /// 1...3 nos sete primeiros ranks; 1 no Olympia.
    let division: Int

    var id: Int { index }

    /// 0...21
    var index: Int {
        if rank == .olympia { return RankPosition.total - 1 }
        return rank.rawValue * 3 + (division - 1)
    }

    /// "Diamante 2" ou apenas "Olympia".
    var nome: String { rank == .olympia ? "Olympia" : "\(rank.nome) \(division)" }

    var color: String { rank.hex }
    var isOlympia: Bool { rank == .olympia }

    static let total = 22

    static func from(index: Int) -> RankPosition {
        let i = max(0, min(RankPosition.total - 1, index))
        if i >= 21 { return RankPosition(rank: .olympia, division: 1) }
        return RankPosition(rank: Rank(rawValue: i / 3) ?? .bronze, division: i % 3 + 1)
    }

    static func < (lhs: RankPosition, rhs: RankPosition) -> Bool { lhs.index < rhs.index }

    var proximo: RankPosition? {
        index + 1 < RankPosition.total ? RankPosition.from(index: index + 1) : nil
    }
}

// MARK: - Limiares

/// Escada de 22 níveis já ajustada a um utilizador concreto.
struct RankThresholds: Equatable {
    /// Limite inferior de cada um dos 22 níveis (cuts[0] = 0, no Bronze 1).
    /// cuts[21] é a entrada no Olympia.
    let cuts: [Double]

    var isEmpty: Bool { cuts.count != RankPosition.total }
    var olympiaEntry: Double { cuts.last ?? 0 }

    func position(forUMRM value: Double) -> RankPosition {
        guard !isEmpty else { return RankPosition(rank: .bronze, division: 1) }
        var idx = 0
        for (i, cut) in cuts.enumerated() where value >= cut { idx = i }
        return RankPosition.from(index: idx)
    }

    /// Progresso 0...1 dentro do nível actual. No Olympia devolve 0 (o progresso é por pontos).
    func progress(forUMRM value: Double, position: RankPosition) -> Double {
        guard !isEmpty, !position.isOlympia, position.index < cuts.count - 1 else { return 0 }
        let lo = cuts[position.index]
        let hi = cuts[position.index + 1]
        guard hi > lo else { return 1 }
        return max(0, min(1, (value - lo) / (hi - lo)))
    }

    /// Pontos infinitos do Olympia: 1000 pontos na entrada e mais 1000 por cada vez
    /// que o levantamento duplica o limiar de entrada. Sem tecto.
    func olympiaPoints(forUMRM value: Double) -> Int {
        guard olympiaEntry > 0 else { return 0 }
        return max(1000, Int((value / olympiaEntry) * 1000))
    }

    /// Pontuação contínua usada para agregar:
    /// 0...21 nos níveis normais; a partir do Olympia cresce sem tecto (21 + excesso).
    func score(forUMRM value: Double) -> Double {
        let p = position(forUMRM: value)
        if p.isOlympia {
            let pontos = Double(olympiaPoints(forUMRM: value))
            return 21 + max(0, (pontos - 1000) / 1000)
        }
        return Double(p.index) + progress(forUMRM: value, position: p)
    }

    /// Quanto falta, em kg, para o nível seguinte; nil no Olympia (é por pontos).
    func kilosToNext(value: Double) -> (next: RankPosition, falta: Double)? {
        let p = position(forUMRM: value)
        guard let next = p.proximo, next.index < cuts.count else { return nil }
        return (next, max(0, ((cuts[next.index] - value) * 10).rounded() / 10))
    }

    /// Quanto falta, em pontos, para o próximo marco do Olympia (múltiplos de 1000).
    func pontosParaProximoMarco(value: Double) -> Int {
        let pontos = olympiaPoints(forUMRM: value)
        let marco = ((pontos / 1000) + 1) * 1000
        return marco - pontos
    }
}

// MARK: - Motor

enum RankEngine {

    /// Coeficiente por faixa etária (modelo da aplicação, documentado no relatório).
    static func ageFactor(_ idade: Int) -> Double {
        switch idade {
        case ..<18: return 0.90
        case 18...24: return 0.95
        case 25...34: return 1.00
        case 35...44: return 0.95
        case 45...54: return 0.88
        case 55...64: return 0.78
        default: return 0.65
        }
    }

    /// Factor de escala por peso corporal: (peso / pesoDeReferência)^expoente.
    static func weightFactor(pesoKg: Double, sexo: Sex, exp: Double) -> Double {
        let ref = sexo == .masculino ? StandardsData.maleReferenceWeight : StandardsData.femaleReferenceWeight
        guard pesoKg > 0, ref > 0 else { return 1 }
        return pow(pesoKg / ref, exp)
    }

    /// Limites de início dos oito ranks (Bronze...Olympia), ajustados ao peso e à idade.
    static func rankBoundaries(entry: StandardEntry, sexo: Sex, pesoKg: Double, idade: Int) -> [Double]? {
        let published = sexo == .masculino ? entry.male : entry.female
        let base = published.contains(where: { $0 > 0 }) ? published : entry.male
        guard base.count == 5, base.allSatisfy({ $0 > 0 }) else { return nil }
        let beg = base[0], nov = base[1], inter = base[2], adv = base[3], eli = base[4]
        let raw = [0.0, beg, nov, (nov + inter) / 2, inter, (inter + adv) / 2, adv, eli]
        let factor = weightFactor(pesoKg: pesoKg, sexo: sexo, exp: entry.exp) * ageFactor(idade)
        return raw.map { (($0 * factor) * 10).rounded() / 10 }
    }

    /// Escada de 22 níveis: três divisões em cada um dos sete primeiros ranks
    /// e o Olympia como nível único (aberto, por pontos).
    static func thresholds(entry: StandardEntry, sexo: Sex, pesoKg: Double, idade: Int) -> RankThresholds {
        guard let bounds = rankBoundaries(entry: entry, sexo: sexo, pesoKg: pesoKg, idade: idade),
              bounds.count == 8 else {
            return RankThresholds(cuts: [])
        }
        var cuts: [Double] = []
        for rankIndex in 0..<7 {
            let lo = bounds[rankIndex]
            let hi = bounds[rankIndex + 1]
            let passo = (hi - lo) / 3
            for divisao in 0..<3 {
                cuts.append(((lo + passo * Double(divisao)) * 10).rounded() / 10)
            }
        }
        cuts.append(bounds[7])          // entrada no Olympia (limiar de Elite)
        return RankThresholds(cuts: cuts)
    }

    /// 1RM estimado por Epley: peso × (1 + reps/30).
    static func oneRepMax(pesoKg: Double, reps: Int) -> Double {
        guard reps > 0 else { return 0 }
        if reps == 1 { return pesoKg }
        let value = pesoKg * (1 + Double(reps) / 30.0)
        return (value * 10).rounded() / 10
    }

    /// Média de pontuações (0...21 nos níveis normais; sem tecto a partir do Olympia).
    static func averageScore(_ scores: [Double]) -> Double? {
        guard !scores.isEmpty else { return nil }
        return scores.reduce(0, +) / Double(scores.count)
    }

    static func position(forScore score: Double) -> RankPosition {
        if score >= 21 { return RankPosition(rank: .olympia, division: 1) }
        return RankPosition.from(index: Int(floor(max(0, score))))
    }

    /// Progresso dentro do nível correspondente a uma pontuação agregada.
    static func progress(forScore score: Double) -> Double {
        if score >= 21 { return 0 }
        return max(0, min(1, score - floor(score)))
    }

    /// Pontos agregados quando o resultado é Olympia (média do excesso sobre 21 × 1000).
    static func aggregatePoints(forScore score: Double) -> Int {
        guard score >= 21 else { return 0 }
        return Int(1000 + (score - 21) * 1000)
    }

    /// Falta (em kg) para o próximo nível; nil no Olympia.
    static func kilosToNextLevel(value: Double, thresholds: RankThresholds) -> (next: RankPosition, falta: Double)? {
        thresholds.kilosToNext(value: value)
    }
}
