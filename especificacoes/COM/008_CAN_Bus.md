# COM-008 — CAN Bus

| Campo             | Valor                              |
| ----------------- | ---------------------------------- |
| **Código**        | COM-008                            |
| **Título**        | CAN Bus                            |
| **Versão**        | 1.0                                |
| **Estado**        | Em Desenvolvimento                 |
| **Autor**         | ShegaPT                            |
| **Classificação** | Especificação de Comunicação       |

---

# 1. Objetivo

O presente documento define a especificação física e de transporte da rede CAN FD (Controller Area Network with Flexible Data-rate) utilizada pelo sistema Aerus para comunicação entre Grupos Computacionais.

O CAN FD constitui a camada de transporte de todas as mensagens TLV trocadas entre os diferentes domínios computacionais do Aerus.

---

# 2. Princípios

A implementação CAN FD do Aerus baseia-se nos seguintes princípios:

* CAN FD (Flexible Data-rate) com payload até 64 bytes;
* topologia partilhada (bus);
* dois buses independentes (operacional e segurança);
* bitrate variável conforme o tipo de dado;
* CAN ID de 29 bits (extended frame);
*Born-off e auto-recovery integrados;
* isolamento galvânico entre buses quando necessário;
* terminação adequada em ambos os extremos do bus.

---

# 3. CAN FD vs CAN Clássico

O Aerus utiliza CAN FD em vez de CAN clássico pelas seguintes razões:

| Característica       | CAN Clássico | CAN FD     |
|---------------------|--------------|------------|
| Payload máximo       | 8 bytes      | 64 bytes   |
| Bitrate de dados     | Até 1 Mbps   | Até 8 Mbps |
| CRC                  | 15-bit       | 17-bit     |
| Controlo de erros    | Básico       | Melhorado  |
| Compatibilidade      | —            | Retrocompatível com CAN |

Com CAN FD, uma mensagem TLV completa pode ser transportada num único frame na maioria dos casos, reduzindo a necessidade de fragmentação.

---

# 4. Topologia

## 4.1 Bus Operacional

O bus operacional é partilhado por todos os Grupos Computacionais participantes:

```text
                          BUS OPERACIONAL
    ┌──────────────────────────────────────────────────────────────┐
    │                                                              │
    │  ┌─────────┐  ┌─────────┐  ┌─────────────┐  ┌─────────┐   │
    │  │ESP32-S  │  │ESP32-S  │  │ RaspberryPi │  │ ESP32-A │   │
    │  │  _01    │  │  _02    │  │             │  │         │   │
    │  │ID:0x11  │  │ID:0x12  │  │  ID:0x01    │  │ ID:0x21 │   │
    │  └────┬────┘  └────┬────┘  └──────┬──────┘  └────┬────┘   │
    │       │            │              │              │          │
    │  ─────┴────────────┴──────────────┴──────────────┴─────    │
    │                                                              │
    │                    ┌──────────┐                             │
    │                    │ ESP32-FS │                             │
    │                    │ ID:0x31  │                             │
    │                    └────┬─────┘                             │
    │                         │                                   │
    └─────────────────────────┼───────────────────────────────────┘
                              │
                    ┌─────────┴─────────┐
                    │  BUS SEGURANÇA     │
    ┌───────────────┼────────────────────┼───────────────────┐
    │               │                    │                   │
    │  ┌────────────┴──┐          ┌──────┴──────┐           │
    │  │   ESP32-FS    │          │  ESP32-FS_A │           │
    │  │   ID:0x31     │          │  ID:0x41    │           │
    │  └───────────────┘          └─────────────┘           │
    │                                                       │
    └───────────────────────────────────────────────────────┘
```

## 4.2 Bus de Segurança

O bus de segurança é exclusivo para comunicação entre ESP32-FS e ESP32-FS_A:

* garante que mensagens de emergência não competem com tráfego operacional;
* permanece funcional mesmo perante falhas no bus operacional;
* CAN IDs neste bus possuem prioridade SUPER_CRITICAL.

## 4.3 ESP32-FS como Ponte

O ESP32-FS está conectado a ambos os buses e pode:

* receber mensagens do bus operacional;
* receber mensagens do bus de segurança;
* avaliar a necessidade de encaminhar informações entre os dois buses;
* tomar decisões de segurança com base em dados de ambos os buses.

---

# 5. CAN ID

## 5.1 Formato Extended (29-bit)

```text
┌────────────────────────────────────────────────────────────┐
│  CAN ID Extended (29 bits)                                  │
│                                                            │
│  PRIORIDADE │ GRUPO_ORIGEM │ GRUPO_DESTINO │ TIPO_MSG     │
│   (3 bit)   │   (4 bit)    │    (4 bit)    │  (4 bit)     │
│    28-26    │    25-22     │     21-18     │   17-14      │
│                                                            │
│  Bits 13-0: Reservados (zeros)                              │
└────────────────────────────────────────────────────────────┘
```

## 5.2 Campos

| Campo            | Bits   | Descrição |
|------------------|--------|-----------|
| Prioridade       | 28-26  | 0=SuperCritical, 1=Critical, 2=High, 3=Medium, 4=Low |
| Grupo Origem     | 25-22  | ID do grupo que envia |
| Grupo Destino    | 21-18  | ID do grupo que recebe (0x0 = broadcast) |
| Tipo Mensagem    | 17-14  | Tipo de dado transportado |
| Reservado        | 13-0   | Zeros (expansão futura) |

## 5.3 Regras

* O bit de prioridade determina o arbiter: ID mais baixo vence;
* Grupo destino 0x0 indica mensagem broadcast;
* O CAN ID é configurado antes da compilação para cada elemento.

A tabela completa de CAN IDs encontra-se em `shared/CAN_IDS`.

---

# 6. Frame Format

## 6.1 CAN FD Frame (Standard)

```text
┌──────────┬──────────┬──────────┬──────────┬──────────┬──────────┬──────────┐
│ SOF      │ Arbitration│ Control  │ Data     │ CRC      │ ACK      │ EOF      │
│ (1 bit)  │ (29 bits) │ (13 bits)│(0-64 B)  │ (17 bits)│ (2 bits) │ (7 bits) │
└──────────┴──────────┴──────────┴──────────┴──────────┴──────────┴──────────┘
```

## 6.2 DLC (Data Length Code)

| DLC | Bytes | DLC | Bytes |
|-----|-------|-----|-------|
| 0   | 0     | 8   | 8     |
| 1   | 1     | 9   | 12    |
| 2   | 2     | 10  | 16    |
| 3   | 3     | 11  | 20    |
| 4   | 4     | 12  | 24    |
| 5   | 5     | 13  | 32    |
| 6   | 6     | 14  | 48    |
| 7   | 7     | 15  | 64    |

**NOTA:** CAN FD utiliza encoding não-linear para DLCs superiores a 8.

---

# 7. Bitrate

## 7.1 Bitrate de Arbitragem

O bitrate de arbitragem é utilizado durante a fase de arbitragem (quando vários nodos competem pelo bus). Todos os nodos devem utilizar o mesmo bitrate de arbitragem.

| Configuração | Valor |
|-------------|-------|
| Operacional | 500 kbps |
| Segurança   | 1 Mbps |

## 7.2 Bitrate de Dados

O bitrate de dados é utilizado após a arbitragem, durante a transmissão do payload. Pode ser superior ao bitrate de arbitragem.

| Tipo de Dado            | Bitrate |
|------------------------|---------|
| Telemetria sensores    | 2 Mbps  |
| Comandos de controlo   | 2 Mbps  |
| Heartbeat / estados    | 500 kbps |
| Segurança / emergência | 5 Mbps  |
| Sincronização temporal | 5 Mbps  |
| Vídeo                  | 5 Mbps  |
| Debug / diagnóstico    | 500 kbps |

## 7.3 Switching de Bitrate

O CAN FD permite alternar entre bitrate de arbitragem e bitrate de dados durante o mesmo frame:

```text
┌─────────────────────────────────────────────────────────────┐
│  BITRATE DE ARBITRAGEM │    BITRATE DE DADOS    │ARBITRAGEM │
│       (500 kbps)       │      (2-5 Mbps)        │ (500 kbps)│
│                        │                         │           │
│  SOF + ID + Control    │      Data + CRC         │ ACK + EOF │
└─────────────────────────────────────────────────────────────┘
```

---

# 8. Terminação

## 8.1 Resistência de Terminação

Cada extremidade do bus CAN deve ser terminada com uma resistência de:

| Parâmetro         | Valor    |
|------------------|----------|
| Resistência      | 120 Ω    |
| Tolerância       | ±5%      |
| Potência mínima  | 1/4 W    |

## 8.2 Impedância do Cabo

O cabo CAN deve possuir impedância característica de:

| Parâmetro         | Valor    |
|------------------|----------|
| Impedância       | 120 Ω    |
| Tolerância       | ±10%     |

## 8.3 Topologia de Terminação

```text
┌──────────┐                                    ┌──────────┐
│  120Ω    │                                    │  120Ω    │
│  ┌───┐   │                                    │  ┌───┐   │
│  │ R │───┤──────┬──────┬──────┬──────┬────────┤──│ R │   │
│  └───┘   │      │      │      │      │        │  └───┘   │
└──────────┘      │      │      │      │        └──────────┘
                ┌─┴─┐  ┌─┴─┐  ┌─┴─┐  ┌─┴─┐
                │N1 │  │N2 │  │N3 │  │N4 │
                └───┘  └───┘  └───┘  └───┘
```

---

# 9. Born-off e Recovery

## 9.1 Born-off

Quando um nó CAN deteta erros consecutivos (erros de formatação, erros CRC, erros de bit), entra em estado de Born-off:

```text
ERROR ACTIVE ──(127 erros)──→ ERROR PASSIVE ──(255 erros)──→ BUS OFF
```

| Estado          | Descrição |
|----------------|-----------|
| ERROR ACTIVE    | Normal, pode transmitir e sinalizar erros |
| ERROR PASSIVE   | Pode transmitir mas não sinaliza erros |
| BUS OFF         | Desligado do bus, não transmite nem recebe |

## 9.2 Auto-Recovery

O Aerus implementa auto-recuperação após Born-off:

```text
BUS OFF ──(tempo configurável)──→ RECONEXÃO ──(128 × 11 recessive bits)──→ ERROR ACTIVE
```

| Parâmetro               | Valor |
|------------------------|-------|
| Tempo mínimo de espera | 1 ms  |
| Máximo de tentativas   | 10    |
| Intervalo entre tentativas | 100 ms |

## 9.3 Regras de Recuperação

* após Born-off, o nó aguarda o tempo configurável antes de tentar reconectar;
* se a reconexão falhar, o nó regista o erro e tenta novamente;
* após 10 tentativas sem sucesso, o nó notifica o módulo de segurança;
* o registo de Born-off deve ser disponibilizado para diagnóstico.

---

# 10. Isolamento Galvânico

## 10.1 Necessidade

O isolamento galvânico entre o CAN transceiver e o microcontrolador é recomendado para:

* proteção contra diferenças de potencial entre nodos;
* redução de interferências eletromagnéticas;
* proteção contra picos de tensão;
* separação entre o domínio operacional e o domínio de segurança.

## 10.2 Implementação

| Método                | Aplicação |
|----------------------|-----------|
| Isolador CAN (ex: ISO1050) | Recomendado para ESP32-FS |
| Transformador de acoplamento | Alternativa para baixas velocidades |
| Óptico (acopladores)  | Não recomendado para CAN FD (limitações de velocidade) |

## 10.3 Requisitos

| Parâmetro             | Valor |
|----------------------|-------|
| Tensão de isolamento | ≥ 2500 V RMS |
| CMC                  | ≥ 100 V/µs |
| Temperatura          | -40°C a +125°C |

---

# 11. Proteção Elétrica

## 11.1 Proteção contra Sobretensão

| Mecanismo            | Descrição |
|---------------------|-----------|
| TVS (Transient Voltage Suppressor) | Proteção contra picos |
| Zener               | Limitação de tensão |
| Fusível              | Proteção contra sobrecorrente |

## 11.2 Proteção contra Inversão de Polaridade

O CAN transceiver deve suportar inversão de polaridade sem dano permanente.

## 11.3 Proteção contra ESD

| Padrão   | Nível |
|---------|-------|
| IEC 61000-4-2 | ≥ 8 kV (contacto) |
| IEC 61000-4-2 | ≥ 15 kV (ar) |

---

# 12. Requisitos do CAN Transceiver

## 12.1 Características Mínimas

| Parâmetro             | Valor mínimo |
|----------------------|-------------|
| Velocidade de dados  | 5 Mbps      |
| Modo CAN FD          | Sim         |
| Tensão de alimentação| 3.3V ou 5V  |
| Modo standby         | Sim         |
| Temperatura          | -40°C a +125°C |

## 12.2 Transceivers Compatíveis

* MCP2562FD (Microchip) — 5V, CAN FD até 5 Mbps
* TCAN1042 (Texas Instruments) — 5V, CAN FD até 5 Mbps
* ISO1042 (Texas Instruments) — 5V, CAN FD isolado
* TJA1043 (NXP) — 3.3V/5V, CAN FD até 5 Mbps

---

# 13. Requisitos do Controlador CAN

## 13.1 ESP32

O ESP32 (e variantes S2, S3, C3) possui um controlador CAN integrado (TWAI) que suporta:

* CAN 2.0A e 2.0B (extended ID);
* filtros de mensagem configuráveis;
* interrupções por receção e erro;
* modo de baixo consumo.

**NOTA:** O TWAI do ESP32 suporta CAN 2.0B mas NÃO suporta CAN FD nativamente. Para CAN FD, é necessário um controlador externo (ex: MCP2518FD via SPI).

## 13.2 RaspberryPi

O RaspberryPi não possui CAN integrado. É necessário um módulo externo:

* MCP2518FD (SPI → CAN FD) — Recomendado
* MCP2515 (SPI → CAN 2.0) — Para CAN clássico
* WS5500 (Ethernet → CAN) — Para aplicações de rede

---

# 14. Fragmentação

## 14.1 Necessidade

Com CAN FD de 64 bytes, a maioria das mensagens TLV cabe num único frame. No entanto, mensagens com muitos campos TLV ou payloads de vídeo podem exceder este limite.

## 14.2 Cálculo do Espaço Disponível

```text
Espaço CAN FD = 64 bytes
Overhead CAN FD = CAN ID + DLC + flags ≈ 8-12 bytes
Espaço TLV = 64 - Overhead ≈ 52-56 bytes

Mensagem TLV mínima = START(1) + MSGID(1) + COUNT(1) + CRC8(1) = 4 bytes
Espaço restante para FIELDS = 52 - 4 = 48 bytes mínimo por frame
```

## 14.3 Estrutura de Fragmentação

| Campo           | Tamanho | Descrição |
|-----------------|---------|-----------|
| Fragment Index  | 1 byte  | Índice do fragmento (0-based) |
| Fragment Total  | 1 byte  | Total de fragmentos |
| TLV Payload     | Variável| Dados do TLV neste fragmento |

## 14.4 Regras

* o primeiro fragmento contém o cabeçalho TLV completo;
* os fragmentos seguintes contêm apenas campos TLV;
* o接收or reconstrói a mensagem completa antes de processar;
* se qualquer fragmento for perdido, a mensagem inteira é descartada;
* o timeout entre fragmentos é o mesmo que o timeout normal.

---

# 15. Filtragem de Mensagens

## 15.1 Filtros Hardware

O controlador CAN pode configurar filtros para aceitar apenas mensagens dirigidas ao nó:

```text
Filtro por CAN ID:
  Acceptance Filter = CAN_ID do grupo + broadcast (0x0)
  Rejection Filter  = Todos os outros CAN IDs
```

## 15.2 Filtros Software

Após aceitação pelo hardware, o software pode filtrar adicionalmente:

* por MSG_ID do TLV;
* por prioridade;
* por grupo de origem;
* por tipo de dado.

---

# 16. Monitorização e Diagnóstico

## 16.1 Registos Disponíveis

| Registo                | Descrição |
|-----------------------|-----------|
| Error Counter (TX)    | Contador de erros de transmissão |
| Error Counter (RX)    | Contador de erros de receção |
| Bus State             | Estado atual (ACTIVE/PASSIVE/OFF) |
| Messages TX           | Total de mensagens transmitidas |
| Messages RX           | Total de mensagens recebidas |
| Last Error Code       | Código do último erro |
| Bit Rate              | Bitrate configurado |
| CAN ID                | CAN ID do nó |

## 16.2 Condições de Erro

| Condição              | Resposta |
|----------------------|----------|
| CRC Error            | Descarte da mensagem, incremento de contador |
| Stuff Error          | Descarte, incremento, possivel Born-off |
| Form Error           | Descarte, incremento, possivel Born-off |
| ACK Error            | Retransmissão, incremento |
| Bit Error            | Verificação, possivel arbitration loss |
| Bus Off              | Auto-recovery, notificação de segurança |

---

# 17. Compatibilidade

## 17.1 Retrocompatibilidade

O CAN FD é retrocompatível com CAN clássico em termos de:

* formato de frame (SOF, Arbitration, ACK, EOF);
* mecanismo de arbiter;
* deteção de erros.

No entanto, um nó CAN FD e um nó CAN clássico NÃO podem comunicar diretamente no mesmo bus porque:

* o CAN FD utiliza DLC differently para payloads > 8 bytes;
* o CAN FD utiliza BRS (Bit Rate Switch) que o CAN clássico não compreende.

**Conclusão:** Todos os nodos no mesmo bus devem ser CAN FD.

## 17.2 Expansão Futura

A arquitetura permite introduzir nodos CAN 2.0 em buses separados, desde que não partilhem o mesmo bus com nodos CAN FD.

---

# 18. Limites do Documento

Este documento não define:

* pinout específico dos conectores CAN;
* modelo específico de CAN transceiver;
* modelo específico de controlador CAN;
* esquema elétrico completo;
* layout de PCB;
* cabo específico (comprimento, seção, tipo);
* testes de conformidade;
* valores específicos de timeout;
* implementação do driver CAN.

Esses elementos serão definidos durante o projeto detalhado de hardware.

---

# 19. Referências

- COM-001 — Arquitetura de Comunicação
- COM-002 — Protocolo TLV
- COM-004 — Prioridades e Filas
- COM-006 — Timeouts e Recuperação
- COM-010 — Integridade
- SHARED-TLV — Definições do Protocolo TLV
- SHARED-CAN-IDS — Alocação de CAN IDs
- HW-004 — Interfaces Elétricas
- HW-006 — Interfaces de Comunicação
- HW-008 — Redundância e Isolamento de Hardware
- ISO 11898-1:2015 — CAN data link layer and physical signalling
- ISO 11898-2:2016 — CAN high-speed physical layer
- ISO 11898-5:2007 — CAN high-speed with low-power mode
