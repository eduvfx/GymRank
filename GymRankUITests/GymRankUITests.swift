//
//  GymRankUITests.swift
//  GymRankUITests
//
//  Testes de interface: usam a app como um utilizador usaria, num simulador de iPhone.
//

import XCTest

final class GymRankUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    private func shot(_ name: String) {
        let s = XCUIScreen.main.screenshot()
        let a = XCTAttachment(screenshot: s)
        a.name = name
        a.lifetime = .keepAlways
        add(a)
    }

    /// Cria o perfil no primeiro arranque (idade e peso já vêm com valores por omissão).
    private func garantirPerfil() {
        let guardar = app.buttons["guardarPerfil"]
        if guardar.waitForExistence(timeout: 8) {
            shot("01-onboarding")
            XCTAssertTrue(app.staticTexts["Idade"].exists || app.staticTexts["IDADE"].exists,
                          "o assistente devia pedir a idade")
            guardar.tap()
        }
        XCTAssertTrue(app.tabBars.buttons["Painel"].waitForExistence(timeout: 10),
                      "depois de guardar o perfil devia entrar no separador Painel")
    }

    func test01_OnboardingCreatesProfileAndShowsDashboard() {
        garantirPerfil()
        XCTAssertTrue(app.staticTexts["Painel"].exists || app.navigationBars["Painel"].exists)
        XCTAssertTrue(app.staticTexts["Rank por parte do corpo"].exists
                      || app.staticTexts["RANK POR PARTE DO CORPO"].exists,
                      "o painel devia listar as partes do corpo")
        shot("02-painel")
    }

    func test02_LogWorkoutAndSeeItInHistory() {
        garantirPerfil()

        app.buttons["registarTreino"].tap()
        XCTAssertTrue(app.navigationBars["Registar treino"].waitForExistence(timeout: 8),
                      "não abriu o ecrã de registo")
        shot("03-registar-treino")

        let guardar = app.buttons["guardarTreino"]
        XCTAssertTrue(guardar.waitForExistence(timeout: 5))
        guardar.tap()

        app.tabBars.buttons["Treinos"].tap()
        XCTAssertTrue(app.navigationBars["Treinos"].waitForExistence(timeout: 8))
        XCTAssertGreaterThanOrEqual(app.cells.count, 1, "o treino devia aparecer no histórico")
        shot("04-historico")
    }

    func test03_ExerciseDetailShowsTwentyTwoLevels() {
        garantirPerfil()

        app.buttons["registarTreino"].tap()
        _ = app.navigationBars["Registar treino"].waitForExistence(timeout: 8)
        app.buttons["guardarTreino"].tap()

        // Painel → Peito → Bench Press
        let peito = app.staticTexts["Peito"]
        XCTAssertTrue(peito.waitForExistence(timeout: 8))
        peito.tap()

        let bench = app.staticTexts["Bench Press"]
        XCTAssertTrue(bench.waitForExistence(timeout: 8), "faltou o exercício Bench Press")
        bench.tap()

        XCTAssertTrue(app.navigationBars["Bench Press"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["Olympia"].waitForExistence(timeout: 5),
                      "a escada devia mostrar o nível Olympia")
        XCTAssertTrue(app.staticTexts["Bronze 1"].exists || app.staticTexts["Bronze 2"].exists,
                      "a escada devia começar no Bronze")
        shot("05-escada-22-niveis")
    }

    func test04_RanksScreenExplainsDivisionsAndInfinitePoints() {
        garantirPerfil()
        app.tabBars.buttons["Perfil"].tap()
        // o NavigationLink expõe-se como botão, não como texto
        let ranks = app.buttons["abrirRanks"]
        if !ranks.waitForExistence(timeout: 6) {
            if !app.buttons["Ranks e conquistas"].exists { app.swipeUp() }
        }
        XCTAssertTrue(ranks.waitForExistence(timeout: 8) || app.buttons["Ranks e conquistas"].waitForExistence(timeout: 3),
                      "o Perfil devia ter a entrada para os ranks")
        if ranks.exists { ranks.tap() } else { app.buttons["Ranks e conquistas"].tap() }
        XCTAssertTrue(app.navigationBars["Ranks"].waitForExistence(timeout: 8))
        // a SwiftUI pode juntar os Text da linha num só elemento ("Olympia, ∞ pontos"),
        // por isso procura-se pelo conteúdo e não pelo identificador
        let infinitos = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS %@", "∞")).firstMatch
        if !infinitos.waitForExistence(timeout: 3) { app.swipeUp() }
        let explicacao = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS[c] %@", "sem tecto")).firstMatch
        XCTAssertTrue(infinitos.waitForExistence(timeout: 4) || explicacao.waitForExistence(timeout: 4),
                      "o ecrã devia explicar os pontos infinitos do Olympia")
        shot("06-ranks")
    }
}
