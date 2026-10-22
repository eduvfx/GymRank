//
//  RoutineDetailView.swift
//  GymRank
//
//  Detalhe de uma rotina e arranque do treino em tempo real.
//

import SwiftUI
import SwiftData

struct RoutineDetailView: View {
    let rotina: Routine

    @Environment(\.modelContext) private var context
    @Query(sort: \RoutineItem.ordem) private var todosItens: [RoutineItem]
    @Query private var profiles: [UserProfile]
    @State private var sessaoAtiva: TrainingSession?
    @State private var editar = false

    private var itens: [RoutineItem] { todosItens.filter { $0.rotinaUID == rotina.uid } }
    private var descanso: Int { profiles.first?.descansoSegundos ?? 90 }
    private var totalSeries: Int { itens.reduce(0) { $0 + $1.seriesAlvo } }

    var body: some View {
        ZStack {
            Color.gymBackground.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    GymCard {
                        VStack(alignment: .leading, spacing: 5) {
                            SectionTitle(text: rotina.nome)
                            Text("\(itens.count) exercícios · \(totalSeries) séries · descanso \(SessionEngine.formato(descanso))")
                                .font(.caption).foregroundStyle(.gymMuted)
                            if !rotina.notas.isEmpty {
                                Text(rotina.notas).font(.caption2).foregroundStyle(.gymMuted)
                            }
                        }
                    }

                    ForEach(Array(itens.enumerated()), id: \.element.id) { indice, item in
                        GymCard {
                            HStack(spacing: 10) {
                                Text("\(indice + 1)")
                                    .font(.caption.bold()).foregroundStyle(.gymMuted)
                                    .frame(width: 18)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(item.exercicioNome)
                                        .font(.system(size: 15, weight: .semibold)).foregroundStyle(.white)
                                    Text("\(item.parte.nome) · \(item.seriesAlvo) × \(item.repsAlvo)")
                                        .font(.caption2).foregroundStyle(.gymMuted)
                                }
                                Spacer()
                            }
                        }
                    }

                    Button { comecar() } label: {
                        Text("Começar treino")
                            .font(.system(size: 15, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(RoundedRectangle(cornerRadius: 13).fill(Color.gymAccent))
                            .foregroundStyle(.white)
                    }
                    .disabled(itens.isEmpty)
                    .accessibilityIdentifier("comecarTreino")

                    Button { editar = true } label: {
                        Text("Editar rotina")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.gymCard))
                            .foregroundStyle(.white)
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle("Rotina")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $editar) { RoutineEditorView(rotina: rotina) }
        .fullScreenCover(item: $sessaoAtiva) { sessao in
            ActiveWorkoutView(sessao: sessao)
        }
    }

    /// Cria a sessão e uma linha por série-alvo, para o registo em tempo real.
    private func comecar() {
        let sessao = TrainingSession(rotinaNome: rotina.nome)
        context.insert(sessao)
        var ordem = 0
        for item in itens {
            for numero in 1...max(1, item.seriesAlvo) {
                ordem += 1
                context.insert(SerieSessao(sessaoUID: sessao.uid,
                                           standardID: item.standardID,
                                           exercicioNome: item.exercicioNome,
                                           parte: item.parte,
                                           ordem: ordem,
                                           numero: numero))
            }
        }
        try? context.save()
        sessaoAtiva = sessao
    }
}
