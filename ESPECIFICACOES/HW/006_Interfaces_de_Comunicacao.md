# HW-006 — Interfaces de Comunicação

| Campo | Valor |
| --- | --- |
| **Código** | HW-006 |
| **Título** | Interfaces de Comunicação |
| **Versão** | 2.0 |
| **Estado** | Em Desenvolvimento |
| **Autor** | ShegaPT |
| **Classificação** | Especificação de Hardware |
| **Referência** | docs/Esquemas/Arquitetura-Computacional.md |

---

# 1. Objetivo

O presente documento define a arquitetura física e lógica das comunicações do sistema AERUS-TELLUS: as cinco redes oficiais (R1 CAN-Principal, R2 Interconnect Fabric do Master Geral, R3 ligação interna do GCV, R4 rádio 5,8 GHz, R5 rádios 2,4 GHz e 868 MHz), a separação entre interface física e protocolo, a comunicação entre processadores (IPC/RPC) no cluster de 4 × RP2350, as regras de prioridade, filas, temporização, integridade e recuperação, e a relação com o protocolo de aplicação.

Explica como um valor medido num RP2040 chega, normalizado, a um núcleo de voo, como dois núcleos do cluster cooperam sem partilhar memória de forma ingénua e como o vídeo nunca congestiona o barramento operacional.

---

# 2. Âmbito

Abrange:

* as cinco redes: meio físico, utilizadores, débitos e responsabilidades;
* CAN-Principal (R1): topologia, terminação, encaminhamento Master Geral ↔ GCV-Router;
* Interconnect Fabric (R2): malha SPI/PIO/DMA + memória partilhada, IPC/RPC, supervisão;
* ligação de visão (R3): i.MX ↔ Router RP2350 ↔ R1; MIPI interno;
* redes rádio (R4/R5): RJ45-RS para COMM-RF 5,8 GHz / 2,4 GHz / 868 MHz;
* prioridades, eventos, filas, temporização, integridade, falha e recuperação.

Não abrange:

* níveis elétricos ao pino (ver HW-004);
* energia (ver HW-005);
* periféricos concretos (ver HW-007);
* estrutura completa das mensagens e tabelas de tipos (ver COM).

---

# 3. Descrição

## 3.1 As cinco redes

| Rede | Designação oficial | Meio físico | Extremos | O que transporta |
| --- | --- | --- | --- | --- |
| R1 | CAN-Principal | CAN FD, par trançado blindado, 120 Ω nas extremidades | Todos os Masters/Routers: Sensorial, Atuador, Cluster, GCV-Router, Comunicação | Sensores normalizados, comandos validados, estados, missão, saúde, energia, eventos |
| R2 | Interconnect Fabric do Master Geral | Malha ponto a ponto: SPI dedicado + PIO + DMA + memória partilhada externa (detalhe por fechar) | RP2350 #1 ⇄ #2 ⇄ #3 ⇄ #4 dentro da COMPUTE-FLIGHT-CLUSTER | IPC/RPC determinístico entre os 8 núcleos: pedidos matemáticos, navegação, supervisão, sincronismo |
| R3 | Ligação de Visão GCV↔Sistema | Interna à carrier: UART/SPI/Ethernet i.MX↔Router; MIPI CSI câmara→i.MX; saída Router→R1 | i.MX 8M Plus ↔ Router RP2350 ↔ R1 | Metadados, estado, heartbeat, telemetria compacta, futuras deteções; nunca píxeis em bruto |
| R4 | Rádio 5,8 GHz | RJ45-RS GCV→COMM-RF 5,8 GHz → TX para terra | GCV → estação terrestre | Vídeo 720p30 + telemetria descendente de visão |
| R5 | Rádios 2,4 GHz + 868 MHz | RJ45-RS Master Geral→COMM-RF 2,4 GHz (RX) e 868 MHz (TX/RX) | Operador/terra ↔ Master Geral | Comando ascendente, telemetria bidirecional, diagnóstico remoto |

```text
                    CAN-Principal R1
                         │
   ┌─────────┬───────────┼────────────┬──────────┐
   ▼         ▼           ▼            ▼          ▼
SENSORIAL  ATUADOR  FLIGHT-CLUSTER  GCV-Router  COMUNICAÇÃO
 (RP2040/    (RP2040/  (R2 interno:   (R3: i.MX   (R1 + R4/R5
  RP2350)    RP2350)   4×RP2350 em    ↔Router)    via RJ45)
                       malha)
                         │              │
                    RJ45─┼─→2,4/868     RJ45─→5,8 GHz TX
```

Comunicação interna (R1/R2/R3) e comunicação externa (R4/R5) são problemas distintos, com requisitos, débitos e ameaças distintos. O barramento externo nunca substitui o interno.

## 3.2 R1 — CAN-Principal em detalhe

Topologia em barramento com stubs curtos; terminação nas extremidades; transceptores com proteção e modo silencioso. Cada grupo participa através do seu Master/Router — nenhum sensor ou atuador fala R1 diretamente sem passar pelo RP2040/RP2350 que o serve.

Camadas (o detalhe lógico pertence a COM):

```text
┌───────────────────────────────┐
│ APLICAÇÃO  — mensagens,       │
│  prioridades, eventos, filas  │
└───────────────┬───────────────┘
                ▼
┌───────────────────────────────┐
│ TRANSPORTE — CAN FD,          │
│  encaminhamento, fragmentação │
└───────────────┬───────────────┘
                ▼
┌───────────────────────────────┐
│ FÍSICA — par trançado,        │
│  terminação, proteção         │
└───────────────────────────────┘
```

Quem fala com quem em R1 (fluxos válidos):

```text
Sensorial ──► Voo/Navegação/Missão/Cálculo/FailSafe (dados + qualidade)
Voo ──► Atuador (comandos validados)
Atuador ──► todos (estado + feedback + diagnóstico)
Missão ──► Voo/FailSafe (pedidos; nunca ordens ao Atuador)
FailSafe ──► Atuador (inibição) + todos (decisões e saúde)
GCV-Router ──► todos (estado, heartbeat, telemetria compacta)
Comunicação ──► terra / terra ──► Master Geral (via R5)
```

## 3.3 R2 — Interconnect Fabric e IPC/RPC

Os quatro RP2350 do Master Geral são nós independentes sobre uma malha de alta velocidade e baixa latência. Candidatas em avaliação: SPI dedicado por par de nós, múltiplos SPI em paralelo, PIO com protocolo dedicado, DMA com buffer duplo, memória partilhada externa e, se necessário, interligação dedicada. O objetivo é determinismo, não débito bruto.

```text
             RP2350 #1 (Voo/Fusão)
                │         │
        ┌───────┘         └───────┐
        ▼                         ▼
 RP2350 #2 (Nav/Cálculo)   RP2350 #3 (Missão ×2)
        │                         │
        └───────┐         ┌───────┘
                ▼         ▼
             RP2350 #4 (Supervisão/Diagnóstico)
```

Formato conceptual de mensagem IPC:

```text
ORIGEM, DESTINO, NÚCLEO, TIPO, REQUEST_ID, TIMESTAMP,
COMPRIMENTO, CARGA, CRC
```

Tipos iniciais: `SENSOR_DATA, ACTUATOR_DATA, MATH_REQUEST/RESPONSE, NAV_REQUEST/RESPONSE, MISSION_REQUEST/RESPONSE, HEALTH_STATUS, SYSTEM_STATUS, TIME_SYNC, FAULT, HEARTBEAT`.

Exemplo de chamada:

```text
Núcleo de Missão ─MATH_REQUEST─► Núcleo de Cálculo
  (executa com FPU/DSP)
Núcleo de Cálculo ─MATH_RESPONSE─► Núcleo de Missão
```

Um núcleo supervisor (no RP2350 #4) observa heartbeats, latências, erros, bloqueios e integridade, gere reinicialização seletiva e sincronização temporal e publica a saúde do cluster em R1. A função de supervisor do cluster não se confunde com o Grupo FailSafe: o primeiro protege a infraestrutura computacional; o segundo protege o voo.

## 3.4 R3 — Ligação de visão

```text
Câmara ─MIPI CSI─► i.MX 8M Plus (ISP→CPU/GPU/NPU→VPU 720p60/720p30)
  │
  │ UART/SPI/Ethernet interna
  ▼
Router RP2350 ─CAN-Principal R1 (metadados + estado)
  │
  │ RJ45
  ▼
COMM-RF 5,8 GHz (R4)
```

O Router filtra: o barramento operacional recebe caixas de deteção, contadores, estados e alarmes — nunca fotogramas. O débito de píxeis separam-se fisicamente do CAN-Principal por construção.

## 3.5 R4/R5 — Redes rádio via RJ45-RS

* **R4 (5,8 GHz TX):** GCV → RJ45 → placa COMM-RF 5,8 GHz → estação terrestre. Transporta vídeo 720p30 + telemetria descendente de visão.
* **R5 (2,4 GHz RX + 868 MHz):** Master Geral → RJ45 → placas COMM-RF 2,4 GHz (comando ascendente) e 868 MHz (telemetria bidirecional de longo alcance). O Master Geral valida, autentica e publica em R1 apenas o que passou nas verificações.

As placas COMM-RF são periféricos inteligentes com presença identificada; a sua ausência é um evento de diagnóstico, não um bloqueio do sistema interno.

## 3.6 Papel dos processadores nas redes

| Processador | Rede | Função |
| --- | --- | --- |
| RP2040 | R1 via controlador CAN; série local com sensores/atuadores | Amostrar/publicar; comandar/devolver estado; respeitar prioridade e período de R1 |
| RP2350B | R1 como Master/Router; R2 como nó do Fabric; R3 como Router do GCV; R4/R5 como gestor via RJ45 | Agregar, fundir, validar, supervisionar, encaminhar, autenticar |
| i.MX 8M Plus | R3 interna + R4 via Router | Codificar vídeo, inferir (futuro), registar; nunca falar R1/R5 diretamente |

## 3.7 Prioridade, eventos, filas, temporização

Mensagens com prioridade (segurança e voo primeiro), eventos assíncronos fora do ciclo periódico, filas com disciplina de prioridade e deteção de saturação, frequências de aquisição (por sensor) distintas das frequências de comunicação (por grupo), com agregação no Master:

```text
Sensor A a 100 Hz ┐
Sensor B a 50 Hz  ├─► Master agrega ─► pacote R1 ao período definido
Sensor C a 20 Hz  ┘
```

Integridade por CRC/HMAC e anti-repetição por sequência (detalhe em COM/SEC); deteção de perda por timeout/heartbeat; recuperação com espera superior ao período nominal e, após falhas consecutivas, degradação controlada ou procedimento FailSafe; anti-sobrecarga por intervalo mínimo entre pedidos repetidos.

---

# 4. Exemplos

## Exemplo 1 — Ciclo normal sensor→atuador

```text
COMPUTE-SENSORIAL (RP2040) publica altitude normalizada em R1 a 20 Hz
  → Fusão (R2) + Navegação (R2) refinam → Voo (R2) calcula comando
  → Voo publica comando validado em R1
  → COMPUTE-ACTUATOR executa PWM e publica feedback em R1
  → FailSafe observa tudo e regista saúde
```

## Exemplo 2 — Evento assíncrono de segurança

```text
Nó FailSafe deteta divergência de IMU fora do ciclo
  → publica FAULT prioritário em R1 imediatamente
  → Voo congela modo, Missão suspende plano, Atuador prepara estado seguro
  → Comunicação sinaliza terra via R5; GCV regista contexto em R3/R4
```

## Exemplo 3 — Vídeo sem perturbar o voo

```text
720p60 processado no i.MX; 720p30 segue por RJ45→5,8 GHz (R4)
Em R1 circula apenas: «GCV OK, 30 fps, 30 ms, 0 deteções, 45 °C»
Qualquer congestionamento em R4 nunca atrasa R1/R2.
```

---

# 5. Interfaces

| Interface | Meio | Documento de detalhe |
| --- | --- | --- |
| R1 CAN-Principal | Par trançado, fichas normalizadas, stubs curtos | HW-004 (física) + COM (lógica, IDs, fragmentação) |
| R2 Fabric | SPI/PIO/DMA + memória partilhada na CLUSTER | Projeto detalhado + COM (IPC) |
| R3 interna GCV | MIPI + UART/SPI/Ethernet + CAN via Router | HW-004, HW-007 |
| R4/R5 RJ45-RS | RJ45 8 vias: série + energia + presença | HW-004, HW-007 |
| Diagnóstico externo | Via Grupo Comunicação (R5) e ficha de manutenção | COM, SEC |

---

# 6. Pontos em aberto

| # | Ponto em aberto | Resolução |
| --- | --- | --- |
| 1 | Topologia física definitiva do Fabric, débitos, latência máxima, relógios, memória partilhada | Projeto CLUSTER + ensaio |
| 2 | Formato IPC final, fragmentação, sincronismo temporal, arranque/atualização dos 4 nós | COM + workloads medidos |
| 3 | Débitos CAN FD (arbitragem/dados), alocação de identificadores, política de prioridades e de descarte | COM |
| 4 | Formato série do RJ45-RS por banda, autenticação do comando ascendente, formatos do stream 720p30 | COM + SEC + COMM-RF |
| 5 | Mecanismo Router↔i.MX (UART/SPI/Ethernet), watchdog e recuperação do SoC | HW-007 + SO do GCV |
| 6 | Orçamento de latência ponta a ponta (sensor→atuador) e por rede | SYS + ensaio temporal |

---

# 7. Referências

* HW-001 — Arquitetura de Hardware
* HW-002 — Grupos Computacionais
* HW-003 — Distribuição de Hardware
* HW-004 — Interfaces Elétricas
* HW-005 — Alimentação e Distribuição de Energia
* HW-007 — Interfaces de Periféricos
* HW-008 — Redundância e Isolamento de Hardware
* HW-009 — Expansibilidade e Configuração de Hardware
* docs/Esquemas/Arquitetura-Computacional.md
