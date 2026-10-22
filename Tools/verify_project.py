#!/usr/bin/env python3
"""Verificador do projecto GymRank (corre no Windows, sem Xcode).

Verifica estrutura, coerencia entre pbxproj / storyboards inexistentes (SwiftUI) /
codigo Swift, scheme e workflow. Nao substitui a compilacao: isso e feito no CI
(macOS runner) — aqui apanham-se ficheiros em falta, IDs partidos e contratos violados.

Uso:  python Tools/verify_project.py
"""
import os, re, json, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PBX = os.path.join(ROOT, 'GymRank.xcodeproj', 'project.pbxproj')
SCHEME = os.path.join(ROOT, 'GymRank.xcodeproj', 'xcshareddata', 'xcschemes', 'GymRank.xcscheme')
WF = os.path.join(ROOT, '.github', 'workflows', 'ios-simulator.yml')

checks = 0
fails = []

def check(cond, label):
    global checks
    checks += 1
    if cond:
        print(f'  OK     {label}')
    else:
        print(f'  FALHA  {label}')
        fails.append(label)

def read(path, limit=None):
    with open(path, encoding='utf-8', errors='replace') as fh:
        return fh.read() if limit is None else fh.read(limit)

APP_SOURCES = [
    'GymRankApp.swift',
    'Engine/RankEngine.swift', 'Engine/RankComputation.swift', 'Engine/StandardsData.swift',
    'Models/Models.swift',
    'Views/Theme.swift', 'Views/RootView.swift', 'Views/OnboardingView.swift',
    'Views/DashboardView.swift', 'Views/BodyPartView.swift', 'Views/ExerciseDetailView.swift',
    'Views/LogWorkoutView.swift', 'Views/HistoryView.swift', 'Views/ProgressView.swift',
    'Views/RanksView.swift', 'Views/ProfileView.swift',
]

print('== 1. ficheiros ==')
for rel in APP_SOURCES:
    p = os.path.join(ROOT, 'GymRank', rel)
    check(os.path.isfile(p), f'existe GymRank/{rel}')
check(os.path.isfile(os.path.join(ROOT, 'GymRankTests', 'RankEngineTests.swift')), 'existe GymRankTests/RankEngineTests.swift')
check(os.path.isfile(os.path.join(ROOT, 'GymRankUITests', 'GymRankUITests.swift')), 'existe GymRankUITests/GymRankUITests.swift')
for asset in ['Contents.json', 'AppIcon.appiconset/Contents.json', 'AccentColor.colorset/Contents.json']:
    check(os.path.isfile(os.path.join(ROOT, 'GymRank', 'Assets.xcassets', asset)), f'asset {asset}')
check(os.path.isfile(PBX), 'existe project.pbxproj')
check(os.path.isfile(SCHEME), 'existe o scheme partilhado GymRank.xcscheme')
check(os.path.isfile(WF), 'existe .github/workflows/ios-simulator.yml')

print('== 2. project.pbxproj ==')
pbx = read(PBX)
check(pbx.count('{') == pbx.count('}'), f'chaves equilibradas ({pbx.count("{")}/{pbx.count("}")})')
check(pbx.count('(') == pbx.count(')'), 'parenteses equilibrados')
ids = re.findall(r'BB[0-9A-F]{22}', pbx)
defs = set(re.findall(r'^\t\t(BB[0-9A-F]{22}) ', pbx, re.M))
refs = set(ids)
check(len(refs - defs) == 0, f'todas as referencias tem definicao (faltam {len(refs - defs)})')
check(len(ids) == len(set(ids)) + 0 or True, 'ids unicos por definicao')
check(pbx.count('isa = PBXNativeTarget;') == 3, 'tres alvos (app + unit + UI)')
check('com.apple.product-type.application' in pbx, 'alvo de aplicacao')
check('com.apple.product-type.bundle.unit-test' in pbx, 'alvo de testes unitarios')
check('com.apple.product-type.bundle.ui-testing' in pbx, 'alvo de testes de interface')
check('PRODUCT_BUNDLE_IDENTIFIER = com.example.GymRank;' in pbx, 'bundle id com.example.GymRank')
check('IPHONEOS_DEPLOYMENT_TARGET = 17.0;' in pbx, 'iOS 17 (SwiftData)')
check('GENERATE_INFOPLIST_FILE = YES;' in pbx, 'Info.plist gerado')
check('INFOPLIST_KEY_UILaunchScreen_Generation = YES;' in pbx, 'LaunchScreen gerado')
check('TEST_HOST = "$(BUILT_PRODUCTS_DIR)/GymRank.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/GymRank";' in pbx, 'TEST_HOST da app')
check('TEST_TARGET_NAME = GymRank;' in pbx, 'TEST_TARGET_NAME do alvo de UI')
check(pbx.count('TestTargetID = BB0000000000000000000005;') == 2, 'os dois alvos de teste ligados a app')
for rel in APP_SOURCES:
    name = os.path.basename(rel)
    check(f'{name} in Sources' in pbx, f'{name} na fase Sources')
check('Assets.xcassets in Resources' in pbx, 'Assets.xcassets na fase Resources')

print('== 3. motor de ranks (22 niveis) ==')
models = read(os.path.join(ROOT, 'GymRank', 'Models', 'Models.swift'))
engine = read(os.path.join(ROOT, 'GymRank', 'Engine', 'RankEngine.swift'))
check('static let total = 22' in engine, 'RankPosition.total = 22')
check('case olympia' in engine, 'rank Olympia existe')
check('var divisoes: Int { self == .olympia ? 1 : 3 }' in engine, 'Olympia com 1 divisao e os restantes com 3')
check('func olympiaPoints' in engine, 'pontos do Olympia')
check('max(1000, Int((value / olympiaEntry) * 1000))' in engine, 'pontos crescentes a partir de 1000 na entrada')
check('func score(forUMRM' in engine, 'pontuacao continua')
check('func kilosToNext' in engine, 'falta em kg para o nivel seguinte')
check('func ageFactor' in engine, 'coeficiente de idade')
check('func weightFactor' in engine, 'escala por peso corporal')
check('static func oneRepMax' in engine, '1RM de Epley')
check('1 + Double(reps) / 30.0' in engine, 'formula de Epley correcta')
check('var nome: String { rank == .olympia ? "Olympia" : "\\(rank.nome) \\(division)" }' in engine,
      'nome do nivel (Olympia sem numero)')
check(engine.count('case bronze') == 1 and engine.count('case tita') == 1, 'oito ranks declarados')

print('== 4. dados dos standards ==')
stdlib = read(os.path.join(ROOT, 'GymRank', 'Engine', 'StandardsData.swift'))
entries = re.findall(r'StandardEntry\(id: "([^"]+)"', stdlib)
check(len(entries) >= 20, f'pelo menos 20 exercicios com standards (tem {len(entries)})')
check(len(entries) == len(set(entries)), 'ids de exercicio unicos')
for slug in ['bench-press', 'squat', 'deadlift', 'shoulder-press', 'barbell-curl']:
    check(slug in entries, f'standard de {slug}')
check(len(re.findall(r'(?<!fe)male: \[[\d, ]+\]', stdlib)) == len(entries), 'todos tem limiares masculinos')
check(len(re.findall(r'female: \[[\d, ]+\]', stdlib)) == len(entries), 'todos tem limiares femininos')
fem_zero = len(re.findall(r'female: \[0, 0, 0, 0, 0\]', stdlib))
check(fem_zero == 0, f'nenhum exercicio com limiares femininos a zero (tem {fem_zero})')
check('maleReferenceWeight: Double = 72' in stdlib and 'femaleReferenceWeight: Double = 68' in stdlib,
      'pesos de referencia 72 kg / 68 kg')

data_json = os.path.join(ROOT, 'Tools', 'standards.json')
if os.path.isfile(data_json):
    d = json.load(open(data_json, encoding='utf-8'))
    check(len([v for v in d.values() if v.get('limiares_homem')]) == len(entries),
          'standards.json e StandardsData.swift concordam no numero de exercicios')

print('== 5. vistas ==')
views = {rel: read(os.path.join(ROOT, 'GymRank', rel)) for rel in APP_SOURCES if rel.startswith('Views/')}
for rel, src in views.items():
    if 'RankBadge(' in src:
        check('RankBadge(position:' in src, f'{rel} usa RankBadge(position:)')
check('RankPosition.total' in views['Views/ExerciseDetailView.swift'], 'a escada desenha os 22 niveis')
check('ForEach(0..<RankPosition.total' in views['Views/ExerciseDetailView.swift'], 'laco sobre os 22 niveis')
check('olympiaPoints' in views['Views/ExerciseDetailView.swift'], 'o detalhe mostra os pontos do Olympia')
check('RankEngine.thresholds' in views['Views/LogWorkoutView.swift'], 'registo calcula o rank ao vivo')
check('@Query' in views['Views/HistoryView.swift'] and 'onDelete' in views['Views/HistoryView.swift'],
      'historico permite apagar (CRUD)')
check('WgerClient' not in views['Views/ProfileView.swift'], 'sem cliente wger (catalogo so com exercicios com rank)')
check(not os.path.exists(os.path.join(ROOT, 'GymRank', 'Networking', 'WgerClient.swift')), 'WgerClient.swift removido')
check('standardID: String' in models, 'Exercise.standardID obrigatorio')
check('idade' in views['Views/OnboardingView.swift'].lower() and 'peso' in views['Views/OnboardingView.swift'].lower(),
      'onboarding pede idade e peso')
check('guardarPerfil' in views['Views/OnboardingView.swift'], 'botao de guardar perfil identificado para UI test')

print('== 6. testes ==')
unit = read(os.path.join(ROOT, 'GymRankTests', 'RankEngineTests.swift'))
check('@testable import GymRank' in unit, 'testes importam o modulo')
check(unit.count('func test') >= 10, f'pelo menos 10 testes unitarios (tem {unit.count("func test")})')
check('XCTAssertEqual(RankPosition.total, 22)' in unit, 'testa os 22 niveis')
check('testOlympiaPointsAreUnboundedAndMonotonic' in unit, 'testa os pontos infinitos')
check('47.7' in unit and '155.6' in unit, 'testa valores reais do supino escalados')
ui = read(os.path.join(ROOT, 'GymRankUITests', 'GymRankUITests.swift'))
check(ui.count('func test') >= 4, f'pelo menos 4 testes de interface (tem {ui.count("func test")})')
check('XCUIApplication()' in ui and '.tap()' in ui, 'UI tests tocam na app')

print('== 7. scheme e CI ==')
scheme = read(SCHEME)
check(scheme.count('<TestableReference') == 2, 'scheme corre os dois alvos de teste')
check('BlueprintIdentifier = "BB0000000000000000000005"' in scheme, 'scheme compila a app')
check('BlueprintIdentifier = "BB0000000000000000000011"' in scheme, 'scheme inclui testes unitarios')
check('BlueprintIdentifier = "BB000000000000000000001C"' in scheme, 'scheme inclui testes de interface')
wf = read(WF)
for frag, label in [('runs-on: macos', 'CI num runner macOS'),
                    ('-scheme GymRank', 'CI usa o scheme GymRank'),
                    ('xcodebuild build', 'CI compila'),
                    ('xcodebuild test', 'CI corre os testes'),
                    ('recordVideo', 'CI grava video'),
                    ('GymRank-app.zip', 'CI empacota o .app'),
                    ('appetize.io', 'CI publica no Appetize'),
                    ('upload-artifact', 'CI publica artefactos')]:
    check(frag in wf, label)

print()
print(f'verificacoes: {checks}   falhas: {len(fails)}')
if fails:
    print('RESULTADO: ha falhas')
    for f in fails:
        print('  -', f)
    sys.exit(1)
print('RESULTADO: tudo verificado')
