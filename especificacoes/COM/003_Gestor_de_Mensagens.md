# COM-003 — Gestor de Mensagens

| Campo             | Valor                              |
| ----------------- | ---------------------------------- |
| **Código**        | COM-003                            |
| **Título**        | Gestor de Mensagens                |
| **Versão**        | 1.0                                |
| **Estado**        | Em Desenvolvimento                 |
| **Autor**         | ShegaPT                            |
| **Classificação** | Especificação de Comunicação       |

---

# 1. Objetivo

O presente documento define o comportamento, estrutura e responsabilidades do Gestor de Mensagens do sistema Aerus, que é o módulo central responsável pela comunicação entre módulos e entre domínios computacionais.

O Gestor de Mensagens constitui a camada de aplicação que integra o protocolo TLV (definido em `COM-002`) com o transporte CAN FD (definido em `COM-008`), garantindo a entrega fiável, ordenada e priorizada de todas as mensagens entre Grupos Computacionais.

---

# 2. Princípios

* ponto único de comunicação inter-grupos em cada elemento;
* receção, validação, encaminhamento e entrega de mensagens TLV;
* gestão de prioridades com base no CAN ID e no TLV MSG_ID;
* fragmentação e reconstituição transparente;
* coexistência com interfaces locais (UART/SPI/I2C) sem conflito;
* determinismo — sem alocações dinâmicas de memória em runtime;
* zero mecanismos de comunicação paralelos fora da arquitetura definida;
* referência a `SYS-003` §13 para integração na arquitetura de software.

---

# 3. Âmbito

Este documento aplica-se a todos os Grupos Computacionais do Aerus:

| Grupo              | Função principal do Gestor |
|-------------------|---------------------------|
| RaspberryPi       | Orquestração — coordena sensores e atuadores |
| ESP32-S           | Aquisição de dados — envia telemetria |
| ESP32-A           | Controlo de atuadores — recebe comandos |
| ESP32-FS          | Segurança — monitoriza e intervém |
| ESP32-FS_A        | Emergência — recebe comandos de emergência |

---

# 4. Arquitetura do Gestor

## 4.1 Diagrama de Blocos

```text
┌─────────────────────────────────────────────────────────────────────┐
│                        GESTOR DE MENSAGENS                          │
│                                                                     │
│  ┌────────────┐   ┌─────────────┐   ┌─────────────┐                 │
│  │  Módulo A   │   │  Módulo B   │   │  Módulo C   │  ← Aplicação   │
│  └─────┬──────┘   └──────┬──────┘   └──────┬──────┘                 │
│        │                  │                  │                      │
│        ▼                  ▼                  ▼                      │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │                   DISPATCHER                                │    │
│  │  - Roteamento por destino (CAN ID)                          │    │
│  │  - Roteamento por tipo (MSG_ID)                             │    │
│  │  - Filas por prioridade                                     │    │
│  └──────────────────────────┬──────────────────────────────────┘    │
│                             │                                       │
│        ┌────────────────────┼────────────────────┐                  │
│        ▼                    ▼                    ▼                  │
│  ┌──────────┐       ┌──────────────┐       ┌──────────┐             │
│  │ TX Queue │       │   VALIDATOR  │       │ RX Queue │             │
│  │ (por     │       │  - CRC8      │       │ (por     │             │
│  │ priorid.)│       │  - Estrutura │       │ priorid.)│             │
│  └────┬─────┘       │  - Limites   │       └────┬─────┘             │
│       │             └──────┬───────┘              │                 │
│       │                    │                      │                 │
│       ▼                    ▼                      ▼                 │
│  ┌──────────┐       ┌──────────────┐       ┌──────────┐             │
│  │   CAN    │       │ FRAGMENTADOR │       │ RECUPO-  │             │
│  │  DRIVER  │◄─────►│ / RECUPOSI-  │◄─────►│ RADOR    │             │
│  │          │       │  TOR         │       │          │             │
│  └──────────┘       └──────────────┘       └──────────┘             │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

## 4.2 Componentes

| Componente        | Responsabilidade                                          |
|-------------------|-----------------------------------------------------------|
| Dispatcher        | Roteamento de mensagens para módulos locais ou para o CAN |
| Validator         | Validação de estrutura, CRC8 e limites das mensagens      |
| TX Queue          | Fila de transmissão organizada por prioridade             |
| RX Queue          | Fila de receção organizada por prioridade                 |
| Fragmentador      | Divisão de mensagens grandes em frames CAN FD             |
| Recuprador        | Reconstrução de mensagens fragmentadas                    |
| CAN Driver        | Interface com o hardware CAN FD                           |

---

# 5. Receção de Mensagens

## 5.1 Fluxo de Receção

```text
Frame CAN FD recebido
        │
        ▼
┌───────────────┐
│ Filtro CAN ID │──(rejeitado)──→ Descarte
│ (hardware)    │
└───────┬───────┘
        │(aceite)
        ▼
┌───────────────┐
│ Extração      │
│ payload TLV   │
└───────┬───────┘
        │
        ▼
┌───────────────┐     ┌─────────────────┐
│ Parser TLV    │────►│ Mensagem TLV    │
│ (FSM, COM-002)│     │ serializada     │
└───────────────┘     └───────┬─────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │ VALIDATOR        │
                    │ 1. START=0xAA?   │──(não)──→ Descarte + Log
                    │ 2. MSG_ID válido?│──(não)──→ Descarte + Log
                    │ 3. tlvCount≤32?  │──(não)──→ Descarte + Log
                    │ 4. CRC8 válido?  │──(não)──→ Descarte + Log
                    │ 5. Tamanho OK?   │──(não)──→ Descarte + Log
                    └───────┬──────────┘
                            │(válido)
                            ▼
                    ┌─────────────────┐
                    │ Decodificação   │
                    │ CAN ID          │
                    │ - prioridade    │
                    │ - origem        │
                    │ - destino       │
                    │ - tipo          │
                    └───────┬─────────┘
                            │
                            ▼
                    ┌─────────────────┐
                    │ Encaminhamento  │
                    │ (Dispatcher)    │
                    └─────────────────┘
```

## 5.2 Validação na Receção

O Validator executa as seguintes verificações em sequência:

| Verificação    | Descrição                                   | Ação em caso de falha          |
|----------------|---------------------------------------------|--------------------------------|
| START byte     | Primeiro byte deve ser 0xAA                 | Descarte imediato              |
| MSG_ID         | Deve estar no intervalo 0x10-0x1F           | Descarte + incremento contador |
| TLV COUNT      | Deve ser ≤ 32                               | Descarte + incremento contador |
| CRC8           | Deve corresponder ao CRC calculado          | Descarte + incremento contador |
| Tamanho        | Mensagem serializada ≤ 1024 bytes           | Descarte + incremento contador |
| CAN ID origem  | Grupo de origem deve ser conhecido          | Descarte + log de segurança    |
| CAN ID destino | Grupo destino deve ser este nó ou broadcast | Descarte silencioso            |

## 5.3 Contadores de Erro

Cada grupo de origem possui contadores independentes:

| Contador                     | Descrição                                 |
|------------------------------|-------------------------------------------|
| `rx_crc_errors[grupo]`       | CRC8 inválido recebido do grupo X         |
| `rx_structure_errors[grupo]` | Estrutura inválida recebida do grupo X    |
| `rx_limit_errors[grupo]`     | Limites excedidos recebidos do grupo X    |
| `rx_total[grupo]`            | Total de mensagens recebidas do grupo X   |
| `rx_discarded[grupo]`        | Total de mensagens descartadas do grupo X |

---

# 6. Transmissão de Mensagens

## 6.1 Fluxo de Transmissão

```text
Módulo de aplicação solicita envio
        │
        ▼
┌───────────────┐
│ TLVBuilder    │
│ Serialização  │
│ (COM-002)     │
└───────┬───────┘
        │
        ▼
┌───────────────┐
│ Validação     │──(inválido)──→ Erro para módulo
│ local         │
└───────┬───────┘
        │(válido)
        ▼
┌───────────────┐
│ Cálculo CRC8  │
│ (SMBUS 0x07)  │
└───────┬───────┘
        │
        ▼
┌───────────────────────┐      ┌────────────────────┐
│ Tamanho ≤ 64 bytes?   │─sim─→│ TX Queue           │
│                       │      │ (classificação por │
└───────────┬───────────┘      │  prioridade)       │
            │não               └────────┬───────────┘
            ▼                          │
    ┌───────────────┐                  ▼
    │ FRAGMENTADOR  │          ┌───────────────┐
    │ (dividir em   │          │ CAN Driver    │
    │  N frames)    │          │ Transmissão   │
    └───────┬───────┘          └───────────────┘
            │
            ▼
    ┌───────────────┐
    │ TX Queue      │
    │ (N fragmentos)│
    └───────┬───────┘
            │
            ▼
    ┌───────────────┐
    │ CAN Driver    │
    │ Transmissão   │
    └───────────────┘
```

## 6.2 Construção do CAN ID

O CAN ID de 29 bits é construído a partir de parâmetros configuráveis:

```text
CAN ID = (Prioridade << 26) | (GrupoOrigem << 22) | (GrupoDestino << 18) | (TipoMsg << 14)
```

| Campo         | Bits   | Fonte                                 |
|---------------|--------|---------------------------------------|
| Prioridade    | 28-26  | Derivada do MSG_ID ou configurada     |
| Grupo Origem  | 25-22  | Configurado por elemento              |
| Grupo Destino | 21-18  | Especificado pelo módulo de aplicação |
| Tipo Mensagem | 17-14  | Classificação do tipo de dado         |
| Reservado     | 13-0   | Zeros                                 |

## 6.3 Encaminhamento

O Dispatcher utiliza a seguinte tabela de roteamento:

| Condição                         | Ação                                        |
|----------------------------------|---------------------------------------------|
| Destino = este nó                | Entrega ao módulo local                     |
| Destino = broadcast (0x0)        | Entrega ao módulo local + retransmite       |
| Destino = outro nó (bus oper.)   | Encaminha para TX Queue do bus operacional  |
| Destino = outro nó (bus seg.)    | Encaminha para TX Queue do bus de segurança |
| Origem = desconhecida            | Descarte + log de segurança                 |

---

# 7. Fragmentação e Reconstituição

## 7.1 Necessidade

O payload máximo de um frame CAN FD é 64 bytes. Mensagens TLV que excedam este limite devem ser fragmentadas.

```text
Espaço efetivo por frame:
  CAN FD payload    = 64 bytes
  Overhead CAN FD   ≈ 8-12 bytes
  Espaço TLV        ≈ 52-56 bytes

Mensagem TLV mínima = START(1) + MSGID(1) + COUNT(1) + CRC8(1) = 4 bytes
Espaço para campos  ≈ 48 bytes mínimo por frame
```

## 7.2 Estrutura de Fragmentação

| Campo           | Tamanho | Descrição                     |
|-----------------|---------|-------------------------------|
| Fragment Index  | 1 byte  | Índice do fragmento (0-based) |
| Fragment Total  | 1 byte  | Número total de fragmentos    |
| TLV Payload     | Variável| Dados TLV neste fragmento     |

## 7.3 Regras de Fragmentação

* o primeiro fragmento contém o cabeçalho TLV completo (START + MSG_ID + COUNT);
* os fragmentos seguintes contêm apenas campos TLV;
* cada fragmento é transmitido como frame CAN FD independente;
* todos os fragmentos do mesmo grupo de mensagens partilham o mesmo CAN ID;
* o receiver reconstrói a mensagem completa antes de processar;
* fragmento perdido → mensagem inteira descartada;
* timeout entre fragmentos = timeout normal de receção.

## 7.4 Reconstituição

```text
Fragmentos recebidos:
  Frag 0/3: [START][MSG_ID][COUNT][FIELD1][FIELD2]
  Frag 1/3: [FIELD3][FIELD4][FIELD5]
  Frag 2/3: [FIELD6][FIELD_N][CRC8]

Reconstituição:
  [START][MSG_ID][COUNT][FIELD1]...[FIELD_N][CRC8]

Validação:
  1. Todos os fragmentos recebidos? (Total = 3, Recebidos = 3)
  2. CRC8 válido?
  3. MSG_ID e COUNT consistentes?
  → Mensagem entregue ao Dispatcher
```

---

# 8. Gestão de Prioridades

## 8.1 Dupla Camada de Prioridade

A prioridade é determinada por dois mecanismos complementares:

```text
┌─────────────────────────────────────────────────────────────┐
│  CAMADA 1: CAN ID (arbiter hardware)                        │
│                                                             │
│  Bits 28-26 do CAN ID determinam quem vence a arbitragem    │
│  ID mais baixo = prioridade mais alta = transmite primeiro  │
└─────────────────────────────────────────────────────────────┘
                            +
┌─────────────────────────────────────────────────────────────┐
│  CAMADA 2: TLV MSG_ID (lógica de aplicação)                 │
│                                                             │
│  MSG_ID determina prioridade de processamento e descarte    │
│  no receptor                                                │
└─────────────────────────────────────────────────────────────┘
```

## 8.2 Mapeamento de Prioridades

| Nível | CAN ID Bits | MSG_ID(s) associados | Comportamento no receptor |
|-------|-------------|----------------------|--------------------------|
| 0 - SUPER_CRITICAL | 0 | MSG_FAILSAFE, MSG_SAFETY_DATA | Nunca descartado, processamento imediato |
| 1 - CRITICAL | 1 | MSG_COMMAND | Sempre processado, sem descarte |
| 2 - HIGH | 2 | MSG_TELEMETRY, MSG_HEARTBEAT, MSG_SI_DATA | Processamento prioritário |
| 3 - MEDIUM | 3 | MSG_VIDEO, MSG_ACK | Processamento normal |
| 4 - LOW | 4 | MSG_SHELL_CMD | Pode ser atrasado |
| 5 - SUPER_LOW | 5 | MSG_DEBUG | Descartável se necessário |

As regras detalhadas encontram-se em `COM-004`.

---

# 9. Coexistência com Interfaces Locais

## 9.1 Separação de Domínios

O Gestor de Mensagens gere exclusivamente a comunicação inter-grupos via CAN. As interfaces locais (UART, SPI, I2C) são geridas pelos módulos de aplicação diretamente:

```text
┌──────────────────────────────────────────────────────────────┐
│                     GESTOR DE MENSAGENS                      │
│                                                              │
│  Comunicação INTER-GRUPOS (CAN FD)                           │
│  ├── ESP32-S  → RaspberryPi (telemetria)                     │
│  ├── ESP32-S  → ESP32-FS (telemetria redundante)             │
│  ├── RaspberryPi → ESP32-A (comandos)                        │
│  ├── ESP32-FS → ESP32-FS_A (emergência, bus segurança)       │
│  └── Todos → Todos (heartbeat, estados)                      │
│                                                              │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│               MÓDULOS DE APLICAÇÃO (independentes)           │
│                                                              │
│  Comunicação LOCAL (UART/SPI/I2C)                            │
│  ├── ESP32-S  ←→ Sensores (UART/SPI/I2C)                     │
│  ├── ESP32-A  ←→ Atuadores (UART/SPI/I2C)                    │
│  ├── ESP32-FS ←→ Sensores supercríticos (UART/SPI/I2C)       │
│  └── ESP32-FS_A ←→ Atuadores emergência (UART/SPI/I2C)       │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

## 9.2 Regra Fundamental

**Nenhum módulo deverá implementar mecanismos próprios de comunicação paralelos à arquitetura definida pelo sistema.**

A comunicação com periféricos locais (sensores via UART/SPI/I2C) é da responsabilidade de cada módulo de aplicação, mas toda a comunicação entre Grupos Computacionais deverá passar exclusivamente pelo Gestor de Mensagens.

## 9.3 Coexistência na Prática

| Interface   | Utilizador | Dados             | Via Gestor?       |
|-------------|------------|-------------------|-------------------|
| UART sensor | ESP32-S    | Leituras brutas   | Não (local)       |
| SPI atuador | ESP32-A    | PWM, configuração | Não (local)       |
| I2C sensor  | ESP32-FS   | Dados críticos    | Não (local)       |
| CAN FD      | Todos      | TLV serializado   | Sim (obrigatório) |

---

# 10. Eventos e Exceções

## 10.1 Tratamento de Eventos

O Gestor de Mensagens processa eventos de forma especial:

| Evento                | Prioridade     | Ação                                               |
|-----------------------|----------------|----------------------------------------------------|
| MSG_FAILSAFE recebido | SUPER_CRITICAL | Processamento imediato, notificação de segurança   |
| Perda de heartbeat    | Variável       | Ativação de timeout (ver `COM-006`)                |
| Erro CRC frequente    | Média          | Registo, notificação de diagnóstico                |
| Born-off CAN          | Crítica        | Notificação de segurança, tentativa de recuperação |
| Fragmento perdido     | Baixa          | Descarte da mensagem, registo                      |

## 10.2 Registo e Rastreabilidade

Cada evento é registado com:

* timestamp (monotonic clock);
* CAN ID da mensagem;
* MSG_ID do TLV;
* grupo de origem;
* código de erro (se aplicável);
* ação tomada.

---

# 11. API do Gestor

## 11.1 Funções Principais

| Função                                  | Descrição                         |
|-----------------------------------------|-----------------------------------|
| `gm_init()`                             | Inicialização do gestor e filas   |
| `gm_send(msg, destino, prioridade)`     | Enviar mensagem TLV para destino  |
| `gm_broadcast(msg, prioridade)`         | Enviar mensagem TLV para todos    |
| `gm_register_handler(msg_id, callback)` | Registar handler para MSG_ID      |
| `gm_get_stats()`                        | Obter estatísticas de comunicação |
| `gm_reset()`                            | Reiniciar gestor e limpar filas   |

## 11.2 Callbacks

```cpp
typedef void (*GM_Handler)(const TLVMessage* msg, const CANID* can_id);

// Registo de handlers
gm_register_handler(MSG_TELEMETRY, on_telemetry_received);
gm_register_handler(MSG_COMMAND, on_command_received);
gm_register_handler(MSG_FAILSAFE, on_failsafe_received);
gm_register_handler(MSG_HEARTBEAT, on_heartbeat_received);
gm_register_handler(MSG_STATE_BROADCAST, on_state_received);
```

## 11.3 Limites Configuráveis

| Parâmetro                | Valor padrão | Descrição                                |
|--------------------------|--------------|------------------------------------------|
| `GM_MAX_QUEUES`          | 6            | Número de filas (uma por prioridade)     |
| `GM_MAX_QUEUE_SIZE`      | 32           | Tamanho máximo de cada fila              |
| `GM_MAX_HANDLERS`        | 16           | Número máximo de handlers registados     |
| `GM_FRAGMENT_TIMEOUT_MS` | 100          | Timeout entre fragmentos                 |
| `GM_MAX_FRAGMENTS`       | 8            | Número máximo de fragmentos por mensagem |
| `GM_RX_BUFFER_SIZE`      | 2048         | Tamanho do buffer de receção             |

---

# 12. Integração com Outros Módulos

## 12.1 Módulos Dependentes

| Módulo                     | Dependência | Descrição                               |
|----------------------------|-------------|-----------------------------------------|
| Security (SEC/)            | HMAC, SEQ   | Autenticação e anti-replay              |
| State Manager (SYS-006)    | Estados     | Reação a mudanças de estado             |
| Temporal Manager (SYS-008) | Timeouts    | Gestão de timeouts por grupo            |
| Safety Module (SEC/)       | Failsafe    | Processamento de mensagens de segurança |

## 12.2 Referências

| Documento | Secção | Relação                                        |
|-----------|--------|------------------------------------------------|
| SYS-003   | §13    | Definição do gestor na arquitetura de software |
| COM-002   | §13    | Parser TLV utilizado pelo gestor               |
| COM-004   | —      | Regras de prioridade e filas                   |
| COM-006   | —      | Timeouts e recuperação                         |
| COM-008   | §14    | Fragmentação CAN FD                            |
| COM-010   | —      | Validação de integridade                       |

---

# 13. Segurança

## 13.1 Validação Multi-Camada

O Gestor de Mensagens implementa validação em duas camadas:

| Camada      | Mecanismo             | Proteção                         |
|-------------|-----------------------|----------------------------------|
| CAN FD      | CRC nativo 17-bit     | Erros de transmissão física      |
| Aplicação   | CRC8 TLV (SMBUS 0x07) | Corrupção na camada de aplicação |
| Segurança   | HMAC (32 bytes)       | Mensagens falsificadas           |
| Anti-replay | SEQ (4 bytes)         | Reenvio de mensagens capturadas  |

## 13.2 Validação no Receiver

```text
┌──────────────────────────────────────────────────────┐
│ SEQUÊNCIA DE VALIDAÇÃO NO RECEIVER                   │
│                                                      │
│ 1. CAN CRC nativo ──(falha)──→ Descarte + incremento │
│          │                                           │
│          ▼ (sucesso)                                 │
│ 2. Filtro CAN ID ──(rejeitado)──→ Descarte           │
│          │                                           │
│          ▼ (aceite)                                  │
│ 3. Parser TLV ──(erro)──→ Descarte + reset parser    │
│          │                                           │
│          ▼ (sucesso)                                 │
│ 4. CRC8 TLV ──(falha)──→ Descarte + incremento       │
│          │                                           │
│          ▼ (sucesso)                                 │
│ 5. HMAC (se presente) ──(falha)──→ Descarte + alerta │
│          │                                           │
│          ▼ (sucesso)                                 │
│ 6. SEQ (se presente) ──(replay)──→ Descarte + alerta │
│          │                                           │
│          ▼ (sucesso)                                 │
│ 7. ENTREGA AO MÓDULO DE APLICAÇÃO                    │
└──────────────────────────────────────────────────────┘
```

---

# 14. Limites do Documento

Este documento não define detalhadamente:

* regras completas de prioridade e descarte (ver `COM-004`);
* regras completas de timeout e recuperação (ver `COM-006`);
* topologia completa de comunicação entre domínios (ver `COM-007`);
* implementação específica do CAN driver (ver `COM-008`);
* algoritmos de segurança e autenticação (ver `SEC/`);
* implementação específica do parser TLV (ver `COM-002`).

---

# 15. Referências

- COM-001 — Arquitetura de Comunicação
- COM-002 — Protocolo TLV
- COM-004 — Prioridades e Filas
- COM-005 — Eventos
- COM-006 — Timeouts e Recuperação
- COM-008 — CAN Bus
- COM-010 — Integridade
- SHARED-TLV — Definições do Protocolo TLV
- SHARED-CAN-IDS — Alocação de CAN IDs
- SYS-003 — Arquitetura de Software (§13)
- SYS-005 — Fluxo Global de Informação
- SYS-008 — Gestão Temporal
- HW-006 — Interfaces de Comunicação
- SEC — Especificações de Segurança
