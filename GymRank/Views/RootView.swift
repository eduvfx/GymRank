//
//  RootView.swift
//  GymRank
//
//  Decide entre o assistente de perfil (primeiro arranque) e o separador principal,
//  e semeia o catálogo de exercícios na primeira execução.
//

import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Query private var profiles: [UserProfile]
    @Query private var exercises: [Exercise]

    var body: some View {
        Group {
            if let profile = profiles.first, profile.isComplete {
                MainTabView(profile: profile)
            } else {
                OnboardingView(existing: profiles.first)
            }
        }
        .preferredColorScheme(.dark)
        .tint(Color.gymAccent)
        .task { seedExercisesIfNeeded() }
    }

    /// Semeia o catálogo a partir do pacote de standards (offline, arranque imediato).
    private func seedExercisesIfNeeded() {
        guard exercises.isEmpty else { return }
        for entry in StandardsData.all {
            context.insert(Exercise(nome: entry.nome, parte: entry.parte, standardID: entry.id))
        }
        // exercícios de peso corporal, sem standard em kg (rank por repetições, fase seguinte)
        let bodyweight: [(String, BodyPart)] = [
            ("Push Ups", .chest), ("Dips", .chest), ("Pull Ups", .back),
            ("Chin Ups", .back), ("Crunches", .core), ("Sit Ups", .core)
        ]
        for (nome, parte) in bodyweight {
            context.insert(Exercise(nome: nome, parte: parte))
        }
        try? context.save()
    }
}

struct MainTabView: View {
    let profile: UserProfile

    var body: some View {
        TabView {
            NavigationStack {
                DashboardView(profile: profile)
            }
            .tabItem { Label("Painel", systemImage: "circle.hexagongrid.fill") }

            NavigationStack {
                HistoryView(profile: profile)
            }
            .tabItem { Label("Treinos", systemImage: "dumbbell.fill") }

            NavigationStack {
                ProgressTabView(profile: profile)
            }
            .tabItem { Label("Progresso", systemImage: "chart.bar.fill") }

            NavigationStack {
                ProfileView(profile: profile)
            }
            .tabItem { Label("Perfil", systemImage: "person.crop.circle") }
        }
    }
}
