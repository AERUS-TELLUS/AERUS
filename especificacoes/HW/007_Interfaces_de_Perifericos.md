# HW-007 — Interfaces de Periféricos

| Campo | Valor |
| --- | --- |
| **Código** | HW-007 |
| **Título** | Interfaces de Periféricos |
| **Versão** | 2.0 |
| **Estado** | Em Desenvolvimento |
| **Autor** | ShegaPT |
| **Classificação** | Especificação de Hardware |
| **Referência** | docs/Esquemas/Arquitetura-Computacional.md |

---

# 1. Objetivo

O presente documento define como os periféricos — sensores, atuadores e controladores, câmara, placas rádio COMM-RF, sistemas auxiliares e implementos — se ligam fisicamente aos grupos computacionais e às PCB da família (COMPUTE-SENSORIAL, COMPUTE-ACTUATOR, COMPUTE-NODE, COMPUTE-FLIGHT-CLUSTER, COMPUTE-VISION-CARRIER e COMM-RF).

Explica a regra de atribuição (cada periférico tem um grupo responsável), as frequências de aquisição face às frequências de comunicação, a agregação, a qualidade dos dados, o comando verificado com retorno, a via de emergência FailSafe e a integração de implementos externos.

---

# 2. Âmbito

Abrange:

* sensores → Grupo Sensorial (RP2040 + Master RP2350B);
* atuadores/ESC → Grupo Atuador (RP2040 ou RP2350B);
* câmara MIPI → GCV (i.MX via COMPUTE-VISION-CARRIER);
* rádios 5,8 GHz / 2,4 GHz / 868 MHz → Grupo Comunicação via RJ45-RS (GCV gere 5,8 GHz; Master Geral gere 2,4 GHz e 868 MHz);
* sensores de reserva → Grupo FailSafe; periféricos auxiliares e implementos;
* inicialização, perda, identificação, configuração física e manutenção.

Não abrange:

* níveis ao pino e fichas (ver HW-004);
* energia (ver HW-005);
* protocolo e redes (ver HW-006);
* sensores/atuadores concretos (ver SEN, ACT) nem implementos concretos (ver IMP).

---

# 3. Descrição

## 3.1 Regra de atribuição

| Periférico | Grupo responsável | PCB | Processador que atende |
| --- | --- | --- | --- |
| Sensores de voo/missão (IMU, magnetómetro, baro, GPS principal, Pitot, temperatura, sonda) | Sensorial | COMPUTE-SENSORIAL (+ Master COMPUTE-NODE) | RP2040 adquire; RP2350B agrega/valida |
| Servos, superfícies, motores via ESC, auxiliares | Atuador | COMPUTE-ACTUATOR | RP2040 (simples) ou RP2350B (exigente) |
| Sensores de reserva (GPS/IMU/baro/temperatura de emergência) | FailSafe/Supervisão | COMPUTE-NODE dedicado | RP2350B |
| Câmara | Visão (GCV) | COMPUTE-VISION-CARRIER | i.MX 8M Plus (píxeis) + Router RP2350 (gestão) |
| Placas rádio 5,8 / 2,4 / 868 MHz | Comunicação (com GCV para 5,8 GHz e Master Geral para 2,4/868) | COMM-RF via RJ45-RS | RP2350 gestores; i.MX produz o stream |
| Auxiliares e implementos | Missão/Comunicação (integração), Voo/FailSafe (limites) | COMPUTE-NODE de integração | RP2350B |

A ligação física nunca confere autoridade: um implemento ligado a um nó de integração não comanda o voo; a câmara ligada ao GCV não comanda atuadores.

## 3.2 Sensores no Grupo Sensorial

```text
Sensor 1 ──┐
Sensor 2 ──┼──► COMPUTE-SENSORIAL (RP2040) ──► CAN-Principal R1 ──► Master Geral
Sensor 3 ──┤      (filtra, calibra, normaliza, valida)
Sensor N ──┘
```

Capacidades de referência do RP2040 (30 GPIO, 4 ADC, 16 PWM, 8 PIO, UART/SPI/I2C ×2, USB 1.1, 264 KB, 2 × M0+ a 133 MHz): suficientes para adquirir IMU por SPI, magnetómetro por I2C, GPS por UART, pressões por ADC/SPI e ainda gerar protocolos dedicados por PIO. Quando o conjunto exigir fusão local, buffers grandes ou TrustZone, o Master COMPUTE-NODE em RP2350B (48 GPIO, 8 ADC, 24 PWM, 12 PIO, 520 KB, FPU/DSP, 2 × M33 a 150 MHz) assume a agregação.

**Aquisição face a comunicação:**

```text
Sensor A ─► 100 Hz ┐
Sensor B ─► 50 Hz  ├─► nó acumula ─► pacote R1 ao período definido (ex.: 20 Hz)
Sensor C ─► 20 Hz  ┘
```

Cada sensor tem a sua frequência; o grupo tem o seu período de publicação. A estrutura das mensagens pertence a COM.

**Estado e qualidade:** cada periférico declara presença, inicialização, validade, degradação, ausência de resposta e incoerência. Valor adquirido sem validação não é valor publicado: gama, coerência cruzada, frescura e diagnóstico do canal condicionam a publicação, com a qualidade a acompanhar o dado.

**Redundância:** a arquitetura suporta N sensores para a mesma grandeza, em nós distintos e, quando a criticidade o justificar, de fabricantes/tecnologias distintos (ver HW-008). A fusão e a votação pertencem a MAT/SEN/SEC.

## 3.3 Atuadores no Grupo Atuador

```text
Master Geral (Voo, via R1)
  │
  ▼
COMPUTE-ACTUATOR ──► andar de potência / controlador / ESC ──► atuador
  │                         │
  │◄── retorno (posição, rotação, corrente, estado) ──◄──────┘
  │
  └──► estado + diagnóstico em R1
```

Ciclo de comando:

1. receber; 2. verificar validade e autenticidade; 3. verificar limites do atuador; 4. converter para PWM/GPIO/série; 5. executar; 6. ler retorno; 7. publicar estado.

Versão RP2040 para atuação simples; versão RP2350B quando exista cinemática, sincronismo multi-eixo, diagnóstico pesado ou necessidade de TrustZone. Motores via ESC: o ESC é a interface de potência; o retorno (rotação, corrente, tensão, temperatura, estado) é lido pelo mesmo COMPUTE-ACTUATOR. Limites (posição, velocidade, corrente, potência) são impostos localmente — nenhum comando fora de limites é executado.

## 3.4 Câmara e GCV

```text
Câmara ─FFC MIPI CSI curto─► módulo i.MX (ISP→CPU/GPU/NPU→VPU)
  → 720p60 interno + 720p30 para terra via Router→RJ45→COMM-RF 5,8 GHz
  → em R1 apenas metadados: estado, fps, latência, temperatura, deteções futuras
```

O RP2350 Router trata de presença da câmara, relógio, energia, watchdog do SoC, temperatura, armazenamento e publicação filtrada. O i.MX nunca é exposto ao CAN-Principal nem aos rádios sem passar pelo Router.

## 3.5 Rádios COMM-RF e sensores de reserva

```text
GCV ─RJ45─► COMM-RF 5,8 GHz ─TX─► terra (vídeo 720p30 + telemetria descendente)
Master Geral ─RJ45─► COMM-RF 2,4 GHz ─RX─► comando ascendente validado ─► R1
Master Geral ─RJ45─► COMM-RF 868 MHz ─TX/RX─► telemetria longo alcance
```

Sensores de reserva do FailSafe (GPS, IMU, barómetro, temperatura de emergência, a completar por análise): ligados a COMPUTE-NODE dedicados, independentes dos principais e, quando aplicável, de fabricantes distintos; alimentam avaliação de emergência e, quando previsto, baliza obrigatória. Em operação normal não são fonte primária de voo.

## 3.6 Via de emergência e auxiliares

Em operação normal: `Missão → (pede) → Voo → (valida) → Atuador`. Em emergência, o FailSafe pode inibir o Atuador normal e ordenar atuação mínima por via independente (detalhe físico por atuador em ACT + HW-008). Auxiliares e implementos (ex.: pulverização com massa, caudal e carga restante) integram-se por nós dedicados: o veículo recebe apenas o necessário para voar em segurança (massa, centragem, limites); a função do implemento permanece no implemento (ver IMP).

## 3.7 Inicialização, perda, identificação e manutenção

Cada periférico declara sequência de inicialização (presença, energia, comunicação, configuração, validade) e só é dado como operacional após passar nos testes. A perda é identificável e graduada (registo, degradação, mudança de modo, procedimento de segurança). Cada periférico possui identidade (tipo, capacidades, parâmetros, interface, configuração) e configuração física explícita (`Sensor A → SENSORIAL_01; Atuador B → ACTUATOR_02`), variável por aeronave (HW-009). Fichas polarizadas, etiquetas e pontos de teste permitem substituição rápida sem redesenhar o sistema.

---

# 4. Exemplos

## Exemplo 1 — Pitot redundante

```text
Pitot A ─► SENSORIAL_01 (RP2040, nariz)
Pitot B ─► SENSORIAL_04 (RP2040, cauda, fabricante distinto)
Ambos ─R1─► Fusão/Navegação comparam, votam e publicam velocidade-ar + qualidade
```

## Exemplo 2 — Profundor com retorno

```text
Voo ─R1─► ACTUATOR_CAUDA (RP2350B): verifica limites, gera PWM,
lê posição real, publica «ordenado vs. real + corrente + diagnóstico»
```

## Exemplo 3 — Implemento de pulverização

```text
Implemento ─► nó de integração: massa, caudal, carga restante ─R1─►
Missão ajusta plano; Voo ajusta limites; FailSafe vigia centragem;
o controlo da pulverização permanece no implemento.
```

---

# 5. Interfaces

| Periférico | Ligação física | Grupo/PCB | Rede de saída |
| --- | --- | --- | --- |
| Sensores I2C/SPI/UART/ADC/PIO | Curta, junto ao nó | SENSORIAL / COMPUTE-SENSORIAL | R1 |
| Atuadores PWM/GPIO/série + retorno | Curta, com andar de potência | ATUADOR / COMPUTE-ACTUATOR | R1 |
| Sensores de reserva | Dedicada, independente | FAILSAFE / COMPUTE-NODE | R1 + via de emergência |
| Câmara | FFC MIPI curto | GCV / COMPUTE-VISION-CARRIER | R3 → R1 (metadados) + R4 (vídeo) |
| Rádios | RJ45-RS + energia + presença | COMUNICAÇÃO / COMM-RF | R4/R5 |
| Implementos/auxiliares | Série dedicada + energia isolada | Nó de integração / COMPUTE-NODE | R1 (dados de voo) |

---

# 6. Pontos em aberto

| # | Ponto em aberto | Resolução |
| --- | --- | --- |
| 1 | Lista final de sensores por classe de aeronave, frequências e critérios RP2040 vs. Master RP2350B | SEN + HW-009 |
| 2 | Lista final de atuadores, limites, PWM, retorno por atuador e versão COMPUTE-ACTUATOR | ACT + HW-008 |
| 3 | Câmara definitiva, FFC, conetor MIPI, modos 720p60/720p30, codecs e formato de transporte | GCV + COMM-RF 5,8 GHz |
| 4 | Sensores de reserva definitivos e diversidade de fabricantes | SEN + SEC + HW-008 |
| 5 | Potências, antenas e fichas RJ45-RS das três COMM-RF | COMM-RF + HW-004/HW-006 |
| 6 | Protocolo de implementos e dados mínimos obrigatórios para voo seguro | IMP |

---

# 7. Referências

* HW-001 — Arquitetura de Hardware
* HW-002 — Grupos Computacionais
* HW-003 — Distribuição de Hardware
* HW-004 — Interfaces Elétricas
* HW-005 — Alimentação e Distribuição de Energia
* HW-006 — Interfaces de Comunicação
* HW-008 — Redundância e Isolamento de Hardware
* HW-009 — Expansibilidade e Configuração de Hardware
* docs/Esquemas/Arquitetura-Computacional.md
