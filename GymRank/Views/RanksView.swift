//
//  RanksView.swift
//  GymRank
//
//  Explicação da escada: 7 ranks com três divisões cada + Olympia com pontos infinitos.
//

import SwiftUI

struct RanksView: View {
    var body: some View {
        ZStack {
            Color.gymBackground.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    SectionTitle(text: "A escada: 22 níveis")

                    VStack(spacing: 6) {
                        ForEach(Rank.allCases) { rank in
                            HStack(spacing: 10) {
                                Circle().fill(rank.color).frame(width: 10, height: 10)
                                Text(rank.nome)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(rank.color)
                                Spacer()
                                if rank == .olympia {
                                    Text("∞ pontos")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(rank.color)
                                        .accessibilityIdentifier("pontosInfinitos")
                                } else {
                                    HStack(spacing: 4) {
                                        ForEach(1...3, id: \.self) { d in
                                            Text("\(d)")
                                                .font(.system(size: 9, weight: .bold))
                                                .frame(width: 16, height: 16)
                                                .background(Circle().fill(rank.color.opacity(0.16)))
                                                .foregroundStyle(rank.color)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .background(RoundedRectangle(cornerRadius: 11).fill(Color.gymCard))
                            .overlay(RoundedRectangle(cornerRadius: 11).stroke(Color.gymLine, lineWidth: 1))
                        }
                    }

                    GymCard {
                        VStack(alignment: .leading, spacing: 6) {
                            SectionTitle(text: "Como funciona")
                            Text("• Cada um dos sete primeiros ranks divide-se em três divisões: Bronze 1 a 3, Prata 1 a 3, e assim por diante até Titã 3 (21 níveis).")
                                .font(.caption).foregroundStyle(Color.gymMuted)
                            Text("• O Olympia é um nível único, sem divisões: a partir do limiar de Elite os pontos sobem sem tecto (1000 pontos na entrada, +1000 por cada duplicação do levantamento).")
                                .font(.caption).foregroundStyle(Color.gymMuted)
                            Text("• Os limites vêm dos standards de força por peso corporal do Strength Level; as divisões e as posições intermédias dividem o intervalo publicado em três partes iguais.")
                                .font(.caption).foregroundStyle(Color.gymMuted)
                        }
                    }

                    GymCard {
                        VStack(alignment: .leading, spacing: 5) {
                            SectionTitle(text: "Fontes")
                            Text("Standards de força: Strength Level (edição 2026).")
                                .font(.caption2).foregroundStyle(Color.gymMuted)
                            Text("Catálogo: 23 exercícios com limiares de força publicados (Strength Level, 2026).")
                                .font(.caption2).foregroundStyle(Color.gymMuted)
                            Text("1RM estimado pela fórmula de Epley.")
                                .font(.caption2).foregroundStyle(Color.gymMuted)
                        }
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle("Ranks")
        .navigationBarTitleDisplayMode(.inline)
    }
}
