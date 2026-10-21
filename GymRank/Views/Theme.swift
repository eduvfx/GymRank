//
//  Theme.swift
//  GymRank
//
//  Linguagem visual: fundo escuro, uma cor por rank e cartões arredondados.
//

import SwiftUI

extension Color {
    init(hex: String) {
        let clean = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: clean).scanHexInt64(&value)
        let r = Double((value & 0xFF0000) >> 16) / 255
        let g = Double((value & 0x00FF00) >> 8) / 255
        let b = Double(value & 0x0000FF) / 255
        self.init(red: r, green: g, blue: b)
    }

    static let gymBackground = Color(hex: "0B0E14")
    static let gymCard = Color(hex: "161B26")
    static let gymCard2 = Color(hex: "1D2432")
    static let gymLine = Color(hex: "2A3345")
    static let gymMuted = Color(hex: "93A0B5")
    static let gymAccent = Color(hex: "4C8DFF")
}

extension Rank {
    var color: Color { Color(hex: hex) }
}

/// Selo da posição na escada (ex.: "DIAMANTE 2" ou "OLYMPIA").
struct RankBadge: View {
    let position: RankPosition
    var compact: Bool = false

    var body: some View {
        Text(position.nome.uppercased())
            .font(.system(size: compact ? 8.5 : 11, weight: .heavy, design: .rounded))
            .kerning(0.5)
            .foregroundStyle(position.rank.color)
            .padding(.horizontal, compact ? 7 : 10)
            .padding(.vertical, compact ? 2 : 4)
            .background(Capsule().fill(position.rank.color.opacity(0.14)))
            .overlay(Capsule().stroke(position.rank.color.opacity(0.45), lineWidth: 1))
    }
}

/// Anel de progresso do rank geral. No Olympia mostra os pontos acumulados.
struct RankRing: View {
    let position: RankPosition?
    let progress: Double
    var points: Int? = nil
    var caption: String = "rank geral do corpo"

    var body: some View {
        ZStack {
            Circle().stroke(Color.gymLine, lineWidth: 14)
            Circle()
                .trim(from: 0, to: position?.isOlympia == true ? 1 : max(0.02, min(1, progress)))
                .stroke(position?.rank.color ?? Color.gymLine,
                        style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 1) {
                Text(position?.rank.nome ?? "—")
                    .font(.system(size: 19, weight: .heavy, design: .rounded))
                    .foregroundStyle(position?.rank.color ?? .gymMuted)
                if let position, !position.isOlympia {
                    Text("divisão \(position.division)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(position.rank.color.opacity(0.85))
                }
                if let points, position?.isOlympia == true {
                    Text("\(points) pts")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(position?.rank.color ?? .gymMuted)
                }
                Text(caption)
                    .font(.system(size: 8.5))
                    .foregroundStyle(.gymMuted)
            }
        }
        .frame(width: 150, height: 150)
    }
}

/// Barra fina de progresso para o nível seguinte.
struct RankProgressBar: View {
    let position: RankPosition?
    let progress: Double
    var height: CGFloat = 7

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.gymLine)
                Capsule()
                    .fill(position?.rank.color ?? Color.gymAccent)
                    .frame(width: position?.isOlympia == true
                           ? geo.size.width
                           : max(4, geo.size.width * max(0, min(1, progress))))
            }
        }
        .frame(height: height)
    }
}

/// Cartão padrão da aplicação.
struct GymCard<Content: View>: View {
    var padding: CGFloat = 14
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.gymCard))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.gymLine, lineWidth: 1))
    }
}

struct SectionTitle: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .kerning(0.9)
            .foregroundStyle(.gymMuted)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
