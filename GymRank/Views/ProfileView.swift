//
//  ProfileView.swift
//  GymRank
//
//  Perfil: dados que alimentam o cálculo, estado do catálogo e créditos.
//

import SwiftUI
import SwiftData

struct ProfileView: View {
    let profile: UserProfile

    @Query private var exercises: [Exercise]

    var body: some View {
        ZStack {
            Color.gymBackground.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    GymCard {
                        VStack(alignment: .leading, spacing: 6) {
                            SectionTitle(text: "Perfil")
                            linha("Nome", profile.nome.isEmpty ? "—" : profile.nome)
                            linha("Idade", "\(profile.idade) anos")
                            linha("Peso", String(format: "%.1f kg", profile.pesoKg))
                            linha("Altura", String(format: "%.0f cm", profile.alturaCm))
                            linha("Sexo", profile.sexo.nome)
                        }
                    }

                    NavigationLink {
                        OnboardingView(existing: profile)
                    } label: {
                        Text("Editar perfil")
                            .font(.system(size: 15, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(RoundedRectangle(cornerRadius: 13).fill(Color.gymCard))
                            .foregroundStyle(.white)
                    }
                    .accessibilityIdentifier("editarPerfil")

                    NavigationLink {
                        RanksView()
                    } label: {
                        Text("Ranks e conquistas")
                            .font(.system(size: 15, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(RoundedRectangle(cornerRadius: 13).fill(Color.gymCard))
                            .foregroundStyle(.white)
                    }
                    .accessibilityIdentifier("abrirRanks")

                    GymCard {
                        VStack(alignment: .leading, spacing: 6) {
                            SectionTitle(text: "Catálogo")
                            Text("\(exercises.count) exercícios, todos com rank publicado.")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white)
                            Text("O catálogo vem incluído na app: sem API externa e sem rede. Só entram exercícios com limiares de força publicados, para que todos tenham rank.")
                                .font(.caption)
                                .foregroundStyle(Color.gymMuted)
                        }
                    }

                    GymCard {
                        VStack(alignment: .leading, spacing: 5) {
                            SectionTitle(text: "Sobre")
                            Text("GymRank · projecto individual de Desenvolvimento para Dispositivos Móveis (MEI, ESTG/IPLeiria, 2026/2027).")
                                .font(.caption2).foregroundStyle(Color.gymMuted)
                            Text("Ranks: Strength Level (2026). 1RM: Epley.")
                                .font(.caption2).foregroundStyle(Color.gymMuted)
                        }
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle("Perfil")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func linha(_ titulo: String, _ valor: String) -> some View {
        HStack {
            Text(titulo).font(.caption).foregroundStyle(Color.gymMuted)
            Spacer()
            Text(valor).font(.system(size: 13, weight: .semibold)).foregroundStyle(.white)
        }
    }
}
