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

    private var chave: String { exercise.standardID ?? "wger-\(exercise.wgerID ?? 0)" }
    private var meu: ExerciseRank? { summary.exercises.first { $0.id == chave } }

    private var limiares: RankThresholds? {
        guard let standard = exercise.standard else { return nil }
        let t = RankEngine.thresholds(entry: standard, sexo: profile.sexo,
                                      pesoKg: profile.pesoKg, idade: profile.idade)
        return t.isEmpty ? nil : t
    }

    var body: some View {
        ZStack {
            Color.gymBackground.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    GymCard {
                        VStack(spacing: 8) {
                            SectionTitle(text: "A tua posição neste exercício")
                            Text(meu?.position.nome ?? "Sem registos")
                                .font(.system(size: 28, weight: .heavy, design: .rounded))
                                .foregroundStyle(meu?.position.rank.color ?? .gymMuted)
                            if let meu {
                                Text("1RM estimado \(String(format: "%.1f", meu.bestUMRM)) kg · "
                                     + String(format: "%.2f", meu.bestUMRM / max(1, profile.pesoKg)) + "× o teu peso")
                                    .font(.caption).foregroundStyle(.gymMuted)
                                if meu.position.isOlympia {
                                    Text("\(meu.olympiaPoints) pontos · sistema sem tecto")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(meu.position.rank.color)
                                    RankProgressBar(position: meu.position, progress: 1)
                                } else {
                                    RankProgressBar(position: meu.position, progress: meu.progress)
                                    if let n = meu.next {
                                        Text("Faltam \(String(format: "%.1f", n.falta)) kg para \(n.next.nome)")
                                            .font(.caption2).foregroundStyle(.gymMuted)
                                    }
                                }
                            }
                        }
                    }

                    SectionTitle(text: "Escada de 22 níveis (para \(String(format: "%.0f", profile.pesoKg)) kg)")

                    if let limiares {
                        VStack(spacing: 4) {
                            ForEach(0..<RankPosition.total, id: \.self) { index in
                                let nivel = RankPosition.from(index: index)
                                let atual = meu?.position == nivel
                                let limite = limiares.cuts[index]
                                HStack(spacing: 8) {
                                    Circle().fill(nivel.rank.color)
                                        .frame(width: atual ? 10 : 7, height: atual ? 10 : 7)
                                    Text(nivel.nome)
                                        .font(.system(size: 11.5, weight: atual ? .heavy : .regular))
                                        .foregroundStyle(atual ? nivel.rank.color : .white)
                                    Spacer()
                                    if nivel.isOlympia {
                                        Text(limite > 0 ? "≥ \(String(format: "%.1f", limite)) kg · ∞ pts" : "∞ pts")
                                            .font(.system(size: 10))
                                            .foregroundStyle(atual ? nivel.rank.color : .gymMuted)
                                    } else {
                                        Text("\(String(format: "%.1f", limite)) kg")
                                            .font(.system(size: 10))
                                            .foregroundStyle(atual ? nivel.rank.color : .gymMuted)
                                    }
                                    if atual {
                                        Text("←").font(.system(size: 10, weight: .bold)).foregroundStyle(nivel.rank.color)
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(RoundedRectangle(cornerRadius: 9)
                                    .fill(atual ? nivel.rank.color.opacity(0.12) : Color.gymCard))
                                .overlay(RoundedRectangle(cornerRadius: 9)
                                    .stroke(atual ? nivel.rank.color.opacity(0.5) : Color.gymLine, lineWidth: 1))
                            }
                        }
                    } else {
                        GymCard {
                            Text("Este exercício é de peso corporal: o rank será calculado por repetições (versão seguinte).")
                                .font(.caption).foregroundStyle(.gymMuted)
                        }
                    }

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
                .padding(16)
            }
        }
        .navigationTitle(exercise.nome)
        .navigationBarTitleDisplayMode(.inline)
    }
}
