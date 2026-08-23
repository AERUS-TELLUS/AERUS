# COM-001 — Arquitetura de Comunicação

| Campo             | Valor                              |
| ----------------- | ---------------------------------- |
| **Código**        | COM-001                            |
| **Título**        | Arquitetura de Comunicação         |
| **Versão**        | 1.0                                |
| **Estado**        | Em Desenvolvimento                 |
| **Autor**         | ShegaPT                            |
| **Classificação** | Especificação de Comunicação       |

---

# 1. Objetivo

O presente documento define a arquitetura geral de comunicação do sistema Aerus, estabelecendo as camadas, princípios, meios de transporte e protocolos utilizados para a troca de informação entre os diferentes Grupos Computacionais.

A arquitetura de comunicação do Aerus é composta por três camadas independentes e complementares, cada uma com uma responsabilidade específica. A separação entre camadas permite alterar o meio de transporte sem afetar o protocolo de mensagens, e vice-versa.

---

# 2. Princípios

A arquitetura de comunicação do Aerus baseia-se nos seguintes princípios:

* separação em camadas (física, transporte, aplicação);
* independência do meio de transporte;
* protocolo de mensagens autónomo e completo (TLV);
* segurança por diseño (CRC, HMAC, anti-replay);
* determinismo (sem alocações dinâmicas);
* extensibilidade (novos IDs sem alterar a estrutura);
* separação entre comunicação inter-grupos e comunicação local com periféricos;
* dois buses independentes (operacional e segurança);
* escalabilidade (adicionar grupos sem alterar o protocolo).

---

# 3. Visão Geral das Camadas

A comunicação entre Grupos Computacionais é composta por três camadas:

```text
┌─────────────────────────────────────────────────────────┐
│                    CAMADA DE APLICAÇÃO                    │
│                                                           │
│              Protocolo TLV (Type-Length-Value)             │
│                                                           │
│  START │ MSG_ID │ COUNT │ FIELDS[ID+LEN+N] │ CRC8 │ ... │
│                                                           │
│  Responsável: significado, integridade, autenticação      │
└──────────────────────────┬──────────────────────────────┘
                           │
                           │ payload serializado
                           ▼
┌─────────────────────────────────────────────────────────┐
│                    CAMADA DE TRANSPORTE                    │
│                                                           │
│                    CAN FD (29-bit ID)                      │
│                                                           │
│  CAN_ID[origem + destino + tipo + prioridade] │ Payload  │
│                                                           │
│  Responsável: roteamento, prioridade, arbiter, fragmentação│
└──────────────────────────┬──────────────────────────────┘
                           │
                           │ frame CAN FD
                           ▼
┌─────────────────────────────────────────────────────────┐
│                    CAMADA FÍSICA                          │
│                                                           │
│              CAN FD (twisted pair + terminated)           │
│                                                           │
│  Responsável: sinal elétrico, Born-off, isolamento        │
└─────────────────────────────────────────────────────────┘
```

---

# 4. Camada de Aplicação — Protocolo TLV

O protocolo TLV (Type-Length-Value) constitui a camada de aplicação de todas as mensagens trocadas entre Grupos Computacionais.

## 4.1 Características

* protocolo completo e autónomo;
* estrutura fixa: START(0xAA) + MSG_ID + TLV_COUNT + TLV_FIELDS + CRC8;
* HMAC (32 bytes) e SEQ (4 bytes) acrescentados pelo módulo Security após serialização;
* CRC8 SMBUS (polinómio 0x07) para detecção de erros na camada de aplicação;
* little-endian para serialização numérica;
* até 32 campos TLV por mensagem;
* payload máximo de 32 bytes por campo (ou 128 bytes para vídeo);
* parser FSM com timeout, overflow protection e reset automático.

## 4.2 Independência do Meio

O TLV é transportado por qualquer meio serial confiável:

* CAN FD (comunicação inter-grupos);
* UART (comunicação local com periféricos);
* SPI (sensores de alta velocidade);
* I2C (sensores de baixa velocidade);
* LoRa (comunicação externa — futuro).

O TLV não contém informação sobre o meio de transporte. A camada de transporte é transparente para a camada de aplicação.

## 4.3 Referência

A definição completa do protocolo TLV encontra-se em `shared/TLV_DEFINITIONS`.

---

# 5. Camada de Transporte — CAN FD

O CAN FD (Controller Area Network with Flexible Data-rate) constitui a camada de transporte para comunicação entre Grupos Computacionais.

## 5.1 Características

* payload até 64 bytes (vs 8 bytes CAN clássico);
* bitrate de arbitragem e de dados configurável separadamente;
* CRC nativo de 17-bit para proteção física;
* arbiter automático baseado em prioridade (ID mais baixo = prioridade mais alta);
* Born-off e auto-recovery integrados;
* suporte para 29-bit ID extendido.

## 5.2 CAN ID

O CAN ID de 29 bits transporta informação de roteamento:

```text
┌────────────────────────────────────────────────────────────┐
│  CAN ID Extended (29 bits)                                  │
│                                                            │
│  PRIORIDADE │ GRUPO_ORIGEM │ GRUPO_DESTINO │ TIPO_MSG     │
│   (3 bit)   │   (4 bit)    │    (4 bit)    │  (4 bit)     │
└────────────────────────────────────────────────────────────┘
```

## 5.3 Referência

A definição completa dos CAN IDs encontra-se em `shared/CAN_IDS`.

---

# 6. Camada Física — CAN FD

## 6.1 Topologia

A comunicação CAN FD do Aerus utiliza uma topologia partilhada (bus) com dois buses independentes:

```text
BUS OPERACIONAL:
┌──────────────────────────────────────────────────────────────────┐
│  ESP32-S_01   ESP32-S_02   RaspberryPi   ESP32-A   ESP32-FS    │
│  CAN_ID:0x11  CAN_ID:0x12  CAN_ID:0x01  CAN_ID:0x21 CAN_ID:0x31│
└──────────────────────────────────────────────────────────────────┘

BUS SEGURANÇA:
┌──────────────────────────────────────────────────────────────────┐
│  ESP32-FS    ESP32-FS_A                                         │
│  CAN_ID:0x31  CAN_ID:0x41                                      │
└──────────────────────────────────────────────────────────────────┘
```

O ESP32-FS está conectado a ambos os buses, funcionando como ponte entre o domínio operacional e o domínio de segurança.

## 6.2 Bitrate

O bitrate é variável e depende do tipo de dado:

| Tipo de Dado            | Bitrate (Dados) | Bitrate (Arbitragem) |
|------------------------|-----------------|---------------------|
| Telemetria sensores    | 2 Mbps          | 500 kbps            |
| Comandos de controlo   | 2 Mbps          | 500 kbps            |
| Heartbeat / estados    | 500 kbps        | 500 kbps            |
| Segurança / emergência | 5 Mbps          | 1 Mbps              |
| Vídeo                  | 5 Mbps          | 1 Mbps              |

## 6.3 Referência

A definição completa do CAN Bus encontra-se em `COM-008`.

---

# 7. Comunicação Local com Periféricos

A comunicação entre controladores e periféricos (sensores e atuadores) não utiliza CAN bus, mas sim interfaces seriais dedicadas:

```text
ESP32-S    ←─UART/SPI/I2C─→ Sensores
ESP32-A    ←─UART/SPI/I2C─→ Atuadores
ESP32-FS   ←─UART/SPI/I2C─→ Sensores supercríticos
ESP32-FS_A ←─UART/SPI/I2C─→ Atuadores emergência
```

Estas interfaces estão documentadas em `HW-006` e `HW-004`.

---

# 8. Separção entre Comunicação Inter-Grupos e Local

```text
┌──────────────────────────────────────────────────────────────────┐
│                     AERUS - VISÃO DE COMUNICAÇÃO                  │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │              COMUNICAÇÃO LOCAL (periféricos)                │  │
│  │                                                            │  │
│  │  ESP32-S ←─UART/SPI/I2C─→ Sensores                       │  │
│  │  ESP32-A ←─UART/SPI/I2C─→ Atuadores                      │  │
│  │  ESP32-FS ←─UART/SPI/I2C─→ Sensores supercríticos        │  │
│  │  ESP32-FS_A ←─UART/SPI/I2C─→ Atuadores emergência        │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │         COMUNICAÇÃO INTER-GRUPOS (CAN bus)                  │  │
│  │                                                            │  │
│  │  ┌──────────────────────────────────────────────────────┐  │  │
│  │  │          BUS OPERACIONAL (partilhado)                 │  │  │
│  │  │  ESP32-S ←→ RaspberryPi ←→ ESP32-A ←→ ESP32-FS      │  │  │
│  │  └──────────────────────────────────────────────────────┘  │  │
│  │                                                            │  │
│  │  ┌──────────────────────────────────────────────────────┐  │  │
│  │  │          BUS SEGURANÇA (dedicado)                      │  │  │
│  │  │  ESP32-FS ←→ ESP32-FS_A                              │  │  │
│  │  └──────────────────────────────────────────────────────┘  │  │
│  │                                                            │  │
│  │  ESP32-FS conectado a AMBOS os buses                       │  │
│  └────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
```

---

# 9. Segurança Multi-Camada

A arquitetura de comunicação possui cinco camadas de proteção:

| Camada | Mecanismo | Protege contra |
|--------|-----------|----------------|
| 1 | CRC nativo CAN FD (17-bit) | Erros de transmissão no canal físico |
| 2 | CRC8 TLV (SMBUS 0x07) | Corrupção na camada de aplicação |
| 3 | HMAC TLV (32 bytes) | Mensagens falsificadas (requer módulo Security) |
| 4 | CAN ID + assinatura | Identificação e autenticação no transporte |
| 5 | SEQ TLV (4 bytes) | Reenvio de mensagens capturadas (anti-replay) |

---

# 10. Prioridade

A prioridade das mensagens é determinada por dois mecanismos complementares:

1. **CAN ID (arbiter nativo):** O bit de prioridade no CAN ID determina quem transmite quando vários nodos competem pelo bus. ID mais baixo = prioridade mais alta.
2. **TLV MSG_ID (lógica de aplicação):** O tipo de mensagem determina a prioridade de processamento e descarte no receptor.

| Prioridade     | CAN ID Bits | TLV MSG_ID(s) | Comportamento |
|----------------|-------------|---------------|---------------|
| SUPER_CRITICAL | 0           | MSG_FAILSAFE, MSG_SAFETY_DATA | Nunca descartado |
| CRITICAL       | 1           | MSG_COMMAND | Sempre transmitido |
| HIGH           | 2           | MSG_TELEMETRY, MSG_HEARTBEAT, MSG_SI_DATA | Prioridade alta |
| MEDIUM         | 3           | MSG_VIDEO, MSG_ACK | Prioridade normal |
| LOW            | 4           | MSG_SHELL_CMD | Pode ser atrasado |
| SUPER_LOW      | 5           | MSG_DEBUG | Descartável se necessário |

---

# 11. Fragmentação

Mensagens TLV que excedam o payload máximo de um frame CAN FD (64 bytes) são fragmentadas em múltiplos frames.

```text
Mensagem TLV grande:
┌─────────────────────────────────────────────────────────────────┐
│ START │ MSG_ID │ COUNT │ FIELD1 │ FIELD2 │ ... │ FIELD_N │ CRC8│
└───────┴────────┴───────┴────────┴────────┴─────┴─────────┴─────┘
                           │
                           │ fragmentação
                           ▼
Frame CAN FD #1:  [Frag0/3] [START+MSG_ID+COUNT+CRC8+FIELD1] (≤64 bytes)
Frame CAN FD #2:  [Frag1/3] [FIELD2+FIELD3+FIELD4]           (≤64 bytes)
Frame CAN FD #3:  [Frag2/3] [FIELD5+FIELD6+FIELD_N+CRC8]     (≤64 bytes)
```

---

# 12. Gestão de Comunicações

A comunicação entre módulos e entre domínios computacionais é efetuada através de um gestor de comunicações dedicado, conforme definido em `SYS-003` §13.

O gestor é responsável por:

* receção de mensagens TLV via CAN FD;
* validação (CRC8, estrutura, limites);
* encaminhamento para o módulo destinatário;
* gestão de prioridades (CAN ID + TLV MSG_ID);
* gestão de eventos;
* gestão de filas;
* entrega ao destinatário;
* fragmentação e reconstituição quando necessário.

Nenhum módulo deverá implementar mecanismos próprios de comunicação paralelos à arquitetura definida pelo sistema.

---

# 13. Comunicação e Temporização

A comunicação entre grupos deverá respeitar os requisitos temporais definidos em `SYS-008`.

* A frequência de comunicação é independente da frequência de aquisição de sensores;
* Heartbeats são transmitidos periodicamente para todos os grupos;
* Eventos de segurança são transmitidos imediatamente, sem aguardar o ciclo periódico;
* Timeouts por grupo determinam a perda de comunicação;
* Sincronização temporal é executada via MSG_SYNC_REQ/MSG_SYNC_RESP.

---

# 14. Comunicação e Segurança

A arquitetura de comunicação suporta os mecanismos de segurança definidos em `SEC/`:

* ESP32-FS possui acesso a ambos os buses;
* Mensagens de segurança utilizam o bus dedicado;
* CAN IDs de segurança possuem prioridade SUPER_CRITICAL;
* HMAC e SEQ previnem ataques de injeção e replay;
* Perda de comunicação com ESP32-FS é tratada como condição de emergência;
* O bus de segurança permanece funcional mesmo perante falhas no bus operacional.

---

# 15. Escalabilidade

A arquitetura de comunicação permite:

* adicionar novos Grupos Computacionais com CAN IDs próprios;
* adicionar novos elementos dentro de grupos existentes;
* adicionar novos tipos de mensagens (MSG_ID);
* adicionar novos campos TLV;
* adicionar novos comandos;
* utilizar novos meios de transporte (LoRa, Ethernet) sem alterar o TLV;
* expandir o CAN ID para mais bits quando necessário.

A introdução de novos elementos deverá procurar manter compatibilidade com a arquitetura existente.

---

# 16. Limites do Documento

Este documento não define detalhadamente:

* estrutura completa das mensagens TLV;
* tabela completa de CAN IDs;
* parâmetros elétricos do CAN;
* algoritmos de fragmentação;
* implementação do gestor de comunicações;
* implementação do parser TLV;
* regras completas de timeout;
* regras completas de prioridade.

Esses elementos encontram-se definidos nas especificações correspondentes (`COM-002`, `COM-004`, `COM-007`, `COM-008`, `COM-010`).

---

# 17. Referências

- SHARED-TLV — Definições do Protocolo TLV
- SHARED-CAN-IDS — Alocação de CAN IDs
- COM-002 — Protocolo TLV
- COM-003 — Gestor de Mensagens
- COM-004 — Prioridades e Filas
- COM-007 — Comunicação entre Domínios Computacionais
- COM-008 — CAN Bus
- COM-010 — Integridade
- HW-006 — Interfaces de Comunicação
- HW-004 — Interfaces Elétricas
- SYS-003 — Arquitetura de Software
- SYS-005 — Fluxo Global de Informação
- SYS-008 — Gestão Temporal
- SEC — Especificações de Segurança
