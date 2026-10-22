//
//  ExerciseDetailView.swift
//  GymRank
//
//  Detalhe do exercício: posição actual, 1RM e a escada completa de 22 níveis.
//

import SwiftUI
import SwiftData

struct ExerciseDetailView: View {
    let profile: UserProfile
    let exercise: Exercise

    @Query private var exercises: [Exercise]
    @Query private var sets: [WorkoutSet]

    private var summary: RankSummary {
        RankSummary.compute(profile: profile, sets: sets, exercises: exercises)
    }

    private var chave: String { exercise.standardID }

    private var meu: ExerciseRank? { summary.exercises.first { $0.id == chave } }

    private var limiares: RankThresholds? {
        guard let standard = exercise.standard else { return nil }
        let t = RankEngine.thresholds(entry: standard,
                                      sexo: profile.sexo,
                                      pesoKg: profile.pesoKg,
                                      idade: profile.idade)
        return t.isEmpty ? nil : t
    }

    private var tituloEscada: String {
        String(format: "Escada de 22 níveis (para %.0f kg)", profile.pesoKg)
    }

    var body: some View {
        ZStack {
            Color.gymBackground.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    cabecalho
                    SectionTitle(text: tituloEscada)
                    escada
                    botaoRegistar
                }
                .padding(16)
            }
        }
        .navigationTitle(exercise.nome)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Blocos separados (uma expressão enorme rebenta o type-checker)

    private var cabecalho: some View {
        GymCard {
            VStack(spacing: 8) {
                SectionTitle(text: "A tua posição neste exercício")
                Text(meu?.position.nome ?? "Sem registos")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(corPosicao)
                detalhe
            }
        }
    }

    private var corPosicao: Color {
        meu?.position.rank.color ?? Color.gymMuted
    }

    @ViewBuilder
    private var detalhe: some View {
        if let meu {
            Text(linha1RM(meu))
                .font(.caption)
                .foregroundStyle(Color.gymMuted)
            if meu.position.isOlympia {
                Text("\(meu.olympiaPoints) pontos · sistema sem tecto")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(meu.position.rank.color)
                RankProgressBar(position: meu.position, progress: 1)
            } else {
                RankProgressBar(position: meu.position, progress: meu.progress)
                if let seguinte = meu.next {
                    Text("Faltam \(String(format: "%.1f", seguinte.falta)) kg para \(seguinte.next.nome)")
                        .font(.caption2)
                        .foregroundStyle(Color.gymMuted)
                }
            }
        }
    }

    private func linha1RM(_ posicao: ExerciseRank) -> String {
        let kg = String(format: "%.1f", posicao.bestUMRM)
        let vezes = String(format: "%.2f", posicao.bestUMRM / max(1, profile.pesoKg))
        return "1RM estimado \(kg) kg · \(vezes)× o teu peso"
    }

    @ViewBuilder
    private var escada: some View {
        if let limiares {
            VStack(spacing: 4) {
                ForEach(0..<RankPosition.total, id: \.self) { index in
                    nivel(index: index, limiares: limiares)
                }
            }
        } else {
            GymCard {
                Text("Este exercício é de peso corporal: o rank será calculado por repetições (versão seguinte).")
                    .font(.caption)
                    .foregroundStyle(Color.gymMuted)
            }
        }
    }

    private func nivel(index: Int, limiares: RankThresholds) -> some View {
        let posicao = RankPosition.from(index: index)
        let atual = meu?.position == posicao
        let limite = limiares.cuts[index]
        return HStack(spacing: 8) {
            Circle()
                .fill(posicao.rank.color)
                .frame(width: atual ? 10 : 7, height: atual ? 10 : 7)
            Text(posicao.nome)
                .font(.system(size: 11.5, weight: atual ? .heavy : .regular))
                .foregroundStyle(atual ? posicao.rank.color : .white)
            Spacer()
            Text(etiqueta(limite: limite, posicao: posicao))
                .font(.system(size: 10))
                .foregroundStyle(atual ? posicao.rank.color : Color.gymMuted)
            if atual {
                Text("←")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(posicao.rank.color)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 9).fill(fundo(atual: atual, posicao: posicao)))
        .overlay(RoundedRectangle(cornerRadius: 9).stroke(borda(atual: atual, posicao: posicao), lineWidth: 1))
    }

    private func etiqueta(limite: Double, posicao: RankPosition) -> String {
        if posicao.isOlympia {
            return limite > 0 ? "≥ \(String(format: "%.1f", limite)) kg · ∞ pts" : "∞ pts"
        }
        return "\(String(format: "%.1f", limite)) kg"
    }

    private func fundo(atual: Bool, posicao: RankPosition) -> Color {
        atual ? posicao.rank.color.opacity(0.12) : Color.gymCard
    }

    private func borda(atual: Bool, posicao: RankPosition) -> Color {
        atual ? posicao.rank.color.opacity(0.5) : Color.gymLine
    }

    private var botaoRegistar: some View {
        NavigationLink {
            LogWorkoutView(profile: profile, exercises: exercises, preselect: exercise)
        } label: {
            Text("Registar série")
                .font(.system(size: 16, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.gymAccent))
                .foregroundStyle(.white)
        }
        .padding(.top, 4)
    }
}
