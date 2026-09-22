# HW-005 — Alimentação e Distribuição de Energia

| Campo | Valor |
| --- | --- |
| **Código** | HW-005 |
| **Título** | Alimentação e Distribuição de Energia |
| **Versão** | 2.0 |
| **Estado** | Em Desenvolvimento |
| **Autor** | ShegaPT |
| **Classificação** | Especificação de Hardware |
| **Referência** | docs/Esquemas/Arquitetura-Computacional.md |

---

# 1. Objetivo

O presente documento define a arquitetura de alimentação do sistema AERUS-TELLUS: as três tensões de entrada disponíveis na aeronave (12 V, 5 V e 3,3 V), a árvore de distribuição até cada PCB da família, as conversões locais e os PMIC com sequenciamento NXP no Grupo Computacional de Visão (GCV) e no Master Geral, bem como monitorização, proteções, arranque, picos e relação com a segurança.

Explica por que razão 3,3/5/12 V são apenas o ponto de partida — nenhum SoC complexo se alimenta diretamente destas tensões sem regulação e sequência — e como evitar que uma falha de energia deite abaixo em simultâneo o domínio normal e o domínio de segurança.

---

# 2. Âmbito

Abrange:

* barramento de entrada 12/5/3,3 V e separação potência/sinal;
* árvore de distribuição por grupo e por PCB;
* PMIC NXP e sequenciamento do i.MX 8M Plus (módulo do GCV) e rails do cluster 4 × RP2350;
* monitorização (tensão, corrente, potência, temperatura), proteções e fusíveis eletrónicos;
* gestão de consumo, picos, arranque e encerramento elétrico;
* redundância e separação energética do FailSafe.

Não abrange:

* fichas e níveis de sinal (ver HW-004);
* protocolo e redes (ver HW-006);
* sensores/atuadores concretos e a sua corrente nominal (ver SEN, ACT);
* modelo de bateria e autonomia de missão (ver ENE, MAT).

---

# 3. Descrição

## 3.1 Entradas disponíveis: 12 V, 5 V e 3,3 V

A aeronave disponibiliza externamente apenas três tensões de entrada para as PCB:

```text
12 V  → cargas de 12 V, ESC, rádios de potência, pré-regulação comutada
5 V   → periféricos, transceptores, câmara, USB, pré-regulação local
3,3 V → I/O digital, pequenos sensores, referência (nunca potência)
```

Estas tensões alimentam fichas de entrada; **não** alimentam diretamente núcleos, DDR ou MIPI. Cada PCB gera localmente as tensões (rails) de que precisa.

```text
ENTRADAS DA PCB            CONVERSÕES LOCAIS           CARGAS
12 V ─┬─► cargas 12 V      ┌─buck──► 5 V / 3,3 V ─────► I/O, transceptores
      └─► reguladores ─────┼─buck──► 1,8 V / 1,1 V /──► núcleos RP2350, Flash, PSRAM
5 V ──┬─► periféricos      │         0,9 V etc.        ► (conforme datasheet)
      └─► reguladores ─────┼─LDO ──► rails limpas ────► ADC, referências, relógios
3,3 V ┬─► I/O              └─PMIC ─► sequência NXP ───► i.MX + LPDDR + eMMC (GCV)
      └─► reguladores
```

## 3.2 Árvore de distribuição por grupo

```text
Fonte principal da aeronave
  │
  ▼
Distribuição principal (barramento 12/5/3,3 V + proteções por derivação)
  │
  ├── Grupo Sensorial (COMPUTE-SENSORIAL + Master COMPUTE-NODE)
  ├── Grupo Atuador (COMPUTE-ACTUATOR + potência dos atuadores em derivação separada)
  ├── Master Geral (COMPUTE-FLIGHT-CLUSTER + RJ45 para 2,4 GHz/868 MHz)
  ├── GCV (COMPUTE-VISION-CARRIER + RJ45 para 5,8 GHz)
  ├── Grupo Comunicação (COMPUTE-NODE + 3 × COMM-RF via RJ45)
  ├── Nós FailSafe distribuídos (derivação protegida independente)
  └── Periféricos (sensores, ESC, câmara — via nós, nunca direto da fonte)
```

Regras:

* A potência dos atuadores (servos, ESC, motores) corre em derivação **separada** da eletrónica digital, com filtragem e ponto único de massa.
* O domínio FailSafe possui derivação protegida independente, para que um curto no domínio normal não o arraste.
* Cada derivação possui proteção dimensionada à carga (fusível, PTC ou eFuse + TVS + inversão de polaridade).

| Consumidor | Fonte preferencial | Notas |
| --- | --- | --- |
| RP2040 e condicionamento local | 3,3 V → LDO local; 5 V como pré-regulação quando o nó incluir periféricos | Desacoplamento junto a cada circuito; plano de massa contínuo |
| RP2350B/2354B (nós, Masters, Router, cluster) | 3,3 V → reguladores de núcleo segundo datasheet; Flash/PSRAM nos seus rails | Sequência simples mas verificada; brown-out detetado pelo supervisor |
| COMPUTE-FLIGHT-CLUSTER (4 × RP2350 + Fabric + memórias) | 12 V → bucks de alto rendimento → rails de núcleo/I/O/memória; 5 V para transceptores | Dimensionar por pico simultâneo dos 4 circuitos + Fabric + RJ45 |
| COMPUTE-VISION-CARRIER | 12/5/3,3 V → **PMIC NXP + reguladores** → rails do i.MX + LPDDR + eMMC + MIPI + Router | Sequenciamento NXP obrigatório; qualquer desvio invalida o arranque |
| COMM-RF (3 placas) | Via RJ45 a partir do GCV/Master Geral, com proteção na origem e na placa | Interruptor de corte por placa para ensaio e poupança |
| Sensores/atuadores | Via o nó que os serve, nunca direto do barramento | Permite corte, medição e diagnóstico por periférico |

## 3.3 PMIC e sequenciamento NXP (GCV e cluster)

O i.MX 8M Plus exige múltiplas tensões com ordem, rampas e temporizações precisas (núcleos, GPU, DDR, I/O, eMMC, MIPI). O mesmo vale, em menor grau, para LPDDR e memórias do cluster.

```text
12 V / 5 V / 3,3 V
      │
      ▼
Gestão de energia (PMIC NXP + bucks/LDO + supervisão)
      │
      ├──► rails do i.MX 8M Plus (ordem NXP estrita)
      ├──► LPDDR (rail dedicado, ruidoso separado do analógico)
      ├──► eMMC / armazenamento
      ├──► MIPI / câmara (com interruptor e sequência)
      ├──► Router RP2350 (arranca primeiro; é quem liberta o SoC)
      └──► Ethernet / CAN / RJ45 (com proteção)
```

Princípio de arranque energético:

```text
Router RP2350 sob tensão → verifica rails → liberta PMIC na ordem NXP
  → aguarda POWER_OK → liberta reset do i.MX → SoC arranca
  → Router assume watchdog e publica estado no CAN-Principal
```

O dimensionamento final (PMIC exato, indutores, condensadores, resistências de sequência, temporizações) é extraído da documentação oficial NXP para o MIMX8ML4DVNLZAB e validado em bancada. Sem essa validação, a carrier não é dada como pronta.

## 3.4 Comparativo energético dos processadores

| Aspeto | RP2040 | RP2350B/2354B | i.MX 8M Plus |
| --- | --- | --- | --- |
| Ordem de consumo | Dezenas de mW típicos por nó | Centenas de mW por circuito (depende de relógio e Fabric) | Unidades a dezenas de W com GPU/NPU/VPU ativas |
| Regulação | LDO/buck simples | Bucks dedicados + LDO limpas para ADC/relógio | PMIC NXP + múltiplos bucks/LDO + sequência |
| Sensibilidade | Baixa; brown-out detetado localmente | Média; relógio e PSRAM exigem rails estáveis | Elevada; DDR e MIPI exigem integridade e desacoplamento rigorosos |
| Térmica | Dissipação na PCB chega | Dissipação + vias térmicas; cluster exige plano e, se necessário, dissipador | Dissipador + circulação de ar + monitorização contínua; Router pode cortar o SoC |

## 3.5 Monitorização energética

Cada nível monitoriza o que precisa para operar e para proteger:

* **Nó (RP2040/RP2350):** tensão de entrada, estado do regulador local, corrente de periféricos quando relevante.
* **Master Geral:** tensões de entrada, correntes por derivação principal, temperatura da PCB e dos reguladores, estado dos RJ45 (placa presente, consumo).
* **GCV:** todas as rails do PMIC, corrente do SoC/LPDDR, temperatura do SoC (interna) e da carrier, estado da câmara e do armazenamento.
* **Sistema:** potência instantânea, energia acumulada e estimativa de autonomia (com ENE/MAT); qualquer medida relevante para segurança é publicada no CAN-Principal e avaliada pelo FailSafe.

## 3.6 Proteções, picos e separação potência/sinal

Proteções por derivação: sobrecorrente, sobretensão, subtensão (brown-out), curto-circuito, inversão de polaridade, transientes/ESD e proteção térmica. Dimensionar por **pico** (arranque de motores, movimento simultâneo de superfícies, inicialização do GCV, TX simultâneo), não por média, com margem para que um pico legítimo nunca reinicie os domínios digitais.

Separação potência/sinal: feixes distintos, filtragem LC/ferrite na fronteira, massa de potência e massa de sinal unidas num único ponto por baía, sem laços. A comutação dos bucks é afastada de ADC, relógios, MIPI e DDR.

## 3.7 Arranque e encerramento elétricos

Arranque: as tensões estabilizam antes de qualquer firmware se declarar pronto; o Router do GCV e o supervisor do cluster são os primeiros a viver e os últimos a autorizar comando. Encerramento: superfícies e motores em condição segura, escrita e sincronização do armazenamento do GCV, e só depois corte — sequência funcional em SYS, execução elétrica aqui.

---

# 4. Exemplos

## Exemplo 1 — Pico simultâneo

```text
Arranque: GCV a codificar + 4 superfícies em movimento + TX 5,8 GHz no máximo
  → corrente de pico = soma dos picos, não das médias
  → bucks do cluster e da carrier dimensionados com margem + monitorização
  → se a margem for violada, o FailSafe limita TX ou adia movimento não crítico
```

## Exemplo 2 — Curto no domínio normal

```text
Curto numa derivação do Grupo Atuador
  → eFuse da derivação corta em µs/ms; barramento principal intacto
  → FailSafe (derivação independente) continua a avaliar e publica evento
  → Missão degrada ou aborta conforme criticidade; registo em R1
```

## Exemplo 3 — Sequência do GCV

```text
12 V presente → Router vivo → PMIC executa ordem NXP → LPDDR → núcleos → I/O
  → POWER_OK → reset libertado → i.MX arranca → MIPI e eMMC ligados
  → qualquer rail fora de tolerância = arranque abortado + diagnóstico
```

---

# 5. Interfaces

| Interface | Origem → Destino | Detalhe |
| --- | --- | --- |
| Barramento 12/5/3,3 V | Fonte → distribuição principal → cada PCB | Bitolas, proteções, fichas; ver também HW-004 |
| Rails locais RP2040/RP2350 | Reguladores de cada PCB → núcleos/I/O/memórias | Documentação oficial do silício |
| Rails PMIC NXP | PMIC → i.MX + LPDDR + eMMC + MIPI + Router | Documentação NXP do MIMX8ML4DVNLZAB |
| RJ45 com energia | GCV/Master Geral → COMM-RF | Corte e medição por placa; ver HW-004/HW-006 |
| Telemetria de energia | Monitores → CAN-Principal → FailSafe/Missão | Grandezas, períodos e limites em COM/SEC |

---

# 6. Pontos em aberto

| # | Ponto em aberto | Resolução |
| --- | --- | --- |
| 1 | PMIC NXP exato, indutores, condensadores, sequência e temporizações para o MIMX8ML4DVNLZAB | Guia NXP + projeto da carrier |
| 2 | Rails e sequência do cluster (núcleos, Flash/PSRAM, Fabric, transceptores) e consumos por modo | Datasheets + medição em bancada |
| 3 | Curvas de proteção por derivação (fusível/eFuse/TVS) e seletividade entre derivações | Projeto + ensaio de curto |
| 4 | Orçamento de potência por modo (voo, missão, visão, TX máximo, emergência) e impacto na autonomia | ENE + MAT + medição |
| 5 | Solução térmica da baía central (dissipadores, ar, limites de alarme/corte) | Ensaio térmico |
| 6 | Modelo de bateria, química, capacidade e conetores da fonte principal | ENE + projeto da célula |

---

# 7. Referências

* HW-001 — Arquitetura de Hardware
* HW-002 — Grupos Computacionais
* HW-003 — Distribuição de Hardware
* HW-004 — Interfaces Elétricas
* HW-006 — Interfaces de Comunicação
* HW-007 — Interfaces de Periféricos
* HW-008 — Redundância e Isolamento de Hardware
* HW-009 — Expansibilidade e Configuração de Hardware
* docs/Esquemas/Arquitetura-Computacional.md
