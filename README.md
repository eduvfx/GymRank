# GymRank — registo de treinos com ranks de videojogo

App **iOS nativa em Swift/SwiftUI** para registar treinos de ginásio e transformar a evolução da força
num sistema de ranks. Projecto individual da unidade curricular **Desenvolvimento para Dispositivos
Móveis** (MEI, ESTG/IPLeiria, 2026/2027).

---

## O que a app faz

- **Perfil** com nome, idade, peso, altura e sexo. **Idade e peso são obrigatórios** — sem eles não há
  cálculo de rank, porque os limites são relativos ao peso corporal e ajustados à faixa de idade.
- **Catálogo de exercícios** (23 com standards de força, agrupados em 7 partes do corpo) e sincronização
  opcional do catálogo completo do **wger** (860 exercícios) pela API pública.
- **Registar treino**: peso, repetições e séries, com **1RM estimado ao vivo** pela fórmula de Epley.
- **Ranks**: um por exercício, um por parte do corpo e um **rank geral do corpo**.

## A escada de ranks (22 níveis)

| Ranks | Divisões | Notas |
|---|---|---|
| Bronze, Prata, Ouro, Platina, Diamante, Campeão, Titã | **1, 2 e 3** | 7 × 3 = 21 níveis |
| **Olympia** | **nível único** | a partir do limiar de Elite entra num **sistema de pontos infinitos** (1000 pontos na entrada, +1000 por cada duplicação do 1RM) |

Os limites vêm dos **standards de força por peso corporal do Strength Level (edição 2026)**: cinco
limiares publicados por exercício e sexo (Beginner, Novice, Intermediate, Advanced, Elite). A app usa
esses cinco valores como âncoras, acrescenta as posições intermédias (Platina, Campeão) e divide cada
rank em três partes iguais; o Olympia fica aberto, pontuado.

Agregação: cada exercício vale uma pontuação contínua `0…21` (níveis) que cresce sem tecto no Olympia;
o rank de uma parte do corpo é a média dos seus exercícios e o rank geral é a média das oito partes com
registos.

## Como correr

Requisitos: **Xcode 16+**, iOS 17+ (usa SwiftData).

```bash
open GymRank.xcodeproj          # ou: xcodebuild -scheme GymRank -destination 'platform=iOS Simulator,name=iPhone 16' build
```

Sem Mac? O projecto compila e é testado num **runner macOS do GitHub Actions** a cada push
(`.github/workflows/ios-simulator.yml`): build → simulador de iPhone → instala e arranca → **grava
vídeo** → corre os testes unitários e de interface → publica screenshots, vídeo e o `.app`.

## Estrutura

```
GymRank/
  GymRankApp.swift            ponto de entrada + contentor SwiftData
  Engine/
    RankEngine.swift          escada de 22 níveis, pontos do Olympia, Epley, idade
    RankComputation.swift     agregação exercício → parte → corpo
    StandardsData.swift       limiares gerados de Tools/standards.json (não editar à mão)
  Models/Models.swift         UserProfile, Exercise, WorkoutSet (@Model)
  Networking/WgerClient.swift cliente da API wger (async/await)
  Views/                      SwiftUI: onboarding, painel, parte, exercício, registo, histórico, progresso, ranks
GymRankTests/                 testes do motor contra valores reais publicados
GymRankUITests/               testes de interface no simulador
Tools/
  fetch_standards.py          recolha dos standards para standards.json
  gen_standards_swift.py      standards.json → StandardsData.swift
  gen_pbxproj.py              gera o project.pbxproj a partir dos ficheiros no disco
  verify_project.py           verificador local (115 verificações)
```

## Testar

```bash
python Tools/verify_project.py     # 115 verificações estruturais, sem Xcode
```

No Mac (ou no CI): `xcodebuild test -project GymRank.xcodeproj -scheme GymRank -destination 'platform=iOS Simulator,name=iPhone 16'`

## Dados e atribuições

- **Standards de força**: [Strength Level](https://strengthlevel.com/strength-standards) — edição 2026,
  287 exercícios, 195 513 376 levantamentos de 27 893 268 utilizadores. Os valores usados estão em
  `Tools/standards.json` (kg, por sexo, com o expoente de escala por peso corporal ajustado por regressão).
- **Catálogo de exercícios**: [wger](https://wger.de) REST API v2, licença **CC-BY-SA 4.0**.
- **1RM**: fórmula de Epley (1985).

### Limites honestos desta versão

- As tabelas por peso corporal e por idade do Strength Level são geradas em JavaScript: a extracção
  directa devolveu as tabelas femininas de 12 dos 23 exercícios. Nos restantes 11 os limiares femininos
  são **estimados** (masculino × 0,556, a razão mediana observada) e estão marcados como tal no código
  gerado e em `standards.json`. O ajuste masculino por peso usa o expoente ajustado nas tabelas
  disponíveis; a validação contra o calculador de referência (homem, supino, 72 kg) dá um desvio médio
  de 10,5 kg nos cinco limiares.
- Exercícios de peso corporal (push-ups, dips, pull-ups, chin-ups, crunches, sit-ups) estão no catálogo
  mas ainda **sem rank** — o rank por repetições é a próxima fase.
- A app compila e corre no simulador através do CI; a verificação local garante a estrutura e os
  contratos, não a compilação.

Autor: Eduardo Gomes (2026165029).
