//
//  GymRankApp.swift
//  GymRank
//
//  Ponto de entrada. Cria o contentor SwiftData com o perfil, o catálogo de
//  exercícios e as séries registadas.
//

import SwiftUI
import SwiftData

@main
struct GymRankApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [UserProfile.self, Exercise.self, WorkoutSet.self])
    }
}
