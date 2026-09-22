# COM-005 — Eventos

| Campo | Valor |
|---|---|
| **Código** | COM-005 |
| **Título** | Eventos |
| **Versão** | 2.0 |
| **Estado** | Aprovado para implementação |
| **Autor** | ShegaPT |
| **Classificação** | Especificação de Comunicação |

---

# 1. Objectivo

O presente documento define a comunicação baseada em eventos: tipos, activação, confirmação, registo e rastreabilidade. Os eventos complementam a comunicação periódica (telemetria, heartbeat) com notificação imediata de ocorrências significativas.

**Proibição estrutural: não existe atalho MISSÃO→ATUADOR.** Nenhum evento originado no Grupo Computacional Missão acciona directamente o Grupo Computacional Atuador. Todo o comando com efeito físico passa obrigatoriamente pelo Grupo Computacional Controlo de Voo (validação de lei de controlo) e é supervisionado pelo Grupo Computacional FailSafe. Qualquer tentativa de bypass é rejeitada pelo Gestor CAN-TLV com registo de segurança.

---

# 2. Princípios

* Evento = mensagem TLV (CAN) ou quadro IPC FAULT/HEALTH (FABRIC) com metadados de evento.
* Eventos de segurança usam SUPER_CRITICAL na CAN-FailSafe (sem descarte) ou prioridade 0 na CAN-Principal para difusão de estado.
* Mecanismo activar/confirmar (trigger/acknowledge) para eventos CRITICAL e superiores.
* Eventos podem preemptar comunicação periódica, nos termos de COM-004.
* Registo integral para rastreabilidade.
* Cadeia de comando fechada: MISSÃO propõe → CONTROLO DE VOO dispõe → ATUADOR executa → FAILSAFE supervisiona.

---

# 3. Cadeia de comando autorizada (anti-bypass)

```
              PROIBIDO (rejeitado + registo)
   ┌─────────────────────────────────────────┐
   │  G-MIS ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─→ G-ACT    │
   └─────────────────────────────────────────┘

              OBRIGATÓRIO
   G-MIS ──(intenção de missão)──► G-CTV ──(comando validado)──► G-ACT
     │                              │                              │
     │                              │                              ▼
     │                              │                    MSG_ACTUATOR_FB (retorno)
     │                              ▼
     └───────── G-FS supervisiona todas as etapas ─────────────────┘
                 (pode interditar via CAN-FailSafe → AE)
```

| Origem | Destino directo permitido? | Via autorizada |
|---|---|---|
| G-MIS → G-ACT | **Não** (rejeitado) | G-MIS → G-CTV → G-ACT |
| G-MIS → G-CTV | Sim (intenção, MISSION_REQ/RESP, MSG_COMMAND com flag `missao`) | — |
| G-CTV → G-ACT | Sim (comando validado) | Supervisão G-FS |
| G-FS → AE | Sim (emergência, CAN-FailSafe) | — |
| Qualquer → AE | Não, excepto G-FS | — |

O Dispatcher do Gestor CAN-TLV implementa esta matriz como regra de encaminhamento (COM-003, COM-007): `se origem=G-MIS e destino=G-ACT ⇒ rejeitar + evento de segurança`.

---

# 4. Tipos de evento

| Tipo | Constante | Prioridade | Exemplos |
|---|---|---|---|
| Segurança | EVT_SAFETY | SUPER_CRITICAL | Activação de failsafe, paragem de emergência, dados G-FS |
| Sensor | EVT_SENSOR | HIGH | Falha/recuperação/deriva de sensor (G-SEN) |
| Actuador | EVT_ACTUATOR | HIGH | Falha/sobrecorrente/recuperação (G-ACT, AE) |
| Sistema | EVT_SYSTEM | MEDIUM–HIGH | Mudança de estado, actualização de configuração, sincronização |
| Comunicação | EVT_COMM | HIGH | Perda/recuperação de heartbeat, bus-off, pico de CRC |
| Missão | EVT_MISSION | MEDIUM | Proposta/alteração de missão (sempre via G-CTV) |
| Cálculo | EVT_MATH | MEDIUM | Conclusão/falha de cálculo (G-CAL, FABRIC) |
| Visão/RF | EVT_VIS_RF | MEDIUM | Perda/recuperação de vídeo 720p30 ou de enlace 2,4/868 MHz |

Eventos específicos por MSG_ID: FAILSAFE (0x14), SAFETY_DATA (0x1B), TELEMETRY/SI_DATA (falhas de sensor), ACTUATOR_FB (falhas de actuador), STATE_BROADCAST (mudanças de estado), HEARTBEAT (perda/recuperação), SYNC_REQ/RESP, CONFIG, VIDEO_DESC (estado do stream).

---

# 5. Activar / confirmar (trigger / acknowledge)

```
Origem ──evento (CAN-ID prioritário)──► Destino ──MSG_ACK──► Origem; registo em ambos.
```

| Prioridade | ACK | Tempo-limite | Reenvios |
|---|---|---|---|
| SUPER_CRITICAL | Sempre | 50 ms | 5 (na FailSafe, reenvio supervisionado) |
| CRITICAL | Sempre | 100 ms | 3 |
| HIGH | Se configurado | 500 ms | 1 |
| MEDIUM ou inferior | Não | — | 0 |

ACK: `MSG_ACK` com `EVENT_ID + ESTADO (0=OK,1=ERRO,2=REJEITADO, ex. bypass tentado) + TIMESTAMP`.

---

# 6. Eventos na CAN-FailSafe

Barramento dedicado G-FS←→AE, prioridade fixa 0, sem descarte, ACK obrigatório, heartbeat próprio de segurança. Isolamento: mensagens da FailSafe nunca são retransmitidas para tráfego ordinário; o G-FS difunde o *estado* de emergência na CAN-Principal, nunca o comando físico.

---

# 7. Eventos no FABRIC

Tipos FAULT, HEALTH_STATUS, SYSTEM_STATUS, HEARTBEAT, TIME_SYNC. FAULT é preemptivo (prioridade 0) e pode originar RPC de diagnóstico (`MATH_REQUEST` de confirmação). Falha de 1×RP2350 gera FAULT com identificação do par afectado e plano de redistribuição (COM-006).

---

# 8. Eventos na RJ45-Privada RS

* Segmento vídeo: eventos `VIDEO_LOST/VIDEO_RECOVERED` (via `MSG_VIDEO_DESC` na CAN, originados pelo Router GCV).
* Segmento comando/telemetria: eventos `LINK_DOWN/LINK_UP`, comutação para voo autónomo sem degradação de controlo.

---

# 9. Eventos por estado do sistema

| Estado | Política |
|---|---|
| INIT/READY/ARMED/FLYING | Todos os tipos; em voo, prioridade a sensor/actuador |
| FAILSAFE | DEBUG promovido a SUPER_CRITICAL para diagnóstico; missão suspensa |
| EMERGENCY | Apenas segurança; missão e cálculo diferível suspensos |
| DISARMED/OFF | Transição segura / sem comunicação |

---

# 10. Registo e rastreabilidade

Cada evento: `timestamp, event_id (16 bits), tipo, gravidade (INFO/WARNING/ERROR/CRITICAL), origem, MSG_ID/CAN-ID ou TIPO FABRIC, acção, resultado`. Log circular de 64 entradas por gestor + contadores; transbordo contabilizado. Tentativa de bypass MISSÃO→ATUADOR gera registo de gravidade CRITICAL com `RESULTADO=REJEITADO`.

---

# 11. API

`event_raise(tipo,gravidade,dados)`, `event_ack(id,estado)`, `event_register_handler(tipo,cb)`, `event_get_log`, `event_clear_log`, `event_get_stats`.

---

# 12. Nota histórica de migração

> Referências a Raspberry Pi / ESP32 / FS_A como origem ou destino de eventos encontram-se revogadas. As origens canónicas são os Grupos do COM-001 §3, o MG e a Atuação de Emergência.

---

# 13. Referências

* COM-001, COM-002, COM-003, COM-004, COM-006, COM-007, COM-008, COM-010
