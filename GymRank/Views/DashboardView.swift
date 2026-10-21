//
//  DashboardView.swift
//  GymRank
//
//  Painel: rank geral do corpo e rank de cada parte, com o objectivo mais próximo.
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    let profile: UserProfile

    @Query private var exercises: [Exercise]
    @Query private var sets: [WorkoutSet]

    private var summary: RankSummary {
        RankSummary.compute(profile: profile, sets: sets, exercises: exercises)
    }

    private var proximoObjetivo: String? {
        let comDados = summary.exercises.compactMap { ex -> (String, RankPosition, Double)? in
            guard let next = ex.next else { return nil }
            return (ex.exercise.nome, next.next, next.falta)
        }
        guard let melhor = comDados.min(by: { $0.2 < $1.2 }) else { return nil }
        return "Faltam \(String(format: "%.1f", melhor.2)) kg no \(melhor.0) para \(melhor.1.nome)"
    }

    var body: some View {
        ZStack {
            Color.gymBackground.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Olá, \(profile.nome.isEmpty ? "atleta" : profile.nome)")
                                .font(.system(size: 22, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                            Text("\(profile.idade) anos · \(String(format: "%.1f", profile.pesoKg)) kg")
                                .font(.caption).foregroundStyle(.gymMuted)
                        }
                        Spacer()
                        if let p = summary.overallPosition { RankBadge(position: p, compact: true) }
                    }

                    GymCard {
                        VStack(spacing: 10) {
                            RankRing(position: summary.overallPosition,
                                     progress: summary.overallProgress,
                                     points: summary.overallPoints)
                            if let objetivo = proximoObjetivo {
                                Text(objetivo)
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(.gymMuted)
                            } else if summary.overallPosition?.isOlympia == true {
                                Text("Estás no Olympia: os pontos continuam a subir sem tecto.")
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(.gymMuted)
                            } else {
                                Text("Regista um treino para começares a subir de rank")
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(.gymMuted)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }

                    SectionTitle(text: "Rank por parte do corpo")

                    ForEach(summary.parts) { part in
                        NavigationLink {
                            BodyPartView(profile: profile, part: part.part)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: part.part.icon)
                                    .font(.system(size: 16))
                                    .foregroundStyle(part.position?.rank.color ?? .gymMuted)
                                    .frame(width: 26)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(part.part.nome)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.white)
                                    Text(part.hasData
                                         ? "\(summary.exerciseRanks(for: part.part).count) exercício(s) com registos"
                                         : "sem dados")
                                        .font(.caption2).foregroundStyle(.gymMuted)
                                }
                                Spacer()
                                if let p = part.position {
                                    RankBadge(position: p, compact: true)
                                } else {
                                    Text("—").foregroundStyle(.gymMuted)
                                }
                            }
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color.gymCard))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.gymLine, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }

                    NavigationLink {
                        LogWorkoutView(profile: profile, exercises: exercises, preselect: nil)
                    } label: {
                        Text("＋  Registar treino")
                            .font(.system(size: 16, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color.gymAccent))
                            .foregroundStyle(.white)
                    }
                    .accessibilityIdentifier("registarTreino")
                    .padding(.top, 6)
                }
                .padding(16)
            }
        }
        .navigationTitle("Painel")
        .navigationBarTitleDisplayMode(.inline)
    }
}
