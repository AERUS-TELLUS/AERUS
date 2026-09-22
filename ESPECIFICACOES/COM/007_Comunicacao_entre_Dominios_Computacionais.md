# COM-007 — Comunicação entre Domínios Computacionais

| Campo | Valor |
|---|---|
| **Código** | COM-007 |
| **Título** | Comunicação entre Domínios Computacionais |
| **Versão** | 2.0 |
| **Estado** | Aprovado para implementação |
| **Autor** | ShegaPT |
| **Classificação** | Especificação de Comunicação |

---

# 1. Objectivo

O presente documento define quem comunica com quem, em que rede, com que endereço e com que tipo de mensagem, incluindo a **matriz TX/RX integral** e as **regras de encaminhamento** entre as cinco redes. Elimina qualquer ambiguidade topológica e consagra a proibição do bypass MISSÃO→ATUADOR.

---

# 2. Princípios

* Um barramento CAN-Intra-Grupo por grupo; uma CAN-Principal inter-masters; uma CAN-FailSafe isolada; um FABRIC intra-MG; duas RJ45-RS ponto-a-ponto.
* Apenas Masters na CAN-Principal (um por grupo + MG + Router GCV).
* G-FS como autoridade de segurança; AE como único destino de emergência.
* Router CAN↔RJ45 como única travessia para RF.
* Encaminhamento explícito por tabela; sem flooding entre redes.

---

# 3. Topologia e endereços

## 3.1 CAN-Intra-Grupo (1 por grupo)

CAN-SEN, CAN-ACT, CAN-CTV, CAN-NAV, CAN-MIS, CAN-CAL, CAN-FS, CAN-VIS, CAN-COM. Endereçamento local ao grupo; o Master filtra e promove para a Principal apenas tráfego inter-grupos.

## 3.2 CAN-Principal — Masters

| Master | Presença | Papel na Principal |
|---|---|---|
| M-SEN (G-SEN) | Sim | Publica telemetria/SI; recebe configuração |
| M-ACT (G-ACT) | Sim | Recebe comando validado; publica retorno |
| M-CTV (G-CTV) | Sim | Publica comando; recebe intenções e navegação |
| M-NAV (G-NAV) | Sim | Publica navegação; recebe medidas |
| M-MIS (G-MIS) | Sim | Publica intenções de missão; recebe estado |
| M-CAL (G-CAL) | Sim | Pedidos/respostas de cálculo |
| M-FS (G-FS) | Sim | Supervisão, segurança, difusão de estado de emergência |
| M-VIS / Router GCV (G-VIS) | Sim | Descritores de vídeo; gestão do segmento 5,8 GHz |
| M-COM (G-COM) | Sim | Coordenação de enlaces (via MG) |
| MG (Master Geral) | Sim | Orquestração, fusão, TIME_SYNC, router RF-CMD |

CAN-ID 29 bits: `(prioridade<<26)|(origem<<22)|(destino<<18)|(tipo<<14)`. Exemplo: M-SEN→MG telemetria: `(2<<26)|(M-SEN<<22)|(MG<<18)|(TELEM<<14)`.

## 3.3 CAN-FailSafe — G-FS ←→ AE

Apenas dois interlocutores; sem endereços de terceiros; prioridade fixa 0.

## 3.4 FABRIC — núcleos 0–7 do MG

Endereço `(SOURCE, DESTINO, NÚCLEO, TIPO, REQ_ID)` (COM-002 Anexo A).

## 3.5 RJ45-Privada RS

Ponto-a-ponto sem endereçamento global: `GCV←→TX 5,8 GHz`; `MG←→RX 2,4 GHz+TX 868 MHz`. Tradução de endereços no router (COM-003).

---

# 4. Matriz TX/RX (CAN-Principal + FailSafe)

Legenda: T = transmite para; R = recebe de; — = sem comunicação directa; SEG = CAN-FailSafe.

```
          │M-SEN│M-ACT│M-CTV│M-NAV│M-MIS│M-CAL│M-FS │M-VIS│M-COM│ MG  │ AE  │
──────────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┤
M-SEN     │  —  │  —  │  R  │  T  │  —  │  T  │  T  │  —  │  —  │ T   │  —  │
M-ACT     │  —  │  —  │  R  │  —  │  —  │  —  │  T  │  —  │  —  │ T   │  —  │
M-CTV     │  R  │  T  │  —  │ R/T │  R  │ R/T │ R/T │  R  │  —  │ R/T │  —  │
M-NAV     │  R  │  —  │ T   │  —  │  T  │  T  │  T  │  —  │  —  │ T   │  —  │
M-MIS     │  —  │  ✕  │  T  │  R  │  —  │ R/T │  R  │  —  │  —  │ R/T │  —  │
M-CAL     │  R  │  —  │  T  │  R  │ R/T │  —  │  R  │  —  │  —  │ R/T │  —  │
M-FS      │  R  │ R/T │ R/T │  R  │  R  │  R  │  —  │  R  │  R  │ R/T │T(SEG)│
M-VIS/GCV │  —  │  —  │  T* │  —  │  —  │  —  │  R  │  —  │  —  │ T*  │  —  │
M-COM     │  —  │  —  │  —  │  —  │  —  │  —  │  R  │  —  │  —  │ R/T │  —  │
MG        │ R/T │ R/T │ R/T │ R/T │ R/T │ R/T │ R/T │ R/T │ R/T │  —  │  —  │
AE        │  —  │  —  │  —  │  —  │  —  │  —  │R(SEG)│ —  │  —  │  —  │  —  │
```
`✕` = bypass MISSÃO→ATUADOR **proibido** (rejeitado pelo dispatcher). `T*` do Router GCV = apenas descritores de vídeo/estado.

Fluxos principais:

* Sensores: M-SEN → MG + M-CTV + M-NAV + M-FS (telemetria/SI, HIGH).
* Navegação: M-NAV → MG + M-CTV + M-MIS (NAVIGATION, HIGH).
* Missão: M-MIS → M-CTV + MG (intenção, MEDIUM/HIGH); jamais para M-ACT.
* Comando: M-CTV → M-ACT (validado, CRITICAL) com retorno M-ACT → M-CTV + MG + M-FS.
* Cálculo: MG/M-CTV/M-NAV/M-MIS ←→ M-CAL (pedidos diferíveis).
* Segurança: M-FS ←→ MG + difusão de estado; M-FS → AE (SEG, emergência).
* Vídeo: Router GCV → MG + M-CTV (descritores); vídeo pesado só na RJ45 5,8 GHz.
* RF comando/telemetria: MG ←→ RF via router (M-COM coordena, não transporta).

---

# 5. Matriz FABRIC (resumo)

| Origem | Destino | Tipos |
|---|---|---|
| Fusão (N2–N3) | Supervisão (N0–N1), MG→CAN | SENSOR_DATA, HEALTH_STATUS |
| Matemática (N4–N5) | Requerentes | RESPONSE a MATH_REQUEST |
| Supervisão (N0–N1) | Todos | TIME_SYNC, FAULT, SYSTEM_STATUS, HEARTBEAT |
| CAN/RF (N6–N7) | Fusão/missão | SENSOR_DATA, MISSION_REQ/RESP |

---

# 6. Regras de encaminhamento (routing)

| # | Regra |
|---|---|
| R1 | Unicast por omissão; difusão apenas com destino 0x0 e tipos autorizados (heartbeat, estado, TIME_SYNC). |
| R2 | ACK para CRITICAL e superiores; evento HIGH com ACK configurável. |
| R3 | Sem retransmissão automática entre redes; reenvio supervisionado na origem. |
| R4 | Filtro por destino em hardware + software; origem desconhecida descartada com registo. |
| R5 | **Anti-bypass**: `G-MIS→G-ACT` rejeitado em qualquer rede, com evento CRITICAL. |
| R6 | Isolamento FailSafe: nada da SEG é retransmitido para tráfego ordinário; só o *estado* é difundido. |
| R7 | Travessia RF só via router com validação e policiamento; tipos não autorizados eliminados. |
| R8 | Router GCV nunca injecta comando no segmento de vídeo; router RF-CMD nunca encapsula vídeo. |
| R9 | Intra-grupo não é promovido sem necessidade inter-grupos (contenção mínima na Principal). |
| R10 | TIME_SYNC origina-se exclusivamente no Supervisor Cluster (MG) — ver COM-009. |

Tabela de encaminhamento (excerto, estrutura `RoutingEntry{origem,destino,msg,prioridade,rede,ack}`):

```
{M-SEN, MG,      MSG_TELEMETRY, 2, PRINCIPAL, false}
{M-SEN, M-FS,    MSG_TELEMETRY, 2, PRINCIPAL, false}
{M-NAV, M-CTV,   NAVIGATION,    2, PRINCIPAL, false}
{M-MIS, M-CTV,   MSG_COMMAND(missao), 2, PRINCIPAL, true}
{M-MIS, M-ACT,   *,             -, -, REJEITAR+EVENTO}
{M-CTV, M-ACT,   MSG_COMMAND,   1, PRINCIPAL, true}
{M-FS,  AE,      MSG_FAILSAFE,  0, FAILSAFE,  true}
{GCV,   MG,      MSG_VIDEO_DESC,3, PRINCIPAL, false}
{MG,    RF868,   TELEMETRIA,    2/1, RJ45,    false}
{RF24,  MG,      COMANDO,       1, RJ45→CAN,  true}
```

---

# 7. Fluxos por tipo de dado (resumo)

* Telemetria: G-SEN → MG/M-CTV/M-NAV/M-FS simultâneo (redundância de supervisão).
* Comando: G-CTV → G-ACT com ACK + retorno; intenção G-MIS→G-CTV a montante.
* Emergência: G-FS → AE (SEG) + difusão de estado na Principal.
* Sincronização: MG → todos (TIME_SYNC, COM-009).
* Vídeo: 720p30 GCV→TX 5,8 GHz; descritores na Principal.

---

# 8. Nota histórica de migração

> Designações Raspberry Pi / ESP32 / FS_A não possuem entradas nesta matriz. Linhas e colunas antigas devem ser remapeadas para os Masters do §3.

---

# 9. Referências

* COM-001, COM-002, COM-003, COM-004, COM-005, COM-006, COM-008, COM-009, COM-010
