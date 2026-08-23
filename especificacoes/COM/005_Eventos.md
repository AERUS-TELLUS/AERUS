# COM-005 — Eventos

| Campo             | Valor                              |
| ----------------- | ---------------------------------- |
| **Código**        | COM-005                            |
| **Título**        | Eventos                            |
| **Versão**        | 1.0                                |
| **Estado**        | Em Desenvolvimento                 |
| **Autor**         | ShegaPT                            |
| **Classificação** | Especificação de Comunicação       |

---

# 1. Objetivo

O presente documento define o mecanismo de comunicação baseada em eventos do sistema Aerus, estabelecendo os tipos de eventos, regras de ativação, confirmação, registo e rastreabilidade.

A comunicação baseada em eventos complementa a comunicação periódica (telemetria, heartbeat), permitindo que situações críticas ou mudanças de estado sejam comunicadas imediatamente entre Grupos Computacionais.

---

# 2. Princípios

* eventos são mensagens TLV com MSG_ID específico;
* eventos de segurança utilizam SUPER_CRITICAL no bus de segurança;
* mecanismo de trigger/acknowledge para eventos críticos;
* eventos podem sobrepor comunicação periódica;
* registo completo para rastreabilidade e diagnóstico;
* determinismo — regras de ativação são previsíveis;
* coexistência com comunicação periódica sem conflito.

---

# 3. Definição de Evento

## 3.1 Conceito

Um evento é uma mensagem TLV transmitida em resposta a uma ocorrência significativa no sistema, como uma mudança de estado, deteção de anomalia ou condição de emergência.

## 3.2 Diferença entre Evento e Mensagem Periódica

| Característica | Mensagem Periódica | Evento |
|---------------|-------------------|--------|
| Gatilho | Timer/ciclo | Ocorrência/estado |
| Frequência | Regular (configurada) | Irregular (sob demanda) |
| Latência | Aceitável | Mínima (imediata) |
| Prioridade | Variável | Tipicamente HIGH ou superior |
| Exemplo | MSG_TELEMETRY | MSG_FAILSAFE |

## 3.3 Estrutura de um Evento

```text
┌─────────────────────────────────────────────────────────────┐
│  EVENTO = Mensagem TLV + Metadados de Evento                 │
│                                                              │
│  Mensagem TLV:                                               │
│  ┌─────────┬─────────┬───────────┬─────────────┬─────────┐ │
│  │ START   │ MSG_ID  │ TLV COUNT │ TLV FIELDS  │ CRC8    │ │
│  │ (0xAA)  │(0x10-1F)│  (0-32)   │ (variável)  │         │ │
│  └─────────┴─────────┴───────────┴─────────────┴─────────┘ │
│                                                              │
│  Metadados de Evento (no TLV FIELDS):                        │
│  - EVENT_TYPE (tipo do evento)                               │
│  - EVENT_SOURCE (origem do evento)                           │
│  - EVENT_TIMESTAMP (quando ocorreu)                          │
│  - EVENT_SEVERITY (gravidade)                                │
│  - EVENT_DATA (dados específicos do evento)                  │
└─────────────────────────────────────────────────────────────┘
```

---

# 4. Tipos de Evento

## 4.1 Classificação

| Tipo | Constante | Descrição | Prioridade |
|------|-----------|-----------|-----------|
| Segurança | `EVT_SAFETY` | Condições de segurança/failsafe | SUPER_CRITICAL |
| Sensor | `EVT_SENSOR` | Anomalias ou mudanças em sensores | HIGH |
| Atuador | `EVT_ACTUATOR` | Falhas ou mudanças em atuadores | HIGH |
| Sistema | `EVT_SYSTEM` | Mudanças de estado, erros internos | MEDIUM-HIGH |
| Comunicação | `EVT_COMM` | Perda de comunicação, erros de CAN | HIGH |

## 4.2 Eventos Específicos

### 4.2.1 Eventos de Segurança

| Evento | MSG_ID | Descrição | Ação |
|--------|--------|-----------|------|
| FAILSAFE_ACTIVATION | MSG_FAILSAFE (0x14) | Ativação de modo failsafe | Controlo transferido para ESP32-FS |
| FAILSAFE_DEACTIVATION | MSG_FAILSAFE (0x14) | Desativação de modo failsafe | Controlo retomado pelo RaspberryPi |
| SAFETY_DATA | MSG_SAFETY_DATA (0x1B) | Dados críticos de segurança | Processamento imediato |
| EMERGENCY_STOP | MSG_FAILSAFE (0x14) | Paragem de emergência | Todos os atuadores para posição segura |

### 4.2.2 Eventos de Sensor

| Evento | MSG_ID | Descrição | Ação |
|--------|--------|-----------|------|
| SENSOR_FAILURE | MSG_TELEMETRY (0x11) | Sensor devolveu dados inválidos | Fusão de sensores compensa |
| SENSOR_RECOVERY | MSG_TELEMETRY (0x11) | Sensor recuperou após falha | Reintegração no sistema |
| SENSOR_DRIFT | MSG_TELEMETRY (0x11) | Drift anormal detetado | Alerta de calibração |

### 4.2.3 Eventos de Atuador

| Evento | MSG_ID | Descrição | Ação |
|--------|--------|-----------|------|
| ACTUATOR_FAILURE | MSG_ACTUATOR_FB (0x1A) | Atuador não responde | Redundância ou failover |
| ACTUATOR_OVERCURRENT | MSG_ACTUATOR_FB (0x1A) | Corrente excessiva | Desativação do canal |
| ACTUATOR_RECOVERY | MSG_ACTUATOR_FB (0x1A) | Atuador recuperou | Reintegração |

### 4.2.4 Eventos de Sistema

| Evento | MSG_ID | Descrição | Ação |
|--------|--------|-----------|------|
| STATE_CHANGE | MSG_STATE_BROADCAST (0x19) | Mudança de estado do grupo | Atualização de todos |
| CONFIG_UPDATE | MSG_CONFIG (0x1E) | Configuração atualizada | Reload de parâmetros |
| SYNC_EVENT | MSG_SYNC_REQ (0x1C) | Evento de sincronização | Sincronização temporal |

### 4.2.5 Eventos de Comunicação

| Evento | MSG_ID | Descrição | Ação |
|--------|--------|-----------|------|
| HEARTBEAT_LOST | MSG_HEARTBEAT (0x10) | Heartbeat perdido | Início de timeout (ver `COM-006`) |
| HEARTBEAT_RECOVERED | MSG_HEARTBEAT (0x10) | Heartbeat recuperado | Cancelamento de timeout |
| CAN_BUS_OFF | — | Born-off detetado | Tentativa de recuperação |
| CRC_ERROR_spike | — | Pico de erros CRC | Alerta de qualidade do canal |

---

# 5. Mecanismo Trigger/Acknowledge

## 5.1 Fluxo Geral

```text
┌──────────┐                              ┌──────────┐
│  NÓ A    │                              │  NÓ B    │
│ (origem) │                              │(destino) │
└────┬─────┘                              └────┬─────┘
     │                                         │
     │  1. Evento detetado                     │
     │  ──────────────────────                 │
     │  Construção de MSG_FAILSAFE             │
     │  com EVENT_TYPE + EVENT_DATA            │
     │                                         │
     │  2. Transmissão imediata                │
     │  ════════════════════════►              │
     │  CAN ID: SUPER_CRITICAL                 │
     │                                         │
     │                          3. Receção     │
     │                          ───────────    │
     │                          Validação      │
     │                          Processamento  │
     │                                         │
     │  4. Confirmação (ACK)                   │
     │  ◄══════════════════════                │
     │  MSG_ACK com EVENT_ID                   │
     │                                         │
     │  5. Registo                             │
     │  ──────────                             │
     │  Timestamp + Evento + ACK               │
     │                                         │
```

## 5.2 Regras de ACK

| Regra | Descrição |
|-------|-----------|
| Eventos CRITICAL+ | SEMPRE requerem ACK |
| Eventos HIGH | Requerem ACK se configurado |
| Eventos MEDIUM- | NÃO requerem ACK |
| Timeout de ACK | Configurável (padrão: 100ms para CRITICAL, 500ms para HIGH) |
| Reenvio | Máximo 3 tentativas antes de perda de comunicação |

## 5.3 Estrutura do ACK

```text
┌─────────────────────────────────────────────────────────────┐
│  MSG_ACK (0x13) — Confirmação de Evento                      │
│                                                              │
│  TLV Fields:                                                 │
│  ├── FLD_EVENT_ID (1 byte): ID do evento confirmado          │
│  ├── FLD_ACK_STATUS (1 byte): 0=OK, 1=ERRO, 2=REJEITADO     │
│  └── FLD_ACK_TIMESTAMP (4 bytes): Timestamp da confirmação   │
└─────────────────────────────────────────────────────────────┘
```

---

# 6. Prioridade de Eventos

## 6.1 Regras de Prioridade

| Prioridade do evento | Pode interromper comunicação periódica? | Pode interromper outro evento? |
|---------------------|----------------------------------------|-------------------------------|
| SUPER_CRITICAL | Sim | Sim |
| CRITICAL | Sim | Não |
| HIGH | Não (aguarda ciclo) | Não |
| MEDIUM | Não | Não |

## 6.2 Sobreposição com Comunicação Periódica

```text
┌─────────────────────────────────────────────────────────────┐
│  LINHA TEMPORAL                                              │
│                                                              │
│  ──[TELEMETRIA]──[HEARTBEAT]──[EVENTO SC]──[TELEMETRIA]──   │
│                                    │                          │
│                          ┌─────────┘                          │
│                          │                                    │
│              O EVENTO interrompe a sequência                  │
│              periódica e é transmitido IMEDIATAMENTE           │
│                                                              │
│  ──[HEARTBEAT]──[EVENTO HIGH]──[HEARTBEAT]──[TELEMETRY]──   │
│                      │                                        │
│              O EVENTO aguarda o próximo                       │
│              slot de transmissão                              │
└─────────────────────────────────────────────────────────────┘
```

---

# 7. Eventos no Bus de Segurança

## 7.1 Especificidade

O bus de segurança (dedicado ESP32-FS ↔ ESP32-FS_A) transporta exclusivamente eventos de segurança:

```text
┌─────────────────────────────────────────────────────────────┐
│  BUS DE SEGURANÇA                                            │
│                                                              │
│  ESP32-FS ←──────────────────────────→ ESP32-FS_A           │
│                                                              │
│  Mensagens permitidas:                                       │
│  ├── MSG_FAILSAFE (0x14) — Comandos de emergência           │
│  ├── MSG_SAFETY_DATA (0x1B) — Dados críticos de segurança   │
│  ├── MSG_HEARTBEAT (0x10) — Heartbeat de segurança          │
│  └── MSG_ACK (0x13) — Confirmações de eventos               │
│                                                              │
│  CAN ID: Prioridade = SUPER_CRITICAL (0) sempre              │
│  Bitrate: 5 Mbps (dados), 1 Mbps (arbitragem)               │
└─────────────────────────────────────────────────────────────┘
```

## 7.2 Regras do Bus de Segurança

| Regra | Descrição |
|-------|-----------|
| Isolamento | Mensagens de segurança NÃO são retransmitidas para o bus operacional |
| Prioridade fixa | Todos os CAN IDs neste bus possuem prioridade SUPER_CRITICAL |
| Sem descarte | Mensagens de segurança NUNCA são descartadas |
|_ACK obrigatório | Todos os eventos requerem confirmação |
| Heartbeat próprio | Heartbeat de segurança separado do heartbeat operacional |

---

# 8. Eventos e Estado do Sistema

## 8.1 Reação a Eventos por Estado

| Estado do sistema | Eventos permitidos | Ação |
|------------------|-------------------|------|
| INIT | Todos | Eventos de inicialização |
| READY | Todos | Comunicação normal |
| ARMED | Todos | Comunicação normal |
| FLYING | Todos | Comunicação normal, prioridade para sensor/actuator |
| FAILSAFE | Todos, com prioridade SUPER_CRITICAL para DEBUG | Diagnóstico intensificado |
| EMERGENCY | Apenas seguridad | Comunicação mínima, foco em emergência |
| DISARMED | Todos | Transição para estado seguro |
| OFF | Nenhum | Sem comunicação |

## 8.2 Geração de Eventos

```text
┌─────────────────────────────────────────────────────────────┐
│  GERAÇÃO DE EVENTOS                                          │
│                                                              │
│  ┌───────────────────┐    ┌───────────────────┐             │
│  │  Módulo de Sensor  │    │  Módulo de Atuador │             │
│  │  (ESP32-S)         │    │  (ESP32-A)         │             │
│  └────────┬──────────┘    └────────┬──────────┘             │
│           │                         │                         │
│           ▼                         ▼                         │
│  ┌─────────────────────────────────────────────────────┐     │
│  │              GESTOR DE EVENTOS                        │     │
│  │                                                       │     │
│  │  1. Detetar ocorrência                               │     │
│  │  2. Classificar (tipo + gravidade)                   │     │
│  │  3. Construir TLV (MSG_ID + campos)                  │     │
│  │  4. Definir prioridade (fixa ou dinâmica)            │     │
│  │  5. Enfileirar para transmissão                      │     │
│  │  6. Registar para rastreabilidade                    │     │
│  └─────────────────────────────────────────────────────┘     │
│           │                                                 │
│           ▼                                                 │
│  ┌───────────────────┐                                     │
│  │  Gestor de Mensagens│ ← Transmissão imediata            │
│  │  (COM-003)         │                                     │
│  └───────────────────┘                                     │
└─────────────────────────────────────────────────────────────┘
```

---

# 9. Registo e Rastreabilidade

## 9.1 Estrutura de Registo

Cada evento é registado com os seguintes campos:

| Campo | Tamanho | Descrição |
|-------|---------|-----------|
| `event_timestamp` | 4 bytes | Timestamp do evento (monotonic clock) |
| `event_id` | 2 bytes | Identificador único do evento |
| `event_type` | 1 byte | Tipo (safety, sensor, actuator, system, comm) |
| `event_severity` | 1 byte | Gravidade (INFO, WARNING, ERROR, CRITICAL) |
| `event_source` | 1 byte | Grupo de origem |
| `event_msg_id` | 1 byte | MSG_ID da mensagem TLV associada |
| `event_can_id` | 4 bytes | CAN ID utilizado |
| `event_action` | 1 byte | Ação tomada (ACK, retry, descarte, etc.) |
| `event_result` | 1 byte | Resultado (sucesso, falha, timeout) |

## 9.2 Ciclo de Vida do Evento

```text
┌─────────────────────────────────────────────────────────────┐
│  CICLO DE VIDA DO EVENTO                                     │
│                                                              │
│  1. OCORRÊNCIA                                              │
│     └─→ Evento detetado no módulo                           │
│                                                              │
│  2. GERAÇÃO                                                 │
│     └─→ Mensagem TLV construída                             │
│                                                              │
│  3. TRANSMISSÃO                                             │
│     └─→ Enfileirada no Gestor de Mensagens                  │
│                                                              │
│  4. RECEÇÃO                                                 │
│     └─→ Validada e processada no destinatário                │
│                                                              │
│  5. CONFIRMAÇÃO                                             │
│     └─→ ACK enviado (se aplicável)                          │
│                                                              │
│  6. REGISTO                                                 │
│     └─→ Evento registado em log                             │
│                                                              │
│  7. RASTREABILIDADE                                         │
│     └─→ Evento consultável para diagnóstico                 │
└─────────────────────────────────────────────────────────────┘
```

## 9.3 Log de Eventos

| Campo | Descrição |
|-------|-----------|
| `log_entries[64]` | Buffer circular de 64 entradas |
| `log_index` | Índice atual (wrap-around) |
| `log_overflow` | Contador de entradas perdidas por overflow |

---

# 10. Timeout de Eventos

## 10.1 Configuração

| Tipo de evento | Timeout de ACK | Máximo de reenvios | Ação após timeout |
|---------------|---------------|--------------------|--------------------|
| SUPER_CRITICAL | 50ms | 5 | Notificação de segurança |
| CRITICAL | 100ms | 3 | Retry + log |
| HIGH | 500ms | 1 | Log |
| MEDIUM | 1000ms | 0 | Descarte |
| LOW | 2000ms | 0 | Descarte |
| SUPER_LOW | — | 0 | Descarte |

## 10.2 Diagrama de Timeout

```text
Evento enviado
     │
     ▼
┌──────────┐
│ Aguardar │
│ ACK      │
└────┬─────┘
     │
     ├──(ACK recebido)──→ Evento completo, registar sucesso
     │
     ├──(timeout)──→ Incrementar contador de reenvio
     │                    │
     │                    ├──(reenvios < máximo)──→ Reenviar evento
     │                    │
     │                    └──(reenvios ≥ máximo)──→ Notificar perda
     │                                                de comunicação
     │
     └──(ACK com erro)──→ Registar falha, reavaliar
```

---

# 11. Eventos que Sobrepõem Comunicação Periódica

## 11.1 Regra

Mensagens com prioridade SUPER_CRITICAL ou CRITICAL podem interromper o ciclo de comunicação periódica:

```text
┌─────────────────────────────────────────────────────────────┐
│  CICLO NORMAL DE COMUNICAÇÃO                                 │
│                                                              │
│  [HEARTBEAT] → [TELEMETRY] → [HEARTBEAT] → [TELEMETRY]     │
│                                                              │
│  COM EVENTO CRITICAL:                                        │
│  [HEARTBEAT] → [TELEMETRY] → [EVENTO CRITICAL] → [HEARTBEAT]│
│                                      │                       │
│                          Interrrompe o ciclo normal          │
│                                                              │
│  COM EVENTO SUPER_CRITICAL:                                  │
│  [EVENTO SC] → [HEARTBEAT] → [TELEMETRY] → [HEARTBEAT]     │
│       │                                                     │
│  Interrompe TUDO — inclusivé heartbeat                      │
└─────────────────────────────────────────────────────────────┘
```

## 11.2 Exceções

* o heartbeat de segurança NÃO é interrompido por nenhum evento;
* o bus de segurança é independente do bus operacional;
* eventos SUPER_CRITICAL no bus de segurança têm sempre prioridade absoluta.

---

# 12. API de Eventos

## 12.1 Funções Principais

| Função | Descrição |
|--------|-----------|
| `event_raise(type, severity, data)` | Ativar um evento |
| `event_ack(event_id, status)` | Confirmar receção de evento |
| `event_register_handler(type, callback)` | Registar handler para tipo de evento |
| `event_get_log()` | Obter log de eventos |
| `event_clear_log()` | Limpar log de eventos |
| `event_get_stats()` | Obter estatísticas de eventos |

## 12.2 Callbacks

```cpp
typedef void (*EventHandler)(const Event* event);

// Registo de handlers
event_register_handler(EVT_SAFETY, on_safety_event);
event_register_handler(EVT_SENSOR, on_sensor_event);
event_register_handler(EVT_ACTUATOR, on_actuator_event);
event_register_handler(EVT_SYSTEM, on_system_event);
event_register_handler(EVT_COMM, on_comm_event);
```

---

# 13. Limites do Documento

Este documento não define:

* implementação do Gestor de Mensagens (ver `COM-003`);
* regras de prioridade e filas (ver `COM-004`);
* timeouts e recuperação (ver `COM-006`);
* topologia de comunicação entre domínios (ver `COM-007`);
* mecanismos de segurança e autenticação (ver `COM-010` e `SEC/`);
* gestão de estados do sistema (ver `SYS-006`).

---

# 14. Referências

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
- SEC — Especificações de Segurança
