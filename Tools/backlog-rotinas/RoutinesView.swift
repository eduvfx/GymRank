//
//  RoutinesView.swift
//  GymRank
//
//  Separação "Rotinas": lista de rotinas, criação/edição e escolha de exercícios.
//

import SwiftUI
import SwiftData

/// Uma escolha de exercício dentro do editor de rotinas (valor imutável, não um modelo).
struct Escolha: Identifiable, Hashable {
    let id = UUID()
    let nome: String
    let standardID: String?
    let parte: BodyPart
}

struct RoutinesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Routine.ordem) private var rotinas: [Routine]
    @Query(sort: \RoutineItem.ordem) private var itens: [RoutineItem]
    @State private var criar = false

    var body: some View {
        ZStack {
            Color.gymBackground.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if rotinas.isEmpty {
                        GymCard {
                            VStack(alignment: .leading, spacing: 6) {
                                SectionTitle(text: "Ainda sem rotinas")
                                Text("Uma rotina é um conjunto de exercícios com séries e repetições-alvo. Cria a primeira e treina a partir dela.")
                                    .font(.caption).foregroundStyle(.gymMuted)
                            }
                        }
                    }
                    ForEach(rotinas) { rotina in
                        NavigationLink {
                            RoutineDetailView(rotina: rotina)
                        } label: {
                            cartao(rotina)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle("Rotinas")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { criar = true } label: { Image(systemName: "plus") }
                    .accessibilityIdentifier("novaRotina")
            }
        }
        .sheet(isPresented: $criar) {
            RoutineEditorView(rotina: nil)
        }
    }

    private func cartao(_ rotina: Routine) -> some View {
        let meus = itens.filter { $0.rotinaUID == rotina.uid }
        let series = meus.reduce(0) { $0 + $1.seriesAlvo }
        return GymCard {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(rotina.nome)
                        .font(.system(size: 16, weight: .bold)).foregroundStyle(.white)
                    Text(meus.isEmpty ? "sem exercícios" : "\(meus.count) exercícios · \(series) séries")
                        .font(.caption).foregroundStyle(.gymMuted)
                    if !rotina.notas.isEmpty {
                        Text(rotina.notas).font(.caption2).foregroundStyle(.gymMuted).lineLimit(1)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.gymMuted)
            }
        }
    }
}

// MARK: - Editor de rotina

struct RoutineEditorView: View {
    let rotina: Routine?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var todasRotinas: [Routine]
    @Query(sort: \RoutineItem.ordem) private var todosItens: [RoutineItem]
    @Query private var profiles: [UserProfile]

    @State private var nome = ""
    @State private var notas = ""
    @State private var series = 3
    @State private var reps = 8
    @State private var escolhas: [Escolha] = []
    @State private var escolherExercicio = false
    @State private var carregado = false

    private var descanso: Int { profiles.first?.descansoSegundos ?? 90 }

    var body: some View {
        NavigationStack {
            Form {
                Section("Rotina") {
                    TextField("Nome (ex.: Peito e tríceps)", text: $nome)
                        .accessibilityIdentifier("nomeRotina")
                    TextField("Notas (opcional)", text: $notas)
                }

                Section("Séries e repetições-alvo") {
                    Stepper("Séries: \(series)", value: $series, in: 1...8)
                    Stepper("Repetições: \(reps)", value: $reps, in: 1...30)
                    LabeledContent("Descanso", value: SessionEngine.formato(descanso))
                }

                Section("Exercícios (\(escolhas.count))") {
                    ForEach(escolhas) { escolha in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(escolha.nome).font(.system(size: 14, weight: .semibold))
                                Text(escolha.parte.nome).font(.caption2).foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                    }
                    .onDelete { indices in escolhas.remove(atOffsets: indices) }
                    .onMove { origem, destino in escolhas.move(fromOffsets: origem, toOffset: destino) }

                    Button("Adicionar exercício") { escolherExercicio = true }
                        .accessibilityIdentifier("adicionarExercicioRotina")
                }
            }
            .navigationTitle(rotina == nil ? "Nova rotina" : "Editar rotina")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { guardar() }
                        .disabled(nome.trimmingCharacters(in: .whitespaces).isEmpty || escolhas.isEmpty)
                        .accessibilityIdentifier("guardarRotina")
                }
            }
            .sheet(isPresented: $escolherExercicio) {
                NavigationStack {
                    ExercicioPickerList { exercicio in
                        escolhas.append(Escolha(nome: exercicio.nome, standardID: exercicio.standardID, parte: exercicio.parte))
                        escolherExercicio = false
                    }
                    .navigationTitle("Exercícios")
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
            .onAppear(perform: carregar)
        }
    }

    private func carregar() {
        guard !carregado else { return }
        carregado = true
        guard let rotina else { return }
        nome = rotina.nome
        notas = rotina.notas
        let meus = todosItens.filter { $0.rotinaUID == rotina.uid }
        escolhas = meus.map { Escolha(nome: $0.exercicioNome, standardID: $0.standardID, parte: $0.parte) }
        if let primeiro = meus.first {
            series = primeiro.seriesAlvo
            reps = primeiro.repsAlvo
        }
    }

    private func guardar() {
        let alvo: Routine
        if let rotina {
            alvo = rotina
            alvo.nome = nome
            alvo.notas = notas
            for item in todosItens where item.rotinaUID == rotina.uid { context.delete(item) }
        } else {
            alvo = Routine(nome: nome, notas: notas, ordem: (todasRotinas.map(\.ordem).max() ?? 0) + 1)
            context.insert(alvo)
        }
        for (indice, escolha) in escolhas.enumerated() {
            let item = RoutineItem(rotinaUID: alvo.uid, standardID: escolha.standardID,
                                   exercicioNome: escolha.nome, parte: escolha.parte,
                                   ordem: indice, seriesAlvo: series, repsAlvo: reps,
                                   descansoSegundos: descanso)
            context.insert(item)
        }
        try? context.save()
        dismiss()
    }
}

// MARK: - Lista de exercícios do catálogo (reutilizada no treino)

struct ExercicioPickerList: View {
    let onEscolher: (Exercise) -> Void

    @Query(sort: \Exercise.nome) private var exercicios: [Exercise]
    @State private var busca = ""

    private var filtrados: [Exercise] {
        guard !busca.isEmpty else { return exercicios }
        return exercicios.filter { $0.nome.localizedCaseInsensitiveContains(busca) }
    }

    var body: some View {
        List {
            ForEach(filtrados) { exercicio in
                Button {
                    onEscolher(exercicio)
                } label: {
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(exercicio.nome).font(.system(size: 14, weight: .semibold))
                            Text(exercicio.parte.nome + (exercicio.standardID == nil ? " · sem rank" : ""))
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "plus.circle").foregroundStyle(.tint)
                    }
                }
            }
        }
        .searchable(text: $busca, prompt: "Procurar exercício")
    }
}
