//
//  MachineDetector.swift
//  GymRank
//
//  Detecta a máquina/exercício a partir de uma fotografia, usando o classificador
//  de imagens do sistema (Vision, VNClassifyImageRequest) — não é preciso modelo
//  treinado à parte — e mapeia as etiquetas para exercícios do catálogo GymRank.
//  O utilizador confirma sempre a sugestão antes de o exercício entrar no treino.
//

import Foundation
import UIKit
import Vision

struct MachineSuggestion: Identifiable, Equatable {
    let id: String        // standardID do catálogo
    let nome: String
    let parte: BodyPart
    let confianca: Double
}

enum MachineDetector {

    /// Termos (etiquetas do classificador, em inglês) associados a cada exercício.
    static let associacoes: [(termos: [String], standardID: String)] = [
        (["bench press", "barbell bench", "chest press machine"], "bench-press"),
        (["dumbbell bench", "dumbbell press"], "dumbbell-bench-press"),
        (["incline bench", "incline press"], "incline-bench-press"),
        (["power rack", "squat rack", "squat"], "squat"),
        (["front squat"], "front-squat"),
        (["deadlift"], "deadlift"),
        (["romanian", "stiff leg"], "romanian-deadlift"),
        (["rowing machine", "rower", "rowing", "bent over row"], "bent-over-row"),
        (["lat pulldown", "pulldown", "cable machine", "cable"], "lat-pulldown"),
        (["seated row", "cable row"], "seated-cable-row"),
        (["lateral raise", "side raise"], "dumbbell-lateral-raise"),
        (["shoulder press", "overhead press", "military press"], "shoulder-press"),
        (["dumbbell shoulder", "arnold press"], "dumbbell-shoulder-press"),
        (["barbell curl", "ez bar", "curl bar"], "barbell-curl"),
        (["dumbbell curl", "dumbbell"], "dumbbell-curl"),
        (["hammer curl"], "hammer-curl"),
        (["tricep", "pushdown", "cable pushdown"], "tricep-pushdown"),
        (["skull crusher", "lying tricep"], "lying-tricep-extension"),
        (["leg extension"], "leg-extension"),
        (["leg curl"], "lying-leg-curl"),
        (["leg press", "sled"], "sled-leg-press"),
        (["hip thrust", "glute bridge"], "hip-thrust"),
        (["calf raise", "calf"], "machine-calf-raise"),
    ]

    /// Máquinas de cardio: reconhecidas mas sem rank de força.
    static let semRank: [String] = ["treadmill", "exercise bike", "stationary bike",
                                    "elliptical", "rowing machine", "stair climber"]

    /// Converte etiquetas do classificador (texto, confiança) em sugestões ordenadas.
    static func sugestoes(etiquetas: [(String, Double)]) -> [MachineSuggestion] {
        var pontos: [String: Double] = [:]
        for (etiqueta, confianca) in etiquetas {
            let termo = etiqueta.lowercased()
            guard !semRank.contains(where: { termo.contains($0) }) else { continue }
            for associacao in associacoes where associacao.termos.contains(where: { termo.contains($0) }) {
                pontos[associacao.standardID, default: 0] += max(0, confianca)
            }
        }
        let lista = pontos.compactMap { id, score -> MachineSuggestion? in
            guard let entrada = StandardsData.entry(id: id) else { return nil }
            return MachineSuggestion(id: id, nome: entrada.nome, parte: entrada.parte,
                                     confianca: min(1, score))
        }
        return Array(lista.sorted { $0.confianca > $1.confianca }.prefix(3))
    }

    /// Corresponde uma etiqueta única ao melhor exercício (usado nos testes).
    static func exercicio(para etiqueta: String) -> MachineSuggestion? {
        sugestoes(etiquetas: [(etiqueta, 1.0)]).first
    }

    /// Corre o classificador de imagens do sistema e devolve até 3 sugestões.
    static func reconhecer(imagem: UIImage) async -> [MachineSuggestion] {
        guard let cgImage = imagem.cgImage else { return [] }
        return await withCheckedContinuation { continuacao in
            let pedido = VNClassifyImageRequest()
            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
            do {
                try handler.perform([pedido])
                let observacoes = (pedido.results ?? [])
                    .sorted { $0.confidence > $1.confidence }
                    .prefix(15)
                    .map { ($0.identifier, Double($0.confidence)) }
                continuacao.resume(returning: sugestoes(etiquetas: Array(observacoes)))
            } catch {
                continuacao.resume(returning: [])
            }
        }
    }
}
