//
//  RankComputation.swift
//  GymRank
//
//  Agrega os registos em posições da escada de 22 níveis:
//  por exercício, por parte do corpo e geral.
//

import Foundation
import SwiftData

struct ExerciseRank: Identifiable {
    let id: String
    let exercise: Exercise
    let bestUMRM: Double
    let position: RankPosition
    let progress: Double
    let thresholds: RankThresholds
    let lastDate: Date?

    /// Pontos do Olympia (0 nos outros níveis).
    var olympiaPoints: Int { position.isOlympia ? thresholds.olympiaPoints(forUMRM: bestUMRM) : 0 }

    /// Pontuação contínua: 0...21 nos níveis normais, sem tecto no Olympia.
    var score: Double {
        position.isOlympia ? 21 + Double(max(0, olympiaPoints - 1000)) / 1000
                           : Double(position.index) + progress
    }

    var next: (next: RankPosition, falta: Double)? { thresholds.kilosToNext(value: bestUMRM) }
}

struct BodyPartRank: Identifiable {
    let part: BodyPart
    let score: Double?

    var id: String { part.rawValue }
    var position: RankPosition? { score.map { RankEngine.position(forScore: $0) } }
    var progress: Double? { score.map { RankEngine.progress(forScore: $0) } }
    var olympiaPoints: Int? {
        guard let score, score >= 21 else { return nil }
        return RankEngine.aggregatePoints(forScore: score)
    }
    var hasData: Bool { score != nil }
}

struct RankSummary {
    let profile: UserProfile
    let exercises: [ExerciseRank]
    let parts: [BodyPartRank]
    let overall: Double?

    var overallPosition: RankPosition? { overall.map { RankEngine.position(forScore: $0) } }
    var overallProgress: Double { overall.map { RankEngine.progress(forScore: $0) } ?? 0 }
    var overallPoints: Int? {
        guard let overall, overall >= 21 else { return nil }
        return RankEngine.aggregatePoints(forScore: overall)
    }

    func exerciseRanks(for part: BodyPart) -> [ExerciseRank] {
        exercises.filter { $0.exercise.parte == part }.sorted { $0.bestUMRM > $1.bestUMRM }
    }

    func rank(for standardID: String) -> ExerciseRank? {
        exercises.first { $0.id == standardID }
    }

    static func compute(profile: UserProfile, sets: [WorkoutSet], exercises: [Exercise]) -> RankSummary {
        var ranks: [ExerciseRank] = []

        for exercise in exercises {
            let key = exercise.standardID ?? "wger-\(exercise.wgerID ?? 0)"
            let mine = sets.filter { $0.exercicioID == key }
            guard let best = mine.map({ $0.umRM }).max(), let standard = exercise.standard else { continue }
            let thresholds = RankEngine.thresholds(entry: standard,
                                                  sexo: profile.sexo,
                                                  pesoKg: profile.pesoKg,
                                                  idade: profile.idade)
            guard !thresholds.isEmpty else { continue }
            let position = thresholds.position(forUMRM: best)
            ranks.append(ExerciseRank(id: key,
                                      exercise: exercise,
                                      bestUMRM: best,
                                      position: position,
                                      progress: thresholds.progress(forUMRM: best, position: position),
                                      thresholds: thresholds,
                                      lastDate: mine.map({ $0.data }).max()))
        }

        let parts = BodyPart.allCases.map { part -> BodyPartRank in
            let scores = ranks.filter { $0.exercise.parte == part }.map { $0.score }
            return BodyPartRank(part: part, score: RankEngine.averageScore(scores))
        }

        let overall = RankEngine.averageScore(parts.compactMap { $0.score })
        return RankSummary(profile: profile, exercises: ranks, parts: parts, overall: overall)
    }
}
