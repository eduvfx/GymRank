//
//  Models.swift
//  GymRank
//
//  Modelo persistente (SwiftData): perfil, exercícios do catálogo e séries registadas.
//

import Foundation
import SwiftData

@Model
final class UserProfile {
    var nome: String
    var idade: Int
    var pesoKg: Double
    var alturaCm: Double
    var sexoRaw: String
    var criadoEm: Date

    init(nome: String, idade: Int, pesoKg: Double, alturaCm: Double, sexo: Sex, criadoEm: Date = .now) {
        self.nome = nome
        self.idade = idade
        self.pesoKg = pesoKg
        self.alturaCm = alturaCm
        self.sexoRaw = sexo.rawValue
        self.criadoEm = criadoEm
    }

    var sexo: Sex {
        get { Sex(rawValue: sexoRaw) ?? .masculino }
        set { sexoRaw = newValue.rawValue }
    }

    /// O perfil só conta como completo quando tem os dados que alimentam o rank.
    var isComplete: Bool { idade > 0 && pesoKg > 0 }
}

@Model
final class Exercise {
    /// Identificador do standard no pacote de dados (ex.: "bench-press"); nil quando vem só do wger.
    var standardID: String?
    /// Identificador do exercício na API wger, quando sincronizado.
    var wgerID: Int?
    var nome: String
    var parteRaw: String
    var equipamento: String?
    var musculoPrincipal: String?
    var atualizadoEm: Date

    init(nome: String, parte: BodyPart, standardID: String? = nil, wgerID: Int? = nil,
         equipamento: String? = nil, musculoPrincipal: String? = nil, atualizadoEm: Date = .now) {
        self.nome = nome
        self.parteRaw = parte.rawValue
        self.standardID = standardID
        self.wgerID = wgerID
        self.equipamento = equipamento
        self.musculoPrincipal = musculoPrincipal
        self.atualizadoEm = atualizadoEm
    }

    var parte: BodyPart {
        get { BodyPart(rawValue: parteRaw) ?? .chest }
        set { parteRaw = newValue.rawValue }
    }

    var standard: StandardEntry? {
        guard let standardID else { return nil }
        return StandardsData.entry(id: standardID)
    }
}

@Model
final class WorkoutSet {
    var exercicioID: String
    var standardID: String?
    var pesoKg: Double
    var reps: Int
    var series: Int
    var data: Date
    /// 1RM estimado guardado no momento do registo (Epley).
    var umRM: Double

    init(exercicioID: String, standardID: String?, pesoKg: Double, reps: Int, series: Int,
         data: Date = .now, umRM: Double? = nil) {
        self.exercicioID = exercicioID
        self.standardID = standardID
        self.pesoKg = pesoKg
        self.reps = reps
        self.series = series
        self.data = data
        self.umRM = umRM ?? RankEngine.oneRepMax(pesoKg: pesoKg, reps: reps)
    }

    var volume: Double { pesoKg * Double(reps) * Double(series) }
}
