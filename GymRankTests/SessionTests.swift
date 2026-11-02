//
//  SessionTests.swift
//  GymRankTests
//
//  Testes do treino em tempo real: formatação de tempo, volume, progresso,
//  melhores 1RM e mapeamento do classificador de imagens para o catálogo.
//

import XCTest
@testable import GymRank

final class SessionTests: XCTestCase {

    func testFormatoTempo() {
        XCTAssertEqual(SessionEngine.formato(0), "0s")
        XCTAssertEqual(SessionEngine.formato(45), "45s")
        XCTAssertEqual(SessionEngine.formato(90), "1:30")
        XCTAssertEqual(SessionEngine.formato(605), "10:05")
    }

    func testVolumeDaSessao() {
        let series: [(peso: Double, reps: Int)] = [(peso: 100, reps: 5), (peso: 80, reps: 10)]
        XCTAssertEqual(SessionEngine.volume(series), 1300, accuracy: 0.01)
        XCTAssertEqual(SessionEngine.volume([]), 0, accuracy: 0.01)
    }

    func testProgressoEPodeSubmeter() {
        XCTAssertEqual(SessionEngine.progresso([true, false, false, true]), 0.5, accuracy: 0.001)
        XCTAssertFalse(SessionEngine.podeSubmeter([false, false]))
        XCTAssertTrue(SessionEngine.podeSubmeter([false, true]))
    }

    func testMelhoresPorExercicio() {
        let pares: [(exercicio: String, umRM: Double)] = [
            (exercicio: "Bench Press", umRM: 120),
            (exercicio: "Bench Press", umRM: 125),
            (exercicio: "Squat", umRM: 140)
        ]
        let melhores = SessionEngine.melhores(pares)
        XCTAssertEqual(melhores["Bench Press"] ?? 0, 125, accuracy: 0.001)
        XCTAssertEqual(melhores["Squat"] ?? 0, 140, accuracy: 0.001)
    }

    func testProximaSerie() {
        XCTAssertEqual(SessionEngine.proximaSerie([true, false, false]), 1)
        XCTAssertNil(SessionEngine.proximaSerie([true, true]))
        XCTAssertNil(SessionEngine.proximaSerie([]))
    }

    func testDeteccaoDaMaquinaPorFotografia() {
        XCTAssertEqual(MachineDetector.exercicio(para: "barbell bench press machine")?.id, "bench-press")
        XCTAssertEqual(MachineDetector.exercicio(para: "lat pulldown cable machine")?.id, "lat-pulldown")
        XCTAssertEqual(MachineDetector.exercicio(para: "leg press machine")?.id, "sled-leg-press")
        XCTAssertNil(MachineDetector.exercicio(para: "treadmill"), "máquinas de cardio não têm rank")
    }

    func testSugestoesOrdenadasPorConfianca() {
        let sugestoes = MachineDetector.sugestoes(etiquetas: [("dumbbell bench press", 0.4),
                                                              ("barbell bench press", 0.9)])
        XCTAssertFalse(sugestoes.isEmpty)
        XCTAssertEqual(sugestoes.first?.id, "bench-press")
        XCTAssertLessThanOrEqual(sugestoes.count, 3)
    }
}
