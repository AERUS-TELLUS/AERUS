# COM-004 — Prioridades e Filas

| Campo | Valor |
|---|---|
| **Código** | COM-004 |
| **Título** | Prioridades e Filas |
| **Versão** | 2.0 |
| **Estado** | Aprovado para implementação |
| **Autor** | ShegaPT |
| **Classificação** | Especificação de Comunicação |

---

# 1. Objectivo

O presente documento define as prioridades e a gestão de filas **por rede** (CAN-Intra-Grupo, CAN-Principal, CAN-FailSafe, FABRIC, RJ45-Privada RS) e o escalonamento dos **8 núcleos** do Master Geral (4×RP2350). Cada rede possui o seu espaço de prioridades; não existe herança automática entre redes.

---

# 2. Princípios

* Dupla camada nas CAN: arbiter de hardware (CAN-ID) + lógica de aplicação (MSG_ID).
* CAN-FailSafe permanentemente SUPER_CRITICAL e sem descarte.
* FABRIC arbitrado por TIPO IPC + núcleo, com preempção de TIME_SYNC e FAULT.
* RJ45-RS arbitrada por direcção e criticidade, com segmentos isolados (vídeo vs comando/telemetria).
* Prevenção de inanição (starvation) nas filas descartáveis.
* Prioridade dinâmica por estado do sistema, decidida pelo Supervisor Cluster no MG.
* Determinismo: limites por ciclo, capacidades fixas, memória estática.

---

# 3. Níveis gerais

| Nível | Designação | Significado |
|---|---|---|
| 0 | SUPER_CRITICAL | Máxima; nunca descartado onde aplicável |
| 1 | CRITICAL | Sempre transmitido e processado |
| 2 | HIGH | Prioritário |
| 3 | MEDIUM | Normal |
| 4 | LOW | Pode aguardar |
| 5 | SUPER_LOW | Descartável |

---

# 4. Prioridades por rede

## 4.1 CAN-Intra-Grupo (uma instância por grupo)

Arbitragem pelo CAN-ID local; mapeamento a partir do MSG_ID:

| MSG_ID | Prioridade | Notas |
|---|---|---|
| MSG_FAILSAFE, MSG_SAFETY_DATA | 0 | Só transitam para o Master se com destino à Principal/FailSafe |
| MSG_COMMAND, MSG_ACK | 1 | Comando local validado |
| MSG_HEARTBEAT, MSG_TELEMETRY, MSG_SI_DATA, MSG_STATE_BROADCAST, MSG_ACTUATOR_FB, MSG_SYNC_* | 2 | Periódicos locais |
| MSG_VIDEO_DESC, MSG_CONFIG | 3 | Descritores e configuração |
| MSG_SHELL_CMD | 4 | Diagnóstico |
| MSG_DEBUG | 5 (dinâmica) | Em FAILSAFE pode subir (ver §7) |

Filas por instância: SC 8, CR 16, HI 32, ME 32, LO 16, SL 8. Transmissão: fila 0 preemptiva; filas 1–5 com round-robin e limites por ciclo (ILIM/4/8/4/2/1).

## 4.2 CAN-Principal (inter-masters)

Apenas Masters + MG + Router GCV. Mapeamento integral:

| MSG_ID | Prioridade | Exigência |
|---|---|---|
| MSG_FAILSAFE, MSG_SAFETY_DATA | 0 | ACK obrigatório; sem descarte |
| MSG_COMMAND, MSG_ACK | 1 | ACK para comando; sem descarte |
| MSG_HEARTBEAT, MSG_TELEMETRY, MSG_SI_DATA, MSG_STATE_BROADCAST, MSG_ACTUATOR_FB, MSG_SYNC_REQ/RESP | 2 | Sem descarte, com envelhecimento |
| MSG_VIDEO_DESC, MSG_CONFIG | 3 | Descarte do mais antigo se cheia |
| MSG_SHELL_CMD | 4 | Descarte do mais antigo; protecção anti-inanição |
| MSG_DEBUG | 5 | Descartável |

Exemplo: telemetria G-SEN→MG com prioridade 2 vence contenda contra descritor de vídeo (3) e diagnóstico (4), mas perde contra comando G-CTV→G-ACT (1) e emergência (0).

## 4.3 CAN-FailSafe (G-FS ←→ AE)

| Tráfego | Prioridade | Política |
|---|---|---|
| Comando de emergência, confirmação, heartbeat de segurança | 0 (fixa) | **Sem descarte**; fila dimensionada para nunca encher (8 posições, transmissão imediata); qualquer pressão anómala gera FAULT |

Não existem níveis 1–5 nesta rede. É proibido multiplexar tráfego ordinário na CAN-FailSafe.

## 4.4 FABRIC (intra-cluster, 8 núcleos)

Arbitragem por TIPO, depois por núcleo:

| TIPO IPC | Prioridade FABRIC | Comportamento |
|---|---|---|
| FAULT, TIME_SYNC | 0 (preemptivo) | Interrompe cálculo em curso no núcleo destino |
| HEALTH_STATUS, SYSTEM_STATUS, HEARTBEAT | 1 | Entrega no ciclo seguinte |
| SENSOR_DATA, NAVIGATION_REQ/RESP | 2 | Fluxo de estimação |
| MATH_REQUEST, RESPONSE, MISSION_REQ/RESP | 2–3 | 2 se com dependência de voo; 3 se diferível |
| BEST_EFFORT / diagnóstico | 4–5 | Descartável sob pressão |

Filas por núcleo: 16 posições para prioridades 0–1 (nunca descartadas), 32 para 2–3, 8 para 4–5. RPC com REQ_ID preserva prioridade do pedido na resposta.

## 4.5 RJ45-Privada RS (dois segmentos isolados)

| Segmento | Direcção | Prioridade | Regra |
|---|---|---|---|
| GCV↔TX 5,8 GHz | Descendente (vídeo 720p30) | Fluxo contínuo isolado | Sem contenda com comando; débito gerido pela placa TX |
| MG↔RX 2,4 GHz (comando ascendente) | Ascendente | 1 (sobre telemetria) | Comando a 50 Hz prevalece |
| MG↔TX 868 MHz (telemetria descendente) | Descendente | 2 periódica / 1 evento | Evento preemptivo sobre periódica |
| Diagnóstico série | Ambas | 4–5 | Só com folga |

É proibida qualquer comparação de prioridade entre segmentos: o isolamento físico torna-a sem sentido.

---

# 5. Escalonamento dos 8 núcleos do MG

O MG possui 4×RP2350 × 2 núcleos = 8 núcleos físicos (N0–N7). Afectação de referência (ajustável pelo Supervisor Cluster):

| Núcleo(s) | Função preferencial |
|---|---|
| N0–N1 (RP2350-0) | Supervisão, TIME_SYNC raiz, FAULT, HMAC/SEQ |
| N2–N3 (RP2350-1) | Fusão sensorial, SENSOR_DATA, NAVIGATION |
| N4–N5 (RP2350-2) | Matemática/cálculo, MATH_REQUEST, MISSION |
| N6–N7 (RP2350-3) | CAN-Principal + Router RF-CMD, HEALTH/SYSTEM_STATUS |

Regras:

* Cada núcleo possui filas FABRIC próprias (§4.4); o arbiter global serve primeiro prioridade 0 em qualquer núcleo.
* RPC pode migrar para núcleo gémeo do mesmo RP2350 se o destino estiver saturado (latência majorada em +50%).
* Núcleos de supervisão (N0–N1) nunca executam cálculo diferível; núcleos de cálculo nunca geram TIME_SYNC.
* Em falha de 1×RP2350, os 6 núcleos restantes assumem as cargas 0–1 e degradam 3–5 (COM-006).

Exemplo numérico: com 8 núcleos a 150 MHz e quadros FABRIC típicos de 32–64 B, o objectivo é RPC local <200 µs e difusão TIME_SYNC a 10 Hz sem jitter superior a 50 µs (valores a confirmar em bancada; majorantes normativos em COM-006).

---

# 6. Descarte e anti-inanição

| Prioridade | Critério | Acção |
|---|---|---|
| 0–1 (CAN) / 0–1 (FABRIC) | Nunca | Permanece até entrega; pressão gera FAULT, não descarte |
| 2 | Fila cheia | Elimina mais antigo; contador `discarded_hi++` |
| 3–4 | Fila cheia | Elimina mais antigo; contadores respectivos |
| 5 | Cheia ou pressão superior | Eliminação imediata |

Invariantes: `discarded_sc == 0` e `discarded_cr == 0` nas CAN; qualquer violação gera alerta de segurança. Anti-inanição: contadores por fila; LOW garantido a cada 100 ciclos, SUPER_LOW a cada 200 (impulsionado temporariamente a HIGH).

---

# 7. Prioridade dinâmica por estado

| MSG_ID / TIPO | NORMAL | FAILSAFE | DEGRADADO (1×RP2350 perdido) |
|---|---|---|---|
| MSG_DEBUG | 5 | 0 | 2 |
| MSG_TELEMETRY / SENSOR_DATA | 2 | 2 | 2 (fusão reduzida) |
| MSG_VIDEO_DESC | 3 | 4 | 4 |
| MSG_SHELL_CMD | 4 | 5 | 5 |
| MATH diferível | 3 | 4 | 5 (suspenso se necessário) |
| MSG_FAILSAFE / FAULT | 0 | 0 | 0 |

A alteração é atómica, ordenada pelo Supervisor Cluster e aplicada em todos os gestores no mesmo ciclo TIME_SYNC.

---

# 8. Exemplo integral

```
CAN-Principal: comando G-CTV→G-ACT (1) vs telemetria G-SEN→MG (2) vs descritor GCV (3)
 → transmite comando; telemetria aguarda; descritor envelhece.
FABRIC: FAULT (0) preempta MATH_REQUEST (3) no N4; resposta RPC herda prioridade 0.
RJ45: evento de emergência (1) preempta telemetria periódica (2) no 868 MHz; vídeo 720p30 prossegue isolado.
```

---

# 9. Nota histórica de migração

> Políticas anteriores indexadas a ESP32/Raspberry Pi/FS_A encontram-se revogadas. As capacidades e prioridades acima aplicam-se aos Grupos Computacionais do COM-001 §3 e aos 8 núcleos do MG.

---

# 10. Referências

* COM-001, COM-002 (+Anexos), COM-003, COM-005, COM-006, COM-007, COM-008, COM-010
