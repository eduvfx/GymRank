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

    /// Semeia o catálogo com os exercícios que têm rank publicado (pacote incluído, offline).
    private func seedExercisesIfNeeded() {
        guard exercises.isEmpty else { return }
        for entry in StandardsData.all {
            context.insert(Exercise(nome: entry.nome, parte: entry.parte, standardID: entry.id))
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
