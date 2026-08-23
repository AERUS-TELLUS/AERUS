# COM-009 — Sincronização

| Campo             | Valor                              |
| ----------------- | ---------------------------------- |
| **Código**        | COM-009                            |
| **Título**        | Sincronização                      |
| **Versão**        | 1.0                                |
| **Estado**        | Em Desenvolvimento                 |
| **Autor**         | ShegaPT                            |
| **Classificação** | Especificação de Comunicação       |

---

# 1. Objetivo

O presente documento define os mecanismos de sincronização temporal entre os Grupos Computacionais do sistema Aerus, estabelecendo os protocolos, mensagens, precisão requerida e múltiplas referências temporais utilizadas.

A sincronização temporal é essencial para a coordenação de aquisição de dados, processamento de comandos e avaliação de segurança em tempo real.

---

# 2. Princípios

* RaspberryPi e ESP32-FS estabelecem referência temporal comum na inicialização;
* ESP32-S e ESP32-A sincronizam-se com a referência comum;
* ESP32-FS_A sincroniza-se com ESP32-FS no bus de segurança;
* múltiplas referências temporais: UTC, monotónico, missão, voo, modo;
* precisão sub-millisegundo para operações críticas;
* referência a `SYS-008` para gestão temporal global;
* determinismo — sincronização é periódica e previsível.

---

# 3. Referências Temporais

## 3.1 Tipos de Referência

| Referência | Descrição | Origem | Precisão |
|-----------|-----------|--------|----------|
| UTC | Tempo Universal Coordenado | GPS/GNSS | ~100ns |
| Monotónico | Relógio desde arranque | Hardware Timer | ~1µs |
| Missão | Tempo desde início da missão | Software | ~1ms |
| Voo | Tempo desde takeoff | Software | ~1ms |
| Modo | Tempo desde última mudança de modo | Software | ~1ms |

## 3.2 Diagrama de Referências

```text
┌─────────────────────────────────────────────────────────────┐
│  REFERÊNCIAS TEMPORAIS                                        │
│                                                              │
│  UTC (GPS/GNSS)                                              │
│  └─→ Referência absoluta, sincronizada com satélites         │
│                                                              │
│  Monotónico (Hardware Timer)                                │
│  └─→ Referência desde arranque, sem overflow                 │
│                                                              │
│  Missão (Software)                                          │
│  └─→ Referência desde início da missão                       │
│                                                              │
│  Voo (Software)                                             │
│  └─→ Referência desde takeoff                                │
│                                                              │
│  Modo (Software)                                            │
│  └─→ Referência desde última mudança de modo                 │
│                                                              │
│  Relações:                                                   │
│  UTC ≥ Monotónico ≥ Missão ≥ Voo ≥ Modo                     │
│  (cada referência pode ser derivada da anterior)             │
└─────────────────────────────────────────────────────────────┘
```

---

# 4. Mensagens de Sincronização

## 4.1 MSG_SYNC_REQ (0x1C)

Mensagem de pedido de sincronização temporal:

```text
┌─────────────────────────────────────────────────────────────┐
│  MSG_SYNC_REQ (0x1C)                                         │
│                                                              │
│  TLV Fields:                                                 │
│  ├── FLD_SYNC_ID (1 byte): Identificador do pedido           │
│  ├── FLD_SYNC_TYPE (1 byte): Tipo de referência pretendida    │
│  │     0x01 = UTC                                            │
│  │     0x02 = Monotónico                                     │
│  │     0x03 = Missão                                         │
│  │     0x04 = Voo                                            │
│  │     0x05 = Todos                                          │
│  ├── FLD_REQ_TIMESTAMP_TX (4 bytes): Timestamp do envio      │
│  └── FLD_REQ_NODE_ID (1 byte): ID do nó solicitante          │
│                                                              │
│  Prioridade: HIGH (2)                                        │
│  Frequência: 1Hz (sincronização) ou sob demanda              │
└─────────────────────────────────────────────────────────────┘
```

## 4.2 MSG_SYNC_RESP (0x1D)

Mensagem de resposta de sincronização temporal:

```text
┌─────────────────────────────────────────────────────────────┐
│  MSG_SYNC_RESP (0x1D)                                        │
│                                                              │
│  TLV Fields:                                                 │
│  ├── FLD_SYNC_ID (1 byte): ID do pedido correspondente       │
│  ├── FLD_SYNC_TYPE (1 byte): Tipo de referência fornecida    │
│  ├── FLD_RESP_TIMESTAMP_TX (4 bytes): Timestamp do envio     │
│  ├── FLD_UTC_SECONDS (4 bytes): UTC segundos desde epoch     │
│  ├── FLD_UTC_MICROSECONDS (4 bytes): Microssegundos          │
│  ├── FLD_MONOTONIC_MS (4 bytes): Monotónico em ms            │
│  ├── FLD_MISSION_MS (4 bytes): Missão em ms                  │
│  ├── FLD_FLIGHT_MS (4 bytes): Voo em ms                      │
│  ├── FLD_MODE_MS (4 bytes): Modo em ms                       │
│  └── FLD_CLOCK_DRIFT (2 bytes): Drift estimado (ppb)        │
│                                                              │
│  Prioridade: HIGH (2)                                        │
│  Latência máxima: 10ms após receção de REQ                   │
└─────────────────────────────────────────────────────────────┘
```

---

# 5. Protocolo de Sincronização

## 5.1 Fluxo de Sincronização

```text
┌──────────┐                              ┌──────────┐
│  NÓ A    │                              │  NÓ B    │
│(solicit.)│                              │(referência)│
└────┬─────┘                              └────┬─────┘
     │                                         │
     │  1. Construir MSG_SYNC_REQ              │
     │  ─────────────────────────────          │
     │  - FLD_SYNC_ID = seq_atual              │
     │  - FLD_REQ_TIMESTAMP_TX = t1            │
     │                                         │
     │  2. Transmissão                         │
     │  ════════════════════════►              │
     │                                         │
     │                          3. Receção     │
     │                          ───────────    │
     │                          t2 = timestamp │
     │                                         │
     │                          4. Processar   │
     │                          ───────────    │
     │                          - Calcular RTT │
     │                          - Construir    │
     │                            MSG_SYNC_RESP│
     │                                         │
     │  5. Receção de RESP                     │
     │  ◄══════════════════════                │
     │  t3 = timestamp                         │
     │                                         │
     │  6. Calcular offset                     │
     │  ──────────────────                     │
     │  RTT = (t3 - t1) - (t2' - t1')         │
     │  offset = t2 + RTT/2 - t1              │
     │                                         │
     │  7. Aplicar correção                     │
     │  ──────────────────                     │
     │  clock_local = clock_local + offset     │
     │                                         │
```

## 5.2 Cálculo de RTT e Offset

```text
┌─────────────────────────────────────────────────────────────┐
│  CÁLCULO DE RTT E OFFSET                                      │
│                                                              │
│  t1 = Timestamp de envio do REQ (nó A)                       │
│  t2 = Timestamp de receção do REQ (nó B)                     │
│  t3 = Timestamp de envio do RESP (nó B)                      │
│  t4 = Timestamp de receção do RESP (nó A)                    │
│                                                              │
│  RTT = (t4 - t1) - (t3 - t2)                                │
│                                                              │
│  Offset = ((t2 - t1) + (t3 - t4)) / 2                       │
│                                                              │
│  ou simplificado:                                            │
│  Offset = t2 + RTT/2 - t1                                   │
│                                                              │
│  Precisão esperada: < 1ms no CAN FD                          │
│  Precisão com BRS: < 100µs                                   │
└─────────────────────────────────────────────────────────────┘
```

---

# 6. Hierarquia de Sincronização

## 6.1 Hierarquia

```text
┌─────────────────────────────────────────────────────────────┐
│  HIERARQUIA DE SINCRONIZAÇÃO                                  │
│                                                              │
│  NÍVEL 0 (Referência primária):                              │
│  ┌─────────────────────────────────────────┐                │
│  │  RaspberryPi ←→ ESP32-FS                 │                │
│  │  (estabelecem referência comum)          │                │
│  └───────────────────┬─────────────────────┘                │
│                      │                                       │
│  NÍVEL 1 (Secundários):                                     │
│  ┌───────────┴───────────┬────────────────┐                 │
│  │                       │                │                 │
│  ▼                       ▼                ▼                 │
│  ESP32-S_01          ESP32-S_02       ESP32-A               │
│  (sincroniza com RPi) (sincroniza     (sincroniza          │
│                        com RPi)        com RPi)             │
│                                                              │
│  NÍVEL 2 (Emergência):                                      │
│  ┌───────────┴────────────────────────┐                     │
│  │                                     │                     │
│  ▼                                     │                     │
│  ESP32-FS_A                            │                     │
│  (sincroniza com ESP32-FS via bus seg.)│                     │
└─────────────────────────────────────────────────────────────┘
```

## 6.2 Regras de Sincronização

| Grupo | Sincroniza com | Bus | Frequência | Prioridade |
|-------|---------------|-----|-----------|-----------|
| RaspberryPi ↔ ESP32-FS | Mútua | Operacional | 1Hz | HIGH |
| ESP32-S_01 | RaspberryPi | Operacional | 1Hz | HIGH |
| ESP32-S_02 | RaspberryPi | Operacional | 1Hz | HIGH |
| ESP32-A | RaspberryPi | Operacional | 1Hz | HIGH |
| ESP32-FS_A | ESP32-FS | Segurança | 1Hz | SUPER_CRITICAL |

---

# 7. Inicialização

## 7.1 Sequência de Arranque

```text
┌─────────────────────────────────────────────────────────────┐
│  SEQUÊNCIA DE ARRANQUE E SINCRONIZAÇÃO                        │
│                                                              │
│  1. Power-on                                                 │
│  └─→ Cada nó inicia com seu relógio local                    │
│                                                              │
│  2. Fase de Discovery (0-2s)                                 │
│  └─→ Heartbeats são transmitidos para detetar nós ativos     │
│                                                              │
│  3. Fase de Sincronização (2-5s)                             │
│  ├── RaspberryPi envia MSG_SYNC_REQ para ESP32-FS            │
│  ├── ESP32-FS responde com MSG_SYNC_RESP                     │
│  ├── RaspberryPi calcula offset e aplica                     │
│  └── ESP32-FS calcula offset e aplica                        │
│                                                              │
│  4. Fase de Propagação (5-8s)                                │
│  ├── RaspberryPi sincroniza ESP32-S_01, ESP32-S_02, ESP32-A │
│  ├── ESP32-FS sincroniza ESP32-FS_A                          │
│  └── Todos os nós possuem referência comum                   │
│                                                              │
│  5. Operação Normal (após 8s)                                │
│  └─→ Sincronização periódica (1Hz)                           │
└─────────────────────────────────────────────────────────────┘
```

## 7.2 Timeout de Inicialização

| Fase | Timeout | Ação em caso de falha |
|------|---------|----------------------|
| Discovery | 2s | Continuar sem sync |
| Sincronização primária | 3s | Usar relógio local |
| Propagação | 3s | Usar relógio local |
| Total | 8s | Operar com relógio local + alerta |

---

# 8. Sincronização Periódica

## 8.1 Frequência

| Condição | Frequência | Descrição |
|----------|-----------|-----------|
| Normal | 1 Hz | Sincronização de manutenção |
| After drift detectado | 10 Hz | Correção acelerada |
| After reinicialização | 10 Hz (primeiros 10s) | Estabilização rápida |
| Failsafe | 1 Hz | Manter sync durante failsafe |

## 8.2 Detecção de Drift

```text
┌─────────────────────────────────────────────────────────────┐
│  DETECÇÃO DE DRIFT                                            │
│                                                              │
│  A cada ciclo de sincronização:                              │
│  1. Calcular offset atual                                    │
│  2. Comparar com offset anterior                             │
│  3. Se |drift| > THRESHOLD_DRIFT:                           │
│     ├── drift < 1ms: Sincronização normal                    │
│     ├── drift 1-10ms: Sincronização acelerada                │
│     ├── drift 10-100ms: Alerta + sincronização acelerada     │
│     └── drift > 100ms: Erro + tentativa de recuperação       │
│                                                              │
│  THRESHOLD_DRIFT = 10ms                                      │
└─────────────────────────────────────────────────────────────┘
```

## 8.3 Diagrama de Sincronização Periódica

```text
┌─────────────────────────────────────────────────────────────┐
│  SINCRONIZAÇÃO PERIÓDICA                                      │
│                                                              │
│  A cada 1000ms (1Hz):                                        │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  1. Nó solicitante envia MSG_SYNC_REQ                │    │
│  │  2. Nó referência responde com MSG_SYNC_RESP         │    │
│  │  3. Nó solicitante calcula offset                    │    │
│  │  4. Nó solicitante aplica correção                   │    │
│  │  5. Regista estatísticas de sync                     │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                              │
│  Estatísticas registadas:                                    │
│  ├── offset_ms: Último offset calculado                     │
│  ├── drift_ppb: Drift em parts per billion                   │
│  ├── rtt_ms: Round-trip time da última sincronização         │
│  ├── sync_errors: Contador de erros de sincronização         │
│  └── last_sync_ms: Timestamp da última sincronização         │
└─────────────────────────────────────────────────────────────┘
```

---

# 9. Requisitos de Precisão

## 9.1 Precisão por Aplicação

| Aplicação | Precisão requerida | Justificação |
|-----------|-------------------|-------------|
| Fusão de sensores | < 1ms | Correlação temporal de dados |
| Controlo de voo | < 5ms | Latência de comandos |
| Heartbeat | < 10ms | Deteção de timeout |
| Logging | < 100ms | Rastreabilidade de eventos |
| Segurança | < 1ms | Avaliação de condições críticas |

## 9.2 Fatores que Afetam Precisão

| Fator | Impacto | Mitigação |
|-------|---------|-----------|
| Latência CAN | ~10-100µs | Medição de RTT |
| Jitter de processamento | ~1-10µs | Hardware timers |
| Drift de cristal | ~10-100 ppm | Sincronização periódica |
| Overflow de timer | ~49 dias (32-bit) | Rollover management |
| Clock skew entre nós | ~10-100 ppm | Calibração contínua |

---

# 10. Múltiplos Relógios

## 10.1 Implementação por Grupo

| Grupo | RTC | Hardware Timer | Software Counters | GPS |
|-------|-----|---------------|-------------------|-----|
| RaspberryPi | Sim (DS3231) | Sim | Sim | Sim (GPS USB) |
| ESP32-S | Não | Sim (64-bit) | Sim | Não |
| ESP32-A | Não | Sim (64-bit) | Sim | Não |
| ESP32-FS | Sim (DS3231) | Sim (64-bit) | Sim | Sim (GPS SPI) |
| ESP32-FS_A | Não | Sim (64-bit) | Sim | Não |

## 10.2 Propagação de UTC

```text
┌─────────────────────────────────────────────────────────────┐
│  PROPAGAÇÃO DE UTC                                             │
│                                                              │
│  GPS (RaspberryPi ou ESP32-FS)                               │
│  └─→ UTC obtido via NMEA ou PPS                              │
│                                                              │
│  Referência primária (RaspberryPi ou ESP32-FS):              │
│  └─→ UTC transmitido via MSG_SYNC_RESP                       │
│                                                              │
│  Nós secundários (ESP32-S, ESP32-A):                         │
│  └─→ UTC derivado da sincronização                           │
│                                                              │
│  ESP32-FS_A:                                                 │
│  └─→ UTC derivado da sincronização com ESP32-FS              │
│                                                              │
│  NOTA: UTC é propagado apenas se GPS estiver disponível.     │
│  Caso contrário, usa-se monotónico como referência.          │
└─────────────────────────────────────────────────────────────┘
```

---

# 11. Tratamento de Erros

## 11.1 Erros de Sincronização

| Erro | Critério | Ação |
|------|---------|------|
| Timeout de RESP | 100ms sem resposta | Retry (máx 3) |
| RTT elevado | RTT > 10ms | Alerta de latência |
| Offset inválido | Offset > 1s | Rejeitar, usar relógio local |
| Drift excessivo | Drift > 100ppm | Alerta de cristal |
| Nó indisponível | 3 syncs sem resposta | Timeout do nó |

## 12.2 Diagrama de Erros

```text
┌─────────────────────────────────────────────────────────────┐
│  TRATAMENTO DE ERROS DE SINCRONIZAÇÃO                         │
│                                                              │
│  MSG_SYNC_REQ enviado                                        │
│       │                                                      │
│       ├──(timeout RESP)──→ Retry 1                           │
│       │                        │                             │
│       │                   (timeout)──→ Retry 2               │
│       │                                    │                 │
│       │                               (timeout)──→ Retry 3   │
│       │                                                    │
│       │                                    (timeout)──→ FALHA│
│       │                                                      │
│       ├──(RTT > 10ms)──→ Alerta, mas sincronizar             │
│       │                                                      │
│       ├──(offset > 1s)──→ Rejeitar, usar relógio local       │
│       │                                                      │
│       └──(sucesso)──→ Aplicar offset, registar               │
└─────────────────────────────────────────────────────────────┘
```

---

# 13. Integração com SYS-008

## 13.1 Referência

A gestão temporal global é definida em `SYS-008`. Este documento (`COM-009`) define especificamente a sincronização entre Grupos Computacionais via CAN.

## 13.2 Interface

```text
┌─────────────────────────────────────────────────────────────┐
│  INTERFACE COM SYS-008                                         │
│                                                              │
│  SYS-008 fornece:                                            │
│  ├── Definição de temporização global                        │
│  ├── Requisitos de latência por aplicação                    │
│  ├── Gestão de timeouts globais                              │
│  └── Políticas de energia vs. performance                    │
│                                                              │
│  COM-009 fornece:                                            │
│  ├── Mecanismo de sincronização via CAN                      │
│  ├── Protocolo MSG_SYNC_REQ / MSG_SYNC_RESP                  │
│  ├── Hierarquia de sincronização                             │
│  └── Precisão alcançável no CAN FD                           │
│                                                              │
│  Cooperação:                                                 │
│  ├── SYS-008 define QUANDO sincronizar                       │
│  ├── COM-009 define COMO sincronizar                         │
│  └── Ambos definem a precisão requerida                      │
└─────────────────────────────────────────────────────────────┘
```

---

# 14. API de Sincronização

## 14.1 Funções Principais

| Função | Descrição |
|--------|-----------|
| `sync_init()` | Inicialização do módulo de sincronização |
| `sync_request(destino, type)` | Enviar pedido de sincronização |
| `sync_handle_response(resp)` | Processar resposta de sincronização |
| `sync_get_offset(grupo)` | Obter offset em relação a um grupo |
| `sync_get_utc()` | Obter UTC atual |
| `sync_get_monotonic()` | Obter timestamp monotónico |
| `sync_get_mission()` | Obter tempo de missão |
| `sync_get_flight()` | Obter tempo de voo |
| `sync_get_mode()` | Obter tempo de modo |

## 14.2 Estruturas de Dados

```cpp
typedef struct {
    uint8_t  sync_id;           // ID da sincronização
    uint8_t  sync_type;         // Tipo de referência
    int32_t  offset_ms;         // Offset em ms
    uint16_t drift_ppb;         // Drift em ppb
    uint32_t rtt_ms;            // Round-trip time
    uint32_t last_sync_ms;     // Timestamp da última sync
    uint32_t sync_errors;      // Contador de erros
} SyncInfo;

typedef struct {
    uint32_t utc_seconds;       // UTC segundos
    uint32_t utc_microseconds;  // UTC microssegundos
    uint64_t monotonic_ms;      // Monotónico em ms
    uint32_t mission_ms;        // Missão em ms
    uint32_t flight_ms;         // Voo em ms
    uint32_t mode_ms;           // Modo em ms
} TemporalReference;
```

---

# 15. Limites do Documento

Este documento não define:

* gestão temporal global (ver `SYS-008`);
* implementação do Gestor de Mensagens (ver `COM-003`);
* regras de prioridade (ver `COM-004`);
* mecanismos de integridade (ver `COM-010`);
* detalhes de hardware timer (ver `HW-006`);
* gestão de estados (ver `SYS-006`).

---

# 16. Referências

- COM-001 — Arquitetura de Comunicação
- COM-002 — Protocolo TLV
- COM-003 — Gestor de Mensagens
- COM-004 — Prioridades e Filas
- COM-006 — Timeouts e Recuperação
- COM-007 — Comunicação entre Domínios Computacionais
- COM-008 — CAN Bus
- COM-010 — Integridade
- SHARED-TLV — Definições do Protocolo TLV
- SHARED-CAN-IDS — Alocação de CAN IDs
- SYS-003 — Arquitetura de Software
- SYS-006 — Gestão de Estados
- SYS-008 — Gestão Temporal
- HW-006 — Interfaces de Comunicação
