# COM-006 — Timeouts e Recuperação

| Campo | Valor |
|---|---|
| **Código** | COM-006 |
| **Título** | Timeouts e Recuperação |
| **Versão** | 2.0 |
| **Estado** | Aprovado para implementação |
| **Autor** | ShegaPT |
| **Classificação** | Especificação de Comunicação |

---

# 1. Objectivo

O presente documento define detecção de perda de comunicação, tempos-limite **por rede** (CAN-Intra-Grupo, CAN-Principal, CAN-FailSafe, FABRIC, RJ45-Privada RS) e o tratamento da **falha de 1×RP2350** do cluster do Master Geral, com recuperação progressiva e degradação proporcional.

---

# 2. Princípios

* Heartbeat em todas as redes internas; supervisão de enlace na RJ45-RS.
* Tempo-limite configurável por rede e por criticidade; zero falsos positivos (declaração após N perdas consecutivas).
* Recuperação com recuo progressivo (cooldown crescente).
* Bus-off CAN com auto-recuperação.
* Falha de 1×RP2350 tratada como degradação gerida, não como emergência total.
* Acções proporcionais: continuar → degradar → failsafe → emergência.

---

# 3. Heartbeats por rede

## 3.1 CAN-Intra-Grupo e CAN-Principal (MSG_HEARTBEAT 0x10)

Campos: `GROUP_ID, STATE, MODE, TIMESTAMP, UPTIME, HEALTH(0–100)`.

| Emissor | Frequência | Prioridade |
|---|---|---|
| Masters G-SEN/G-ACT/G-CTV/G-NAV/G-MIS/G-CAL/G-COM/G-VIS | 5 Hz (200 ms) | HIGH |
| G-FS (na Principal, difusão de estado) | 10 Hz (100 ms) | HIGH |
| Master Geral | 10 Hz (100 ms) | HIGH |

Destino: difusão em cada barramento. Cada Master monitoriza os heartbeats de que depende (matriz COM-007).

## 3.2 CAN-FailSafe (heartbeat de segurança)

G-FS←→AE a 10 Hz, prioridade 0, sem descarte. Ausência declara-se em 3 períodos (300 ms) e implica EMERGENCY.

## 3.3 FABRIC (HEARTBEAT + TIME_SYNC)

Heartbeat por núcleo a 10 Hz + TIME_SYNC do Supervisor Cluster a 10 Hz. Ausência de um núcleo em 5 períodos (500 ms) declara núcleo suspeito; confirmação cruzada pelo gémeo do mesmo RP2350 em mais 500 ms declara RP2350 afectado.

## 3.4 RJ45-Privada RS (supervisão de enlace)

Sem heartbeat CAN; supervisão por tramas de enlace: comando 50 Hz ascendente, telemetria 10 Hz descendente, estado de stream 1 Hz no vídeo. `LINK_DOWN` após 500 ms sem trama válida (comando) ou 2 s sem telemetria/vídeo.

---

# 4. Tempos-limite por rede

| Rede | Período nominal | Declaração (perdas consecutivas) | Tempo-limite efectivo |
|---|---|---|---|
| CAN-Intra-Grupo | 200 ms | 5 | 1000 ms |
| CAN-Principal (Master ordinário) | 200 ms | 5 | 1000 ms |
| CAN-Principal (G-FS, MG) | 100 ms | 3 | 300 ms |
| CAN-FailSafe | 100 ms | 3 | 300 ms (emergência imediata) |
| FABRIC (núcleo) | 100 ms | 5+5 (suspeita+confirmação) | 1000 ms |
| RJ45 comando (2,4 GHz) | 20 ms | 25 | 500 ms → voo autónomo |
| RJ45 telemetria (868 MHz) | 100 ms | 20 | 2000 ms |
| RJ45 vídeo (5,8 GHz) | 1 Hz estado | 2 | 2000 ms → evento VIDEO_LOST |

Multiplicador por estado: NORMAL ×1,0; ARMED ×0,9; FLYING ×0,8; FAILSAFE ×0,6; EMERGENCY ×0,5 (tempos-limite mais curtos sob maior criticidade).

Fórmula: `timeout = periodo × N_perdas × multiplicador_estado`.

Exemplo numérico: Master G-SEN na Principal em voo: 200 ms × 5 × 0,8 = 800 ms até declaração.

---

# 5. Níveis de perda e acções

| Nível | Critério | Acção |
|---|---|---|
| 0 Normal | Heartbeats OK | Operação normal |
| 1 Degradado | 1–2 perdas | Registo + redundância (ex.: fusão com G-NAV) |
| 2 Perda parcial | Declaração de 1 Master não-crítico | Recuperação + degradação funcional; preparar aterragem |
| 3 Perda crítica | Master crítico (G-CTV, G-FS, MG) ou FailSafe | FAILSAFE; controlo sob G-FS |
| 4 Perda total / Emergência | AE sem G-FS ou múltiplos críticos | EMERGENCY via AE |

---

# 6. Recuperação

## 6.1 Recuo progressivo (CAN)

Tentativa → espera 200 ms → reenvio de reactivação → resposta? Recuperação (reset de contadores) : recuo 500/1000/1500/2000/2500 ms até 5 tentativas → perda definitiva + degradação.

## 6.2 Bus-off CAN

ERROR_ACTIVE → (127 erros) → ERROR_PASSIVE → (255) → BUS_OFF → espera 1 ms → reconexão após 128×11 bits recessivos → ERROR_ACTIVE; 10 tentativas espaçadas de 100 ms; após esgotamento, notificação de segurança.

## 6.3 FABRIC

Núcleo sem resposta a RPC dentro do tempo-limite ⇒ reemissão para o gémeo; falha do par ⇒ isolamento do RP2350 e redistribuição (ver §7).

## 6.4 RJ45-RS

Sem reenvio CAN sobre RF; o router sinaliza LINK_DOWN, retoma TX/RX automaticamente e regista estatísticas. O voo não é degradado por perda de RF.

---

# 7. Falha de 1×RP2350 (procedimento obrigatório)

O MG possui 4×RP2350 (8 núcleos). A perda de um RP2350 (2 núcleos) é o modo de falha dimensionante do cluster.

```
t0: Núcleos Nx,Ny sem HEARTBEAT (5 períodos) → SUSPEITOS
t0+500ms: Gémeo/confirmação cruzada + FAULT → RP2350-K DECLARADO FALHADO
t1: Gestor FABRIC isola Nx,Ny; Supervisor Cluster (nos 3 RP2350 restantes) redistribui:
    - Supervisão/TIME_SYNC/FAULT → N0–N1 restantes (nunca desguarnecidos)
    - Fusão/navegação → prioridade sobre cálculo diferível
    - MATH diferível e diagnóstico → suspensos ou a 10% (COM-004)
t2: Estado DEGRADADO difundido na CAN-Principal (STATE_BROADCAST + SYSTEM_STATUS)
t3: Recuperação: reinicialização vigiada do RP2350-K; reintegração só após 10 s de
    HEARTBEAT+TIME_SYNC estáveis e validação SHA/TrustZone (COM-010); sem reintegração
    a quente de RPC pendentes (REQ_ID expirados são repetidos, não retomados).
```

| Fase | Tempo-limite | Acção em falha |
|---|---|---|
| Suspeita | 500 ms | Marcar, sem migrar |
| Declaração | +500 ms | Isolar + redistribuir |
| Estabilização | 10 s | Operar degradado |
| Reintegração | 10 s estáveis | Readmissão; caso contrário, voo degradado até aterragem |

Exemplo: falha do RP2350-2 (N4–N5, cálculo): MISSION/MATH diferíveis suspensos; fusão (N2–N3) e supervisão (N0–N1) intactas; CAN-Principal e RF-CMD (N6–N7) intactas; voo prossegue em modo DEGRADADO com aterragem planeada.

Degradação associada (tabela): perda de 1 RP2350 ⇒ Nível 2 (perda parcial) no MG; perda de 2 RP2350 ⇒ Nível 3 (FAILSAFE); perda de 3+ ⇒ Nível 4 (EMERGENCY via G-FS/AE, independente do MG).

---

# 8. Criticidade por entidade

| Entidade | Criticidade | Recuperação |
|---|---|---|
| G-FS / AE | Super-crítica | Reenvio imediato supervisionado; sem recuo |
| MG / G-CTV | Crítica | Recuo curto; FAILSAFE se esgotado |
| G-SEN/G-ACT/G-NAV/G-MIS/G-CAL/G-COM/G-VIS | Alta/média | Recuo normal; redundância e degradação |

---

# 9. Registo e diagnóstico

Por rede e por origem: contadores de timeouts, recuperações, bus-off, RPC expirados, LINK_DOWN/UP, downtime total e máximo. Estrutura `TimeoutStats` por rede (CAN, FABRIC, RF).

---

# 10. Nota histórica de migração

> Tabelas antigas indexadas a Raspberry Pi / ESP32 / FS_A encontram-se revogadas e substituídas pelas tabelas por rede deste documento.

---

# 11. Referências

* COM-001, COM-003, COM-004, COM-005, COM-007, COM-008, COM-009, COM-010
