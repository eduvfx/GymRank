//
//  HistoryView.swift
//  GymRank
//
//  Histórico de treinos: listar, ver e apagar registos (CRUD).
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    let profile: UserProfile

    @Environment(\.modelContext) private var context
    @Query(sort: \WorkoutSet.data, order: .reverse) private var sets: [WorkoutSet]
    @Query private var exercises: [Exercise]

    private func nome(de set: WorkoutSet) -> String {
        exercises.first { $0.standardID == set.standardID }?.nome ?? set.exercicioID
    }

    private func posicao(de set: WorkoutSet) -> RankPosition? {
        guard let standard = exercises.first(where: { $0.standardID == set.standardID })?.standard else { return nil }
        let t = RankEngine.thresholds(entry: standard, sexo: profile.sexo,
                                      pesoKg: profile.pesoKg, idade: profile.idade)
        guard !t.isEmpty else { return nil }
        return t.position(forUMRM: set.umRM)
    }

    var body: some View {
        ZStack {
            Color.gymBackground.ignoresSafeArea()
            if sets.isEmpty {
                VStack(spacing: 8) {
                    Text("Ainda não há treinos").font(.headline).foregroundStyle(.white)
                    Text("Regista a primeira série no separador Painel.")
                        .font(.caption).foregroundStyle(.gymMuted)
                }
            } else {
                List {
                    ForEach(sets) { item in
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(nome(de: item))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.white)
                                Text("\(String(format: "%.1f", item.pesoKg)) kg × \(item.reps) × \(item.series) · "
                                     + item.data.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption2).foregroundStyle(.gymMuted)
                                Text("1RM \(String(format: "%.1f", item.umRM)) kg")
                                    .font(.caption2).foregroundStyle(.gymMuted)
                            }
                            Spacer()
                            if let p = posicao(de: item) { RankBadge(position: p, compact: true) }
                        }
                        .listRowBackground(Color.gymCard)
                    }
                    .onDelete { indexSet in
                        for index in indexSet { context.delete(sets[index]) }
                        try? context.save()
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color.gymBackground)
            }
        }
        .navigationTitle("Treinos")
        .navigationBarTitleDisplayMode(.inline)
    }
}
