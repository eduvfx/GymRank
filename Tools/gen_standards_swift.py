#!/usr/bin/env python3
"""Gera GymRank/Engine/StandardsData.swift a partir de Tools/standards.json.

A app consome os standards do Strength Level já extraídos (kg, por sexo), com o
expoente de escala por peso corporal ajustado por regressão em log-log.
Correr:  python Tools/gen_standards_swift.py
"""
import json, os, collections

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
DATA = os.path.join(HERE, 'standards.json')
OUT = os.path.join(ROOT, 'GymRank', 'Engine', 'StandardsData.swift')

d = json.load(open(DATA, encoding='utf-8'))

# ordem fixa das partes do corpo (taxonomia usada na app)
PARTS = ['Chest', 'Back', 'Shoulders', 'Biceps', 'Triceps', 'Legs', 'Calves', 'Core']
PT = {'Chest': 'Peito', 'Back': 'Costas', 'Shoulders': 'Ombros', 'Biceps': 'Bíceps',
      'Triceps': 'Tríceps', 'Legs': 'Pernas', 'Calves': 'Gémeos', 'Core': 'Core'}

rows = []
def _ordem(kv):
    v = kv[1]
    parte = v.get('parte_corpo', '')
    return (PARTS.index(parte) if parte in PARTS else 99, kv[0])

for slug, v in sorted(((k, x) for k, x in d.items() if not k.startswith('_')), key=_ordem):
    m, f = v.get('limiares_homem') or {}, v.get('limiares_mulher') or {}
    if not m:
        continue
    rows.append(dict(
        id=slug, nome=v['nome'], parte=v['parte_corpo'], partePT=PT.get(v['parte_corpo'], v['parte_corpo']),
        exp=v.get('expoente_bw') or 0.60,
        fem_estimado=bool(v.get('limiares_mulher_estimado')),
        m=[m['beginner'], m['novice'], m['intermediate'], m['advanced'], m['elite']],
        f=[f.get('beginner', 0), f.get('novice', 0), f.get('intermediate', 0), f.get('advanced', 0), f.get('elite', 0)]
          if f else [0, 0, 0, 0, 0],
    ))

lines = []
lines.append('//')
lines.append('//  StandardsData.swift  —  GERADO POR Tools/gen_standards_swift.py')
lines.append('//  Não editar à mão: os valores vêm de Tools/standards.json (Strength Level, 2026).')
lines.append('//')
lines.append('//  Limiares em kg para o peso de referência (72 kg homens / 68 kg mulheres).')
lines.append('//  `exp` é o expoente de escala por peso corporal: limiar(BW) = limiar * (BW/BWref)^exp')
lines.append('')
lines.append('import Foundation')
lines.append('')
lines.append('/// Um exercício com os limiares publicados (Beginner, Novice, Intermediate, Advanced, Elite).')
lines.append('struct StandardEntry: Identifiable, Hashable {')
lines.append('    let id: String')
lines.append('    let nome: String')
lines.append('    let parte: BodyPart')
lines.append('    let exp: Double')
lines.append('    /// limiares masculinos em kg (5 valores publicados)')
lines.append('    let male: [Double]')
lines.append('    /// limiares femininos em kg (5 valores publicados)')
lines.append('    let female: [Double]')
lines.append('}')
lines.append('')
lines.append('enum StandardsData {')
lines.append('    static let maleReferenceWeight: Double = 72')
lines.append('    static let femaleReferenceWeight: Double = 68')
lines.append('')
lines.append('    static let all: [StandardEntry] = [')
for r in rows:
    ms = ', '.join(f'{x:.0f}' for x in r['m'])
    fs = ', '.join(f'{x:.0f}' for x in r['f'])
    nota = ''  # marca os limiares femininos estimados (ver Tools/standards.json)
    if r.get('fem_estimado'):
        nota = '  // limiares femininos estimados (ver Tools/standards.json)'
    lines.append(f'        StandardEntry(id: "{r["id"]}", nome: "{r["nome"]}", parte: .{r["parte"].lower()}, '
                 f'exp: {r["exp"]:.3f},\n'
                 f'                      male: [{ms}],\n'
                 f'                      female: [{fs}]),{nota}')
lines.append('    ]')
lines.append('')
lines.append('    static func entry(id: String) -> StandardEntry? { all.first { $0.id == id } }')
lines.append('    static func entries(for part: BodyPart) -> [StandardEntry] { all.filter { $0.parte == part } }')
lines.append('}')
lines.append('')

os.makedirs(os.path.dirname(OUT), exist_ok=True)
open(OUT, 'w', encoding='utf-8').write('\n'.join(lines))
print(f'{len(rows)} exercícios -> {OUT}')
contagem = collections.Counter(r['parte'] for r in rows)
print('por parte:', dict(contagem))
