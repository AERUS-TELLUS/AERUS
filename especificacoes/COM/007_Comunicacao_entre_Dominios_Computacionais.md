# COM-007 — Comunicação entre Domínios Computacionais

| Campo             | Valor                              |
| ----------------- | ---------------------------------- |
| **Código**        | COM-007                            |
| **Título**        | Comunicação entre Domínios Computacionais |
| **Versão**        | 1.0                                |
| **Estado**        | Em Desenvolvimento                 |
| **Autor**         | ShegaPT                            |
| **Classificação** | Especificação de Comunicação       |

---

# 1. Objetivo

O presente documento define a topologia completa de comunicação entre os domínios computacionais do Aerus, especificando quem comunica com quem, em que bus, com que CAN ID e com que MSG_ID.

Estabelece os fluxos de dados por tipo de mensagem, as regras de comunicação direta, a ponte entre buses e as regras de comunicação intra-grupo.

---

# 2. Princípios

* topologia de dois buses (operacional e segurança);
* ESP32-FS como ponte entre os dois buses;
* comunicação direta apenas quando justificada;
* sensor data simultâneo para RaspberryPi e ESP32-FS;
* regras claras de roteamento por tipo de mensagem;
* zero ambiguidade na topologia;
* determinismo — cada fluxo é previsível e testável.

---

# 3. Topologia Geral

## 3.1 Diagrama Completo

```text
┌──────────────────────────────────────────────────────────────────────────┐
│                                                                          │
│                        BUS OPERACIONAL                                   │
│                                                                          │
│  ┌──────────┐  ┌──────────┐  ┌────────────┐  ┌──────────┐             │
│  │ ESP32-S  │  │ ESP32-S  │  │ RaspberryPi│  │ ESP32-A  │             │
│  │  _01     │  │  _02     │  │            │  │          │             │
│  │ ID: 0x11 │  │ ID: 0x12 │  │ ID: 0x01   │  │ ID: 0x21 │             │
│  └────┬─────┘  └────┬─────┘  └─────┬──────┘  └────┬─────┘             │
│       │              │              │              │                     │
│  ─────┴──────────────┴──────────────┴──────────────┴───────────────     │
│                                                                          │
│                              ┌──────────┐                                │
│                              │ ESP32-FS │                                │
│                              │ ID: 0x31 │                                │
│                              └────┬─────┘                                │
│                                   │                                      │
└───────────────────────────────────┼──────────────────────────────────────┘
                                    │
                          ┌─────────┴─────────┐
                          │                   │
                          │   BUS SEGURANÇA   │
                          │                   │
              ┌───────────┴────┐    ┌────────┴────────┐
              │    ESP32-FS    │    │   ESP32-FS_A    │
              │    ID: 0x31    │    │   ID: 0x41      │
              └────────────────┘    └─────────────────┘
                                    │
                                    │ (comunicação local)
                                    ▼
                              ┌───────────┐
                              │ Atuadores │
                              │ Emergência│
                              └───────────┘
```

## 3.2 Atribuição de CAN IDs

| Grupo | Elemento | CAN ID | Bus | Descrição |
|-------|---------|--------|-----|-----------|
| RPi | RaspberryPi_01 | 0x01 | Operacional | Orquestração primária |
| ESP32-S | ESP32-S_01 | 0x11 | Operacional | Sensores primários |
| ESP32-S | ESP32-S_02 | 0x12 | Operacional | Sensores secundários |
| ESP32-A | ESP32-A_01 | 0x21 | Operacional | Atuadores primários |
| ESP32-FS | ESP32-FS_01 | 0x31 | Ambos | Segurança |
| ESP32-FS_A | ESP32-FS_A_01 | 0x41 | Segurança | Emergência |

## 3.3 CAN ID Detalhado (29 bits)

```text
┌────────────────────────────────────────────────────────────────┐
│  CAN ID = (Prioridade << 26) | (Origem << 22) | (Destino << 18) │
│           | (Tipo << 14) | (Reservado << 0)                      │
│                                                                  │
│  Exemplo: ESP32-S_01 → RaspberryPi (telemetria)                 │
│  CAN ID = (2 << 26) | (0x11 << 22) | (0x01 << 18) | (0x02 << 14)│
│         = 0x84440000                                             │
│                                                                  │
│  Exemplo: ESP32-FS → ESP32-FS_A (emergência)                    │
│  CAN ID = (0 << 26) | (0x31 << 22) | (0x41 << 18) | (0x02 << 14)│
│         = 0xC4400000                                             │
└────────────────────────────────────────────────────────────────┘
```

---

# 4. Fluxos de Dados por Tipo de Mensagem

## 4.1 Dados de Sensores (MSG_TELEMETRY)

```text
┌──────────────────────────────────────────────────────────────────┐
│  FLUXO: DADOS DE SENSORES                                         │
│                                                                   │
│  ESP32-S_01 ──┬──► RaspberryPi    (telemetria primária)          │
│               │                                                   │
│               └──► ESP32-FS       (telemetria redundante/segurança)│
│                                                                   │
│  ESP32-S_02 ──┬──► RaspberryPi    (telemetria secundária)        │
│               │                                                   │
│               └──► ESP32-FS       (telemetria redundante/segurança)│
│                                                                   │
│  CAN ID: 0x[2][origem][0x01][0x02]                               │
│  MSG_ID: MSG_TELEMETRY (0x11)                                    │
│  Frequência: 50-200ms (configurável por sensor)                  │
│  Prioridade: HIGH (2)                                            │
│                                                                   │
│  NOTA: Dados de sensores são transmitidos SIMULTANEAMENTE       │
│  para RaspberryPi E ESP32-FS, garantindo redundância.            │
└──────────────────────────────────────────────────────────────────┘
```

## 4.2 Comandos de Voo (MSG_COMMAND)

```text
┌──────────────────────────────────────────────────────────────────┐
│  FLUXO: COMANDOS DE VO                                            │
│                                                                   │
│  RaspberryPi ──────────────────► ESP32-A                          │
│                                                                   │
│  CAN ID: 0x[1][0x01][0x21][0x02]                                │
│  MSG_ID: MSG_COMMAND (0x12)                                      │
│  Frequência: 50-100ms (ciclo de controlo)                        │
│  Prioridade: CRITICAL (1)                                        │
│                                                                   │
│  Conteúdo:                                                       │
│  ├── Setpoints de atitude (roll, pitch, yaw)                     │
│  ├── Comandos de throttling                                      │
│  ├── Modos de voo                                                │
│  └── Configuração de controladores                               │
└──────────────────────────────────────────────────────────────────┘
```

## 4.3 Dados de Segurança (MSG_SAFETY_DATA)

```text
┌──────────────────────────────────────────────────────────────────┐
│  FLUXO: DADOS DE SEGURANÇA                                        │
│                                                                   │
│  Bus Operacional:                                                 │
│  ESP32-S ──► ESP32-FS     (sensores para avaliação de segurança) │
│                                                                   │
│  Bus de Segurança:                                                │
│  ESP32-FS ──► ESP32-FS_A  (decisões de segurança)                │
│                                                                   │
│  CAN ID (operacional): 0x[0][origem][0x31][0x02]                 │
│  CAN ID (segurança):   0x[0][0x31][0x41][0x02]                  │
│  MSG_ID: MSG_SAFETY_DATA (0x1B)                                  │
│  Frequência: 100ms ou sob demanda                                │
│  Prioridade: SUPER_CRITICAL (0)                                  │
│                                                                   │
│  NOTA: ESP32-FS avalia dados de segurança e, se necessário,     │
│  envia comandos de emergência para ESP32-FS_A.                   │
└──────────────────────────────────────────────────────────────────┘
```

## 4.4 Heartbeat (MSG_HEARTBEAT)

```text
┌──────────────────────────────────────────────────────────────────┐
│  FLUXO: HEARTBEAT                                                 │
│                                                                   │
│  Bus Operacional (broadcast):                                     │
│  RaspberryPi ──► Todos         (100ms, 10Hz)                     │
│  ESP32-S_01  ──► Todos         (200ms, 5Hz)                      │
│  ESP32-S_02  ──► Todos         (200ms, 5Hz)                      │
│  ESP32-A     ──► Todos         (200ms, 5Hz)                      │
│  ESP32-FS    ──► Todos         (100ms, 10Hz)                     │
│                                                                   │
│  Bus de Segurança (unicast):                                      │
│  ESP32-FS    ──► ESP32-FS_A   (100ms, 10Hz)                     │
│  ESP32-FS_A  ──► ESP32-FS     (100ms, 10Hz)                     │
│                                                                   │
│  MSG_ID: MSG_HEARTBEAT (0x10)                                    │
│  Prioridade: HIGH (2) / SUPER_CRITICAL (0) no bus seg.          │
└──────────────────────────────────────────────────────────────────┘
```

## 4.5 Estados (MSG_STATE_BROADCAST)

```text
┌──────────────────────────────────────────────────────────────────┐
│  FLUXO: BROADCAST DE ESTADO                                       │
│                                                                   │
│  Cada grupo transmite seu estado para todos:                      │
│                                                                   │
│  RaspberryPi ──► Todos    (estado do orquestrador)               │
│  ESP32-S     ──► Todos    (estado dos sensores)                  │
│  ESP32-A     ──► Todos    (estado dos atuadores)                 │
│  ESP32-FS    ──► Todos    (estado de segurança)                  │
│  ESP32-FS_A  ──► Todos    (estado de emergência)                 │
│                                                                   │
│  CAN ID: 0x[2][origem][0x00][0x02]  (broadcast)                 │
│  MSG_ID: MSG_STATE_BROADCAST (0x19)                              │
│  Frequência: 500ms ou sob demanda                                │
│  Prioridade: HIGH (2)                                            │
└──────────────────────────────────────────────────────────────────┘
```

## 4.6 Confirmação (MSG_ACK)

```text
┌──────────────────────────────────────────────────────────────────┐
│  FLUXO: CONFIRMAÇÃO                                                │
│                                                                   │
│  Resposta direta ao remetente:                                    │
│                                                                   │
│  ESP32-A ──► RaspberryPi   (ACK de comando recebido)             │
│  ESP32-FS_A ──► ESP32-FS   (ACK de emergência recebida)         │
│  RaspberryPi ──► ESP32-S    (ACK de configuração)                │
│                                                                   │
│  CAN ID: resposta ao CAN ID do remetente (bits destino = origem)│
│  MSG_ID: MSG_ACK (0x13)                                          │
│  Prioridade: CRITICAL (1)                                        │
│                                                                   │
│  NOTA: ACK é SEMPRE unicast, nunca broadcast.                    │
└──────────────────────────────────────────────────────────────────┘
```

---

# 5. ESP32-FS como Ponte

## 5.1 Função de Ponte

O ESP32-FS está conectado a ambos os buses e funciona como ponte entre o domínio operacional e o domínio de segurança:

```text
┌──────────────────────────────────────────────────────────────────┐
│  ESP32-FS COMO PONTE                                              │
│                                                                   │
│  Bus Operacional                                                 │
│  ┌──────────────────────────────────────────────────────┐       │
│  │  ESP32-S ←→ RaspberryPi ←→ ESP32-A ←→ ESP32-FS      │       │
│  └──────────────────────┬───────────────────────────────┘       │
│                         │                                         │
│                         ▼                                         │
│              ┌─────────────────────┐                              │
│              │      ESP32-FS       │                              │
│              │                     │                              │
│              │  Avalia dados de    │                              │
│              │  ambos os buses     │                              │
│              │                     │                              │
│              │  Toma decisões de   │                              │
│              │  segurança          │                              │
│              │                     │                              │
│              │  Encaminha apenas   │                              │
│              │  informação de      │                              │
│              │  segurança          │                              │
│              └─────────┬───────────┘                              │
│                        │                                          │
│                        ▼                                          │
│  Bus de Segurança                                                │
│  ┌──────────────────────────────────────────────────────┐       │
│  │  ESP32-FS ←─────────────────────────→ ESP32-FS_A     │       │
│  └──────────────────────────────────────────────────────┘       │
└──────────────────────────────────────────────────────────────────┘
```

## 5.2 Regras de Encaminhamento

| Dados recebidos | Origem | Destino | Encaminha? | Justificação |
|----------------|--------|---------|-----------|-------------|
| Sensores | ESP32-S | ESP32-FS | Não | Dados já recebidos diretamente |
| Comandos | RPi | ESP32-A | Não | Domínio operacional |
| Segurança | ESP32-FS | ESP32-FS_A | Sim | Domínio de segurança |
| Failsafe | ESP32-FS | Todos | Sim | Emergência |
| Heartbeat | Qualquer | Todos | Não | Broadcast nativo |

## 5.3 Isolamento entre Buses

```text
┌──────────────────────────────────────────────────────────────────┐
│  REGRA DE ISOLAMENTO                                              │
│                                                                   │
│  1. Mensagens do bus operacional NUNCA são retransmitidas        │
│     para o bus de segurança (exceto dados de segurança           │
│     que o ESP32-FS processa localmente).                         │
│                                                                   │
│  2. Mensagens do bus de segurança NUNCA são retransmitidas       │
│     para o bus operacional.                                       │
│                                                                   │
│  3. O ESP32-FS processa dados de ambos os buses                 │
│     LOCALMENTE, mas não encaminha entre buses.                   │
│                                                                   │
│  4. A única exceção é quando o ESP32-FS toma uma decisão        │
│     de segurança com base em dados do bus operacional e          │
│     envia comando de emergência para o bus de segurança.         │
└──────────────────────────────────────────────────────────────────┘
```

---

# 6. Comunicação Direta

## 6.1 Quando é Permitida

A comunicação direta (sem passar pelo orquestrador RaspberryPi) é permitida apenas nas seguintes situações:

| Comunicação | Justificação |
|------------|-------------|
| ESP32-S → ESP32-FS | Sensores críticos para avaliação de segurança |
| ESP32-FS → ESP32-FS_A | Comandos de emergência |
| Qualquer → Todos | Heartbeat e broadcast de estado |
| ESP32-A → ESP32-FS | Feedback de atuadores para monitorização |

## 6.2 Regras de Comunicação Direta

```text
┌──────────────────────────────────────────────────────────────────┐
│  REGRAS DE COMUNICAÇÃO DIRETA                                     │
│                                                                   │
│  1. Comunicação direta é PERMITIDA apenas para:                  │
│     ├── Sensores críticos (ESP32-S → ESP32-FS)                   │
│     ├── Emergência (ESP32-FS → ESP32-FS_A)                      │
│     ├── Heartbeat (todos → todos, broadcast)                     │
│     └── Broadcast de estado (todos → todos)                      │
│                                                                   │
│  2. Comunicação direta é PROIBIDA para:                          │
│     ├── Comandos de voo (devem passar pelo RPi)                  │
│     ├── Configuração (devem passar pelo RPi)                     │
│     ├── Dados não-críticos                                       │
│     └── Qualquer comunicação não justificada                     │
│                                                                   │
│  3. Justificação deve ser documentada e aprovada.                │
└──────────────────────────────────────────────────────────────────┘
```

## 6.3 Tabela de Comunicação Direta

| Origem | Destino | Bus | MSG_ID | Justificação |
|--------|---------|-----|--------|-------------|
| ESP32-S | RaspberryPi | Operacional | MSG_TELEMETRY | Dados primários |
| ESP32-S | ESP32-FS | Operacional | MSG_TELEMETRY | Redundância segurança |
| ESP32-S_02 | RaspberryPi | Operacional | MSG_TELEMETRY | Dados secundários |
| ESP32-S_02 | ESP32-FS | Operacional | MSG_TELEMETRY | Redundância segurança |
| RaspberryPi | ESP32-A | Operacional | MSG_COMMAND | Comandos de voo |
| ESP32-FS | ESP32-FS_A | Segurança | MSG_FAILSAFE | Emergência |
| ESP32-FS | ESP32-FS_A | Segurança | MSG_SAFETY_DATA | Dados de segurança |
| Todos | Todos | Operacional | MSG_HEARTBEAT | Heartbeat |
| Todos | Todos | Operacional | MSG_STATE_BROADCAST | Estado |
| ESP32-A | RaspberryPi | Operacional | MSG_ACTUATOR_FB | Feedback |
| ESP32-A | ESP32-FS | Operacional | MSG_ACTUATOR_FB | Monitorização |

---

# 7. Comunicação Intra-Grupo

## 7.1 Definição

Comunicação intra-grupo é a comunicação entre elementos do mesmo grupo computacional (ex: ESP32-S_01 e ESP32-S_02).

## 7.2 Regras

| Regra | Descrição |
|-------|-----------|
| Via CAN | Comunicação intra-grupo utiliza o mesmo bus CAN |
| CAN ID próprio | Cada elemento possui CAN ID único |
| Sem prioridade especial | Intra-grupo não tem prioridade automática |
| Broadcast permitido | Elementos podem fazer broadcast para grupo |

## 7.3 Exemplo: Grupo ESP32-S

```text
┌──────────────────────────────────────────────────────────────────┐
│  COMUNICAÇÃO INTRA-GRUPO: ESP32-S                                 │
│                                                                   │
│  ESP32-S_01 (ID: 0x11) ←→ ESP32-S_02 (ID: 0x12)                │
│                                                                   │
│  Comunicação:                                                    │
│  ├── Sincronização de dados de sensores                          │
│  ├── Cross-check de leituras                                     │
│  ├── Fusão prévia de dados                                       │
│  └── Heartbeat intra-grupo                                       │
│                                                                   │
│  CAN ID: 0x[2][0x11][0x12][0x02] (S_01 → S_02)                 │
│  CAN ID: 0x[2][0x12][0x11][0x02] (S_02 → S_01)                 │
│                                                                   │
│  NOTA: Comunicação intra-grupo é opcional e configurável.        │
└──────────────────────────────────────────────────────────────────┘
```

---

# 8. Matriz de Comunicação Completa

## 8.1 Quem Comunica com Quem

```text
┌──────────┬────────────┬──────────┬───────────┬──────────────┬────────────┐
│          │ RaspberryPi│ ESP32-S  │ ESP32-A   │ ESP32-FS     │ ESP32-FS_A │
│          │ (0x01)     │ (0x11/12)│ (0x21)    │ (0x31)       │ (0x41)     │
├──────────┼────────────┼──────────┼───────────┼──────────────┼────────────┤
│RaspberryPi│     —      │ RX       │ TX        │ RX/TX        │ —          │
│ESP32-S   │ TX         │   —      │ —         │ TX           │ —          │
│ESP32-A   │ RX         │ —        │   —       │ TX           │ —          │
│ESP32-FS  │ RX/TX      │ RX       │ RX/TX     │   —          │ TX (seg)   │
│ESP32-FS_A│ —          │ —        │ —         │ RX (seg)     │   —        │
└──────────┴────────────┴──────────┴───────────┴──────────────┴────────────┘

TX = Transmite para    RX = Recebe de
```

## 8.2 Fluxo Normal de Informação

```text
┌──────────────────────────────────────────────────────────────────┐
│  FLUXO NORMAL DE INFORMAÇÃO                                       │
│                                                                   │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐                   │
│  │ ESP32-S  │───►│RaspberryPi│───►│ ESP32-A  │                   │
│  │ (sensores│    │(orquest.) │    │(atuadores│                   │
│  └────┬─────┘    └─────┬────┘    └──────────┘                   │
│       │                │                                          │
│       │                ▼                                          │
│       │         ┌──────────┐                                     │
│       │         │ ESP32-FS │                                     │
│       │         │(segurança│                                     │
│       └────────►│  +ponte) │                                     │
│                 └─────┬────┘                                     │
│                       │                                          │
│                       ▼                                          │
│                 ┌──────────┐                                     │
│                 │ESP32-FS_A│                                     │
│                 │(emergência)                                     │
│                 └──────────┘                                     │
└──────────────────────────────────────────────────────────────────┘
```

---

# 9. Diagrama de Fluxo por Tipo de Dado

## 9.1 Telemetria

```text
┌──────────────────────────────────────────────────────────────────┐
│  FLUXO: TELEMETRIA                                                │
│                                                                   │
│  1. ESP32-S lê sensores (UART/SPI/I2C)                          │
│  2. ESP32-S serializa TLV (MSG_TELEMETRY)                       │
│  3. ESP32-S transmite via CAN FD                                 │
│  4. Frame CAN FD com CAN ID de HIGH prioridade                   │
│                                                                   │
│  Destinos simultâneos:                                            │
│  ├── RaspberryPi (broadcast, CAN ID destino = 0x00)             │
│  └── ESP32-FS (unicast, CAN ID destino = 0x31)                  │
│                                                                   │
│  5. RaspberryPi processa para controlo de voo                    │
│  6. ESP32-FS processa para avaliação de segurança                │
└──────────────────────────────────────────────────────────────────┘
```

## 9.2 Comandos

```text
┌──────────────────────────────────────────────────────────────────┐
│  FLUXO: COMANDOS                                                  │
│                                                                   │
│  1. RaspberryPi calcula setpoints                                │
│  2. RaspberryPi serializa TLV (MSG_COMMAND)                     │
│  3. RaspberryPi transmite via CAN FD                             │
│  4. Frame CAN FD com CAN ID de CRITICAL prioridade               │
│                                                                   │
│  Destino:                                                        │
│  └── ESP32-A (unicast, CAN ID destino = 0x21)                   │
│                                                                   │
│  5. ESP32-A processa comandos                                    │
│  6. ESP32-A envia MSG_ACK para RaspberryPi                       │
│  7. ESP32-A envia MSG_ACTUATOR_FB para monitorização             │
└──────────────────────────────────────────────────────────────────┘
```

## 9.3 Emergência

```text
┌──────────────────────────────────────────────────────────────────┐
│  FLUXO: EMERGÊNCIA                                                │
│                                                                   │
│  1. ESP32-FS deteta condição de emergência                       │
│  2. ESP32-FS serializa TLV (MSG_FAILSAFE)                       │
│  3. ESP32-FS transmite via bus de segurança                      │
│  4. Frame CAN FD com CAN ID de SUPER_CRITICAL prioridade         │
│                                                                   │
│  Destino:                                                        │
│  └── ESP32-FS_A (unicast, CAN ID destino = 0x41)                │
│                                                                   │
│  5. ESP32-FS_A processa comando de emergência                    │
│  6. ESP32-FS_A ativa atuadores de emergência                     │
│  7. ESP32-FS_A envia MSG_ACK para ESP32-FS                       │
│                                                                   │
│  SIMULTANEAMENTE:                                                │
│  8. ESP32-FS envia MSG_FAILSAFE no bus operacional               │
│  9. Todos os grupos notificados da emergência                    │
└──────────────────────────────────────────────────────────────────┘
```

---

# 10. Regras de Comunicação

## 10.1 Regras Gerais

| # | Regra | Descrição |
|---|-------|-----------|
| R1 | Unicast por omissão | Comunicação ponto-a-ponto |
| R2 | Broadcast explícito | Destino 0x0 = todos os grupos |
| R3 | ACK para CRITICAL+ | Mensagens CRITICAL+ requerem confirmação |
| R4 | Sem retransmissão automática | Retransmissão apenas sob pedido |
| R5 | Filtro por destino | Cada nó aceita apenas mensagens dirigidas |
| R6 | Prioridade fixa | Prioridade determinada pelo MSG_ID |
| R7 | Sem roteamento | Mensagens são entregues diretamente |

## 10.2 Regras de Segurança

| # | Regra | Descrição |
|---|-------|-----------|
| S1 | Bus de segurança isolado | Mensagens de segurança não cruzam buses |
| S2 | ESP32-FS como ponte | Único elemento com acesso a ambos os buses |
| S3 | Prioridade máxima | Mensagens de segurança são SUPER_CRITICAL |
| S4 | Sem descarte | Mensagens de segurança nunca são descartadas |
| S5 | ACK obrigatório | Todos os eventos de segurança requerem ACK |

---

# 11. Configuração

## 11.1 Tabela de Roteamento

```cpp
typedef struct {
    uint8_t group_origin;      // Grupo de origem
    uint8_t group_destination; // Grupo de destino (0x0 = broadcast)
    uint8_t msg_id;            // Tipo de mensagem
    uint8_t priority;          // Prioridade CAN
    uint8_t bus;               // 0=operacional, 1=segurança
    bool requires_ack;         // Se requer confirmação
} RoutingEntry;

static const RoutingEntry ROUTING_TABLE[] = {
    // ESP32-S → RaspberryPi (telemetria)
    {0x11, 0x01, MSG_TELEMETRY,    2, 0, false},
    // ESP32-S → ESP32-FS (telemetria redundante)
    {0x11, 0x31, MSG_TELEMETRY,    2, 0, false},
    // RaspberryPi → ESP32-A (comandos)
    {0x01, 0x21, MSG_COMMAND,      1, 0, true},
    // ESP32-FS → ESP32-FS_A (emergência)
    {0x31, 0x41, MSG_FAILSAFE,     0, 1, true},
    // Todos → Todos (heartbeat, broadcast)
    {0x00, 0x00, MSG_HEARTBEAT,    2, 0, false},
};
```

---

# 12. Limites do Documento

Este documento não define:

* implementação do Gestor de Mensagens (ver `COM-003`);
* regras de prioridade e filas (ver `COM-004`);
* mecanismos de timeout (ver `COM-006`);
* parâmetros elétricos do CAN (ver `COM-008`);
* mecanismos de integridade (ver `COM-010`);
* sincronização temporal (ver `COM-009`);
* detalhes de cada mensagem TLV (ver `COM-002`).

---

# 13. Referências

- COM-001 — Arquitetura de Comunicação
- COM-002 — Protocolo TLV
- COM-003 — Gestor de Mensagens
- COM-004 — Prioridades e Filas
- COM-005 — Eventos
- COM-006 — Timeouts e Recuperação
- COM-008 — CAN Bus
- COM-009 — Sincronização
- COM-010 — Integridade
- SHARED-TLV — Definições do Protocolo TLV
- SHARED-CAN-IDS — Alocação de CAN IDs
- SYS-003 — Arquitetura de Software
- SYS-005 — Fluxo Global de Informação
- HW-002 — Grupos Computacionais
