//
//  ProfileView.swift
//  GymRank
//
//  Perfil: dados que alimentam o cálculo, sincronização do catálogo e créditos.
//

import SwiftUI
import SwiftData

struct ProfileView: View {
    let profile: UserProfile

    @Environment(\.modelContext) private var context
    @Query private var exercises: [Exercise]
    @State private var mensagem: String?
    @State private var aSincronizar = false

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

                    GymCard {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionTitle(text: "Catálogo de exercícios (wger)")
                            Text("\(exercises.count) exercícios na base local.")
                                .font(.caption).foregroundStyle(.gymMuted)
                            Button {
                                Task { await sincronizar() }
                            } label: {
                                HStack {
                                    if aSincronizar { SwiftUI.ProgressView().tint(.white) }
                                    Text(aSincronizar ? "A sincronizar…" : "Sincronizar com o wger")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 11)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.gymAccent))
                                .foregroundStyle(.white)
                            }
                            .disabled(aSincronizar)
                            .accessibilityIdentifier("sincronizarWger")
                            if let mensagem {
                                Text(mensagem).font(.caption2).foregroundStyle(.gymMuted)
                            }
                        }
                    }

                    GymCard {
                        VStack(alignment: .leading, spacing: 5) {
                            SectionTitle(text: "Sobre")
                            Text("GymRank · projecto individual de Desenvolvimento para Dispositivos Móveis (MEI, ESTG/IPLeiria, 2026/2027).")
                                .font(.caption2).foregroundStyle(.gymMuted)
                            Text("Standards: Strength Level (2026). Catálogo: wger, CC-BY-SA 4.0. 1RM: Epley.")
                                .font(.caption2).foregroundStyle(.gymMuted)
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
            Text(titulo).font(.caption).foregroundStyle(.gymMuted)
            Spacer()
            Text(valor).font(.system(size: 13, weight: .semibold)).foregroundStyle(.white)
        }
    }

    /// Sincroniza o catálogo do wger; em falha mantém a base local (modo offline).
    private func sincronizar() async {
        aSincronizar = true
        mensagem = nil
        defer { aSincronizar = false }
        do {
            let remotos = try await WgerClient().fetchExercises()
            var novos = 0
            for remoto in remotos {
                if exercises.contains(where: { $0.wgerID == remoto.id }) { continue }
                let parte = WgerClient.bodyPart(for: remoto.category?.name)
                context.insert(Exercise(nome: remoto.nome,
                                        parte: parte,
                                        standardID: nil,
                                        wgerID: remoto.id,
                                        equipamento: remoto.equipamento,
                                        musculoPrincipal: remoto.musculoPrincipal))
                novos += 1
            }
            try? context.save()
            mensagem = "Sincronizados \(remotos.count) exercícios do wger (\(novos) novos)."
        } catch {
            mensagem = "Sem ligação ao wger — a usar a base local (\(error.localizedDescription))."
        }
    }
}
