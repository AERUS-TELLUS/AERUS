# COM-004 — Prioridades e Filas

| Campo             | Valor                              |
| ----------------- | ---------------------------------- |
| **Código**        | COM-004                            |
| **Título**        | Prioridades e Filas                |
| **Versão**        | 1.0                                |
| **Estado**        | Em Desenvolvimento                 |
| **Autor**         | ShegaPT                            |
| **Classificação** | Especificação de Comunicação       |

---

# 1. Objetivo

O presente documento define as regras de prioridade, gestão de filas e políticas de descarte utilizadas pelo Gestor de Mensagens (`COM-003`) para garantir a entrega adequada de mensagens entre Grupos Computacionais do Aerus.

A gestão de prioridades é implementada em duas camadas complementares: o arbiter hardware do CAN ID e a lógica de aplicação do TLV MSG_ID.

---

# 2. Princípios

* dupla camada de prioridade (CAN ID + TLV MSG_ID);
* mensagens críticas nunca são descartadas;
* prevenção de starvation para mensagens de baixa prioridade;
* dinamismo — prioridade pode mudar conforme o contexto do sistema;
* determinismo — regras de descarte são previsíveis e testáveis;
* zero alocações dinâmicas em runtime;
* todas as regras configuráveis via parâmetros estáticos.

---

# 3. Arquitetura de Prioridades

## 3.1 Camada 1: CAN ID (Arbiter Hardware)

Os 3 bits de prioridade do CAN ID (bits 28-26) determinam quem vence a arbitragem quando vários nodos competem pelo bus simultaneamente:

```text
┌─────────────────────────────────────────────────────────────┐
│  CAN ID Extended (29 bits)                                  │
│                                                             │
│  PRIORIDADE │ GRUPO_ORIGEM │ GRUPO_DESTINO │ TIPO_MSG       │
│   (3 bit)   │   (4 bit)    │    (4 bit)    │  (4 bit)       │
│    28-26    │    25-22     │     21-18     │   17-14        │
│                                                             │
│  Bits mais baixos = ID mais baixo = prioridade mais alta    │
└─────────────────────────────────────────────────────────────┘
```

**Regra de arbiter:** Quando dois ou mais nodos iniciam transmissão simultaneamente, o nodo com o CAN ID mais baixo vence e continua a transmitir. Os outros nodos aguardam e tentam novamente.

## 3.2 Camada 2: TLV MSG_ID (Lógica de Aplicação)

O MSG_ID do TLV (1 byte, 0x10-0x1F) determina a prioridade de processamento e as regras de descarte no receptor:

```text
┌─────────────────────────────────────────────────────────────┐
│  TLV Message                                                │
│                                                             │
│  START(0xAA) │ MSG_ID │ COUNT │ FIELDS... │ CRC8            │
│               │         │       │            │              │
│               └────┬────┘       └────────────┘              │
│                    │                                        │
│         Define prioridade          Define conteúdo          │
│         de processamento           da mensagem              │
└─────────────────────────────────────────────────────────────┘
```

---

# 4. Níveis de Prioridade

## 4.1 Definição dos Níveis

| Nível | CAN ID Bits | Designação     | Descrição                                 |
|-------|-------------|----------------|-------------------------------------------|
| 0     | 000         | SUPER_CRITICAL | Máxima prioridade — nunca descartado      |
| 1     | 001         | CRITICAL       | Crítico — sempre transmitido e processado |
| 2     | 010         | HIGH           | Elevada — prioridade no processamento     |
| 3     | 011         | MEDIUM         | Normal — processamento padrão             |
| 4     | 100         | LOW            | Baixa — pode ser atrasado                 |
| 5     | 101         | SUPER_LOW      | Mínima — descartável se necessário        |

## 4.2 Diagrama de Prioridades

```text
SUPER_CRITICAL (0) ─────── Nunca descartado
       │                    │
       │ Processamento      │ Descarte
       │ imediato           │ proibido
       ▼                    ▼
CRITICAL (1) ───────────── Sempre transmitido
       │
       │ Sem timeout
       │ de processamento
       ▼
HIGH (2) ───────────────── Prioridade elevada
       │
       │ Pode ser atrasado
       │ mas não descartado
       ▼                    ▼
MEDIUM (3) ─────────────── Processamento normal
       │
       │ Pode ser descartado
       │ se fila estiver cheia
       ▼
LOW (4) ────────────────── Pode ser atrasado
       │
       │ Starvation prevenida
       │ por counter mínino
       ▼
SUPER_LOW (5) ──────────── Descartável
                           Pode ser eliminado
                           em qualquer momento
```

---

# 5. Mapeamento MSG_ID → Prioridade

## 5.1 Tabela Completa

| MSG_ID | Constante           | Prioridade padrão | Descrição                          |
|--------|---------------------|-------------------|------------------------------------|
| 0x14   | MSG_FAILSAFE        | SUPER_CRITICAL    | Ativação/desativação FailSafe      |
| 0x1B   | MSG_SAFETY_DATA     | SUPER_CRITICAL    | Dados de segurança (ESP32-FS only) |
| 0x12   | MSG_COMMAND         | CRITICAL          | Comandos de controlo               |
| 0x13   | MSG_ACK             | CRITICAL          | Confirmação de receção             |
| 0x10   | MSG_HEARTBEAT       | HIGH              | Heartbeat periódico                |
| 0x11   | MSG_TELEMETRY       | HIGH              | Dados de telemetria                |
| 0x18   | MSG_SI_DATA         | HIGH              | Dados em unidades SI               |
| 0x19   | MSG_STATE_BROADCAST | HIGH              | Broadcast de estado                |
| 0x1A   | MSG_ACTUATOR_FB     | HIGH              | Feedback de atuadores              |
| 0x16   | MSG_VIDEO           | MEDIUM            | Dados de vídeo                     |
| 0x17   | MSG_SHELL_CMD       | LOW               | Comando shell remoto               |
| 0x1C   | MSG_SYNC_REQ        | HIGH              | Pedido de sincronização            |
| 0x1D   | MSG_SYNC_RESP       | HIGH              | Resposta de sincronização          |
| 0x1E   | MSG_CONFIG          | MEDIUM            | Dados de configuração              |
| 0x15   | MSG_DEBUG           | SUPER_LOW         | Debug (prioridade dinâmica)        |
| 0x1F   | MSG_RESERVED        | MEDIUM            | Reservado                          |

## 5.2 Prioridade Dinâmica

A prioridade de MSG_DEBUG pode ser alterada dinamicamente conforme o estado do sistema:

```text
┌─────────────────────────────────────────────────────────────┐
│  PRIORIDADE DINÂMICA DE MSG_DEBUG                           │
│                                                             │
│  Estado NORMAL:       MSG_DEBUG → SUPER_LOW (5)             │
│  Estado Failsafe:     MSG_DEBUG → SUPER_CRITICAL (0)        │
│  Estado DEGRADADO:    MSG_DEBUG → HIGH (2)                  │
│                                                             │
│  Justificação: em failsafe, informação de debug é crítica   │
│  para diagnóstico e recuperação.                            │
└─────────────────────────────────────────────────────────────┘
```

---

# 6. Filas de Transmissão

## 6.1 Estrutura de Filas

Cada nó CAN possui um conjunto de filas de transmissão, uma por nível de prioridade:

```text
┌─────────────────────────────────────────────────────────────┐
│  FILAS DE TRANSMISSÃO (por nó)                              │
│                                                             │
│  ┌─────────────────────────────────────┐                    │
│  │  FILA 0: SUPER_CRITICAL             │  ← Processamento   │
│  │  [MSG_FAILSAFE][MSG_SAFETY_DATA]    │    imediato        │
│  └─────────────────────────────────────┘                    │
│  ┌─────────────────────────────────────┐                    │
│  │  FILA 1: CRITICAL                   │  ← Sem timeout     │
│  │  [MSG_COMMAND][MSG_ACK]             │    de espera       │
│  └─────────────────────────────────────┘                    │
│  ┌─────────────────────────────────────┐                    │
│  │  FILA 2: HIGH                       │  ← Processamento   │
│  │  [MSG_TELEMETRY][MSG_HEARTBEAT]     │    prioritário     │
│  └─────────────────────────────────────┘                    │
│  ┌─────────────────────────────────────┐                    │
│  │  FILA 3: MEDIUM                     │  ← Processamento   │
│  │  [MSG_VIDEO][MSG_ACK]               │    normal          │
│  └─────────────────────────────────────┘                    │
│  ┌─────────────────────────────────────┐                    │
│  │  FILA 4: LOW                        │  ← Pode atrasar    │
│  │  [MSG_SHELL_CMD]                    │                    │
│  └─────────────────────────────────────┘                    │
│  ┌─────────────────────────────────────┐                    │
│  │  FILA 5: SUPER_LOW                  │  ← Descartável     │
│  │  [MSG_DEBUG]                        │                    │
│  └─────────────────────────────────────┘                    │
│                                                             │
│  Transmissão: FILA 0 primeiro → FILA 5 último               │
└─────────────────────────────────────────────────────────────┘
```

## 6.2 Regras de Transmissão

| Regra            | Descrição                                           |
|------------------|-----------------------------------------------------|
| Preempção        | FILA 0 preempção todas as outras                    |
| Round-robin      | Filas 2-5 usam round-robin para prevenir starvation |
| FIFO intra-fila  | Mensagens dentro da mesma fila são FIFO             |
| Máximo por ciclo | Máximo de N mensagens de cada fila por ciclo        |

## 6.3 Capacidade das Filas

| Parâmetro       | Valor | Descrição                   |
|-----------------|-------|-----------------------------|
| `QUEUE_SIZE_SC` | 8     | Tamanho fila SUPER_CRITICAL |
| `QUEUE_SIZE_CR` | 16    | Tamanho fila CRITICAL       |
| `QUEUE_SIZE_HI` | 32    | Tamanho fila HIGH           |
| `QUEUE_SIZE_ME` | 32    | Tamanho fila MEDIUM         |
| `QUEUE_SIZE_LO` | 16    | Tamanho fila LOW            |
| `QUEUE_SIZE_SL` | 8     | Tamanho fila SUPER_LOW      |

---

# 7. Filas de Receção

## 7.1 Estrutura

As filas de receção espelham a estrutura de transmissão:

```text
┌─────────────────────────────────────────────────────────────┐
│  FILAS DE RECEÇÃO (por nó)                                  │
│                                                             │
│  ┌─────────────────────────────────────┐                    │
│  │  FILA RX 0: SUPER_CRITICAL          │  → Processamento   │
│  │  [MSG_FAILSAFE][MSG_SAFETY_DATA]    │    imediato        │
│  └─────────────────────────────────────┘                    │
│  ┌─────────────────────────────────────┐                    │
│  │  FILA RX 1: CRITICAL                │  → Sem timeout     │
│  │  [MSG_COMMAND][MSG_ACK]             │    de espera       │
│  └─────────────────────────────────────┘                    │
│  ┌─────────────────────────────────────┐                    │
│  │  FILA RX 2: HIGH                    │  → Processamento   │
│  │  [MSG_TELEMETRY][MSG_HEARTBEAT]     │    prioritário     │
│  └─────────────────────────────────────┘                    │
│  ┌─────────────────────────────────────┐                    │
│  │  FILA RX 3: MEDIUM                  │  → Processamento   │
│  │  [MSG_VIDEO][MSG_SYNC]              │    normal          │
│  └─────────────────────────────────────┘                    │
│  ┌─────────────────────────────────────┐                    │
│  │  FILA RX 4: LOW                     │  → Pode atrasar    │
│  │  [MSG_SHELL_CMD]                    │                    │
│  └─────────────────────────────────────┘                    │
│  ┌─────────────────────────────────────┐                    │
│  │  FILA RX 5: SUPER_LOW               │  → Descartável     │
│  │  [MSG_DEBUG]                        │                    │
│  └─────────────────────────────────────┘                    │
│                                                             │
│  Processamento: RX 0 primeiro → RX 5 último                 │
└─────────────────────────────────────────────────────────────┘
```

## 7.2 Regras de Processamento

| Prioridade     | Política de processamento                           |
|----------------|-----------------------------------------------------|
| SUPER_CRITICAL | Processamento imediato, interrompe ciclo atual      |
| CRITICAL       | Processamento no próximo ciclo, sem atraso          |
| HIGH           | Processamento antes de MEDIUM e LOW                 |
| MEDIUM         | Processamento no ciclo normal                       |
| LOW            | Processamento quando houver espaço                  |
| SUPER_LOW      | Processamento apenas se não houver outros pendentes |

---

# 8. Regras de Descarte

## 8.1 Critérios de Descarte

As regras de descarte variam conforme a prioridade da mensagem:

| Prioridade     | Critério de descarte     | Ação                                                      |
|----------------|--------------------------|-----------------------------------------------------------|
| SUPER_CRITICAL | **Nunca descartado**     | Mensagem permanece na fila até ser processada             |
| CRITICAL       | **Nunca descartado**     | Mensagem permanece na fila até ser processada             |
| HIGH           | Fila cheia               | Descarte da mensagem mais antiga da fila HIGH             |
| MEDIUM         | Fila cheia               | Descarte da mensagem mais antiga da fila MEDIUM           |
| LOW            | Fila cheia               | Descarte da mensagem mais antiga da fila LOW              |
| SUPER_LOW      | Fila cheia **ou** sempre | Descarte imediato se fila cheia ou se SUPER_HIGH pendente |

## 8.2 Diagrama de Decisão de Descarte

```text
Mensagem recebida para FILA de prioridade P
        │
        ▼
┌───────────────┐
│ P = SUPER_    │──sim──→ NUNCA descartar
│ CRITICAL?     │         Adicionar à fila
└───────┬───────┘
        │não
        ▼
┌───────────────┐
│ P = CRITICAL? │──sim──→ NUNCA descartar
│               │         Adicionar à fila
└───────┬───────┘
        │não
        ▼
┌───────────────┐
│ Fila está     │──sim──→ Descartar mensagem mais antiga
│ cheia?        │         Adicionar nova mensagem
└───────┬───────┘
        │não
        ▼
┌───────────────┐
│ P = SUPER_    │──sim──→ Verificar se há mensagens
│ LOW?          │         SUPER_HIGH pendentes
└───────┬───────┘
        │não
        ▼
Adicionar à fila normalmente
```

## 8.3 Contadores de Descarte

Cada nó mantém contadores independentes:

| Contador       | Descrição                                            |
|----------------|------------------------------------------------------|
| `discarded_sc` | Mensagens SUPER_CRITICAL descartadas (deveria ser 0) |
| `discarded_cr` | Mensagens CRITICAL descartadas (deveria ser 0)       |
| `discarded_hi` | Mensagens HIGH descartadas                           |
| `discarded_me` | Mensagens MEDIUM descartadas                         |
| `discarded_lo` | Mensagens LOW descartadas                            |
| `discarded_sl` | Mensagens SUPER_LOW descartadas                      |

**Invariantes de segurança:**
* `discarded_sc` deve ser sempre 0;
* `discarded_cr` deve ser sempre 0;
* Qualquer valor não-zero em `discarded_sc` ou `discarded_cr` gera alerta de segurança.

---

# 9. Prevenção de Starvation

## 9.1 Problema

Mensagens de baixa prioridade (LOW, SUPER_LOW) poderiam nunca ser processadas se houver sempre mensagens de prioridade superior pendentes.

## 9.2 Mecanismo de Prevenção

```text
┌─────────────────────────────────────────────────────────────┐
│  MECANISMO DE PREVENÇÃO DE STARVATION                       │
│                                                             │
│  Contador por fila: starvation_counter[P]                   │
│                                                             │
│  Regra: se starvation_counter[P] > THRESHOLD,               │
│         fila P ganha prioridade temporária de HIGH          │
│                                                             │
│  THRESHOLD por prioridade:                                  │
│    LOW:      100 ciclos sem processamento                   │
│    SUPER_LOW: 200 ciclos sem processamento                  │
│                                                             │
│  Após processamento: starvation_counter[P] = 0              │
│                                                             │
│  Resultado: LOW é garantido ser processado a cada           │
│             100 ciclos no máximo; SUPER_LOW a cada 200      │
└─────────────────────────────────────────────────────────────┘
```

## 9.3 Parâmetros de Starvation

| Parâmetro                 | Prioridade | Valor | Descrição                                         |
|---------------------------|------------|-------|---------------------------------------------------|
| `STARVATION_THRESHOLD_LO` | LOW        | 100   | Máximo de ciclos sem processamento                |
| `STARVATION_THRESHOLD_SL` | SUPER_LOW  | 200   | Máximo de ciclos sem processamento                |
| `STARVATION_BOOST`        | Variável   | HIGH  | Prioridade temporária quando starvation detectado |

---

# 10. Prioridade Dinâmica por Estado do Sistema

## 10.1 Tabela de Contexto

A prioridade de alguns MSG_ID pode mudar conforme o estado do sistema:

| MSG_ID        | Estado NORMAL      | Estado Failsafe    | Estado DEGRADADO   |
|---------------|--------------------|--------------------|--------------------|
| MSG_DEBUG     | SUPER_LOW (5)      | SUPER_CRITICAL (0) | HIGH (2)           |
| MSG_TELEMETRY | HIGH (2)           | HIGH (2)           | MEDIUM (3)         |
| MSG_VIDEO     | MEDIUM (3)         | LOW (4)            | LOW (4)            |
| MSG_SHELL_CMD | LOW (4)            | SUPER_LOW (5)      | SUPER_LOW (5)      |
| MSG_CONFIG    | MEDIUM (3)         | LOW (4)            | LOW (4)            |
| MSG_FAILSAFE  | SUPER_CRITICAL (0) | SUPER_CRITICAL (0) | SUPER_CRITICAL (0) |

## 10.2 Mecanismo de Alteração

```text
Evento de mudança de estado do sistema
        │
        ▼
┌───────────────┐
│ State Manager │
│ notifica      │
│ mudança       │
└───────┬───────┘
        │
        ▼
┌───────────────┐
│ Gestor de     │
│ Mensagens     │
│ atualiza      │
│ tabela de     │
│ prioridades   │
└───────────────┘
```

A alteração é atómica e afeta todas as mensagens recebidas/ transmitidas a partir desse momento.

---

# 11. Escalonamento de Transmissão

## 11.1 Algoritmo

```text
┌──────────────────────────────────────────────────────────────┐
│  ALGORITMO DE ESCALONAMENTO DE TRANSMISSÃO                   │
│                                                              │
│  1. Verificar FILA 0 (SUPER_CRITICAL)                        │
│     └─→ Se não vazia: transmitir IMEDIATAMENTE               │
│                                                              │
│  2. Verificar FILA 1 (CRITICAL)                              │
│     └─→ Se não vazia: transmitir ANTES de outras             │
│                                                              │
│  3. Para FILAS 2-5 (HIGH → SUPER_LOW):                       │
│     └─→ Aplicar round-robin com starvation boost             │
│                                                              │
│  4. Em cada ciclo de transmissão:                            │
│     └─→ Máximo MAX_PER_CYCLE mensagens por fila              │
│                                                              │
│  5. Registra último ciclo de processamento por fila          │
│     └─→ Para cálculo de starvation                           │
└──────────────────────────────────────────────────────────────┘
```

## 11.2 Limites por Ciclo

| Fila   | Máximo por ciclo | Descrição                         |
|--------|------------------|-----------------------------------|
| FILA 0 | Ilimitado        | SUPER_CRITICAL sempre transmitido |
| FILA 1 | 4                | CRITICAL: máximo 4 por ciclo      |
| FILA 2 | 8                | HIGH: máximo 8 por ciclo          |
| FILA 3 | 4                | MEDIUM: máximo 4 por ciclo        |
| FILA 4 | 2                | LOW: máximo 2 por ciclo           |
| FILA 5 | 1                | SUPER_LOW: máximo 1 por ciclo     |

---

# 12. Exemplo: Fluxo Completo

```text
┌──────────────────────────────────────────────────────────────┐
│  EXEMPLO: RECEÇÃO E PROCESSAMENTO                            │
│                                                              │
│  1. Frame CAN FD recebido                                    │
│     CAN ID: Prioridade=2, Origem=0x12(ESP32-S),              │
│             Destino=0x01(RaspberryPi), Tipo=0x02             │
│                                                              │
│  2. Decodificação do CAN ID                                  │
│     → Prioridade CAN = HIGH (2)                              │
│                                                              │
│  3. Parser TLV                                               │
│     → MSG_ID = 0x11 (MSG_TELEMETRY)                          │
│     → Prioridade TLV = HIGH (2)                              │
│                                                              │
│  4. Prioridade efetiva = MAX(CAN, TLV) = HIGH (2)            │
│                                                              │
│  5. Enfileiramento na FILA RX 2 (HIGH)                       │
│                                                              │
│  6. Processamento (quando chegar a vez)                      │
│     → Handler de MSG_TELEMETRY invocado                      │
│     → Dados processados pelo módulo de aplicação             │
│                                                              │
│  7. Resposta (se necessário)                                 │
│     → MSG_ACK com prioridade CRITICAL (1)                    │
│     → Enfileirado na FILA TX 1                               │
│     → Transmissão no próximo ciclo                           │
└──────────────────────────────────────────────────────────────┘
```

---

# 13. Configuração

## 13.1 Parâmetros Estáticos

Todos os parâmetros são configuráveis em tempo de compilação:

```cpp
// Prioridades
static const uint8_t PRIORITY_MSG_FAILSAFE = 0;  // SUPER_CRITICAL
static const uint8_t PRIORITY_MSG_COMMAND  = 1;  // CRITICAL
static const uint8_t PRIORITY_MSG_TELEMETRY= 2;  // HIGH
static const uint8_t PRIORITY_MSG_DEBUG    = 5;  // SUPER_LOW (normal)
static const uint8_t PRIORITY_MSG_DEBUG_FS = 0;  // SUPER_LOW (failsafe)

// Filas
static const uint8_t QUEUE_SIZE[] = {8, 16, 32, 32, 16, 8};

// Starvation
static const uint16_t STARVATION_THRESHOLD[] = {0, 0, 0, 0, 100, 200};

// Limites por ciclo
static const uint8_t MAX_PER_CYCLE[] = {0xFF, 4, 8, 4, 2, 1};
```

## 13.2 Validação em Tempo de Compilação

```cpp
static_assert(QUEUE_SIZE[0] > 0, "Fila SUPER_CRITICAL deve ter espaço");
static_assert(QUEUE_SIZE[1] > 0, "Fila CRITICAL deve ter espaço");
static_assert(STARVATION_THRESHOLD[4] > 0, "Starvation threshold LOW deve ser > 0");
static_assert(STARVATION_THRESHOLD[5] > 0, "Starvation threshold SL deve ser > 0");
```

---

# 14. Limites do Documento

Este documento não define:

* implementação específica do Gestor de Mensagens (ver `COM-003`);
* topologia completa de comunicação (ver `COM-007`);
* timeouts e mecanismos de recuperação (ver `COM-006`);
* mecanismos de integridade (ver `COM-010`);
* parâmetros elétricos do CAN (ver `COM-008`).

---

# 15. Referências

- COM-001 — Arquitetura de Comunicação
- COM-002 — Protocolo TLV
- COM-003 — Gestor de Mensagens
- COM-005 — Eventos
- COM-006 — Timeouts e Recuperação
- COM-007 — Comunicação entre Domínios Computacionais
- COM-008 — CAN Bus
- COM-010 — Integridade
- SHARED-TLV — Definições do Protocolo TLV
- SHARED-CAN-IDS — Alocação de CAN IDs
- SYS-003 — Arquitetura de Software
- SYS-006 — Gestão de Estados
- SYS-008 — Gestão Temporal
