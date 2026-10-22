//
//  BodyPartView.swift
//  GymRank
//
//  Lista dos exercícios de uma parte do corpo, cada um com a sua posição na escada.
//

import SwiftUI
import SwiftData

struct BodyPartView: View {
    let profile: UserProfile
    let part: BodyPart

    @Query private var exercises: [Exercise]
    @Query private var sets: [WorkoutSet]

    private var summary: RankSummary {
        RankSummary.compute(profile: profile, sets: sets, exercises: exercises)
    }

    private var daParte: [Exercise] {
        exercises.filter { $0.parte == part }.sorted { $0.nome < $1.nome }
    }

    private var rankDaParte: BodyPartRank? {
        summary.parts.first { $0.part == part }
    }

    var body: some View {
        ZStack {
            Color.gymBackground.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    cabecalho
                    SectionTitle(text: "Exercícios (\(daParte.count))")
                    ForEach(daParte) { exercise in
                        NavigationLink {
                            ExerciseDetailView(profile: profile, exercise: exercise)
                        } label: {
                            linha(exercise)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle(part.nome)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Blocos separados (uma expressão enorme rebenta o type-checker)

    private var cabecalho: some View {
        GymCard {
            VStack(alignment: .leading, spacing: 8) {
                SectionTitle(text: "Rank da parte do corpo")
                HStack(spacing: 8) {
                    Text(rankDaParte?.position?.nome ?? "Sem dados")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundStyle(cor)
                    Spacer()
                    subtitulo
                }
                RankProgressBar(position: rankDaParte?.position,
                                progress: rankDaParte?.progress ?? 0)
            }
        }
    }

    private var cor: Color {
        rankDaParte?.position?.rank.color ?? Color.gymMuted
    }

    @ViewBuilder
    private var subtitulo: some View {
        if let pontos = rankDaParte?.olympiaPoints {
            Text("\(pontos) pts")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(cor)
        } else if let progresso = rankDaParte?.progress {
            Text("\(Int(progresso * 100))% para o próximo")
                .font(.caption2)
                .foregroundStyle(Color.gymMuted)
        }
    }

    private func linha(_ exercise: Exercise) -> some View {
        let posicao = summary.rank(for: exercise.standardID ?? "")
        return HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 3) {
                Text(exercise.nome)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                Text(textoDetalhe(exercise, posicao))
                    .font(.caption2)
                    .foregroundStyle(Color.gymMuted)
            }
            Spacer()
            if let posicao {
                RankBadge(position: posicao.position, compact: true)
            } else {
                Text("—").foregroundStyle(Color.gymMuted)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 13).fill(Color.gymCard))
        .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color.gymLine, lineWidth: 1))
    }

    private func textoDetalhe(_ exercise: Exercise, _ posicao: ExerciseRank?) -> String {
        guard let posicao else {
            return exercise.standard == nil ? "peso corporal" : "sem registos"
        }
        let kg = String(format: "%.1f", posicao.bestUMRM)
        if let data = posicao.lastDate {
            return "melhor 1RM \(kg) kg · \(Self.formatter.string(from: data))"
        }
        return "melhor 1RM \(kg) kg"
    }

    static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd/MM"
        return f
    }()
}
