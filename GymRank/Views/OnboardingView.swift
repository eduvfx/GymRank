//
//  OnboardingView.swift
//  GymRank
//
//  Recolha obrigatória da idade e do peso — sem estes dados não há cálculo de rank.
//

import SwiftUI
import SwiftData

struct OnboardingView: View {
    let existing: UserProfile?

    @Environment(\.modelContext) private var context
    @State private var nome: String = ""
    @State private var idade: Int = 24
    @State private var peso: Double = 80
    @State private var altura: Double = 178
    @State private var sexo: Sex = .masculino

    private var idadeValida: Bool { (14...99).contains(idade) }
    private var pesoValido: Bool { (30...250).contains(peso) }

    var body: some View {
        ZStack {
            Color.gymBackground.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("🏋️").font(.system(size: 46))
                        Text("GymRank")
                            .font(.system(size: 30, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Regista os teus treinos e sobe de rank. Do Bronze ao Olympia — como num videojogo.")
                            .font(.subheadline)
                            .foregroundStyle(Color.gymMuted)
                    }
                    .padding(.bottom, 6)

                    SectionTitle(text: "Dados obrigatórios para o cálculo do rank")

                    GymCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Nome (opcional)")
                                .font(.system(size: 10, weight: .semibold)).kerning(0.8)
                                .foregroundStyle(Color.gymMuted)
                            TextField("O teu nome", text: $nome)
                                .textFieldStyle(.plain)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                    }

                    GymCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Idade").font(.system(size: 10, weight: .semibold)).kerning(0.8).foregroundStyle(Color.gymMuted)
                            Stepper(value: $idade, in: 14...99) {
                                Text("\(idade) anos")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                            .accessibilityIdentifier("stepperIdade")
                        }
                    }

                    GymCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Peso corporal").font(.system(size: 10, weight: .semibold)).kerning(0.8).foregroundStyle(Color.gymMuted)
                            Stepper(value: $peso, in: 30...250, step: 0.5) {
                                Text(String(format: "%.1f kg", peso))
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                            .accessibilityIdentifier("stepperPeso")
                        }
                    }

                    GymCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Altura").font(.system(size: 10, weight: .semibold)).kerning(0.8).foregroundStyle(Color.gymMuted)
                            Stepper(value: $altura, in: 120...230, step: 1) {
                                Text(String(format: "%.0f cm", altura))
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                    }

                    GymCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Sexo (muda as tabelas de referência)")
                                .font(.system(size: 10, weight: .semibold)).kerning(0.8)
                                .foregroundStyle(Color.gymMuted)
                            Picker("Sexo", selection: $sexo) {
                                ForEach(Sex.allCases) { Text($0.nome).tag($0) }
                            }
                            .pickerStyle(.segmented)
                            .accessibilityIdentifier("pickerSexo")
                        }
                    }

                    Text("A idade e o peso definem contra que população te comparas: os limites de cada rank são relativos ao teu peso corporal e ajustados à tua faixa de idade.")
                        .font(.caption)
                        .foregroundStyle(Color.gymMuted)

                    Button {
                        guardar()
                    } label: {
                        Text("Guardar perfil")
                            .font(.system(size: 16, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color.gymAccent))
                            .foregroundStyle(.white)
                    }
                    .disabled(!idadeValida || !pesoValido)
                    .accessibilityIdentifier("guardarPerfil")
                    .padding(.top, 4)
                }
                .padding(18)
            }
        }
        .onAppear {
            if let existing {
                nome = existing.nome
                idade = existing.idade
                peso = existing.pesoKg
                altura = existing.alturaCm
                sexo = existing.sexo
            }
        }
    }

    private func guardar() {
        if let existing {
            existing.nome = nome
            existing.idade = idade
            existing.pesoKg = peso
            existing.alturaCm = altura
            existing.sexo = sexo
        } else {
            context.insert(UserProfile(nome: nome, idade: idade, pesoKg: peso, alturaCm: altura, sexo: sexo))
        }
        try? context.save()
    }
}
