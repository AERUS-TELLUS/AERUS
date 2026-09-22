# HW-004 — Interfaces Elétricas

| Campo | Valor |
| --- | --- |
| **Código** | HW-004 |
| **Título** | Interfaces Elétricas |
| **Versão** | 2.0 |
| **Estado** | Em Desenvolvimento |
| **Autor** | ShegaPT |
| **Classificação** | Especificação de Hardware |
| **Referência** | docs/Esquemas/Arquitetura-Computacional.md |

---

# 1. Objetivo

O presente documento define os princípios e requisitos gerais das interfaces elétricas do sistema AERUS-TELLUS: sinais digitais e analógicos, GPIO, ADC, PWM, retorno de atuadores, CAN-Principal, série sobre RJ45 para as placas rádio, MIPI CSI, DDR/LPDDR, Ethernet, alimentação local e proteções.

Explica o que cada interface deve garantir (compatibilidade, integridade, proteção, estado seguro), como dimensionar cada utilização e que constrangimentos de impedância, comprimento e encaminhamento condicionam o desenho das PCB — com valores finais a fechar no projeto detalhado a partir da documentação oficial do silício dos RP2040/RP2350, da documentação NXP.

---

# 2. Âmbito

Abrange:

* domínios de sinal face a domínios de potência;
* GPIO, ADC, PWM, retorno (feedback) e condicionamento;
* CAN-Principal (nível físico), RJ45-RS, UART/SPI/I2C locais, Ethernet na carrier;
* MIPI CSI e LPDDR/eMMC na COMPUTE-VISION-CARRIER (regras, não valores finais);
* isolamento, proteção, estado seguro, arranque e encerramento;
* identificação, modularidade e compatibilidade.

Não abrange:

* árvore de alimentação completa (ver HW-005);
* protocolo lógico e CAN IDs (ver HW-006 e COM);
* periféricos concretos (ver HW-007, SEN, ACT).

---

# 3. Descrição

## 3.1 Princípio geral

Cada interface é dimensionada pela função que desempenha e pelo equipamento que interliga. Deve garantir, conforme aplicável: compatibilidade elétrica, integridade do sinal, proteção dos equipamentos, isolamento entre domínios, operação dentro de limites e deteção de condições anómalas.

```text
Alimentação (12/5/3,3 V + rails locais)
  │
  ├── Grupo Sensorial / Atuador / Nós / Cluster / GCV
  ├── Sensores, atuadores, ESC, câmara, rádios
  └── Massas e blindagens (estrela, ponto único)
```

A existência de uma ligação elétrica nunca implica autoridade funcional. Sinal e autoridade vivem em camadas distintas.

## 3.2 Capacidades elétricas dos processadores

| Recurso | RP2040 (COMPUTE-SENSORIAL, COMPUTE-ACTUATOR simples) | RP2350B/2354B (COMPUTE-NODE, COMPUTE-ACTUATOR exigente, CLUSTER, Router GCV) | i.MX 8M Plus (módulo do GCV) |
| --- | --- | --- | --- |
| GPIO | 30, 3,3 V, com controlo de slew e pull | 48 na variante B, 3,3 V, mais PWM e ADC | Bancos de aplicação (níveis da carrier); GPIO de sistema via expansores quando necessário |
| ADC | 4 entradas, 12 bits, referência interna/externa | 8 entradas na variante B | Aquisição de precisão entregue aos RP2040/RP2350; i.MX não substitui o ADC de campo |
| PWM | 16 canais (slices com dois canais) | 24 canais na variante B | PWM de aplicação, retroiluminação e gestão |
| PIO | 8 máquinas (2 blocos) — UART/SPI/I2C extra, WS2812, DShot simples, descodificação | 12 máquinas (3 blocos) — protocolos dedicados, Interconnect Fabric, CAN com controlador | Não aplicável; periféricos dedicados |
| Série | UART ×2, SPI ×2, I2C ×2, USB 1.1 | UART ×2, SPI ×2, I2C ×2, USB 1.1 | UART ×4, eCSPI, I2C, SAI, USB 3.0/2.0, PCIe, 2 × GbE, 2 × CAN-FD |
| Corrente por pino | Limitada (ordem de mA; ver datasheet); saídas de potência sempre via andar dedicado | Idem; nunca comandar servo/relé diretamente | Idem; comando via drivers na carrier |

Regra de ouro: nenhum pino de microprocessador alimenta diretamente servo, motor, relé ou longa cablagem de potência. Existe sempre um andar de adaptação (driver, MOSFET, buffer, transceptor).

## 3.3 GPIO, ADC, PWM e retorno

**GPIO:** cada utilização declara direção, estado inicial (com pull definido), nível ativo, comportamento em arranque/encerramento/erro. Nenhum GPIO que afete segurança permanece flutuante.

**ADC:** declarar gama, resolução efetiva, referência, impedância de fonte, frequência de amostragem, filtragem anti-aliasing, proteção contra sobretensão e diagnóstico de fio cortado. O condicionamento (divisor, amplificador, filtro) vive junto ao RP2040/RP2350 do nó, não a metros de distância.

**PWM:** declarar frequência, resolução, gama de impulso (ex.: 1000–2000 µs para servos, a confirmar por atuador), estado de inicialização (saída em nível seguro, sem impulsos espúrios), limites e comportamento em perda de comando (congelar, centrar ou desligar — conforme atuador, ver ACT e SEC).

**Retorno (feedback):** posição, rotação, corrente, tensão, temperatura ou estado do controlador (incluindo ESC). A ausência de codificador não significa ausência de retorno: a eletrónica do controlador pode publicar estado por série. O retorno é adquirido pelo mesmo COMPUTE-ACTUATOR que comanda, fechando o lacete local de verificação.

## 3.4 CAN-Principal (R1) — nível físico

Barramento CAN FD em par trançado blindado, 120 Ω em cada extremidade, stubs curtos, transceptores com modo silencioso e proteção. Cada PCB expõe o barramento em ficha normalizada com CAN_H, CAN_L, massa de sinal e, quando aplicável, deteção de presença. Velocidades de arbitragem e de dados, alocação de identificadores e fragmentação pertencem a HW-006/COM; aqui define-se apenas a integridade física: continuidade, terminação, isolamento (quando exigido entre domínios) e proteção contra transientes.

## 3.5 Série sobre RJ45 para COMM-RF (R4/R5)

As três placas COMM-RF (5,8 GHz, 2,4 GHz, 868 MHz) ligam-se ao sistema exclusivamente por cabo RJ45 de 8 vias:

```text
GCV ──RJ45──► COMM-RF 5,8 GHz (TX vídeo/telemetria descendente)
Master Geral ──RJ45──► COMM-RF 2,4 GHz (RX comando)
Master Geral ──RJ45──► COMM-RF 868 MHz (telemetria bidirecional)
```

Cada cabo transporta: par série (TX/RX), alimentação claramente separada do sinal, massa e sinalização de presença/identificação da placa. Não se expõe I2C/SPI bruto ao exterior nem se partilha o CAN-Principal com as placas rádio. A pinagem exata do RJ45-RS, proteções e comprimentos máximos são objeto do projeto detalhado (pontos em aberto).

## 3.6 Interfaces locais UART/SPI/I2C e Ethernet

UART/SPI/I2C vivem **dentro** de cada PCB ou em ligações curtíssimas a sensores/atuadores adjacentes (ver HW-007). Não constituem redes de sistema. A Ethernet existe na COMPUTE-VISION-CARRIER (i.MX ↔ Router ↔ ficha de diagnóstico, e, quando aplicável, interligação interna de alto débito); não é barramento partilhado do veículo.

## 3.7 MIPI CSI, LPDDR e eMMC no GCV (regras)

A COMPUTE-VISION-CARRIER é a única PCB com requisitos de muito alta velocidade:

* **MIPI CSI (câmara → i.MX):** FFC o mais curto possível, pares diferenciais com impedância controlada, comprimentos equalizados, referência de massa contínua, sem mudanças de camada desnecessárias, afastamento de comutação. Larguras, espaçamentos e tolerâncias a extrair do guia de layout NXP (por definir).
* **LPDDR (i.MX → memória):** topologia, comprimentos, equalização e plano de referência estritamente segundo o guia NXP e o empilhamento escolhido; sem desvios criativos.
* **eMMC e relógios:** encaminhamento curto, desacoplamento segundo PMIC/NXP, cristal com guardas e massa dedicada.

Qualquer revisão da carrier sem verificação de impedância, simulação (quando exigível) e revisão de layout face ao guia NXP é considerada incompleta.

## 3.8 Isolamento, proteção, estado seguro, arranque e encerramento

**Isolamento:** aplicar (ótico, magnético ou por transceptor isolado) entre potência e sinal, entre domínios de segurança e operação normal quando a análise o exigir, e em interfaces com o exterior (rádios, diagnóstico).

**Proteção (por interface, conforme aplicável):** sobretensão (TVS), sobrecorrente (fusível/PTC/eFuse), curto-circuito, inversão de polaridade, transientes (load-dump do lado da bateria, ESD do lado do operador), filtragem EMC.

**Estado seguro:** cada interface com efeito na aeronave declara o seu estado em arranque, perda de comunicação, falha do controlador, reinicialização, ausência de retorno e entrada em FailSafe. Em arranque, as saídas nascem em nível seguro antes de qualquer módulo comandar; no encerramento, motores e superfícies são postos em condição apropriada antes de cortar energia (sequências funcionais em SYS; execução elétrica aqui).

## 3.9 Identificação, modularidade e compatibilidade

Cada ficha e cada feixe são identificados por origem, destino, função, tipo de sinal, alimentação associada, grupo e periférico. Nenhum periférico se liga sem verificação documentada de tensão, corrente, níveis lógicos, frequência, polaridade, impedância e isolamento; a incompatibilidade resolve-se com adaptador dedicado, nunca com improviso. A modularidade exige que trocar um sensor, atuador ou nó não obrigue a redesenhar o sistema.

---

# 4. Exemplos

## Exemplo 1 — Entrada analógica de temperatura

```text
NTC ─(divisor + filtro RC junto ao RP2040)─► ADC do COMPUTE-SENSORIAL
  → 12 bits, referência externa estável, amostragem sobredimensionada + média
  → deteção de fio cortado por gama (fora de escala = inválido)
  → publicação normalizada em °C + qualidade
```

## Exemplo 2 — Saída PWM para servo com retorno

```text
Master Geral ─CAN─► COMPUTE-ACTUATOR (RP2040)
  → verifica limites 1000–2000 µs → gera PWM a 50 Hz
  → lê retorno (potenciómetro do servo ou estado do controlador)
  → publica posição real + diagnóstico; em timeout CAN, aplica posição segura
```

## Exemplo 3 — Ligação rádio via RJ45

```text
GCV (Router RP2350) ─RJ45 (série + alimentação + presença)─► COMM-RF 5,8 GHz
  → stream 720p30 + telemetria; placa identificada por resistência de presença;
  → ausência = evento de diagnóstico, sem afetar CAN-Principal
```

---

# 5. Interfaces

| Interface | Suporte físico | Capítulo de detalhe |
| --- | --- | --- |
| GPIO/ADC/PWM/retorno | Pistas curtas + condicionamento local + fichas polarizadas | §3.3, HW-007, SEN, ACT |
| CAN-Principal | Par trançado blindado, 120 Ω, stubs curtos | §3.4, HW-006 |
| RJ45-RS (3 × COMM-RF) | Cabo RJ45 8 vias, série + alimentação + presença | §3.5, HW-006, HW-007 |
| UART/SPI/I2C locais | Dentro da PCB ou ligações curtíssimas | §3.6, HW-007 |
| MIPI CSI / LPDDR / eMMC / Ethernet | Carrier do GCV, impedância controlada | §3.7 |
| Alimentação local | Reguladores a partir de 12/5/3,3 V + PMIC NXP no GCV/cluster | HW-005 |

---

# 6. Pontos em aberto

| # | Ponto em aberto | Resolução |
| --- | --- | --- |
| 1 | Pinagem definitiva do RJ45-RS por banda, proteções, comprimentos máximos, identificação de placa | Projeto detalhado COMM-RF + HW-006 |
| 2 | Níveis lógicos, gamas ADC e frequências PWM por sensor/atuador concreto | SEN, ACT |
| 3 | Empilhamento, larguras, espaçamentos e tolerâncias de impedância (CAN, MIPI, DDR, Ethernet, RJ45) | Guia NXP + fabricante de PCB |
| 4 | Comprimento máximo do FFC MIPI e conetor exato da câmara | HW-007 + datasheet da câmara |
| 5 | Estratégia de isolamento por interface (onde isolar e com que componente) | Análise de segurança + HW-008 |
| 6 | Curvas de proteção (fusíveis, eFuses, TVS) por derivação | HW-005 + ensaio |

---

# 7. Referências

* HW-001 — Arquitetura de Hardware
* HW-002 — Grupos Computacionais
* HW-003 — Distribuição de Hardware
* HW-005 — Alimentação e Distribuição de Energia
* HW-006 — Interfaces de Comunicação
* HW-007 — Interfaces de Periféricos
* HW-008 — Redundância e Isolamento de Hardware
* HW-009 — Expansibilidade e Configuração de Hardware
* docs/Esquemas/Arquitetura-Computacional.md
