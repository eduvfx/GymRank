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
                    GymCard {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionTitle(text: "Rank da parte do corpo")
                            HStack {
                                Text(rankDaParte?.position?.nome ?? "Sem dados")
                                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                                    .foregroundStyle(rankDaParte?.position?.rank.color ?? .gymMuted)
                                Spacer()
                                if let points = rankDaParte?.olympiaPoints {
                                    Text("\(points) pts").font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(rankDaParte?.position?.rank.color ?? .gymMuted)
                                } else if let progress = rankDaParte?.progress {
                                    Text("\(Int(progress * 100))% para o próximo")
                                        .font(.caption2).foregroundStyle(.gymMuted)
                                }
                            }
                            RankProgressBar(position: rankDaParte?.position, progress: rankDaParte?.progress ?? 0)
                        }
                    }

                    SectionTitle(text: "Exercícios (\(daParte.count))")

                    ForEach(daParte) { exercise in
                        NavigationLink {
                            ExerciseDetailView(profile: profile, exercise: exercise)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(exercise.nome)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.white)
                                    if let r = summary.rank(for: exercise.standardID ?? "") {
                                        Text("melhor 1RM \(String(format: "%.1f", r.bestUMRM)) kg"
                                             + (r.lastDate.map { " · \(Self.formatter.string(from: $0))" } ?? ""))
                                            .font(.caption2).foregroundStyle(.gymMuted)
                                    } else {
                                        Text(exercise.standard == nil ? "peso corporal" : "sem registos")
                                            .font(.caption2).foregroundStyle(.gymMuted)
                                    }
                                }
                                Spacer()
                                if let r = summary.rank(for: exercise.standardID ?? "") {
                                    RankBadge(position: r.position, compact: true)
                                } else {
                                    Text("—").foregroundStyle(.gymMuted)
                                }
                            }
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 13).fill(Color.gymCard))
                            .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color.gymLine, lineWidth: 1))
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

    static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd/MM"
        return f
    }()
}
