//
//  StandardsData.swift  —  GERADO POR Tools/gen_standards_swift.py
//  Não editar à mão: os valores vêm de Tools/standards.json (Strength Level, 2026).
//
//  Limiares em kg para o peso de referência (72 kg homens / 68 kg mulheres).
//  `exp` é o expoente de escala por peso corporal: limiar(BW) = limiar * (BW/BWref)^exp

import Foundation

/// Um exercício com os limiares publicados (Beginner, Novice, Intermediate, Advanced, Elite).
struct StandardEntry: Identifiable, Hashable {
    let id: String
    let nome: String
    let parte: BodyPart
    let exp: Double
    /// limiares masculinos em kg (5 valores publicados)
    let male: [Double]
    /// limiares femininos em kg (5 valores publicados)
    let female: [Double]
}

enum StandardsData {
    static let maleReferenceWeight: Double = 72
    static let femaleReferenceWeight: Double = 68

    static let all: [StandardEntry] = [
        StandardEntry(id: "bench-press", nome: "Bench Press", parte: .chest, exp: 0.222,
                      male: [49, 70, 96, 127, 160],
                      female: [19, 33, 51, 72, 97]),
        StandardEntry(id: "dumbbell-bench-press", nome: "Dumbbell Bench Press", parte: .chest, exp: 0.225,
                      male: [17, 26, 38, 53, 69],
                      female: [7, 13, 20, 30, 40]),
        StandardEntry(id: "incline-bench-press", nome: "Incline Bench Press", parte: .chest, exp: 0.235,
                      male: [43, 63, 86, 114, 144],
                      female: [15, 27, 43, 63, 85]),
        StandardEntry(id: "bent-over-row", nome: "Bent Over Row", parte: .back, exp: 0.994,
                      male: [43, 62, 87, 116, 147],
                      female: [24, 34, 48, 64, 82]),  // limiares femininos estimados (ver Tools/standards.json)
        StandardEntry(id: "deadlift", nome: "Deadlift", parte: .back, exp: 0.917,
                      male: [80, 113, 154, 202, 253],
                      female: [41, 63, 91, 124, 160]),
        StandardEntry(id: "lat-pulldown", nome: "Lat Pulldown", parte: .back, exp: 0.696,
                      male: [42, 60, 82, 107, 134],
                      female: [23, 34, 47, 63, 80]),
        StandardEntry(id: "seated-cable-row", nome: "Seated Cable Row", parte: .back, exp: 0.196,
                      male: [41, 60, 84, 112, 142],
                      female: [22, 33, 48, 65, 84]),
        StandardEntry(id: "dumbbell-lateral-raise", nome: "Dumbbell Lateral Raise", parte: .shoulders, exp: 0.219,
                      male: [4, 9, 16, 24, 34],
                      female: [2, 5, 9, 13, 19]),  // limiares femininos estimados (ver Tools/standards.json)
        StandardEntry(id: "dumbbell-shoulder-press", nome: "Dumbbell Shoulder Press", parte: .shoulders, exp: 0.237,
                      male: [13, 21, 30, 42, 55],
                      female: [7, 12, 17, 23, 31]),  // limiares femininos estimados (ver Tools/standards.json)
        StandardEntry(id: "shoulder-press", nome: "Shoulder Press", parte: .shoulders, exp: 0.224,
                      male: [29, 44, 62, 84, 107],
                      female: [16, 24, 34, 47, 59]),  // limiares femininos estimados (ver Tools/standards.json)
        StandardEntry(id: "barbell-curl", nome: "Barbell Curl", parte: .biceps, exp: 0.202,
                      male: [19, 30, 45, 62, 82],
                      female: [11, 17, 25, 34, 46]),  // limiares femininos estimados (ver Tools/standards.json)
        StandardEntry(id: "dumbbell-curl", nome: "Dumbbell Curl", parte: .biceps, exp: 0.198,
                      male: [7, 13, 21, 31, 42],
                      female: [4, 7, 12, 18, 25]),
        StandardEntry(id: "hammer-curl", nome: "Hammer Curl", parte: .biceps, exp: 0.234,
                      male: [9, 15, 23, 32, 43],
                      female: [5, 8, 12, 18, 23]),
        StandardEntry(id: "lying-tricep-extension", nome: "Lying Tricep Extension", parte: .triceps, exp: 1.199,
                      male: [15, 27, 43, 63, 86],
                      female: [7, 13, 21, 31, 42]),
        StandardEntry(id: "tricep-pushdown", nome: "Tricep Pushdown", parte: .triceps, exp: 0.904,
                      male: [19, 34, 54, 79, 107],
                      female: [9, 18, 30, 45, 62]),
        StandardEntry(id: "front-squat", nome: "Front Squat", parte: .legs, exp: 0.600,
                      male: [54, 77, 105, 137, 172],
                      female: [30, 43, 58, 76, 96]),  // limiares femininos estimados (ver Tools/standards.json)
        StandardEntry(id: "hip-thrust", nome: "Hip Thrust", parte: .legs, exp: 0.283,
                      male: [45, 85, 140, 208, 286],
                      female: [25, 47, 78, 116, 159]),  // limiares femininos estimados (ver Tools/standards.json)
        StandardEntry(id: "leg-extension", nome: "Leg Extension", parte: .legs, exp: 0.600,
                      male: [43, 68, 99, 137, 179],
                      female: [24, 38, 55, 76, 100]),  // limiares femininos estimados (ver Tools/standards.json)
        StandardEntry(id: "lying-leg-curl", nome: "Lying Leg Curl", parte: .legs, exp: 0.600,
                      male: [26, 43, 63, 89, 116],
                      female: [14, 24, 35, 49, 64]),  // limiares femininos estimados (ver Tools/standards.json)
        StandardEntry(id: "romanian-deadlift", nome: "Romanian Deadlift", parte: .legs, exp: 0.600,
                      male: [58, 87, 122, 164, 210],
                      female: [31, 48, 68, 93, 120]),
        StandardEntry(id: "sled-leg-press", nome: "Sled Leg Press", parte: .legs, exp: 0.600,
                      male: [96, 153, 227, 316, 414],
                      female: [53, 85, 126, 176, 230]),  // limiares femininos estimados (ver Tools/standards.json)
        StandardEntry(id: "squat", nome: "Squat", parte: .legs, exp: 0.221,
                      male: [66, 95, 131, 173, 219],
                      female: [32, 51, 76, 105, 137]),
        StandardEntry(id: "machine-calf-raise", nome: "Machine Calf Raise", parte: .calves, exp: 0.211,
                      male: [43, 82, 137, 205, 284],
                      female: [24, 46, 76, 114, 158]),  // limiares femininos estimados (ver Tools/standards.json)
    ]

    static func entry(id: String) -> StandardEntry? { all.first { $0.id == id } }
    static func entries(for part: BodyPart) -> [StandardEntry] { all.filter { $0.parte == part } }
}
