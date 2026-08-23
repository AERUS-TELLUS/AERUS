# COM-006 — Timeouts e Recuperação

| Campo             | Valor                              |
| ----------------- | ---------------------------------- |
| **Código**        | COM-006                            |
| **Título**        | Timeouts e Recuperação             |
| **Versão**        | 1.0                                |
| **Estado**        | Em Desenvolvimento                 |
| **Autor**         | ShegaPT                            |
| **Classificação** | Especificação de Comunicação       |

---

# 1. Objetivo

O presente documento define os mecanismos de deteção de perda de comunicação, timeout por grupo computacional, processos de recuperação e regras de degradação progressiva do sistema Aerus.

A gestão de timeouts é fundamental para a segurança do voo, permitindo que o sistema detete falhas de comunicação e tome as medidas apropriadas para manter a integridade do voo.

---

# 2. Princípios

* heartbeat periódico por todos os Grupos Computacionais;
* timeout configurável por grupo e por criticidade;
* recuperação progressiva com cooldown entre tentativas;
* born-off recovery (CAN bus-off) com auto-recovery;
* ações proporcionais à gravidade da perda de comunicação;
* determinismo — todos os timeouts são previsíveis;
* zero falsos positivos — timeout só é declarado após confirmação.

---

# 3. Heartbeat

## 3.1 Definição

O heartbeat é uma mensagem periódica MSG_HEARTBEAT (0x10) transmitida por todos os Grupos Computacionais para indicar que estão operacionais e comunicacionalmente ativos.

## 3.2 Formato

```text
┌─────────────────────────────────────────────────────────────┐
│  MSG_HEARTBEAT (0x10)                                        │
│                                                              │
│  TLV Fields:                                                 │
│  ├── FLD_GROUP_ID (1 byte): Identificador do grupo           │
│  ├── FLD_STATE (1 byte): Estado atual do grupo               │
│  ├── FLD_MODE (1 byte): Modo de funcionamento                │
│  ├── FLD_TIMESTAMP (4 bytes): Timestamp monotónico           │
│  ├── FLD_UPTIME (4 bytes): Tempo de atividade (ms)           │
│  └── FLD_HEALTH (1 byte): Indicador de saúde (0-100)        │
└─────────────────────────────────────────────────────────────┘
```

## 3.3 Frequência por Grupo

| Grupo | Frequência | Prioridade CAN | Descrição |
|-------|-----------|----------------|-----------|
| RaspberryPi | 100ms (10 Hz) | HIGH (2) | Orquestração — heartbeat principal |
| ESP32-S | 200ms (5 Hz) | HIGH (2) | Sensores — dados de saúde |
| ESP32-A | 200ms (5 Hz) | HIGH (2) | Atuadores — dados de saúde |
| ESP32-FS | 100ms (10 Hz) | HIGH (2) | Segurança — heartbeat crítico |
| ESP32-FS_A | 100ms (10 Hz) | SUPER_CRITICAL (0) | Emergência — heartbeat supercrítico |

## 3.4 Destino do Heartbeat

```text
┌─────────────────────────────────────────────────────────────┐
│  FLUXO DE HEARTBEAT                                          │
│                                                              │
│  Bus Operacional:                                            │
│  ├── RaspberryPi → Todos (broadcast)                        │
│  ├── ESP32-S → RaspberryPi + ESP32-FS                       │
│  ├── ESP32-A → RaspberryPi + ESP32-FS                       │
│  └── ESP32-FS → Todos (broadcast)                           │
│                                                              │
│  Bus de Segurança:                                           │
│  ├── ESP32-FS → ESP32-FS_A                                  │
│  └── ESP32-FS_A → ESP32-FS                                  │
│                                                              │
│  NOTA: Heartbeat é SEMPRE broadcast para garantir           │
│  que todos os grupos recebam a informação.                   │
└─────────────────────────────────────────────────────────────┘
```

## 3.5 Detecção de Perda

Cada nó monitoriza o heartbeat de todos os outros grupos que necessita:

```text
┌─────────────────────────────────────────────────────────────┐
│  MONITORIZAÇÃO DE HEARTBEAT                                   │
│                                                              │
│  Para cada grupo G monitorizado:                             │
│  ├── received_heartbeat[G] = timestamp da última receção     │
│  ├── expected_interval[G] = frequência esperada de G         │
│  ├── timeout_threshold[G] = expected_interval × multiplier   │
│  └── last_heartbeat[G] = dados do último heartbeat           │
│                                                              │
│  Cálculo de timeout:                                         │
│  current_time - received_heartbeat[G] > timeout_threshold[G] │
│  → TIMEOUT DECLARADO para grupo G                            │
└─────────────────────────────────────────────────────────────┘
```

---

# 4. Timeouts

## 4.1 Configuração por Grupo

| Grupo | Timeout (Normal) | Timeout (Crítico) | Timeout (Emergência) | Descrição |
|-------|-----------------|-------------------|---------------------|-----------|
| RaspberryPi | 500ms | 200ms | 100ms | Orquestração |
| ESP32-S | 1000ms | 500ms | 200ms | Sensores |
| ESP32-A | 1000ms | 500ms | 200ms | Atuadores |
| ESP32-FS | 300ms | 150ms | 50ms | Segurança |
| ESP32-FS_A | 300ms | 150ms | 50ms | Emergência |

## 4.2 Multiplier de Timeout

O multiplier é ajustável conforme o estado do sistema:

```text
┌─────────────────────────────────────────────────────────────┐
│  MULTIPLIER DE TIMEOUT POR ESTADO                             │
│                                                              │
│  Estado NORMAL:      multiplier = 3.0                        │
│  Estado ARMED:       multiplier = 2.5                        │
│  Estado FLYING:      multiplier = 2.0                        │
│  Estado FAILSAFE:    multiplier = 1.5                        │
│  Estado EMERGENCY:   multiplier = 1.0                        │
│                                                              │
│  timeout = base_interval × multiplier                        │
│                                                              │
│  Exemplo ESP32-FS em voo:                                     │
│  timeout = 100ms × 2.0 = 200ms                              │
└─────────────────────────────────────────────────────────────┘
```

## 4.3 Critérios de Declaração de Timeout

Um timeout é declarado quando **todas** as seguintes condições são verdadeiras:

| Critério | Descrição |
|---------|-----------|
| Tempo excedido | Tempo desde última receção > threshold |
| Sem confirmação | Nenhuma mensagem recebida do grupo |
| Heartbeats consecutivos perdidos | ≥ N heartbeats não recebidos |
| Canal operacional | CAN bus operacional ativo |

## 4.4 Diagrama de Timeout

```text
┌─────────────────────────────────────────────────────────────┐
│  DETECÇÃO DE TIMEOUT                                         │
│                                                              │
│  Heartbeat recebido de grupo G                               │
│  → received_heartbeat[G] = current_time                     │
│  → consecutive_missed[G] = 0                                │
│                                                              │
│  Timer de verificação (período = 50ms)                       │
│  → Para cada grupo G monitorizado:                           │
│     │                                                        │
│     ├──(current_time - received[G] > timeout[G])?           │
│     │   │                                                    │
│     │   ├──não──→ Grupo OK                                   │
│     │   │                                                    │
│     │   └──sim──→ Incrementar consecutive_missed[G]          │
│     │                │                                       │
│     │                ├──(consecutive < N)?                   │
│     │                │   └──→ Aguardar próximo ciclo         │
│     │                │                                       │
│     │                └──(consecutive ≥ N)?                   │
│     │                    └──→ TIMEOUT DECLARADO              │
│     │                         → Ação de recuperação         │
└─────────────────────────────────────────────────────────────┘
```

---

# 5. Níveis de Perda de Comunicação

## 5.1 Classificação

| Nível | Critério | Descrição | Ação |
|-------|---------|-----------|------|
| 0 - Normal | Heartbeats OK | Comunicação plena | Operação normal |
| 1 - Degradado | 1-2 heartbeats perdidos | Comunicação intermitente | Alerta + redundância |
| 2 - Perda Parcial | 3-5 heartbeats perdidos | Perda significativa | Degradação + recuperação |
| 3 - Perda Crítica | >5 heartbeats perdidos | Perda severa | Failsafe |
| 4 - Perda Total | Todos os grupos inativos | Falha sistémica | Emergência |

## 5.2 Ações por Nível

```text
┌─────────────────────────────────────────────────────────────┐
│  NÍVEIS DE PERDA E AÇÕES                                     │
│                                                              │
│  NÍVEL 0 (Normal):                                           │
│  └─→ Operação normal, sem ações especiais                    │
│                                                              │
│  NÍVEL 1 (Degradado):                                        │
│  ├── Registo de evento                                       │
│  ├── Alerta de diagnóstico                                   │
│  └── Ativação de redundância (se disponível)                 │
│                                                              │
│  NÍVEL 2 (Perda Parcial):                                    │
│  ├── Registo de evento                                       │
│  ├── Tentativa de recuperação                                │
│  ├── Degradação de funcionalidade                            │
│  └── Notificação ao módulo de segurança                      │
│                                                              │
│  NÍVEL 3 (Perda Crítica):                                    │
│  ├── Registo de evento                                       │
│  ├── Ativação de FAILSAFE                                    │
│  ├── Controlo transferido para ESP32-FS                      │
│  └── Comunicação apenas via bus de segurança                 │
│                                                              │
│  NÍVEL 4 (Perda Total):                                      │
│  ├── Registo de evento                                       │
│  ├── Ativação de EMERGENCY                                   │
│  ├── ESP32-FS_A assume controlo                              │
│  └── Aterrissagem de emergência                              │
└─────────────────────────────────────────────────────────────┘
```

---

# 6. Mecanismos de Recuperação

## 6.1 Retry com Cooldown

Após deteção de timeout, o sistema tenta recuperar a comunicação:

```text
┌─────────────────────────────────────────────────────────────┐
│  RETRY COM COOLDOWN                                          │
│                                                              │
│  1. Timeout detetado                                         │
│     → Iniciar ciclo de recuperação                           │
│                                                              │
│  2. Tentativa de reenvio                                     │
│     → Enviar mensagem de reativação para grupo G             │
│                                                              │
│  3. Aguardar resposta                                        │
│     → timeout_retry = 200ms                                  │
│                                                              │
│  4. Resposta recebida?                                       │
│     ├── sim → Recuperação bem-sucedida                       │
│     │         → Reset de contadores                          │
│     │         → Registo de recuperação                       │
│     │                                                        │
│     └── não → Verificar cooldown                             │
│              │                                               │
│              ├──(cooldown excedido)?                         │
│              │   ├──sim──→ Próxima tentativa                 │
│              │   └──não──→ Aguardar cooldown                 │
│              │                                               │
│              └──(máximo de tentativas excedido)?             │
│                  └──→ Falha definitiva                       │
│                       → Ação de degradação                   │
└─────────────────────────────────────────────────────────────┘
```

## 6.2 Cooldown

O cooldown é o intervalo mínimo entre tentativas de recuperação consecutivas:

| Parâmetro | Valor | Descrição |
|-----------|-------|-----------|
| `COOLDOWN_INITIAL` | 500ms | Cooldown inicial |
| `COOLDOWN_INCREMENT` | 500ms | Incremento por tentativa |
| `COOLDOWN_MAXIMUM` | 5000ms | Cooldown máximo |
| `MAX_RETRY_ATTEMPTS` | 5 | Máximo de tentativas |

```cpp
uint32_t calculate_cooldown(uint8_t attempt) {
    uint32_t cooldown = COOLDOWN_INITIAL + (attempt * COOLDOWN_INCREMENT);
    return (cooldown > COOLDOWN_MAXIMUM) ? COOLDOWN_MAXIMUM : cooldown;
}
```

## 6.3 Retry Progressivo

```text
┌─────────────────────────────────────────────────────────────┐
│  RETRY PROGRESSIVO                                           │
│                                                              │
│  Tentativa 1: cooldown = 500ms                              │
│  Tentativa 2: cooldown = 1000ms                             │
│  Tentativa 3: cooldown = 1500ms                             │
│  Tentativa 4: cooldown = 2000ms                             │
│  Tentativa 5: cooldown = 2500ms                             │
│                                                              │
│  Se todas falharam:                                          │
│  → Declaração de perda definitiva                            │
│  → Ação de degradação                                        │
└─────────────────────────────────────────────────────────────┘
```

---

# 7. Born-off Recovery

## 7.1 Definição

Born-off é o estado em que um nó CAN é desligado do bus devido a erros consecutivos de transmissão/receção.

## 7.2 Transição de Estados

```text
┌─────────────────────────────────────────────────────────────┐
│  ESTADOS CAN ERRORS                                          │
│                                                              │
│  ERROR ACTIVE ──(127 erros)──→ ERROR PASSIVE                 │
│       │                              │                       │
│       │                              │ (255 erros)          │
│       │                              ▼                       │
│       │                        BUS OFF                       │
│       │                              │                       │
│       │                              │ (auto-recovery)       │
│       │                              ▼                       │
│       │                    RECONEXÃO                          │
│       │                              │                       │
│       │                              │ (128 × 11 recessive   │
│       │                              │  bits observados)     │
│       │                              ▼                       │
│       └──────────────────────── ERROR ACTIVE                 │
└─────────────────────────────────────────────────────────────┘
```

## 7.3 Parâmetros de Recuperação

| Parâmetro | Valor | Descrição |
|-----------|-------|-----------|
| `BORN_OFF_WAIT_MS` | 1ms | Tempo mínimo de espera antes de reconexão |
| `BORN_OFF_MAX_ATTEMPTS` | 10 | Máximo de tentativas de reconexão |
| `BORN_OFF_RETRY_INTERVAL_MS` | 100ms | Intervalo entre tentativas |

## 7.4 Processo de Recuperação

```text
┌─────────────────────────────────────────────────────────────┐
│  BORN-OFF RECOVERY                                           │
│                                                              │
│  1. Deteção de Born-off                                     │
│     → Notificação ao módulo de segurança                     │
│     → Registo de evento                                      │
│                                                              │
│  2. Espera inicial                                          │
│     → Aguardar BORN_OFF_WAIT_MS                             │
│                                                              │
│  3. Tentativa de reconexão                                   │
│     → Verificar se CAN bus está livre                        │
│     → 128 × 11 recessive bits detectados                    │
│                                                              │
│  4. Reconexão bem-sucedida?                                 │
│     ├── sim → Estado = ERROR ACTIVE                         │
│     │         → Reset de contadores de erro                  │
│     │         → Registo de recuperação                       │
│     │                                                        │
│     └── não → Incrementar tentativa                          │
│              │                                               │
│              ├──(tentativas < máximo)?                       │
│              │   └──→ Aguardar intervalo, retry              │
│              │                                               │
│              └──(tentativas ≥ máximo)?                       │
│                  └──→ Falha definitiva                       │
│                       → Notificação ao módulo de segurança   │
│                       → Ação de degradação                   │
└─────────────────────────────────────────────────────────────┘
```

---

# 8. Regras por Criticidade

## 8.1 Criticidade do Grupo

| Grupo | Criticidade | Política de Timeout | Política de Recuperação |
|-------|-----------|--------------------|-----------------------|
| ESP32-FS | Super-crítica | Timeout mínimo (50ms emergência) | Retry imediato, sem cooldown |
| ESP32-FS_A | Super-crítica | Timeout mínimo (50ms emergência) | Retry imediato, sem cooldown |
| RaspberryPi | Crítica | Timeout curto (100ms emergência) | Retry com cooldown curto |
| ESP32-S | Alta | Timeout médio (200ms emergência) | Retry com cooldown médio |
| ESP32-A | Alta | Timeout médio (200ms emergência) | Retry com cooldown médio |

## 8.2 Ações por Criticidade

```text
┌─────────────────────────────────────────────────────────────┐
│  AÇÕES POR CRITICIDADE                                       │
│                                                              │
│  SUPER-CRÍTICO (ESP32-FS, ESP32-FS_A):                       │
│  ├── Timeout imediato (sem tolerância)                       │
│  ├── Retry sem cooldown                                      │
│  ├── Máximo 3 tentativas                                     │
│  └── Ação: EMERGENCY imediata                                │
│                                                              │
│  CRÍTICO (RaspberryPi):                                      │
│  ├── Timeout curto                                           │
│  ├── Retry com cooldown curto (500ms)                        │
│  ├── Máximo 5 tentativas                                     │
│  └── Ação: FAILSAFE                                          │
│                                                              │
│  ALTO (ESP32-S, ESP32-A):                                    │
│  ├── Timeout médio                                           │
│  ├── Retry com cooldown médio (1000ms)                       │
│  ├── Máximo 5 tentativas                                     │
│  └── Ação: Degradação + redundância                          │
│                                                              │
│  MÉDIO/BAIXO:                                                │
│  ├── Timeout longo                                           │
│  ├── Retry com cooldown longo (2000ms)                       │
│  ├── Máximo 3 tentativas                                     │
│  └── Ação: Log + continue                                    │
└─────────────────────────────────────────────────────────────┘
```

---

# 9. Degradação Progressiva

## 9.1 Níveis de Degradação

| Nível | Condição | Funcionalidade afetada | Ação |
|-------|---------|----------------------|------|
| 0 | Sem degradação | Nenhuma | Operação normal |
| 1 | Perda de 1 grupo não-crítico | Redução de redundância | Continuar voo |
| 2 | Perda de 2+ grupos não-críticos | Funcionalidade reduzida | Preparar aterrissagem |
| 3 | Perda de 1 grupo crítico | Controlo degradado | Aterrissagem imediata |
| 4 | Perda de grupo super-crítico | Controlo comprometido | EMERGENCY |

## 9.2 Diagrama de Degradação

```text
┌─────────────────────────────────────────────────────────────┐
│  DEGRADAÇÃO PROGRESSIVA                                      │
│                                                              │
│  NÍVEL 0: Todos os grupos comunicam                          │
│  └─→ Operação normal                                         │
│                                                              │
│  NÍVEL 1: Perda de ESP32-S_02                                │
│  └─→ Continuar com ESP32-S_01 (redundância)                  │
│                                                              │
│  NÍVEL 2: Perda de ESP32-S_01 e ESP32-S_02                   │
│  └─→ Perda total de sensores, fallback para GPS              │
│                                                              │
│  NÍVEL 3: Perda de ESP32-A                                   │
│  └─→ Perda de controlo de atuadores, FAILSAFE                │
│                                                              │
│  NÍVEL 4: Perda de ESP32-FS                                  │
│  └─→ Perda de segurança, EMERGENCY                           │
│                                                              │
│  NÍVEL 5: Perda de RaspberryPi                               │
│  └─→ Perda de orquestração, ESP32-FS assume                  │
└─────────────────────────────────────────────────────────────┘
```

---

# 10. Registo e Diagnóstico

## 10.1 Eventos de Timeout

Cada timeout gera um evento registado com:

| Campo | Descrição |
|-------|-----------|
| `timeout_group` | Grupo que perdeu comunicação |
| `timeout_level` | Nível de perda (0-4) |
| `timeout_timestamp` | Timestamp do timeout |
| `timeout_duration` | Duração da perda |
| `timeout_recovery` | Se houve recuperação |
| `timeout_action` | Ação tomada |

## 10.2 Estatísticas

```cpp
struct TimeoutStats {
    uint32_t timeout_count[MAX_GROUPS];      // Total de timeouts por grupo
    uint32_t recovery_count[MAX_GROUPS];     // Total de recuperações por grupo
    uint32_t born_off_count;                 // Total de born-offs
    uint32_t born_off_recovery_count;        // Total de recuperações de born-off
    uint32_t total_downtime_ms[MAX_GROUPS];  // Tempo total sem comunicação
    uint32_t max_downtime_ms[MAX_GROUPS];    // Máximo downtime consecutivo
};
```

---

# 11. Integração com Outros Módulos

## 11.1 Dependências

| Módulo | Relação |
|--------|---------|
| COM-003 (Gestor de Mensagens) | Gere transmissão/receção de heartbeat |
| COM-004 (Prioridades e Filas) | Define prioridade do heartbeat |
| COM-005 (Eventos) | Gera eventos de timeout |
| COM-008 (CAN Bus) | Born-off e recovery do CAN |
| SYS-006 (Gestão de Estados) | Reage a mudanças de estado por timeout |
| SYS-008 (Gestão Temporal) | Fornece timestamps para cálculo de timeout |
| SEC (Segurança) | Recebe notificações de timeout crítico |

## 11.2 Diagrama de Integração

```text
┌─────────────────────────────────────────────────────────────┐
│  INTEGRAÇÃO DO MÓDULO DE TIMEOUT                              │
│                                                              │
│  ┌──────────┐     ┌──────────────┐     ┌──────────────┐    │
│  │  COM-003  │────►│   TIMEOUT    │◄────│  COM-005     │    │
│  │  Gestor   │     │   MODULE     │     │  Eventos     │    │
│  └──────────┘     └──────┬───────┘     └──────────────┘    │
│                           │                                  │
│                           ▼                                  │
│                    ┌──────────────┐                          │
│                    │  SYS-006     │                          │
│                    │  State Mgr   │                          │
│                    └──────┬───────┘                          │
│                           │                                  │
│                           ▼                                  │
│                    ┌──────────────┐                          │
│                    │  SYS-008     │                          │
│                    │  Temporal    │                          │
│                    └──────────────┘                          │
└─────────────────────────────────────────────────────────────┘
```

---

# 12. Limites do Documento

Este documento não define:

* implementação do Gestor de Mensagens (ver `COM-003`);
* regras de prioridade e filas (ver `COM-004`);
* topologia completa de comunicação (ver `COM-007`);
* parâmetros elétricos do CAN (ver `COM-008`);
* mecanismos de integridade (ver `COM-010`);
* gestão de estados do sistema (ver `SYS-006`);
* detalhes de implementação do Born-off (ver `COM-008` §9).

---

# 13. Referências

- COM-001 — Arquitetura de Comunicação
- COM-002 — Protocolo TLV
- COM-003 — Gestor de Mensagens
- COM-004 — Prioridades e Filas
- COM-005 — Eventos
- COM-007 — Comunicação entre Domínios Computacionais
- COM-008 — CAN Bus
- COM-010 — Integridade
- SHARED-TLV — Definições do Protocolo TLV
- SHARED-CAN-IDS — Alocação de CAN IDs
- SYS-006 — Gestão de Estados
- SYS-008 — Gestão Temporal
- SEC — Especificações de Segurança
