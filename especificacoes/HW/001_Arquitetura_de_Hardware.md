# HW-001 — Arquitetura de Hardware

| Campo | Valor |
| --- | --- |
| **Código** | HW-001 |
| **Título** | Arquitetura de Hardware |
| **Versão** | 2.0 |
| **Estado** | Em Desenvolvimento |
| **Autor** | ShegaPT |
| **Classificação** | Especificação de Hardware |
| **Referência** | docs/Esquemas/Arquitetura-Computacional.md |

---

# 1. Objetivo

O presente documento define a arquitetura física geral do sistema AERUS-TELLUS.

Explica, de forma detalhada e pedagógica, como o sistema computacional embarcado está organizado em grupos especializados, que processadores são utilizados em cada nível, que família de placas de circuito impresso (PCB) materializa essa organização, como os grupos se interligam através de cinco redes distintas e como a alimentação em 3,3 V / 5 V / 12 V sustenta o conjunto.

Destina-se a enquadrar todos os restantes documentos de hardware (HW-002 a HW-009), bem como as especificações de comunicação, sensores, atuadores, segurança e energia.

---

# 2. Âmbito

Este documento abrange:

* a filosofia de computação distribuída adotada;
* os três níveis de processamento (Módulo Menor, Módulo Maior/Master, Master Geral e Computador de Visão);
* os nove grupos computacionais oficiais;
* a família de PCB adotada;
* as cinco redes de interligação e a rede de alimentação;
* os princípios de separação, autoridade e isolamento;
* os limites do documento e a relação com HW-002 a HW-009.

Não abrange:

* valores elétricos finais ao nível do pino (ver HW-004);
* dimensionamento térmico e de proteções ao nível do componente (ver HW-004, HW-005);
* protocolo lógico completo (ver COM);
* sensores e atuadores concretos (ver SEN, ACT);
* algoritmos de controlo, navegação e segurança (ver MAT, SEC).

---

# 3. Descrição

## 3.1 Filosofia geral: muitos computadores pequenos e especializados

A regra fundadora da arquitetura é:

> **Não construir um computador grande para fazer tudo. Construir vários computadores pequenos e especializados que, em conjunto, formam o computador do veículo.**

Cada unidade computacional executa uma responsabilidade bem delimitada, expõe interfaces claras e funciona, tanto quanto possível, de forma independente das restantes. A falha de um domínio funcional (por exemplo, missão) não implica automaticamente a perda do controlo de voo nem da supervisão de segurança.

A decomposição funcional adotada é:

```text
aquisição e normalização de sensores
  → processamento de sensores
    → fusão sensorial
      → navegação
        → controlo de voo
          → comando de atuadores
            + cálculo matemático dedicado
            + gestão de missão
            + supervisão e segurança FailSafe
            + visão computacional e vídeo
            + comunicação rádio e diagnóstico
```

## 3.2 Três níveis de processamento + visão

| Nível | Designação oficial | Processador | Papel principal |
| --- | --- | --- | --- |
| N1 | Módulo Menor | RP2040 | Aquisição, normalização, PWM, GPIO, SPI, I2C, UART, PIO, pequenas máquinas de estado determinísticas |
| N2 | Módulo Maior / Master de grupo | RP2350B / RP2354B | Processamento embarcado complexo, mestria de grupo, FPU/DSP, supervisão local, TrustZone, maior SRAM e PIO |
| N3 | Master Geral (cluster) | 4 × RP2350 em INTERCONNECT FABRIC (8 núcleos) | Controlo de voo, fusão sensorial, navegação, cálculo, missão, supervisão do cluster, diagnóstico |
| NV | Grupo Computacional de Visão (GCV) | NXP i.MX 8M Plus MIMX8ML4DVNLZAB + Router RP2350 | Vídeo 720p60, ISP, GPU, NPU, codificação, ligação à câmara por MIPI CSI |

### 3.2.1 Quadro comparativo dos processadores

| Característica | RP2040 (Módulo Menor) | RP2350 (Módulo Maior / Master / Cluster) | i.MX 8M Plus MIMX8ML4DVNLZAB (GCV) |
| --- | --- | --- | --- |
| Núcleos | 2 × ARM Cortex-M0+ | 2 × ARM Cortex-M33 (ou 2 × Hazard3 RISC-V, selecionável) | 4 × ARM Cortex-A53 + 1 × Cortex-M7 |
| Frequência máxima | até 133 MHz | até 150 MHz | A53 até ~1,8 GHz; M7 até ~800 MHz (valores nominais NXP, a confirmar por revisão de silício) |
| SRAM interna | 264 KB | 520 KB | SRAM interna + LPDDR externa (capacidade por definir) |
| Flash | Externa (QSPI) | Externa QSPI; variante RP2354B com 2 MB empilhados | eMMC externa + Flash QSPI para arranque (por definir) |
| GPIO | 30 | 30 na variante A; 48 na variante B | Bancos de I/O de aplicação + M7 (mapeamento na carrier, por definir) |
| ADC | 4 entradas | ADC (8 entradas na variante B) | Via periféricos externos e PMIC (o i.MX não substitui o ADC de aquisição) |
| PWM | 16 canais | 24 canais na variante B | PWM de aplicação e de gestão de energia/iluminação |
| PIO | 8 máquinas de estado (2 blocos) | 12 máquinas de estado (3 blocos) | Não aplicável; periféricos dedicados (SAI, eCSPI, I2C, UART, PCIe, USB, GbE, CAN-FD) |
| DMA | Sim | 16 canais | Controladores DMA do SoC + GPU/VPU |
| FPU / DSP | Não | FPU de precisão simples e dupla; instruções DSP; TrustZone; acelerador SHA-256 | GPU (OpenGL ES/Vulkan), ISP, NPU (~2,3 TOPS), VPU para codificação/descodificação |
| USB | USB 1.1 dispositivo/anfitrião | USB 1.1 | USB 3.0 / 2.0 OTG |
| Câmaras | Não | Não (apenas supervisão e transporte) | 2 × MIPI CSI, ISP dedicado |
| Redes | UART/SPI/I2C/CAN via controlador externo | UART/SPI/I2C/CAN-FD via controlador; Ethernet via MAC externo quando necessário | 2 × GbE, 2 × CAN-FD nativos, PCIe, UART/SPI/I2C |
| Vocação | Periferia determinística de baixo custo | Nó computacional determinístico principal | Computador multimédia e de inteligência artificial embarcada |

A variante preferencial para qualquer função de mestria é a **RP2350B / RP2354B** (encapsulamento QFN-80, 10 × 10 mm, 48 GPIO, 8 entradas analógicas, mais PWM), precisamente pelo número de interfaces necessárias a um Master de grupo.

### 3.2.2 Módulo Menor (RP2040) — em detalhe

O RP2040 executa o seguinte encadeamento canónico:

```text
Sensor / Entrada física
  ↓
RP2040 — aquisição (ADC, GPIO, SPI, I2C, UART, PIO)
  ↓
filtragem → calibração → normalização → validação
  ↓
mensagem normalizada
  ↓
barramento do sistema (CAN-Principal via controlador)
```

E, no sentido da atuação:

```text
Comando normalizado (CAN-Principal)
  ↓
RP2040 — validação e limites
  ↓
geração PWM / GPIO / SPI / UART
  ↓
Atuador / Controlador
  ↓
leitura de retorno (feedback)
  ↓
estado normalizado → CAN-Principal
```

### 3.2.3 Módulo Maior / Master (RP2350B/2354B) — em detalhe

O RP2350B é o Master de cada grupo que exija cálculo, supervisão ou coordenação. Trata, entre outras, de fusão sensorial, navegação, controlo, gestão de missão, supervisão FailSafe e encaminhamento (Router) no GCV.

Características exploradas de forma sistemática: FPU para cálculo em vírgula flutuante, instruções DSP para filtragem, 520 KB de SRAM para buffers e filas, 12 PIO para protocolos dedicados e para o Interconnect Fabric, TrustZone para separação entre firmware crítico e não crítico, SHA-256 para integridade e arranque seguro.

### 3.2.4 Master Geral — cluster de 4 × RP2350 + Interconnect Fabric

O Master Geral é uma única PCB da família COMPUTE-FLIGHT-CLUSTER com quatro RP2350B/2354B, totalizando oito núcleos aplicacionais:

```text
4 × RP2350
  ↓
4 × 2 núcleos
  ↓
8 núcleos computacionais especializados e cooperantes
```

Distribuição inicial (a afinar por medição de carga em HW-002 e HW-009):

```text
RP2350 #1
├── Núcleo 0 → Controlo de Voo
└── Núcleo 1 → Fusão Sensorial

RP2350 #2
├── Núcleo 0 → Navegação
└── Núcleo 1 → Cálculo Matemático dedicado

RP2350 #3
├── Núcleo 0 → Gestão de Missão
└── Núcleo 1 → Planeamento / lógica de missão

RP2350 #4
├── Núcleo 0 → Supervisão / FailSafe do cluster
└── Núcleo 1 → Diagnóstico / monitorização de saúde (health)
```

Os quatro circuitos não são apresentados ao programador como um único SoC simétrico. São **serviços computacionais cooperantes** que comunicam por mensagens estruturadas (IPC/RPC) sobre o Interconnect Fabric interno (combinação de SPI dedicado, PIO, DMA e memória partilhada externa, com topologia ponto a ponto em malha — ver HW-006).

### 3.2.5 Grupo Computacional de Visão (GCV) — i.MX 8M Plus

O GCV resolve um problema de natureza distinta: débito de píxeis, memória e aceleração. Por isso recorre ao NXP i.MX 8M Plus MIMX8ML4DVNLZAB:

```text
                   i.MX 8M Plus
              ┌──────────────────┐
              │ Cortex-A53 ×4    │ → Linux aplicacional, visão, telemetria de vídeo
              ├──────────────────┤
              │ Cortex-M7        │ → tempo real, controlo de pipeline
              ├──────────────────┤
              │ GPU              │ → composição, pré/pós-processamento
              ├──────────────────┤
              │ ISP              │ → pipeline da câmara MIPI CSI
              ├──────────────────┤
              │ NPU (~2,3 TOPS)  │ → deteção e classificação (função futura)
              ├──────────────────┤
              │ VPU              │ → codificação 720p60 e stream 720p30
              └──────────────────┘
```

Encadeamento de vídeo:

```text
Câmara
  │ MIPI CSI
  ▼
i.MX 8M Plus → ISP → CPU/GPU/NPU → VPU
  │
  ├── processamento principal 720p60
  └── conversão → 720p30 → Router RP2350 → RJ45 → TX 5,8 GHz → estação terrestre
```

O GCV inclui sempre um **Router RP2350** que trata de watchdog, gestão de energia, arranque, recuperação e comunicação com o CAN-Principal. O i.MX nunca fala diretamente CAN-Principal sem passar pelo Router (ver HW-006 e HW-007).

## 3.3 Os nove grupos computacionais (nomenclatura oficial)

| # | Grupo oficial | Sigla funcional | Processador de referência | PCB de referência |
| --- | --- | --- | --- | --- |
| 1 | Grupo Computacional Sensorial | SENSORIAL | RP2040 (aquisição); RP2350B como Master quando o conjunto exigir fusão local | COMPUTE-SENSORIAL; COMPUTE-NODE para o Master |
| 2 | Grupo Computacional Atuador | ATUADOR | RP2040 para atuação simples; RP2350B para conjuntos com cinemática ou diagnóstico pesado | COMPUTE-ACTUATOR |
| 3 | Grupo Computacional de Controlo de Voo | VOO | RP2350 (núcleo dedicado no Master Geral) | COMPUTE-FLIGHT-CLUSTER |
| 4 | Grupo Computacional de Navegação | NAV | RP2350 (núcleo dedicado no Master Geral) | COMPUTE-FLIGHT-CLUSTER |
| 5 | Grupo Computacional de Missão | MISSÃO | RP2350 (núcleos dedicados no Master Geral) | COMPUTE-FLIGHT-CLUSTER |
| 6 | Grupo Computacional de Cálculo | CÁLCULO | RP2350 (núcleo/serviço matemático no Master Geral) | COMPUTE-FLIGHT-CLUSTER |
| 7 | Grupo Computacional FailSafe/Supervisão | FAILSAFE | RP2350 (núcleo supervisor no Master Geral + nós FailSafe distribuídos em COMPUTE-NODE) | COMPUTE-FLIGHT-CLUSTER + COMPUTE-NODE |
| 8 | Grupo Computacional de Visão (GCV) | VISÃO | i.MX 8M Plus + Router RP2350 | COMPUTE-VISION-CARRIER |
| 9 | Grupo Computacional de Comunicação | COMUNICAÇÃO | RP2040/RP2350 nos adaptadores + RP2350 Router no GCV + Master Geral como gestor | COMPUTE-NODE + COMM-RF |

Qualquer menção a designações anteriores, baseadas em famílias de consumo genéricas, encontra-se revogada. A única nomenclatura válida é a do quadro acima.

Diagrama de autoridade (não representa cablagem):

```text
              Grupo FailSafe/Supervisão
                         │
          ┌──────────────┴──────────────┐
          │                             │
   Grupo de Missão              Grupo de Controlo de Voo
          │                             │
          │        ┌────────────────────┼───────────────────┐
          │        │                    │                   │
          ▼        ▼                    ▼                   ▼
   Grupo de  Grupo de            Grupo                Grupo
   Cálculo   Navegação         Sensorial              Atuador
          │        │                    │                   │
          └────────┴─────────┬──────────┴──────────┬────────┘
                             │                     │
                             ▼                     ▼
                    Grupo de Visão (GCV)   Grupo de Comunicação
```

Princípio de segurança estrutural:

```text
MISSÃO
  │ solicita / propõe
  ▼
CONTROLO DE VOO
  │ valida (envelope, limites, estado FailSafe)
  ▼
ATUADOR
  │ executa e devolve feedback
```

Nunca é permitido o caminho direto `MISSÃO → ATUADOR` sem validação do Controlo de Voo, nem o caminho `VISÃO → ATUADOR`.

## 3.4 Família de PCB (nomenclatura oficial)

| PCB | Composição | Grupos servidos | Notas |
| --- | --- | --- | --- |
| COMPUTE-SENSORIAL | 1 × RP2040 + condicionamento + proteção + CAN-Principal via controlador | Sensorial | Placa periférica distribuída junto aos sensores |
| COMPUTE-ACTUATOR | RP2040 (versão simples) ou RP2350B (versão com diagnóstico/cinemática) + andares de potência/comando + leitura de retorno | Atuador | Versão RP2350 quando o atuador exigir FPU, mais PWM ou TrustZone |
| COMPUTE-NODE | 1 × RP2350B/2354B genérico | Sensorial (Master), Comunicação, FailSafe distribuído, Navegação remota quando justificado | Nó genérico; o firmware define a personalidade |
| COMPUTE-FLIGHT-CLUSTER | 4 × RP2350B/2354B + Interconnect Fabric + Flash/PSRAM + CAN-Principal + RJ45 para rádios 2,4 GHz/868 MHz + gestão de energia e relógio | Voo, Navegação, Missão, Cálculo, FailSafe/Supervisão (núcleo supervisor) | Master Geral do veículo |
| COMPUTE-VISION-CARRIER | Carrier + módulo computacional (i.MX 8M Plus + LPDDR + eMMC + PMIC NXP + MIPI CSI) + Router RP2350 + Ethernet + CAN + Power + System-Connector + RJ45 para TX 5,8 GHz | Visão (GCV) | Opção modular recomendada para a primeira revisão; alternativa monolítica apenas após validação |
| COMM-RF | Três placas rádio: 5,8 GHz (vídeo/telemetria descendente), 2,4 GHz (comando/telemetria), 868 MHz (telemetria de longo alcance), cada uma com RJ45-RS | Comunicação (e GCV para 5,8 GHz) | Ligação ao sistema exclusivamente por ficha RJ45 par RS/série + alimentação; sem I2C/SPI exposto ao exterior |

```text
┌────────────────────────────────────────────────────────┐
│ COMPUTE-VISION-CARRIER                                 │
│                                                        │
│  Câmara FFC → MIPI CSI → Módulo i.MX (SoC+LPDDR+eMMC+  │
│  PMIC) → Router RP2350 → CAN-Principal + Ethernet +    │
│  RJ45 (→ TX 5,8 GHz) + Power + System-Connector        │
└────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────┐
│ COMPUTE-FLIGHT-CLUSTER (Master Geral)                  │
│                                                        │
│  RP2350 #1 ⇄ RP2350 #2 ⇄ RP2350 #3 ⇄ RP2350 #4         │
│  (Interconnect Fabric) → CAN-Principal + RJ45 (→ RX    │
│  2,4 GHz / TX 868 MHz) + relógio + gestão de energia   │
└────────────────────────────────────────────────────────┘
```

Cada PCB possui identificação própria, versão de hardware, firmware próprio, watchdog, diagnóstico e conetor normalizado.

## 3.5 As cinco redes + alimentação

| Rede | Designação | Meio físico | Utilizadores | Função |
| --- | --- | --- | --- | --- |
| R1 | CAN-Principal | CAN FD, par trançado, terminação nas extremidades | Todos os grupos via os respetivos Masters/Routers | Barramento operacional partilhado: sensores normalizados, comandos validados, estados, missão, diagnóstico |
| R2 | Interconnect Fabric do Master Geral | Malha ponto a ponto SPI/PIO/DMA + memória partilhada externa | Os 4 × RP2350 internos | IPC/RPC determinístico de baixa latência entre os 8 núcleos |
| R3 | Ligação de Visão GCV↔Sistema | UART/SPI/Ethernet interna Carrier↔módulo + CAN-Principal via Router; MIPI CSI câmara→i.MX | i.MX ↔ Router RP2350 ↔ CAN-Principal | Isolar o débito de píxeis do barramento operacional; o Router filtra e publica apenas metadados e estado |
| R4 | Rede Rádio 5,8 GHz | RJ45 (série/RS sobre RJ45) GCV→placa COMM-RF 5,8 GHz → TX | GCV → estação terrestre | Vídeo 720p30 + telemetria descendente de visão |
| R5 | Redes Rádio 2,4 GHz + 868 MHz | RJ45 Master Geral→placas COMM-RF 2,4 GHz (RX) e 868 MHz (TX/RX) | Master Geral ↔ estação terrestre / operador | Comando ascendente e telemetria bidirecional de longo alcance |
| E | Alimentação | Barramento 12 V / 5 V / 3,3 V + conversões locais + PMIC NXP no GCV e no cluster | Todas as PCB | Ver HW-005; sequenciamento NXP obrigatório no GCV |

```text
                    CAN-Principal (R1)
                         │
   ┌─────────┬───────────┼────────────┬──────────┐
   ▼         ▼           ▼            ▼          ▼
SENSORIAL  ATUADOR  FLIGHT-CLUSTER  GCV-Router  COMUNICAÇÃO
   │         │      (R2 interno)      │ (R3)      │ (R4/R5 via RJ45)
   │         │           │            │          │
   │         │      RJ45─┼─→ 2,4 GHz / 868 MHz   │
   │         │           │                       │
   │         │      GCV ─┴─→ RJ45 → 5,8 GHz TX   │
```

## 3.6 O que a arquitetura proíbe

* Concentrar todas as responsabilidades num único microcontrolador.
* Utilizar o RP2350 onde um RP2040 bem dimensionado baste.
* Tratar o cluster como um único SoC simétrico e transparente.
* Enviar píxeis em bruto para RP2040/RP2350.
* Misturar lógica de missão com acionamento físico sem validação.
* Utilizar o barramento rádio externo como substituto da comunicação interna.
* Alimentar o i.MX ou as DDR diretamente de 3,3/5/12 V sem PMIC e sequenciamento NXP.
* Desenhar a carrier do GCV sem cumprir os requisitos de layout NXP para DDR e MIPI.

---

# 4. Exemplos

## Exemplo 1 — Da pressão estática ao comando do profundor

```text
Tomada estática → COMPUTE-SENSORIAL (RP2040)
  → filtragem + calibração + conversão em altitude normalizada
  → CAN-Principal (R1)
  → Master Geral: Fusão → Navegação → Controlo de Voo
  → CAN-Principal: comando validado do profundor
  → COMPUTE-ACTUATOR (RP2040/RP2350)
  → PWM verificado + feedback → CAN-Principal
```

## Exemplo 2 — Perda do barramento principal

```text
CAN-Principal (R1) indisponível
  → Núcleo supervisor do cluster + nós FailSafe detetam por heartbeat/timeout
  → Controlo de Voo mantém último modo seguro com dados locais
  → FailSafe avalia envelope e, se necessário, ordena inibição do ATUADOR normal
  → Via de emergência (FailSafe → atuação mínima) assume superfícies críticas
  → Evento registado; telemetria via R5 quando disponível
```

## Exemplo 3 — Cadeia de visão ponta a ponta

```text
Câmara → MIPI CSI → ISP (i.MX) → VPU 720p60/720p30
  → Router RP2350 publica em R1 apenas: estado, heartbeat, telemetria compacta
  → Stream 720p30 via RJ45 → placa COMM-RF 5,8 GHz → estação terrestre
  → Deteção NPU (futura) publica em R1 apenas caixas/objetos, nunca píxeis
```

---

# 5. Interfaces

| Interface | Onde é definida | Relação com este documento |
| --- | --- | --- |
| CAN-Principal (elétrica e conetores) | HW-004, HW-006 | Este documento define a existência e o papel; o detalhe pertence a HW-004/HW-006 |
| Interconnect Fabric | HW-006 | Topologia, protocolo IPC, latência e sincronismo |
| MIPI CSI, DDR, Ethernet, RJ45-RS | HW-004, HW-007 | Requisitos de impedância e comprimento; valores finais por definir |
| Alimentação 3,3/5/12 V, PMIC, sequenciamento | HW-005 | Árvore de energia e sequência NXP |
| Periféricos (sensores, atuadores, ESC, câmara, rádios) | HW-007, SEN, ACT | Atribuição grupo↔periférico |
| Redundância e isolamento | HW-008 | Política de degradação e independência do FailSafe |
| Configuração por aeronave | HW-009 | Parametrização pré-compilação |

---

# 6. Pontos em aberto

| # | Ponto em aberto | Documento de resolução |
| --- | --- | --- |
| 1 | Topologia física definitiva do Interconnect Fabric (largura, relógio, memória partilhada, FPGA de suporte ou apenas PIO/DMA) | HW-006 |
| 2 | Protocolo IPC: formato, fragmentação, largura de banda, latência máxima, sincronização temporal, arranque e atualização de firmware do cluster | HW-006, COM |
| 3 | Escolha RP2350B face a RP2354B por nó (Flash empilhada, PSRAM, custo, disponibilidade) e quantidades de Flash/PSRAM | HW-009 |
| 4 | Carrier do GCV: capacidade LPDDR, eMMC, PMIC exato NXP, sequência, indutores, conetor MIPI, larguras e impedâncias, empilhamento | HW-004, HW-005, HW-007 |
| 5 | Sistema operativo do GCV, pipeline VPU, codecs, formato de transporte 720p30, mecanismo Router↔i.MX e Router↔R1 | HW-006, HW-007 |
| 6 | Atribuição definitiva dos atuadores à via de emergência FailSafe e dimensionamento COMM-RF (potências, antenas, fichas RJ45-RS) | HW-007, HW-008, HW-009 |
| 7 | Gestão térmica, EMC/EMI, certificação e estratégia de ensaios do conjunto | HW-003, HW-004, HW-005, HW-008 |

---

# 7. Referências

* docs/Esquemas/Arquitetura-Computacional.md (referência normativa de computação)
* HW-002 — Grupos Computacionais
* HW-003 — Distribuição de Hardware
* HW-004 — Interfaces Elétricas
* HW-005 — Alimentação e Distribuição de Energia
* HW-006 — Interfaces de Comunicação
* HW-007 — Interfaces de Periféricos
* HW-008 — Redundância e Isolamento de Hardware
* HW-009 — Expansibilidade e Configuração de Hardware
* COM, SEN, ACT, SEC, MAT, ENE — especificações complementares
