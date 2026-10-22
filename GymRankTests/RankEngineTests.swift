//
//  RankEngineTests.swift
//  GymRankTests
//
//  Testes do motor de ranks contra os valores reais publicados.
//  Escada de 22 níveis: 7 ranks × 3 divisões + Olympia único com pontos infinitos.
//

import XCTest
@testable import GymRank

final class RankEngineTests: XCTestCase {

    private let bench = StandardsData.entry(id: "bench-press")!

    private func cutsBench(sexo: Sex = .masculino, peso: Double = 80, idade: Int = 24) -> [Double] {
        RankEngine.thresholds(entry: bench, sexo: sexo, pesoKg: peso, idade: idade).cuts
    }

    // MARK: - Estrutura da escada

    func testLadderHas22Levels() {
        XCTAssertEqual(RankPosition.total, 22)
        XCTAssertEqual(cutsBench().count, 22)
        XCTAssertEqual(RankPosition.from(index: 0).nome, "Bronze 1")
        XCTAssertEqual(RankPosition.from(index: 2).nome, "Bronze 3")
        XCTAssertEqual(RankPosition.from(index: 3).nome, "Prata 1")
        XCTAssertEqual(RankPosition.from(index: 20).nome, "Titã 3")
        XCTAssertEqual(RankPosition.from(index: 21), RankPosition(rank: .olympia, division: 1))
        XCTAssertEqual(RankPosition.from(index: 21).nome, "Olympia")
    }

    func testSevenRanksHaveThreeDivisionsAndOlympiaOne() {
        for rank in Rank.allCases {
            XCTAssertEqual(rank.divisoes, rank == .olympia ? 1 : 3, "divisões de \(rank.nome)")
        }
        XCTAssertEqual(Rank.allCases.count, 8)
        // 7 ranks × 3 divisões + Olympia = 22
        XCTAssertEqual(Rank.allCases.map(\.divisoes).reduce(0, +), 22)
    }

    func testEveryExerciseHasAnAscendingLadder() {
        for entry in StandardsData.all {
            let cuts = RankEngine.thresholds(entry: entry, sexo: .masculino, pesoKg: 80, idade: 30).cuts
            XCTAssertEqual(cuts.count, 22, "\(entry.id) sem 22 níveis")
            XCTAssertEqual(cuts.first, 0, "\(entry.id) devia começar em 0")
            for i in 1..<cuts.count {
                XCTAssertGreaterThan(cuts[i], cuts[i-1], "\(entry.id): cortes não crescentes em \(i)")
            }
        }
    }

    // MARK: - Valores reais (supino, homem 80 kg, 24 anos)

    func testBenchPressBoundaries() {
        let cuts = cutsBench()
        // limites de rank publicados (49, 70, 96, 127, 160 kg) escalados por peso e idade:
        // factor = (80/72)^0,222 × 0,95 ≈ 0,9725
        XCTAssertEqual(cuts[0], 0, accuracy: 0.01)
        XCTAssertEqual(cuts.first ?? -1, 0, accuracy: 0.01)
        XCTAssertEqual(cuts[3], 47.7, accuracy: 0.6)     // Prata 1  (= Beginner)
        XCTAssertEqual(cuts[6], 68.1, accuracy: 0.6)     // Ouro 1   (= Novice)
        XCTAssertEqual(cuts[12], 93.4, accuracy: 0.6)    // Diamante 1 (= Intermediate)
        XCTAssertEqual(cuts[18], 123.5, accuracy: 0.7)   // Titã 1   (= Advanced)
        XCTAssertEqual(cuts[21], 155.6, accuracy: 0.8)   // Olympia  (= Elite)
    }

    func testBenchPressPositionsAt80kg() {
        let t = RankEngine.thresholds(entry: bench, sexo: .masculino, pesoKg: 80, idade: 24)
        XCTAssertEqual(t.position(forUMRM: 0).nome, "Bronze 1")
        XCTAssertEqual(t.position(forUMRM: 20).nome, "Bronze 2")
        XCTAssertEqual(t.position(forUMRM: 40).nome, "Bronze 3")
        XCTAssertEqual(t.position(forUMRM: 50).nome, "Prata 1")
        XCTAssertEqual(t.position(forUMRM: 70).nome, "Ouro 1")
        XCTAssertEqual(t.position(forUMRM: 75).nome, "Ouro 2")
        XCTAssertEqual(t.position(forUMRM: 100).nome, "Diamante 2")
        XCTAssertEqual(t.position(forUMRM: 110).nome, "Campeão 1")
        XCTAssertEqual(t.position(forUMRM: 130).nome, "Titã 1")
        XCTAssertEqual(t.position(forUMRM: 140).nome, "Titã 2")
        XCTAssertEqual(t.position(forUMRM: 156).nome, "Olympia")
        XCTAssertEqual(t.position(forUMRM: 250).nome, "Olympia")
    }

    func testKilosToNextLevel() {
        let t = RankEngine.thresholds(entry: bench, sexo: .masculino, pesoKg: 80, idade: 24)
        let next = t.kilosToNext(value: 100)
        XCTAssertEqual(next?.next.nome, "Diamante 3")
        XCTAssertEqual(next?.falta ?? 0, 3.4, accuracy: 0.4)
        XCTAssertNil(t.kilosToNext(value: 200), "no Olympia não há próximo nível por kg")
    }

    // MARK: - Olympia: pontos infinitos

    func testOlympiaPointsAreUnboundedAndMonotonic() {
        let t = RankEngine.thresholds(entry: bench, sexo: .masculino, pesoKg: 80, idade: 24)
        let entrada = t.olympiaEntry
        let p1 = t.olympiaPoints(forUMRM: entrada)
        let p2 = t.olympiaPoints(forUMRM: entrada * 2)
        let p3 = t.olympiaPoints(forUMRM: entrada * 4)
        XCTAssertEqual(Double(p1), 1000, accuracy: 60)
        XCTAssertEqual(Double(p2), 2000, accuracy: 60)
        XCTAssertEqual(Double(p3), 4000, accuracy: 60)
        XCTAssertGreaterThan(p3, p2)
        XCTAssertGreaterThan(p2, p1)
        // a pontuação agregada cresce sem tecto
        XCTAssertGreaterThan(t.score(forUMRM: entrada * 4), t.score(forUMRM: entrada * 2))
        XCTAssertGreaterThan(t.score(forUMRM: entrada * 2), 21.0)
        XCTAssertEqual(t.pontosParaProximoMarco(value: entrada), 1000)
    }

    // MARK: - Epley, idade e sexo

    func testEpleyFormula() {
        XCTAssertEqual(RankEngine.oneRepMax(pesoKg: 100, reps: 1), 100, accuracy: 0.01)
        XCTAssertEqual(RankEngine.oneRepMax(pesoKg: 100, reps: 5), 116.7, accuracy: 0.05)
        XCTAssertEqual(RankEngine.oneRepMax(pesoKg: 80, reps: 10), 106.7, accuracy: 0.05)
        XCTAssertEqual(RankEngine.oneRepMax(pesoKg: 0, reps: 5), 0, accuracy: 0.01)
    }

    func testAgeLowersTheThresholds() {
        let jovem = cutsBench(idade: 24)
        let senior = cutsBench(idade: 55)
        XCTAssertLessThan(senior[3], jovem[3], "aos 55 anos o limite de Prata 1 tem de ser menor")
        XCTAssertEqual(RankEngine.ageFactor(24), 0.95, accuracy: 0.001)
        XCTAssertEqual(RankEngine.ageFactor(30), 1.00, accuracy: 0.001)
        XCTAssertEqual(RankEngine.ageFactor(60), 0.78, accuracy: 0.001)
    }

    func testFemaleThresholdsAreLower() {
        let homem = cutsBench(sexo: .masculino)
        let mulher = cutsBench(sexo: .feminino, peso: 60)
        XCTAssertLessThan(mulher[3], homem[3])
        XCTAssertGreaterThan(mulher[3], 0)
    }

    // MARK: - Agregação

    func testAggregationOfScores() {
        XCTAssertEqual(RankEngine.averageScore([5.0, 7.0])!, 6.0, accuracy: 0.0001)
        XCTAssertNil(RankEngine.averageScore([]))
        XCTAssertEqual(RankEngine.position(forScore: 6.0).nome, "Ouro 1")
        XCTAssertEqual(RankEngine.position(forScore: 10.5).nome, "Platina 2")
        XCTAssertEqual(RankEngine.position(forScore: 21.5).nome, "Olympia")
        XCTAssertTrue(RankEngine.position(forScore: 99).isOlympia)
        XCTAssertGreaterThan(RankEngine.aggregatePoints(forScore: 23), 1000)
    }
}
