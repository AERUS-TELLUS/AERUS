# HW-002 — Grupos Computacionais

| Campo | Valor |
| --- | --- |
| **Código** | HW-002 |
| **Título** | Grupos Computacionais |
| **Versão** | 2.0 |
| **Estado** | Em Desenvolvimento |
| **Autor** | ShegaPT |
| **Classificação** | Especificação de Hardware |
| **Referência** | docs/Esquemas/Arquitetura-Computacional.md |

---

# 1. Objetivo

O presente documento define o conceito de Grupo Computacional e descreve, de forma detalhada e explicativa, os nove grupos oficiais do sistema AERUS-TELLUS: Sensorial, Atuador, Controlo de Voo, Navegação, Missão, Cálculo, FailSafe/Supervisão, Visão (GCV) e Comunicação.

Explica o que distingue um grupo lógico de uma placa física, que processador (RP2040, RP2350B/2354B ou i.MX 8M Plus) serve cada grupo, como os grupos se relacionam em autoridade e em fluxo de dados e que exemplos concretos ilustram o funcionamento quotidiano de cada um.

---

# 2. Âmbito

Abrange:

* conceito de Grupo Computacional e de elemento físico;
* os nove grupos oficiais, com função, responsabilidades, processador e placa;
* quadro comparativo RP2040 / RP2350 / i.MX 8M Plus aplicado aos grupos;
* hierarquia de autoridade e fluxos normais de informação;
* biblioteca matemática por domínio e gestão de recursos.

Não abrange:

* distribuição física na célula (ver HW-003);
* detalhe elétrico e de fichas (ver HW-004);
* energia (ver HW-005);
* protocolo e redes (ver HW-006);
* periféricos concretos (ver HW-007, SEN, ACT).

---

# 3. Descrição

## 3.1 Conceito de Grupo Computacional

Um Grupo Computacional é uma **unidade lógica e funcional** constituída por um ou mais elementos computacionais que partilham a mesma responsabilidade arquitetónica.

```text
Grupo Computacional (lógica: responsabilidade + autoridade + interfaces)
  │
  ├── Elemento físico 01 (PCB + firmware + periféricos)
  ├── Elemento físico 02
  └── Elemento físico 03
```

Um grupo não corresponde obrigatoriamente a um processador, a uma placa ou a um ponto físico único. A quantidade de elementos depende da aeronave: número de sensores, localização de atuadores, frequências, redundância e massa disponível.

Exemplo para o Grupo Sensorial:

```text
Grupo Computacional Sensorial
│
├── COMPUTE-SENSORIAL_01 (RP2040, sensores do nariz)
├── COMPUTE-SENSORIAL_02 (RP2040, sensores da asa esquerda)
├── COMPUTE-SENSORIAL_03 (RP2040, sensores da asa direita)
└── COMPUTE-NODE_SENS_MASTER (RP2350B, Master do grupo, fusão local)
```

## 3.2 Quadro geral dos nove grupos

| Grupo oficial | Responsabilidade nuclear | Processador | PCB | Observações |
| --- | --- | --- | --- | --- |
| 1. Sensorial | Aquisição, filtragem, calibração, normalização, validação e publicação | RP2040 nos nós; RP2350B no Master do grupo | COMPUTE-SENSORIAL + COMPUTE-NODE | Nós junto aos sensores; Master agrega e publica no CAN-Principal |
| 2. Atuador | Validação, conversão, comando PWM/GPIO/série, leitura de retorno, publicação de estado | RP2040 (simples); RP2350B (conjuntos exigentes) | COMPUTE-ACTUATOR | Nunca aceita ordem direta da Missão sem validação do Voo |
| 3. Controlo de Voo | Leis de controlo, estabilização, envelope, modos de voo | RP2350, núcleo dedicado no Master Geral | COMPUTE-FLIGHT-CLUSTER | Autoridade técnica sobre o Atuador em operação normal |
| 4. Navegação | Estimação de posição, velocidade, atitude, altitude; fusão com dados sensoriais | RP2350, núcleo dedicado no Master Geral | COMPUTE-FLIGHT-CLUSTER | Serve Voo e Missão; não comanda atuadores diretamente |
| 5. Missão | Plano de missão, fases, planeamento, gestão de carga útil e de implementos | 2 × núcleos RP2350 no Master Geral | COMPUTE-FLIGHT-CLUSTER | Propõe; não impõe. O Voo valida |
| 6. Cálculo | Serviço matemático especializado (álgebra, filtros, geodesia, otimização) para os restantes núcleos | RP2350, núcleo/serviço dedicado | COMPUTE-FLIGHT-CLUSTER | Exposto por IPC/RPC; evita duplicar matemática em cada núcleo |
| 7. FailSafe/Supervisão | Monitorização independente, deteção de falhas, decisão de emergência, inibição, atuação mínima | RP2350 supervisor no cluster + nós COMPUTE-NODE distribuídos | COMPUTE-FLIGHT-CLUSTER + COMPUTE-NODE | Maior autoridade hierárquica; avalia e pode recusar pedidos da Missão |
| 8. Visão — GCV | Aquisição MIPI, ISP, vídeo 720p60/720p30, GPU, NPU (futura), telemetria de visão | i.MX 8M Plus MIMX8ML4DVNLZAB + Router RP2350 | COMPUTE-VISION-CARRIER | Nunca publica píxeis no CAN-Principal; apenas metadados e estado |
| 9. Comunicação | Gestão das placas rádio 5,8 GHz / 2,4 GHz / 868 MHz via RJ45-RS, encaminhamento, diagnóstico externo | RP2350 (gestão) + RP2040 (adaptadores quando simples) | COMPUTE-NODE + COMM-RF | Master Geral gere R5; GCV gere R4 |

## 3.3 Características dos processadores aplicadas aos grupos

| Característica | RP2040 — nós Sensorial/Atuador/Comunicação simples | RP2350B/2354B — Masters, cluster, FailSafe, Router | i.MX 8M Plus — GCV |
| --- | --- | --- | --- |
| Núcleos | 2 × Cortex-M0+ a 133 MHz | 2 × Cortex-M33 a 150 MHz, FPU, DSP, TrustZone, SHA-256 | 4 × Cortex-A53 + Cortex-M7 + GPU + ISP + NPU + VPU |
| Memória | 264 KB SRAM; Flash QSPI externa | 520 KB SRAM; Flash QSPI ou 2 MB empilhados (RP2354B); PSRAM expansível | LPDDR externa + eMMC; dimensionamento por definir |
| GPIO / PWM / ADC / PIO | 30 GPIO, 4 ADC, 16 PWM, 8 PIO | 48 GPIO, 8 ADC, 24 PWM, 12 PIO (variante B) | Periféricos de aplicação; MIPI CSI ×2; GbE ×2; CAN-FD ×2 |
| Interfaces de sistema | UART ×2, SPI ×2, I2C ×2, USB 1.1 | UART ×2, SPI ×2, I2C ×2, USB 1.1 + PIO para CAN/Ethernet via controlador | USB 3.0/2.0, PCIe, SAI, eCSPI, UART, GbE, CAN-FD nativos |
| Segurança | Watchdog, arranque simples | TrustZone, arranque seguro, SHA-256, watchdog com janela | TrustZone, arranque seguro, watchdog do SoC + watchdog externo do Router |
| Papel típico | Ler um sensor e publicar valor normalizado; gerar um PWM verificado | Coordenar um grupo; fundir sensores; navegar; controlar; supervisionar | Ver, codificar, inferir, registar |

A regra de escolha é funcional: usa-se o processador mais simples que cumpra com margem os requisitos temporais, de memória e de interfaces. O RP2350B/2354B é obrigatório sempre que exista FPU/DSP intensivo, TrustZone, mais de 30 GPIO ou coordenação de grupo.

## 3.4 Os nove grupos em detalhe

### 3.4.1 Grupo Computacional Sensorial

Função: transformar sinais elétricos heterogéneos em grandezas físicas normalizadas, validadas e datadas.

Responsabilidades: aquisição (ADC, SPI, I2C, UART, PIO), filtragem, calibração, conversão de unidades, validação de gama e de coerência, agregação por elemento, publicação no CAN-Principal, sinalização de qualidade (válido, degradado, inválido, sem resposta).

Estrutura: N nós COMPUTE-SENSORIAL (RP2040) junto aos sensores + um Master COMPUTE-NODE (RP2350B) quando o volume justificar. Cada nó cumpre as frequências dos seus periféricos sem depender do Master para amostrar.

### 3.4.2 Grupo Computacional Atuador

Função: transformar comandos normalizados em sinais físicos seguros e devolver o estado real.

Responsabilidades: receção do CAN-Principal, verificação de validade e de limites, conversão para PWM/GPIO/série, comando do andar de potência ou do controlador do atuador (incluindo ESC de motores), leitura de retorno (posição, rotação, corrente, temperatura, estado do controlador), publicação de estado, aplicação de estado seguro em arranque, falha ou inibição FailSafe.

Variantes COMPUTE-ACTUATOR: versão RP2040 para servos e saídas simples; versão RP2350B para conjuntos com cinemática, múltiplos PWM sincronizados, diagnóstico pesado ou TrustZone.

### 3.4.3 Grupo Computacional de Controlo de Voo

Função: manter a aeronave dentro do envelope e executar os comandos validados.

Vive num núcleo dedicado do Master Geral (COMPUTE-FLIGHT-CLUSTER). Consome fusão sensorial e navegação, aplica leis de controlo, impõe limites, gera comandos para o Grupo Atuador e publica estado de voo. É a única entidade que pode validar comandos com destino aos atuadores em operação normal.

### 3.4.4 Grupo Computacional de Navegação

Função: estimar onde a aeronave está, para onde vai e com que atitude e energia.

Vive em núcleo dedicado do Master Geral. Consome sensores normalizados e fusão, executa filtros e geodesia (com recurso ao Grupo de Cálculo para operações pesadas), publica posição, velocidade, atitude, altitude e incertezas. Serve Voo, Missão e FailSafe.

### 3.4.5 Grupo Computacional de Missão

Função: gerir o plano — fases, waypoints, carga útil, implementos, decisões de missão.

Ocupa dois núcleos do Master Geral (gestão + planeamento/lógica). Publica intenções e pedidos (nunca ordens diretas aos atuadores). O Controlo de Voo e o FailSafe validam cada pedido face ao envelope e à segurança.

### 3.4.6 Grupo Computacional de Cálculo

Função: serviço matemático partilhado do cluster.

Exemplo de chamada entre núcleos (IPC/RPC):

```text
Núcleo de Missão
  │ MATH_REQUEST (matriz, filtro, geodesia)
  ▼
Núcleo de Cálculo — executa com FPU/DSP
  │ MATH_RESPONSE + tempo + estado
  ▼
Núcleo de Missão — prossegue
```

Evita que cada núcleo reimplemente a mesma matemática e facilita ensaio e certificação.

### 3.4.7 Grupo Computacional FailSafe/Supervisão

Função: proteger pessoas, bens e aeronave, mesmo contra o próprio sistema normal.

É o grupo de maior autoridade hierárquica. Monitoriza heartbeats, latências, CRC/HMAC, coerência de dados e watchdogs; avalia pedidos da Missão e do Voo; pode inibir o Atuador normal e ordenar atuação mínima de emergência; gere sincronização temporal e registo de falhas. Inclui o núcleo supervisor do cluster e nós COMPUTE-NODE distribuídos com sensores de reserva (posição, atitude, altitude, temperatura) de fabricantes, quando possível, distintos dos principais.

Exemplo de decisão independente:

```text
Missão → pede emergência / FailSafe avalia sensores + estados + feedback
  ├── aceita → procedimento de emergência
  └── recusa → mantém operação normal e regista
```

### 3.4.8 Grupo Computacional de Visão (GCV)

Função: ver, codificar e, no futuro, compreender.

Composição COMPUTE-VISION-CARRIER: módulo com i.MX 8M Plus + LPDDR + eMMC + PMIC NXP + MIPI CSI, sobre carrier com Router RP2350, Ethernet, CAN, Power e System-Connector, mais RJ45 para a placa COMM-RF de 5,8 GHz.

O Router trata de watchdog do SoC, temperatura, estado da câmara e do armazenamento, gestão de energia, arranque, recuperação, telemetria e publicação filtrada no CAN-Principal. O i.MX trata de píxeis. Esta separação é intencional e inegociável.

### 3.4.9 Grupo Computacional de Comunicação

Função: levar e trazer informação entre o veículo e o exterior, sem confundir redes internas com externas.

Gestão: Master Geral gere as placas COMM-RF de 2,4 GHz (RX de comando) e 868 MHz (telemetria bidirecional de longo alcance) via RJ45-RS; GCV gere a placa COMM-RF de 5,8 GHz (TX de vídeo 720p30 + telemetria descendente) via RJ45. Nós COMPUTE-NODE tratam de encaminhamento, filas, prioridades e diagnóstico externo (manutenção em terra).

## 3.5 Separação funcional resumida

| Grupo | Palavra-chave | Não faz |
| --- | --- | --- |
| Sensorial | Medir e normalizar | Controlo, missão, atuação |
| Atuador | Executar com segurança | Decidir missão ou navegação |
| Voo | Controlar e validar | Planear missão |
| Navegação | Estimar | Comandar atuadores |
| Missão | Planear e pedir | Comandar atuadores diretamente |
| Cálculo | Servir matemática | Decidir sozinho |
| FailSafe | Proteger e inibir | Gerir missão normal |
| Visão | Ver e codificar | Comandar voo |
| Comunicação | Transportar | Decidir conteúdo operacional |

## 3.6 Biblioteca matemática por domínio

Cada domínio que calcule possui a sua implementação da biblioteca matemática aplicável, distribuída por elemento para evitar dependência central:

```text
Sensorial_01 → MAT-SENSORIAL (filtros, calibração)
Sensorial_02 → MAT-SENSORIAL (cópia coerente)
Cálculo      → MAT-CÁLCULO (álgebra, geodesia, otimização)
Navegação    → MAT-NAV (filtros de estimação)
Voo          → MAT-VOO (leis de controlo)
```

A definição das fórmulas pertence a MAT; este documento define apenas o princípio de distribuição.

## 3.7 Gestão de recursos

Cada elemento utiliza apenas os módulos necessários ao modo e estado correntes. Módulos inativos podem ser suspensos para libertar CPU, memória, barramento e energia, sem comprometer funções necessárias ao estado atual. A política concreta por módulo pertence a SYS e SEC.

---

# 4. Exemplos

## Exemplo 1 — Aeronave pequena (configuração mínima)

```text
Sensorial:  1 × COMPUTE-SENSORIAL + Master acumulado no cluster
Atuador:    1 × COMPUTE-ACTUATOR (RP2040)
Cluster:    1 × COMPUTE-FLIGHT-CLUSTER (8 núcleos ativos, alguns em carga reduzida)
GCV:        1 × COMPUTE-VISION-CARRIER
Comunicação: placas COMM-RF 5,8 GHz + 2,4 GHz (868 MHz opcional)
```

## Exemplo 2 — Aeronave grande com sensores distribuídos

```text
Sensorial:  5 × COMPUTE-SENSORIAL (nariz, asas, cauda, trem, Pitot redundante)
            + 1 × COMPUTE-NODE Master
Atuador:    3 × COMPUTE-ACTUATOR (superfícies + propulsão + auxiliares)
Cluster:    1 × COMPUTE-FLIGHT-CLUSTER
FailSafe distribuído: 1 × COMPUTE-NODE com GPS/IMU/barómetro de reserva
GCV:        1 × COMPUTE-VISION-CARRIER
Comunicação: 3 × COMM-RF completas
```

## Exemplo 3 — Chamada Missão → Cálculo → Voo

```text
Missão precisa de distância geodésica e de uma otimização de percurso
  → IPC MATH_REQUEST ao Cálculo (com REQUEST_ID e TIMESTAMP)
  → Cálculo responde MATH_RESPONSE + CRC
  → Missão formula pedido de trajetória ao Voo
  → Voo valida envelope e publica comando ao Atuador
  → Atuador executa, lê feedback e publica estado
```

---

# 5. Interfaces

| Grupo | Publica (R1 CAN-Principal) | Consome | Redes físicas |
| --- | --- | --- | --- |
| Sensorial | Grandezas normalizadas + qualidade + heartbeat | Configuração, sincronismo temporal | R1; nós falam com Master por R1 |
| Atuador | Estado + feedback + diagnóstico | Comandos validados do Voo; inibição do FailSafe | R1 |
| Voo / Navegação / Missão / Cálculo | Estados, estimativas, pedidos, respostas matemáticas | Sensores, estados, IPC interno R2 | R2 (interno) + R1 (externo) |
| FailSafe | Estado de saúde, decisões, inibições | Tudo o necessário à avaliação (sensores, feedback, estados) | R1 + vias dedicadas de emergência (HW-008) |
| Visão (GCV) | Estado, heartbeat, telemetria compacta, deteções futuras (sem píxeis) | Configuração, sincronismo | R3 interno + R1 via Router + R4 (5,8 GHz) |
| Comunicação | Encaminhamento, estado dos enlaces, diagnóstico | Mensagens a transportar | R1 + R4/R5 via RJ45-RS |

---

# 6. Pontos em aberto

| # | Ponto em aberto | Resolução |
| --- | --- | --- |
| 1 | Distribuição definitiva dos 8 núcleos por carga medida (Voo, Fusão, Navegação, Cálculo, Missão ×2, Supervisão, Diagnóstico) | HW-006, HW-009, ensaios de carga |
| 2 | Critério objetivo para decidir COMPUTE-ACTUATOR em RP2040 face a RP2350B por atuador | HW-007, ACT |
| 3 | Necessidade de Master Sensorial dedicado face a Master acumulado no cluster, por classe de aeronave | HW-009 |
| 4 | Nós FailSafe distribuídos: quantidade, sensores de reserva e diversidade de fabricantes | HW-008, SEN |
| 5 | Personalidades de firmware do COMPUTE-NODE (Sensorial-Master, Comunicação, FailSafe, Navegação remota) e sua certificação separada | COM, SEC |
| 6 | Sistema operativo do GCV, pipeline, codecs e formato das deteções NPU publicadas em R1 | HW-006, HW-007 |

---

# 7. Referências

* HW-001 — Arquitetura de Hardware
* HW-003 — Distribuição de Hardware
* HW-004 — Interfaces Elétricas
* HW-005 — Alimentação e Distribuição de Energia
* HW-006 — Interfaces de Comunicação
* HW-007 — Interfaces de Periféricos
* HW-008 — Redundância e Isolamento de Hardware
* HW-009 — Expansibilidade e Configuração de Hardware
* docs/Esquemas/Arquitetura-Computacional.md
