# COM-003 — Gestor de Mensagens

| Campo | Valor |
|---|---|
| **Código** | COM-003 |
| **Título** | Gestor de Mensagens |
| **Versão** | 2.0 |
| **Estado** | Aprovado para implementação |
| **Autor** | ShegaPT |
| **Classificação** | Especificação de Comunicação |

---

# 1. Objectivo

O presente documento define as três funções obrigatórias de gestão das comunicações: (i) **Gestor CAN-TLV**, (ii) **Gestor FABRIC** e (iii) **Router CAN↔RJ45**. Nenhuma outra entidade pode transportar informação inter-grupos, intra-cluster ou para o exterior. Qualquer mecanismo paralelo encontra-se proibido.

---

# 2. Princípios

* Ponto único de passagem por domínio: todo o TLV inter-grupos passa pelo Gestor CAN-TLV; todo o IPC intra-cluster passa pelo Gestor FABRIC; toda a travessia interno↔externo passa pelo Router CAN↔RJ45.
* Determinismo: memória estática, filas limitadas, sem alocação dinâmica em execução.
* Validação antes de encaminhamento, sempre.
* Segregação: a CAN-FailSafe possui gestor dedicado sem partilha de filas com tráfego ordinário.
* Proibição de atalhos: sem comunicação MISSÃO→ATUADOR directa (ver COM-005).

---

# 3. Âmbito (nomenclatura canónica)

| Entidade | Instância de gestão |
|---|---|
| G-SEN, G-ACT, G-CTV, G-NAV, G-MIS, G-CAL, G-COM, G-VIS | Gestor CAN-TLV (redes 1 e 2) |
| G-FS | Gestor CAN-TLV dedicado + gestor da CAN-FailSafe (rede 3) |
| Master Geral (4×RP2350, 8 núcleos) | Gestor CAN-TLV (rede 2) + Gestor FABRIC (rede 4) + Router CAN↔RJ45 comando/telemetria (rede 5) |
| Router GCV (função no G-VIS) | Gestor CAN-TLV (rede 2) + Router CAN↔RJ45 vídeo/descritores (rede 5) |
| Atuação de Emergência | Extremidade da CAN-FailSafe (não é grupo; sem gestor autónomo) |

---

# 4. Gestor CAN-TLV

## 4.1 Diagrama de blocos

```
┌────────────────────── GESTOR CAN-TLV ──────────────────────┐
│                                                            │
│  Aplicação (módulos do grupo)                              │
│  ┌────────┐  ┌────────┐  ┌────────┐                         │
│  │ Mód. A │  │ Mód. B │  │ Mód. C │                         │
│  └───┬────┘  └───┬────┘  └───┬────┘                         │
│      └───────────┼───────────┘                              │
│                  ▼                                          │
│  ┌──────────────────────────────────────┐                  │
│  │ DISPATCHER (por destino CAN-ID e     │                  │
│  │ MSG_ID; Intra-Grupo vs Principal vs  │                  │
│  │ FailSafe) + filas por prioridade     │                  │
│  └──────┬───────────────────┬───────────┘                  │
│         ▼                   ▼                              │
│  ┌────────────┐   ┌──────────────────┐   ┌────────────┐     │
│  │ TX Queue   │   │ VALIDATOR        │   │ RX Queue   │     │
│  │ por prior. │   │ START/MSG/COUNT/ │   │ por prior. │     │
│  └─────┬──────┘   │ CRC8/HMAC/SEQ    │   └─────┬──────┘     │
│        │          └────────┬─────────┘         │            │
│        ▼                   ▼                  ▼            │
│  ┌───────────┐   ┌──────────────────┐   ┌───────────┐       │
│  │ CAN DRIVER│◄─►│ FRAGMENTADOR /   │◄─►│ RECOMPOS. │       │
│  │ (MCP2518FD│   │ RECOMPOSITOR     │   │           │       │
│  │ +transc.) │   │ (≤64 B/quadro)   │   │           │       │
│  └───────────┘   └──────────────────┘   └───────────┘       │
└────────────────────────────────────────────────────────────┘
```

Componentes: Dispatcher, Validator, TX/RX Queues, Fragmentador/Recompositor, CAN Driver. Contadores de erro por origem (CRC, estrutura, limites, totais, descartes).

## 4.2 Recepção

```
Quadro CAN-FD → filtro CAN-ID (hardware) → extracção TLV → parser FSM (COM-002)
 → VALIDATOR: START=0xAA? MSG_ID 0x10–0x1F? COUNT≤32? CRC8? tamanho≤1024?
   HMAC/SEQ (se presentes)? origem conhecida? destino = este Master ou difusão?
 → Dispatcher → fila RX por prioridade → entrega ao módulo
```

Falha em qualquer verificação implica descarte com registo. Na CAN-FailSafe, o descarte gera ainda evento de supervisão e pedido de reenvio (nunca silêncio).

## 4.3 Transmissão

```
Módulo → TLVBuilder → validação local → CRC8 → cabeçalho CAN-ID 29 bits
 → TX Queue por prioridade → fragmentação se >64 B → CAN Driver
```

CAN-ID 29 bits: `(prioridade<<26)|(origem<<22)|(destino<<18)|(tipo<<14)`. Origem/destino são Masters (ou difusão 0x0); tipo classifica o dado. Tabela integral em COM-007/COM-008.

## 4.4 Encaminhamento (resumo)

| Condição | Acção |
|---|---|
| Destino = este Master | Entrega local |
| Destino = difusão | Entrega local (+ processamento de difusão, sem retransmissão automática) |
| Destino = outro Master (mesma rede) | TX Queue da rede respectiva |
| Mensagem de segurança na CAN-FailSafe | Fila dedicada SUPER_CRITICAL, sem descarte |
| Origem desconhecida | Descarte + registo de segurança |

## 4.5 API

`gm_init`, `gm_send(msg,destino,prioridade)`, `gm_broadcast(msg,prioridade)`, `gm_register_handler(msg_id,cb)`, `gm_get_stats`, `gm_reset`. Limites típicos: 6 filas, 32 entradas por fila HIGH/MEDIUM, 8 em SUPER_CRITICAL (dimensionada para nunca encher), 8 fragmentos/mensagem, 100 ms entre fragmentos.

---

# 5. Gestor FABRIC (intra-cluster, Master Geral)

## 5.1 Função

 Gere o IPC determinístico de baixa latência entre os 8 núcleos dos 4×RP2350, incluindo RPC entre núcleos (pedido `MATH_REQUEST`/`NAVIGATION_REQ`/`MISSION_REQ` → resposta `RESPONSE` correlacionada por REQ_ID).

```
┌────────────────── GESTOR FABRIC (MG) ──────────────────┐
│ Núcleos 0–7 (4×RP2350)                                 │
│  ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐ │
│  │ N0 │ │ N1 │ │ N2 │ │ N3 │ │ N4 │ │ N5 │ │ N6 │ │ N7 │ │
│  └──┬─┘ └──┬─┘ └──┬─┘ └──┬─┘ └──┬─┘ └──┬─┘ └──┬─┘ └──┬─┘ │
│     └──────┴──────┴──────┬──────┴──────┴──────┴──────┘   │
│                         ▼                              │
│  ┌─────────────────────────────────────────────────┐   │
│  │ ARBITER FABRIC (por TIPO + núcleo; TIME_SYNC e  │   │
│  │ FAULT preemptivos) + filas por núcleo           │   │
│  └──────┬────────────────────────────┬─────────────┘   │
│         ▼                            ▼                 │
│  ┌──────────────┐            ┌───────────────┐          │
│  │ RPC TRACKER  │            │ CRC FABRIC    │          │
│  │ (REQ_ID,     │            │ (validação)   │          │
│  │  tempos-     │            │               │          │
│  │  limite)     │            │               │          │
│  └──────────────┘            └───────────────┘          │
│  Transporte: SPI/DMA/PIO/memória partilhada (a definir; │
│  protocolo lógico invariante — COM-002 Anexo A)         │
└────────────────────────────────────────────────────────┘
```

Tipos servidos: SENSOR_DATA, MATH_REQUEST, RESPONSE, NAVIGATION_REQ/RESP, MISSION_REQ/RESP, HEALTH_STATUS, SYSTEM_STATUS, TIME_SYNC, FAULT, HEARTBEAT.

## 5.2 Regras

* Todo o quadro FABRIC possui SOURCE/DESTINO/NÚCLEO/TIPO/REQ_ID/TIMESTAMP/COMPRIMENTO/PAYLOAD/CRC (COM-002 Anexo A).
* RPC: o emissor regista REQ_ID com tempo-limite (COM-006); a resposta com o mesmo REQ_ID completa a chamada; expiração gera FAULT.
* TIME_SYNC e FAULT são preemptivos sobre tráfego de cálculo.
* Sem alocação dinâmica; filas por núcleo dimensionadas em COM-004.
* Falha de 1×RP2350: o Gestor FABRIC isola o par de núcleos afectado, redistribui cargas críticas e sinaliza DEGRADADO (COM-006).

## 5.3 API

`fab_init`, `fab_call(núcleo_dest,tipo,payload,timeout)→REQ_ID`, `fab_reply(req_id,payload)`, `fab_publish(tipo,payload)`, `fab_poll(núcleo)`, `fab_stats`.

---

# 6. Router CAN↔RJ45 (única travessia interno↔externo)

Duas instâncias independentes, sem partilha:

| Instância | Sede | Segmento RJ45-RS | Função |
|---|---|---|---|
| Router-RF-CMD | MG | MG←→RX 2,4 GHz + TX 868 MHz | Encapsula/descapsula comando ascendente e telemetria descendente; traduz endereços CAN↔série; policia débito e prioridade; rejeita vídeo |
| Router-GCV-VID | G-VIS (Router GCV) | GCV←→TX 5,8 GHz | Gere o stream 720p30 para a placa TX; publica na CAN apenas `MSG_VIDEO_DESC`; rejeita injecção de comando no segmento de vídeo |

```
 INTERNO (CAN)                    ROUTER                    EXTERNO (RJ45-RS + RF)
 Masters/TLV ──► [valida→traduz→policia] ──► série RS ──► RX 2,4 / TX 868 (cmd/telem.)
 série RS ──► [valida CRC+soma→traduz→FILTRA] ──► TLV CAN (só tipos autorizados)
 GCV ──► [gestão de stream] ──► série RS ──► TX 5,8 GHz ──► 720p30 no ar
```

Regras imperativas:

1. Todo o TLV encapsulado para RF foi previamente validado (CRC8/HMAC/SEQ) na CAN.
2. Todo o conteúdo vindo de RF é validado (soma de verificação + SEQ de enlace) antes de qualquer injecção na CAN; tipos não autorizados são eliminados com registo.
3. O Router-RF-CMD jamais encapsula vídeo; o Router-GCV-VID jamais injecta comando no segmento de vídeo.
4. Débitos policiados: comando 50 Hz prioritário sobre telemetria periódica; telemetria de evento preemptiva sobre periódica (COM-004).
5. Falha de RF não se propaga como falha CAN: o router sinaliza `LINK_DOWN` e o sistema prossegue em voo autónomo.

Exemplo numérico: comando de 24 B a 50 Hz ⇒ 1 200 B/s úteis (≈ 9,6 kbit/s); telemetria de 64 B a 10 Hz ⇒ 640 B/s; ambos folgadamente cabem em 115 200 bit/s com folga para reenvios e eventos.

---

# 7. Coexistência com interfaces locais

UART/SPI/I2C com sensores e actuadores são periféricas locais de cada grupo (documentadas em HW) e não constituem redes do modelo. Toda a comunicação inter-grupos, intra-cluster e com o exterior passa obrigatoriamente pelas três funções deste documento.

---

# 8. Segurança e validação

Sequência no receptor CAN: CRC CAN (hardware) → filtro CAN-ID → parser TLV → CRC8 → HMAC → SEQ → entrega. No FABRIC: CRC FABRIC → TIPO/REQ_ID → entrega/RPC. No Router: validação do domínio de origem antes de qualquer tradução. Contadores por camada (COM-010).

---

# 9. Nota histórica de migração

> Raspberry Pi, ESP32 e FS_A não são instâncias deste gestor e não possuem filas, handlers nem rotas. Correspondências antigas (ex.: «orquestrador», «ponte entre barramentos») devem ser reatribuídas ao Master Geral, aos Masters de Grupo e ao Router GCV nos termos do §3.

---

# 10. Referências

* COM-001 — Arquitetura de Comunicação
* COM-002 — Protocolo TLV (+ Anexos FABRIC e RJ45)
* COM-004 — Prioridades e Filas
* COM-005 — Eventos
* COM-006 — Timeouts e Recuperação
* COM-007 — Comunicação entre Domínios
* COM-008 — CAN Bus
* COM-010 — Integridade
