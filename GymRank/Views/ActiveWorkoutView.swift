//
//  ActiveWorkoutView.swift
//  GymRank
//
//  Treino em tempo real: uma linha por série, 1RM ao vivo, descanso e submissão.
//

import SwiftUI
import SwiftData
import Combine

/// Agrupamento das séries da sessão por exercício.
struct GrupoSeries: Identifiable {
    let nome: String
    let parte: BodyPart
    var id: String { nome }
    let series: [SerieSessao]
}

struct ActiveWorkoutView: View {
    let sessao: TrainingSession

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var series: [SerieSessao]
    @Query private var perfis: [UserProfile]

    @StateObject private var descanso = RestTimer()
    @State private var mostrarCatalogo = false
    @State private var decorrido: Int = 0

    init(sessao: TrainingSession) {
        self.sessao = sessao
        let uid = sessao.uid
        _series = Query(filter: #Predicate<SerieSessao> { $0.sessaoUID == uid },
                        sort: [SortDescriptor(\SerieSessao.ordem)])
    }

    private var descansoPadrao: Int { perfis.first?.descansoSegundos ?? 90 }
    private var concluidas: [Bool] { series.map { $0.concluida } }
    private var progresso: Double { SessionEngine.progresso(concluidas) }
    private var podeSubmeter: Bool { SessionEngine.podeSubmeter(concluidas) }
    private var feitas: Int { concluidas.filter { $0 }.count }

    private var grupos: [GrupoSeries] {
        var ordem: [String] = []
        var mapa: [String: [SerieSessao]] = [:]
        for serie in series {
            if mapa[serie.exercicioNome] == nil { ordem.append(serie.exercicioNome) }
            mapa[serie.exercicioNome, default: []].append(serie)
        }
        return ordem.map { nome in
            let lista = mapa[nome] ?? []
            return GrupoSeries(nome: nome, parte: lista.first?.parte ?? .chest, series: lista)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.gymBackground.ignoresSafeArea()
                ScrollView { conteudo.padding(16) }
            }
            .safeAreaInset(edge: .bottom) { rodape }
            .navigationTitle(sessao.rotinaNome)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fechar") { fechar() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { mostrarCatalogo = true } label: { Image(systemName: "plus.circle") }
                        .accessibilityIdentifier("acrescentarExercicio")
                }
            }
            .sheet(isPresented: $mostrarCatalogo) {
                CatalogoTreinoSheet(sessao: sessao, descanso: descansoPadrao)
            }
            .onAppear { decorrido = Int(Date.now.timeIntervalSince(sessao.inicio)) }
            .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
                decorrido = Int(Date.now.timeIntervalSince(sessao.inicio))
            }
        }
    }

    // MARK: - Blocos separados (evita expressões grandes para o type-checker)

    private var conteudo: some View {
        VStack(alignment: .leading, spacing: 12) {
            cabecalho
            ForEach(grupos) { grupo in
                bloco(grupo)
            }
            if series.isEmpty {
                aviso
            }
        }
    }

    private var aviso: some View {
        GymCard {
            Text("Sem séries nesta sessão. Usa o + para acrescentar exercícios.")
                .font(.caption).foregroundStyle(Color.gymMuted)
        }
    }

    private var cabecalho: some View {
        GymCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(SessionEngine.formato(decorrido))
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                    Spacer()
                    Text("\(feitas)/\(series.count) séries")
                        .font(.caption).foregroundStyle(Color.gymMuted)
                }
                ProgressView(value: progresso)
                    .tint(Color.gymAccent)
            }
        }
    }

    private func bloco(_ grupo: GrupoSeries) -> some View {
        GymCard {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(grupo.nome)
                            .font(.system(size: 14, weight: .bold)).foregroundStyle(.white)
                        Text(grupo.parte.nome).font(.caption2).foregroundStyle(Color.gymMuted)
                    }
                    Spacer()
                    if let melhor = melhor1RM(grupo) {
                        Text("1RM \(String(format: "%.0f", melhor)) kg")
                            .font(.caption2).foregroundStyle(Color.gymMuted)
                    }
                }
                ForEach(grupo.series) { serie in
                    SerieLinha(serie: serie) { descanso.iniciar(segundos: descansoPadrao) }
                }
            }
        }
    }

    private func melhor1RM(_ grupo: GrupoSeries) -> Double? {
        let valores = grupo.series.map { $0.umRM }.filter { $0 > 0 }
        return valores.max()
    }

    private var rodape: some View {
        VStack(spacing: 8) {
            if descanso.ativo { barraDescanso }
            botaoSubmeter
        }
        .padding(12)
        .background(.ultraThinMaterial)
    }

    private var botaoSubmeter: some View {
        Button { submeter() } label: {
            Text("Submeter treino")
                .font(.system(size: 15, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(RoundedRectangle(cornerRadius: 13).fill(Color.gymAccent))
                .foregroundStyle(.white)
        }
        .disabled(!podeSubmeter)
        .opacity(podeSubmeter ? 1 : 0.45)
        .accessibilityIdentifier("submeterTreino")
    }

    private var barraDescanso: some View {
        HStack(spacing: 10) {
            Text(SessionEngine.formato(descanso.restante))
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(Color.gymAccent)
            ProgressView(value: descanso.fracao)
                .tint(Color.gymAccent)
            Button("+15") { descanso.acrescentar(15) }
                .font(.caption.bold())
            Button("saltar") { descanso.parar() }
                .font(.caption)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.gymCard))
    }

    // MARK: - Ações

    private func fechar() {
        descanso.parar()
        dismiss()
    }

    private func submeter() {
        descanso.parar()
        for serie in series where serie.concluida {
            context.insert(WorkoutSet(exercicioID: serie.standardID,
                                      standardID: serie.standardID,
                                      pesoKg: serie.pesoKg,
                                      reps: max(1, serie.reps),
                                      series: 1,
                                      data: sessao.inicio,
                                      umRM: serie.umRM))
        }
        sessao.fim = .now
        sessao.concluida = true
        try? context.save()
        dismiss()
    }
}

/// Linha editável de uma série.
struct SerieLinha: View {
    @Bindable var serie: SerieSessao
    let onConcluir: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            numero
            campoPeso
            campoReps
            valor1RM
            Spacer()
            botaoConcluir
        }
    }

    private var numero: some View {
        Text("\(serie.numero)")
            .font(.caption2.bold())
            .foregroundStyle(Color.gymMuted)
            .frame(width: 14)
    }

    private var campoPeso: some View {
        TextField("kg", value: $serie.pesoKg, format: .number.precision(.fractionLength(0...2)))
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.center)
            .font(.system(size: 13, weight: .semibold))
            .padding(.vertical, 5)
            .frame(width: 58)
            .background(RoundedRectangle(cornerRadius: 7).fill(Color.white.opacity(0.07)))
            .foregroundStyle(.white)
    }

    private var campoReps: some View {
        TextField("reps", value: $serie.reps, format: .number)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .font(.system(size: 13, weight: .semibold))
            .padding(.vertical, 5)
            .frame(width: 48)
            .background(RoundedRectangle(cornerRadius: 7).fill(Color.white.opacity(0.07)))
            .foregroundStyle(.white)
    }

    private var valor1RM: some View {
        Text(serie.umRM > 0 ? String(format: "%.0f", serie.umRM) : "—")
            .font(.caption2)
            .foregroundStyle(Color.gymMuted)
            .frame(width: 26)
    }

    private var botaoConcluir: some View {
        Button {
            serie.concluida.toggle()
            if serie.concluida {
                serie.recalcular1RM()
                onConcluir()
            }
        } label: {
            Image(systemName: serie.concluida ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 20))
                .foregroundStyle(serie.concluida ? Color.green : Color.gymMuted)
        }
        .buttonStyle(.plain)
    }
}

/// Catálogo para acrescentar exercícios a meio do treino, incluindo por fotografia.
struct CatalogoTreinoSheet: View {
    let sessao: TrainingSession
    let descanso: Int

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var series: [SerieSessao]
    @State private var foto = false

    init(sessao: TrainingSession, descanso: Int) {
        self.sessao = sessao
        self.descanso = descanso
        let uid = sessao.uid
        _series = Query(filter: #Predicate<SerieSessao> { $0.sessaoUID == uid })
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                botaoFoto
                ExercicioPickerList { exercicio in
                    adicionar(nome: exercicio.nome,
                              standardID: exercicio.standardID,
                              parte: exercicio.parte)
                    dismiss()
                }
            }
            .navigationTitle("Acrescentar exercício")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fechar") { dismiss() }
                }
            }
            .sheet(isPresented: $foto) {
                PhotoExerciseView { nome, standardID, parte in
                    adicionar(nome: nome, standardID: standardID, parte: parte)
                    foto = false
                    dismiss()
                }
            }
        }
    }

    private var botaoFoto: some View {
        Button { foto = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "camera.fill")
                Text("Adicionar por fotografia da máquina")
                    .font(.system(size: 14, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.gymAccent))
            .foregroundStyle(.white)
        }
        .padding(12)
        .accessibilityIdentifier("adicionarPorFoto")
    }

    private func adicionar(nome: String, standardID: String, parte: BodyPart) {
        let base = series.count
        for numero in 1...3 {
            context.insert(SerieSessao(sessaoUID: sessao.uid,
                                       standardID: standardID,
                                       exercicioNome: nome,
                                       parte: parte,
                                       ordem: base + numero,
                                       numero: numero))
        }
        try? context.save()
    }
}
