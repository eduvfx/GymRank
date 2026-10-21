#!/usr/bin/env python3
"""Recolhe os standards de força do Strength Level para Tools/standards.json.

Cada exercício tem, na página /strength-standards/<slug>/kg:
  • tabela "Entire Community → Weight" masculina e feminina (5 limiares em kg)
  • tabela "By Bodyweight" (que serve para ajustar o limiar ao peso corporal)

O que este script faz:
 1. lê os dois blocos de limiares (masculino e feminino) de cada exercício;
 2. ajusta por regressão em log-log o expoente `b` de `limiar = a · BW^b` sobre a
    tabela de peso corporal disponível no HTML;
 3. marca como estimados os limiares femininos que não foi possível ler
    (a página gera parte das tabelas em JavaScript).

Uso:  python Tools/fetch_standards.py
"""
import json, math, os, re, statistics, urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, 'standards.json')
UA = {'User-Agent': 'Mozilla/5.0 (compatible; GymRank course project)'}
KS = ['beginner', 'novice', 'intermediate', 'advanced', 'elite']

EXERCISES = {
    'bench-press': 'Chest', 'incline-bench-press': 'Chest', 'dumbbell-bench-press': 'Chest',
    'deadlift': 'Back', 'bent-over-row': 'Back', 'lat-pulldown': 'Back', 'seated-cable-row': 'Back',
    'shoulder-press': 'Shoulders', 'dumbbell-shoulder-press': 'Shoulders', 'dumbbell-lateral-raise': 'Shoulders',
    'squat': 'Legs', 'front-squat': 'Legs', 'romanian-deadlift': 'Legs', 'sled-leg-press': 'Legs',
    'leg-extension': 'Legs', 'lying-leg-curl': 'Legs', 'hip-thrust': 'Legs', 'machine-calf-raise': 'Calves',
    'barbell-curl': 'Biceps', 'dumbbell-curl': 'Biceps', 'hammer-curl': 'Biceps',
    'tricep-pushdown': 'Triceps', 'lying-tricep-extension': 'Triceps',
}


def fetch(slug):
    url = f'https://strengthlevel.com/strength-standards/{slug}/kg'
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=60) as r:
        return r.read().decode('utf-8', 'replace')


def convert(html):
    """O HTML desta página traz as tabelas em markdown-like text quando lido pelo
    extractor; aqui procuramos os padrões '| Beginner | 49 kg |' directamente."""
    txt = re.sub(r'<[^>]+>', ' ', html)
    return txt


def tiers(text):
    out = {}
    for lvl in ['Beginner', 'Novice', 'Intermediate', 'Advanced', 'Elite']:
        m = re.search(r'\|\s*' + lvl + r'\s*\|\s*(\d+)\s*kg\s*\|', text)
        if m:
            out[lvl.lower()] = int(m.group(1))
    return out


def bw_rows(text):
    rows = []
    for m in re.finditer(r'\|\s*(\d+)\s*\|((?:\s*\d+\s*\|){5})', text):
        rows.append([int(m.group(1))] + [int(x) for x in re.findall(r'\d+', m.group(2))])
    return rows


def fit_exponent(rows):
    """limiar = a · BW^b, ajustado em log-log para cada nível; devolve a média de b."""
    bs = []
    for col in range(1, 6):
        xs, ys = [], []
        for row in rows:
            if row[0] > 0 and row[col] > 0:
                xs.append(math.log(row[0])); ys.append(math.log(row[col]))
        if len(xs) >= 4:
            mx, my = sum(xs) / len(xs), sum(ys) / len(ys)
            den = sum((x - mx) ** 2 for x in xs)
            if den > 1e-9:
                bs.append(sum((x - mx) * (y - my) for x, y in zip(xs, ys)) / den)
    return round(sum(bs) / len(bs), 3) if bs else None


def main():
    data = {}
    for slug, parte in EXERCISES.items():
        try:
            txt = convert(fetch(slug))
        except Exception as exc:                      # rede/404
            print(f'  {slug:<26} ERRO: {exc}')
            continue
        partes = re.split(r'##\s*Female', txt)
        male_txt = partes[0]
        female_txt = partes[1] if len(partes) > 1 else ''
        m = tiers(male_txt)
        f = tiers(female_txt)
        bw = bw_rows(male_txt)
        data[slug] = {
            'nome': slug.replace('-', ' ').title(), 'parte_corpo': parte, 'unidade': 'kg',
            'limiares_homem': m, 'limiares_mulher': f,
            'limiares_mulher_estimado': False if len(f) == 5 else None,
            'expoente_bw': fit_exponent(bw),
            'fonte': 'strengthlevel.com/strength-standards/<ex>/kg (2026)',
        }
        print(f"  {slug:<26} M={list(m.values())} F={list(f.values()) or '—'} b={data[slug]['expoente_bw']}")

    # femininos em falta: razão mediana observada nos pares reais
    pares = []
    for v in data.values():
        if v['limiares_mulher'] and v['limiares_mulher_estimado'] is False:
            for k in KS:
                pares.append(v['limiares_mulher'][k] / v['limiares_homem'][k])
    razao = round(statistics.median(pares), 3) if pares else 0.556
    estimadas = []
    for slug, v in data.items():
        if v['limiares_mulher']:
            continue
        if not v['limiares_homem']:
            continue
        v['limiares_mulher'] = {k: max(1, round(v['limiares_homem'][k] * razao)) for k in KS}
        v['limiares_mulher_estimado'] = True
        estimadas.append(slug)
    data['_meta'] = {'razao_feminino_masculino': razao, 'estimadas': estimadas,
                     'nota': 'limiares femininos estimados = masculinos x razão mediana das tabelas reais'}
    json.dump(data, open(OUT, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    print(f'\n{len(data) - 1} exercícios -> {OUT}  (femininos estimados: {len(estimadas)})')


if __name__ == '__main__':
    main()
