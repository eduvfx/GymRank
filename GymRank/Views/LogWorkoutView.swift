//
//  LogWorkoutView.swift
//  GymRank
//
//  Registo de uma série com o 1RM estimado e a posição na escada ao vivo.
//

import SwiftUI
import SwiftData

struct LogWorkoutView: View {
    let profile: UserProfile
    let exercises: [Exercise]
    let preselect: Exercise?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var selecionado: String = ""
    @State private var peso: Double = 60
    @State private var reps: Int = 5
    @State private var series: Int = 3

    private var comStandard: [Exercise] {
        exercises.filter { $0.standard != nil }.sorted { $0.nome < $1.nome }
    }

    private var exercicio: Exercise? {
        comStandard.first { $0.standardID == selecionado }
    }

    private var umRM: Double { RankEngine.oneRepMax(pesoKg: peso, reps: reps) }

    private var limiares: RankThresholds? {
        guard let standard = exercicio?.standard else { return nil }
        let t = RankEngine.thresholds(entry: standard, sexo: profile.sexo,
                                      pesoKg: profile.pesoKg, idade: profile.idade)
        return t.isEmpty ? nil : t
    }

    private var posicaoPrevista: RankPosition? {
        limiares.map { $0.position(forUMRM: umRM) }
    }

    private var pontosPrevistos: Int? {
        guard let limiares, let posicaoPrevista, posicaoPrevista.isOlympia else { return nil }
        return limiares.olympiaPoints(forUMRM: umRM)
    }

    var body: some View {
        ZStack {
            Color.gymBackground.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    GymCard {
                        VStack(alignment: .leading, spacing: 6) {
                            SectionTitle(text: "Exercício")
                            Picker("Exercício", selection: $selecionado) {
                                ForEach(comStandard) { ex in
                                    Text(ex.nome).tag(ex.standardID)
                                }
                            }
                            .pickerStyle(.menu)
                            .accessibilityIdentifier("pickerExercicio")
                        }
                    }

                    GymCard {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionTitle(text: "Peso")
                            Stepper(value: $peso, in: 0...500, step: 0.5) {
                                Text(String(format: "%.1f kg", peso))
                                    .font(.system(size: 18, weight: .bold)).foregroundStyle(.white)
                            }
                            .accessibilityIdentifier("stepperPesoLevantado")
                        }
                    }

                    GymCard {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionTitle(text: "Repetições")
                            Stepper(value: $reps, in: 1...30) {
                                Text("\(reps)").font(.system(size: 18, weight: .bold)).foregroundStyle(.white)
                            }
                            .accessibilityIdentifier("stepperReps")
                        }
                    }

                    GymCard {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionTitle(text: "Séries")
                            Stepper(value: $series, in: 1...20) {
                                Text("\(series)").font(.system(size: 18, weight: .bold)).foregroundStyle(.white)
                            }
                            .accessibilityIdentifier("stepperSeries")
                        }
                    }

                    GymCard {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionTitle(text: "1RM estimado (Epley) — ao vivo")
                            HStack {
                                Text(String(format: "%.1f kg", umRM))
                                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                                    .foregroundStyle(.white)
                                Spacer()
                                if let posicaoPrevista { RankBadge(position: posicaoPrevista) }
                            }
                            if let pontosPrevistos {
                                Text("\(pontosPrevistos) pontos no Olympia — os pontos sobem sem tecto.")
                                    .font(.caption2).foregroundStyle(Color.gymMuted)
                            } else if let limiares, let posicaoPrevista,
                                      let next = limiares.kilosToNext(value: umRM) {
                                Text("Faltam \(String(format: "%.1f", next.falta)) kg para \(next.next.nome).")
                                    .font(.caption2).foregroundStyle(Color.gymMuted)
                            }
                            Text("1RM = peso × (1 + reps/30). Guardar actualiza o exercício, a parte do corpo e o rank geral.")
                                .font(.caption2).foregroundStyle(Color.gymMuted)
                        }
                    }

                    Button {
                        guardar()
                    } label: {
                        Text("Guardar treino")
                            .font(.system(size: 16, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color.gymAccent))
                            .foregroundStyle(.white)
                    }
                    .disabled(exercicio == nil)
                    .accessibilityIdentifier("guardarTreino")
                }
                .padding(16)
            }
        }
        .navigationTitle("Registar treino")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let preselect, let id = preselect.standardID {
                selecionado = id
            } else if selecionado.isEmpty, let first = comStandard.first?.standardID {
                selecionado = first
            }
        }
    }

    private func guardar() {
        guard let exercicio, let standardID = exercicio.standardID else { return }
        context.insert(WorkoutSet(exercicioID: standardID,
                                  standardID: standardID,
                                  pesoKg: peso,
                                  reps: reps,
                                  series: series))
        try? context.save()
        dismiss()
    }
}
