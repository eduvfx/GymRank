//
//  ProgressView.swift (ProgressTabView tem este nome para não colidir com a ProgressView da SwiftUI)
//  GymRank
//
//  Progresso: evolução do 1RM por exercício e das partes do corpo.
//

import SwiftUI
import SwiftData

struct ProgressTabView: View {
    let profile: UserProfile

    @Query private var exercises: [Exercise]
    @Query(sort: \WorkoutSet.data) private var sets: [WorkoutSet]
    @State private var selecionado: String = ""

    private var comDados: [Exercise] {
        let ids = Set(sets.compactMap { $0.standardID })
        return exercises.filter { ids.contains($0.standardID ?? "") }.sorted { $0.nome < $1.nome }
    }

    private var pontos: [(Date, Double)] {
        sets.filter { $0.standardID == selecionado }
            .map { ($0.data, $0.umRM) }
            .suffix(8)
            .map { $0 }
    }

    private var summary: RankSummary {
        RankSummary.compute(profile: profile, sets: sets, exercises: exercises)
    }

    var body: some View {
        ZStack {
            Color.gymBackground.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    GymCard {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionTitle(text: "1RM estimado por exercício")
                            if comDados.isEmpty {
                                Text("Sem registos ainda. Regista um treino para veres a evolução.")
                                    .font(.caption).foregroundStyle(.gymMuted)
                            } else {
                                Picker("Exercício", selection: $selecionado) {
                                    ForEach(comDados) { ex in
                                        Text(ex.nome).tag(ex.standardID ?? "")
                                    }
                                }
                                .pickerStyle(.menu)
                                .accessibilityIdentifier("pickerProgresso")

                                if pontos.isEmpty {
                                    Text("Sem dados para este exercício.")
                                        .font(.caption).foregroundStyle(.gymMuted)
                                } else {
                                    GraficoBarras(pontos: pontos)
                                    if let ultimo = pontos.last, let primeiro = pontos.first {
                                        Text("\(pontos.count) registos · \(String(format: "%.1f", ultimo.1 - primeiro.1)) kg de evolução")
                                            .font(.caption2).foregroundStyle(.gymMuted)
                                    }
                                }
                            }
                        }
                    }

                    SectionTitle(text: "Evolução por parte do corpo")
                    ForEach(summary.parts) { part in
                        HStack(spacing: 10) {
                            Text(part.part.nome)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 70, alignment: .leading)
                            RankProgressBar(position: part.position, progress: part.progress ?? 0)
                            if let p = part.position {
                                RankBadge(position: p, compact: true)
                            } else {
                                Text("—").font(.caption2).foregroundStyle(.gymMuted)
                            }
                        }
                        .padding(.vertical, 2)
                    }

                    GymCard {
                        VStack(alignment: .leading, spacing: 4) {
                            SectionTitle(text: "Rank geral do corpo")
                            Text(summary.overallPosition?.nome ?? "Sem dados")
                                .font(.system(size: 24, weight: .heavy, design: .rounded))
                                .foregroundStyle(summary.overallPosition?.rank.color ?? .gymMuted)
                            if let pts = summary.overallPoints {
                                Text("\(pts) pontos no Olympia").font(.caption2)
                                    .foregroundStyle(summary.overallPosition?.rank.color ?? .gymMuted)
                            }
                            Text("Média das oito partes do corpo com registos.")
                                .font(.caption2).foregroundStyle(.gymMuted)
                        }
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle("Progresso")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if selecionado.isEmpty { selecionado = comDados.first?.standardID ?? "" }
        }
    }
}

/// Gráfico de barras simples (sem dependências) da evolução do 1RM.
struct GraficoBarras: View {
    let pontos: [(Date, Double)]

    private var maximo: Double { max(1, pontos.map { $0.1 }.max() ?? 1) }

    var body: some View {
        HStack(alignment: .bottom, spacing: 7) {
            ForEach(Array(pontos.enumerated()), id: \.offset) { _, ponto in
                VStack(spacing: 4) {
                    Text(String(format: "%.0f", ponto.1))
                        .font(.system(size: 8))
                        .foregroundStyle(.gymMuted)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient(colors: [Color(hex: "7FD1FF"), Color(hex: "7FD1FF").opacity(0.25)],
                                             startPoint: .top, endPoint: .bottom))
                        .frame(height: max(6, 90 * ponto.1 / maximo))
                    Text(ponto.0.formatted(.dateTime.day().month(.twoDigits)))
                        .font(.system(size: 7))
                        .foregroundStyle(.gymMuted)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 130)
        .accessibilityIdentifier("graficoProgresso")
    }
}
