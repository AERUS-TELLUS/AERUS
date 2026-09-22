# SYS-004 — Arquitetura Hardware

| Campo             | Valor                    |
|-------------------|--------------------------|
| **Código**        | SYS-004                  |
| **Título**        | Arquitetura Hardware     |
| **Versão**        | 2.0                      |
| **Estado**        | Em Desenvolvimento       |
| **Autor**         | ShegaPT                  |
| **Classificação** | Especificação de Sistema |

---

# 1. Objetivo

O presente documento define a arquitetura física do sistema AERUS. Estabelecem-se a organização dos grupos computacionais em hardware, a distribuição de responsabilidades por placa, os processadores normativos, as redes físicas e os princípios de alimentação, isolamento e evolução.

Não se especificam modelos de sensores, valores de componentes, esquemas elétricos nem protocolos binários. Tais matérias pertencem às especificações HW (série) e COM.

---

# 2. Âmbito

Aplica-se a todas as PCB do sistema: Módulos Menores, Masters de Grupo, Master Geral em cluster, placa(s) do Grupo de Visão, placas do Grupo de Comunicação e interligações (CAN, INTERCONNECT FABRIC, RJ45 privada, MIPI, alimentação).

---

# 3. Descrição Detalhada

## 3.1. Filosofia da arquitetura

A arquitetura baseia-se em processamento distribuído: em vez de concentrar tudo numa unidade, distribuem-se responsabilidades por grupos especializados, com obtenção de:

- Redução da carga individual e determinismo local.
- Robustez e tolerância a falhas por isolamento.
- Manutenção simples e evolução independente por grupo.
- Escalabilidade (uma ou várias unidades por grupo, sem alteração da arquitetura).

Cada grupo executa localmente o processamento do seu domínio antes de publicar resultados; transmite-se informação tratada, não sinais elétricos em bruto.

## 3.2. Processadores normativos

### 3.2.1. RP2040 — Módulo Menor

Características de referência: 2x Cortex-M0+ até 133 MHz; 264 KB SRAM; 30 GPIO; 4 analógicas; 2x UART, 2x SPI, 2x I2C; 16 PWM; USB; 8 máquinas PIO; DMA; baixo consumo.

Utilização normativa: aquisição, filtragem, calibração, normalização, conversão de unidades, geração de PWM, SPI/I2C/UART, protocolos personalizados por PIO, pequenas máquinas de estado, monitorização local. Nunca como computador principal de voo.

### 3.2.2. RP2350 — Módulo Maior / Master

Características de referência: 2x Cortex-M33 até 150 MHz (alternativa 2x Hazard3 RISC-V); 520 KB SRAM; FPU; DSP; 16 DMA; 12 PIO; 2x UART/SPI/I2C; ADC; USB; TrustZone; SHA-256; Flash/PSRAM externa.

Variantes e preferência:

| Variante | Encapsulamento | GPIO / PWM / Analógicas | Nota |
|----------|----------------|--------------------------|------|
| RP2350A | QFN-60 7x7 mm | 30 / padrão / 4 | Uso geral compacto |
| **RP2350B (preferida)** | QFN-80 10x10 mm | 48 / 24 / 8 | **Masters e cluster** |
| RP2354A | como A + 2 MB Flash | idem A | Quando se pretenda Flash empilhada |
| **RP2354B (preferida c/ Flash)** | como B + 2 MB Flash | idem B | **Masters e cluster quando aplicável** |

A escolha definitiva depende de GPIO, Flash/PSRAM, disponibilidade e custo, mas para computadores principais considera-se prioritariamente RP2350B/RP2354B.

### 3.2.3. NXP i.MX 8M Plus MIMX8ML4DVNLZAB — GCV

SoC de visão com 4x Cortex-A53 + Cortex-M7 + GPU + ISP + NPU + motor de vídeo, interfaces de câmara (MIPI CSI), Ethernet e CAN-FD. Adequado a captura, ISP, composição GPU, inferência futura e codificação de vídeo. O dimensionamento de LPDDR, armazenamento (eMMC), PMIC, MIPI, impedâncias e layout DDR/MIPI processa-se estritamente a partir da documentação oficial da NXP.

## 3.3. Grupos em hardware

Cada grupo representa um domínio funcional; o hardware pode evoluir sem alteração da arquitetura, desde que se preservem responsabilidades e interfaces.

- **Sensorial**: PCB(s) de sensores com RP2040 + Master RP2350; CAN-Intra-Grupo interna; saída para CAN-Principal.
- **Atuador**: PCB(s) de atuadores com RP2040 + Master RP2350; idem.
- **Missão/Navegação/Voo/Cálculo/Supervisão**: concentrados no Master Geral (ver 3.4); quando se justifique desagregação física, cada subgrupo utiliza Master RP2350 próprio ligado à CAN-Principal, sem alteração lógica.
- **Visão (GCV)**: placa de visão (ver 3.6).
- **Comunicação**: placa(s) com Master RP2350 (ou RP2040 para funções simples), transceptores CAN, interfaces série RS para RF e conectores RJ45 privados.
- **FailSafe/Supervisão**: núcleo no Master Geral + rede CAN-FailSafe dedicada + capacidade de inibição; pode incluir PCB própria de supervisão com RP2350 quando a análise de segurança o exija.

Cada PCB possui: identificação própria, versão de hardware, firmware próprio, interfaces documentadas, alimentação documentada, watchdog, diagnóstico e conetor(es) normalizados.

## 3.4. Master Geral — cluster 4x RP2350

PCB principal com 4x RP2350B/RP2354B e INTERCONNECT FABRIC dedicada (SPI dedicado/múltiplo, DMA, PIO, memória partilhada externa, links ponto-a-ponto ou combinação; a fechar). Objetivo: comunicação determinística de baixa latência entre nós independentes.

```text
            ┌──────── RP2350 #1 (Voo+Fusão)
            │              │
  CAN-Principal ───┼── FABRIC ──┼─── CAN-FailSafe (só Supervisão)
            │              │
            └──────── RP2350 #2 (Nav+Cálculo)
                           │
            ┌──────── RP2350 #3 (Missão+Planeamento)
            │              │
            └──────── RP2350 #4 (Supervisão+Diagnóstico)
```

Um núcleo assume supervisão do cluster: heartbeat dos nós, watchdog, latência, erros, bloqueio, reinicialização, sincronização temporal, integridade de mensagens e estado do cluster. Não se confunde supervisão de infraestrutura com computação de voo.

Perante falha de 1x RP2350, aplica-se o definido em SYS-002/SYS-006/SEC (deteção, identificação, degradação controlada, registo).

## 3.5. Redes físicas

- **CAN-Intra-Grupo**: uma por grupo (Sensorial, Atuador, e demais quando desagregados). Barramento curto, transceptores CAN/CAN-FD conforme HW/COM, mensagens TLV.
- **CAN-Principal**: espinha inter-masters (Masters de Grupo + Master Geral + Router GCV + Comunicação). Topologia, terminação, redundância e débito em HW/COM.
- **CAN-FailSafe**: rede separada, exclusiva de segurança. Cablagem e conetores segregados; nunca partilha transceptor com tráfego normal.
- **INTERCONNECT FABRIC**: rede intra-cluster na PCB do Master Geral. Requisitos: determinismo, baixa latência, CRC, timestamps, deteção de nó mudo.
- **RJ45-Privada (RS)**: dois enlaces ponto-a-ponto, sempre que exista RF: (a) GCV ↔ placa TX 5.8 GHz; (b) Master Geral/GCCOM ↔ placa RX 2.4 GHz / TX 868 MHz. Protocolo série RS (RS-422/485 a confirmar), pinagem e blindagem em HW/COM. Nunca se ligam módulos RF a barramentos partilhados.

## 3.6. Placa de visão (GCV)

Solução modular preferencial para reduzir risco na primeira revisão:

```text
┌────────────────────────────────────────────┐
│              VISION CARRIER PCB            │
│                                            │
│ Câmara FFC → MIPI CSI → Módulo de cálculo  │
│                                            │
│ Módulo: i.MX 8M Plus + LPDDR + Storage     │
│         + PMIC/reguladores                 │
│                                            │
│ Router RP2350 (supervisão, watchdog,       │
│   energia, CAN-Principal, telemetria)      │
│                                            │
│ Ethernet(rightsizing) │ CAN │ Energia │ RJ45-RS → TX 5.8 GHz │
│ Conetor de sistema normalizado             │
└────────────────────────────────────────────┘
```

Admite-se, como alternativa, i.MX direto na placa. A opção modular é preferida na primeira revisão.

Arquitetura de alimentação do GCV:

```text
12 V / 5 V / 3.3 V (entradas)
         │
         ▼
Gestão de energia (PMIC + reguladores)
         ├──► rails do i.MX 8M Plus (sequenciamento NXP)
         ├──► LPDDR
         ├──► eMMC/armazenamento
         ├──► MIPI/periféricos
         └──► Router RP2350
```

O layout observa integralmente guias da NXP (largura, impedância, DDR, MIPI, desacoplamento, térmico).

## 3.7. Alimentação geral

Entradas externas por PCB: apenas 3.3 V, 5 V e 12 V. Rails internas geradas localmente:

```text
12 V ─┬─► cargas 12 V
      └─► reguladores ─► rails intermédias

 5 V ─┬─► periféricos
      └─► reguladores ─► núcleos, memórias

3.3 V ─┬─► I/O
       └─► reguladores ─► 1.8 V / 1.1 V / 0.8 V etc. conforme SoC/MCU
```

Aplica-se sequenciamento onde exigido (em especial i.MX), supervisão de rails, arranque monotónico e proteção. Redundância de alimentação, gestão térmica, EMC/EMI e certificação: ver HW/ENE/SEC.

## 3.8. Aquisição, atuação e independência física

- Todos os sensores ligam-se ao Grupo Sensorial; todos os atuadores, ao Grupo Atuador. Admite-se sensor dedicado a outro grupo apenas com justificação e sem alteração dos princípios.
- Todos os atuadores fornecem realimentação (posição, velocidade, rotação, corrente, tensão, estado, telemetria), conforme a tecnologia.
- Cada grupo possui o maior grau possível de independência: falhas internas de um grupo não impedem, sempre que possível, o funcionamento dos restantes.
- A comunicação entre grupos processa-se por interfaces apropriadas (CAN/RJ45-RS/Fabric), definidas em HW/COM, nunca por sinais elétricos ad hoc.

## 3.9. Família de PCB padronizadas (objetivo)

```text
COMPUTE-SENSOR   ─ RP2040 (+ Master RP2350)
COMPUTE-ACTUATOR ─ RP2040/RP2350
COMPUTE-NODE     ─ RP2350 (master genérico)
COMPUTE-FLIGHT   ─ 4x RP2350 (Master Geral)
COMPUTE-VISION   ─ i.MX 8M Plus + Router RP2350
COMPUTE-COMM     ─ RP2040/RP2350 + CAN + RS/RJ45
```

---

# 4. Exemplos

## Exemplo 1 — Escolha de variante

```text
Master Sensorial com 34 GPIO necessários + 6 PWM + 5 analógicas
→ RP2350A insuficiente (30 GPIO / 4 analógicas)
→ decisão: RP2350B (48 GPIO / 8 analógicas / 24 PWM).
Se necessária Flash empilhada → RP2354B.
```

## Exemplo 2 — Ligação de RF (correta)

```text
GCV ──RJ45 privada (par diferencial RS)──► Placa TX 5.8 GHz ──antena──► Solo
MG/GCCOM ──RJ45 privada (RS)──► Placa RX 2.4 GHz (telecomando)
MG/GCCOM ──RJ45 privada (RS)──► Placa TX 868 MHz (telemetria)
Nunca: RF pendurada na CAN-Principal.
```

## Exemplo 3 — Rails do GCV

```text
Entrada 12 V → buck → 5 V intermédio → PMIC NXP → 1.8/1.1/0.8 V (sequência NXP)
Entrada 3.3 V → I/O e Router RP2350
Monitorização por Router: PG, temperatura, corrente; watchdog do SoC.
```

---

# 5. Interfaces Com Outros Documentos

| Documento | Relação |
|-----------|---------|
| SYS-002 | Grupos lógicos aqui materializados |
| SYS-003 | Software que corre neste hardware |
| SYS-005 | Redes físicas aqui listadas, detalhadas em mensagens |
| HW-001/002/003/005/006/008 | Arquitetura, grupos, distribuição, energia, interfaces, redundância |
| COM-001/008 | Barramentos e CAN |
| SEC | Requisitos de segregação e inibição |
| ENE | Dimensionamento energético |

---

# 6. Estado / Pontos Em Aberto

- **Estado**: Em Desenvolvimento.
- **Pontos em aberto**:
  - Topologia física da FABRIC e conetores/depopulação da PCB do cluster.
  - Flash/PSRAM por RP2350, boot, redundância A/B.
  - PMIC/LPDDR/eMMC finais do GCV e stack de layout.
  - Confirmação RS-422/RS-485, débito, pinagem RJ45, blindagem.
  - Redundância física de CAN (simples/dupla), terminação e encaminhamento.
  - Térmica, EMC/EMI, vibração e ensaios.

