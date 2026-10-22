//
//  SessionEngine.swift
//  GymRank
//
//  Cálculos puros do treino em tempo real (volume, progresso, formatação de tempo)
//  e o temporizador de descanso configurável usado no treino activo.
//

import Foundation
import Combine

enum SessionEngine {

    /// Formata segundos como relógio curto: 45 -> "45s", 90 -> "1:30".
    static func formato(_ segundos: Int) -> String {
        let s = max(0, segundos)
        if s < 60 { return "\(s)s" }
        return String(format: "%d:%02d", s / 60, s % 60)
    }

    /// Volume total da sessão (kg levantados), a partir de pares peso/repetições.
    static func volume(_ pares: [(peso: Double, reps: Int)]) -> Double {
        pares.reduce(0) { $0 + max(0, $1.peso) * Double(max(0, $1.reps)) }
    }

    /// Melhor 1RM por exercício, para o cabeçalho de cada bloco do treino.
    static func melhores(_ pares: [(exercicio: String, umRM: Double)]) -> [String: Double] {
        var mapa: [String: Double] = [:]
        for par in pares where par.umRM > 0 {
            mapa[par.exercicio] = max(mapa[par.exercicio] ?? 0, par.umRM)
        }
        return mapa
    }

    /// Só se submete um treino quando há pelo menos uma série concluída.
    static func podeSubmeter(_ concluidas: [Bool]) -> Bool {
        concluidas.contains(true)
    }

    /// Fracção de séries concluídas (0...1) para a barra de progresso.
    static func progresso(_ concluidas: [Bool]) -> Double {
        guard !concluidas.isEmpty else { return 0 }
        return Double(concluidas.filter { $0 }.count) / Double(concluidas.count)
    }

    /// Sugere a próxima série a preencher: a primeira ainda não concluída.
    static func proximaSerie(_ concluidas: [Bool]) -> Int? {
        concluidas.firstIndex(of: false)
    }
}

/// Temporizador de descanso entre séries, com duração configurável no perfil.
@MainActor
final class RestTimer: ObservableObject {
    @Published private(set) var restante: Int = 0
    @Published private(set) var total: Int = 0
    @Published private(set) var ativo: Bool = false

    private var tarefa: Task<Void, Never>?

    /// Arranca (ou reinicia) a contagem com a duração indicada em segundos.
    func iniciar(segundos: Int) {
        guard segundos > 0 else { return }
        tarefa?.cancel()
        total = segundos
        restante = segundos
        ativo = true
        tarefa = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard let self, !Task.isCancelled else { return }
                if self.restante > 1 {
                    self.restante -= 1
                } else {
                    self.restante = 0
                    self.ativo = false
                    return
                }
            }
        }
    }

    func parar() {
        tarefa?.cancel()
        tarefa = nil
        ativo = false
        restante = 0
    }

    /// Acrescenta tempo ao descanso em curso (ex.: +15 s).
    func acrescentar(_ segundos: Int) {
        guard ativo else { return }
        restante = max(0, restante + segundos)
        total = max(total, restante)
    }

    /// 0 no início do descanso, 1 no fim — para o anel de progresso.
    var fracao: Double {
        guard total > 0 else { return 0 }
        return Double(total - restante) / Double(total)
    }
}
