# COM-009 — Sincronização

| Campo | Valor |
|---|---|
| **Código** | COM-009 |
| **Título** | Sincronização |
| **Versão** | 2.0 |
| **Estado** | Aprovado para implementação |
| **Autor** | ShegaPT |
| **Classificação** | Especificação de Comunicação |

---

# 1. Objectivo

O presente documento define a sincronização temporal entre Grupos Computacionais e núcleos do Master Geral. A raiz de tempo é o **Supervisor Cluster sedeado no MG**; a difusão faz-se por **TIME_SYNC** (FABRIC) e por **MSG_SYNC_REQ/RESP** (CAN). Referência de gestão temporal global: SYS-008; este documento define o *como* sobre as cinco redes.

---

# 2. Princípios

* Raiz única: Supervisor Cluster no MG (núcleos N0–N1, RP2350-0).
* Sincronização em cascata: FABRIC (intra-MG) → CAN-Principal → CAN-Intra-Grupo; FailSafe com heartbeat próprio referenciado à mesma raiz.
* Múltiplas referências: UTC (se GNSS), monotónico, missão, voo, modo.
* Precisão: sub-milissegundo intra-MG; <1 ms nas CAN; <100 µs com débito de dados elevado (objectivos; majorantes em §8).
* Determinismo: cadência fixa, correcção por offset com protecção contra saltos.

---

# 3. Referências temporais

| Referência | Origem | Precisão alvo |
|---|---|---|
| UTC | GNSS (via G-SEN/G-NAV, se disponível) | ~100 ns na fonte; propagada a ~1 ms |
| Monotónico | Temporizadores RP2350 / hardware de cada Master | ~1 µs local |
| Missão / Voo / Modo | Software (MG + Masters) | ~1 ms |

Relações: UTC (absoluto, quando disponível) disciplina o monotónico; missão/voo/modo derivam do monotónico corrigido.

---

# 4. Mensagens e quadros

## 4.1 CAN: MSG_SYNC_REQ (0x1C) / MSG_SYNC_RESP (0x1D)

REQ: `SYNC_ID, SYNC_TYPE (UTC/monotónico/missão/voo/todos), TX_TIMESTAMP, NODE_ID`. RESP: `SYNC_ID, SYNC_TYPE, TX_TIMESTAMP, UTC_S/µS, MONO_MS, MISSION_MS, FLIGHT_MS, MODE_MS, DRIFT_ppb`. Prioridade HIGH; latência de resposta ≤10 ms.

## 4.2 FABRIC: TIME_SYNC

Quadro IPC com TIPO=TIME_SYNC, TIMESTAMP do cluster e sequência; prioridade 0 preemptiva; cadência 10 Hz intra-MG.

---

# 5. Protocolo (RTT/offset)

```
Requerente ──REQ(t1)──► Raiz ──(t2 recepção, t3 envio)──RESP──► Requerente (t4)
RTT = (t4−t1) − (t3−t2); Offset = ((t2−t1)+(t3−t4))/2.
```

Exemplo numérico: t1=1000,000 ms; t2=1000,400 ms; t3=1000,500 ms; t4=1000,900 ms ⇒ RTT=0,800 ms; Offset=+0,450 ms; correcção aplicada por filtro (passo máximo 1 ms/ciclo para evitar saltos; saltos >1 s rejeitados com relógio local + alerta).

---

# 6. Hierarquia (raiz Supervisor Cluster)

```
        ┌──────────────────────────────┐
        │ SUPERVISOR CLUSTER (MG N0–N1)│  raiz; TIME_SYNC 10 Hz FABRIC
        └──────┬───────────┬───────────┘
               │           │ CAN-Principal (MSG_SYNC 1 Hz)
   ┌───────────┴─┐   ┌─────┴────────┐   ┌──────────────┐
   │ Núcleos MG  │   │ Masters      │   │ M-FS (G-FS)  │
   │ N2–N7       │   │ SEN/ACT/CTV/ │   │ ↓ FailSafe   │
   │ (FABRIC)    │   │ NAV/MIS/CAL/ │   │ AE (heartbeat│
   └─────────────┘   │ COM/VIS      │   │ referenciado)│
                     │ → Intra-Grupo│   └──────────────┘
                     └──────────────┘
```

| Sincronizado | Com | Rede | Cadência |
|---|---|---|---|
| Núcleos N2–N7 | Supervisor N0–N1 | FABRIC | 10 Hz |
| Masters | MG | Principal | 1 Hz (10 Hz após deriva/reinício) |
| Elementos internos | Master do grupo | Intra-Grupo | 1 Hz |
| AE | G-FS | FailSafe | Referenciado (heartbeat 10 Hz) |

Arranque: descoberta 0–2 s (heartbeats) → sincronização raiz↔G-FS 2–5 s → propagação 5–8 s → operação (1 Hz); sem sincronização em 8 s, opera-se com relógio local + alerta.

---

# 7. Deriva, erros e RTC

Deriva: |offset| <1 ms normal; 1–10 ms correcção acelerada; 10–100 ms alerta; >100 ms erro + recuperação; TIMEOUT RESP 100 ms com 3 reenvios; RTT >10 ms alerta; offset >1 s rejeitado. RTC (ex.: DS3231) apenas como auxiliar de UTC quando previsto em HW; GNSS propaga UTC via RESP se disponível, senão monotónico como referência.

---

# 8. Requisitos de precisão (majorantes normativos)

| Aplicação | Majorante |
|---|---|
| Fusão sensorial / segurança | <1 ms |
| Controlo de voo | <5 ms |
| Heartbeat/timeout | <10 ms |
| Registo | <100 ms |

Jitter de TIME_SYNC intra-MG ≤50 µs (objectivo de bancada).

---

# 9. API e estruturas

`sync_init, sync_request(dest,tipo), sync_handle_response, sync_get_{offset,utc,monotonic,mission,flight,mode}`. Estruturas `SyncInfo{sync_id,tipo,offset_ms,drift_ppb,rtt_ms,last_sync,erros}` e `TemporalReference{utc_s,utc_us,mono_ms,mission_ms,flight_ms,mode_ms}`.

---

# 10. Nota histórica de migração

> Hierarquias anteriores entre Raspberry Pi e ESP32 encontram-se revogadas; a raiz é o Supervisor Cluster do MG nos termos do §6.

---

# 11. Referências

* COM-001, COM-002, COM-003, COM-004, COM-006, COM-007, COM-008, COM-010; SYS-008.
