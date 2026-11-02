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
    /// Descanso entre séries, configurável no perfil (segundos).
    var descansoSegundos: Int

    init(nome: String, idade: Int, pesoKg: Double, alturaCm: Double, sexo: Sex, criadoEm: Date = .now) {
        self.nome = nome
        self.idade = idade
        self.pesoKg = pesoKg
        self.alturaCm = alturaCm
        self.sexoRaw = sexo.rawValue
        self.criadoEm = criadoEm
        self.descansoSegundos = descansoSegundos
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
    /// Identificador do standard no pacote de dados (ex.: "bench-press"). Todo o catálogo tem rank.
    var standardID: String
    var nome: String
    var parteRaw: String
    var atualizadoEm: Date

    init(nome: String, parte: BodyPart, standardID: String, atualizadoEm: Date = .now) {
        self.nome = nome
        self.parteRaw = parte.rawValue
        self.standardID = standardID
        self.atualizadoEm = atualizadoEm
    }

    var parte: BodyPart {
        get { BodyPart(rawValue: parteRaw) ?? .chest }
        set { parteRaw = newValue.rawValue }
    }

    var standard: StandardEntry? { StandardsData.entry(id: standardID) }
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


// MARK: - Rotinas e treino em tempo real

@Model
final class Routine {
    var uid: UUID
    var nome: String
    var notas: String
    var ordem: Int
    var criadoEm: Date

    init(nome: String, notas: String = "", ordem: Int = 0, criadoEm: Date = .now) {
        self.uid = UUID()
        self.nome = nome
        self.notas = notas
        self.ordem = ordem
        self.criadoEm = criadoEm
    }
}

@Model
final class RoutineItem {
    var rotinaUID: UUID
    var standardID: String
    var exercicioNome: String
    var parteRaw: String
    var ordem: Int
    var seriesAlvo: Int
    var repsAlvo: Int

    init(rotinaUID: UUID, standardID: String, exercicioNome: String, parte: BodyPart,
         ordem: Int, seriesAlvo: Int = 3, repsAlvo: Int = 8) {
        self.rotinaUID = rotinaUID
        self.standardID = standardID
        self.exercicioNome = exercicioNome
        self.parteRaw = parte.rawValue
        self.ordem = ordem
        self.seriesAlvo = seriesAlvo
        self.repsAlvo = repsAlvo
    }

    var parte: BodyPart {
        get { BodyPart(rawValue: parteRaw) ?? .chest }
        set { parteRaw = newValue.rawValue }
    }
}

@Model
final class TrainingSession {
    var uid: UUID
    var rotinaNome: String
    var inicio: Date
    var fim: Date?
    var concluida: Bool

    init(rotinaNome: String, inicio: Date = .now) {
        self.uid = UUID()
        self.rotinaNome = rotinaNome
        self.inicio = inicio
        self.fim = nil
        self.concluida = false
    }

    var duracao: TimeInterval { (fim ?? .now).timeIntervalSince(inicio) }
}

@Model
final class SerieSessao {
    var sessaoUID: UUID
    var standardID: String
    var exercicioNome: String
    var parteRaw: String
    var ordem: Int
    var numero: Int
    var pesoKg: Double
    var reps: Int
    var concluida: Bool
    var umRM: Double

    init(sessaoUID: UUID, standardID: String, exercicioNome: String, parte: BodyPart,
         ordem: Int, numero: Int, pesoKg: Double = 0, reps: Int = 0) {
        self.sessaoUID = sessaoUID
        self.standardID = standardID
        self.exercicioNome = exercicioNome
        self.parteRaw = parte.rawValue
        self.ordem = ordem
        self.numero = numero
        self.pesoKg = pesoKg
        self.reps = reps
        self.concluida = false
        self.umRM = 0
    }

    var parte: BodyPart {
        get { BodyPart(rawValue: parteRaw) ?? .chest }
        set { parteRaw = newValue.rawValue }
    }

    func recalcular1RM() {
        umRM = RankEngine.oneRepMax(pesoKg: pesoKg, reps: reps)
    }
}
