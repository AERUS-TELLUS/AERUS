# CAN_IDS — Alocação de CAN IDs do Aerus

| Campo             | Valor                              |
| ----------------- | ---------------------------------- |
| **Código**        | SHARED-CAN-IDS                     |
| **Título**        | Alocação de CAN IDs                |
| **Versão**        | 1.0                                |
| **Estado**        | Em Desenvolvimento                 |
| **Autor**         | ShegaPT                            |
| **Classificação** | Protocolo Partilhado               |

---

# 1. Objetivo

O presente documento define a tabela de alocação de CAN IDs utilizados pelo sistema Aerus para comunicação entre Grupos Computacionais.

O CAN ID é a camada de transporte que determina a origem, destino e prioridade de cada frame CAN FD transmitido no bus. O payload de cada frame contém uma mensagem TLV serializada conforme definido em `TLV_DEFINITIONS`.

---

# 2. Princípios

* Cada Grupo Computacional possui um CAN ID próprio e exclusivo;
* Cada elemento dentro de um grupo (quando existirem vários) possui um CAN ID único;
* O CAN ID permite roteamento automático pelo bus sem necessidade de processamento adicional;
* O ESP32-FS possui CAN IDs em ambos os buses (operacional e segurança);
* IDs reservados são mantidos para expansão futura.

---

# 3. Formato do CAN ID (Extended 29-bit)

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

**Campos:**

| Campo            | Bits   | Descrição |
|------------------|--------|-----------|
| Prioridade       | 28-26  | 0=SuperCritical, 1=Critical, 2=High, 3=Medium, 4=Low |
| Grupo Origem     | 25-22  | ID do grupo que envia a mensagem |
| Grupo Destino    | 21-18  | ID do grupo que recebe (0x0 = broadcast) |
| Tipo Mensagem    | 17-14  | Tipo de dado transportado |
| Reservado        | 13-0   | Zeros (expansão futura) |

---

# 4. Tabela de Grupos Computacionais

| Grupo           | ID Grupo | Descrição |
|-----------------|----------|-----------|
| Reserved        | 0x0      | Nenhum / Broadcast |
| RaspberryPi     | 0x1      | Nível 1 — Orquestração |
| ESP32-S         | 0x2      | Nível 2 — Aquisição |
| ESP32-A         | 0x3      | Nível 2 — Controlo |
| ESP32-FS        | 0x4      | Nível 0 — Segurança |
| ESP32-FS_A      | 0x5      | Nível 1 — Emergência |
| Reserved        | 0x6-0xF  | Expansão futura |

---

# 5. Tabela de Tipos de Mensagem (CAN)

| Tipo  | Constante       | Descrição |
|-------|-----------------|-----------|
| 0x0   | MSG_TYPE_DATA   | Dados de telemetria / sensores |
| 0x1   | MSG_TYPE_CMD    | Comandos |
| 0x2   | MSG_TYPE_ACK    | Confirmação de receção |
| 0x3   | MSG_TYPE_EVENT  | Eventos / failsafe |
| 0x4   | MSG_TYPE_SYNC   | Sincronização temporal |
| 0x5   | MSG_TYPE_STATE  | Broadcast de estado |
| 0x6   | MSG_TYPE_HEART  | Heartbeat |
| 0x7   | MSG_TYPE_SAFETY | Dados de segurança |
| 0x8-0xF | Reserved     | Expansão futura |

---

# 6. Tabela Completa de CAN IDs Atribuídos

## 6.1 Bus Operacional

| CAN ID     | Grupo Origem   | Grupo Destino  | Tipo        | Prioridade | Descrição |
|------------|----------------|----------------|-------------|------------|-----------|
| 0x01000000 | RaspberryPi    | Broadcast      | DATA        | HIGH       | Telemetria para todos |
| 0x01100000 | RaspberryPi    | ESP32-S        | CMD         | HIGH       | Comandos para sensores |
| 0x01200000 | RaspberryPi    | ESP32-A        | CMD         | CRITICAL   | Comandos de voo |
| 0x01300000 | RaspberryPi    | ESP32-FS       | DATA        | HIGH       | Estados para segurança |
| 0x01600000 | RaspberryPi    | Broadcast      | HEART       | MEDIUM     | Heartbeat RaspberryPi |
| 0x01400000 | RaspberryPi    | Broadcast      | EVENT       | HIGH       | Eventos de missão |
| 0x02000000 | ESP32-S_01     | Broadcast      | DATA        | HIGH       | Sensores front |
| 0x02040000 | ESP32-S_01     | ESP32-FS       | DATA        | HIGH       | Sensores front → segurança |
| 0x02100000 | ESP32-S_01     | RaspberryPi    | DATA        | HIGH       | Sensores front → RPi |
| 0x02200000 | ESP32-S_02     | Broadcast      | DATA        | HIGH       | Sensores rear |
| 0x02240000 | ESP32-S_02     | ESP32-FS       | DATA        | HIGH       | Sensores rear → segurança |
| 0x02300000 | ESP32-S_02     | RaspberryPi    | DATA        | HIGH       | Sensores rear → RPi |
| 0x02400000 | ESP32-S_03     | Broadcast      | DATA        | HIGH       | Sensores left |
| 0x02500000 | ESP32-S_04     | Broadcast      | DATA        | HIGH       | Sensores right |
| 0x02600000 | ESP32-S        | Broadcast      | STATE       | MEDIUM     | Estado ESP32-S |
| 0x02E00000 | ESP32-S        | Broadcast      | HEART       | MEDIUM     | Heartbeat ESP32-S |
| 0x03000000 | ESP32-A_01     | Broadcast      | DATA        | HIGH       | Atuadores front |
| 0x03040000 | ESP32-A_01     | ESP32-FS       | DATA        | HIGH       | Atuadores front → segurança |
| 0x03100000 | ESP32-A_01     | RaspberryPi    | DATA        | HIGH       | Atuadores front → RPi |
| 0x03200000 | ESP32-A_02     | Broadcast      | DATA        | HIGH       | Atuadores rear |
| 0x03600000 | ESP32-A        | Broadcast      | STATE       | MEDIUM     | Estado ESP32-A |
| 0x03E00000 | ESP32-A        | Broadcast      | HEART       | MEDIUM     | Heartbeat ESP32-A |
| 0x04000000 | ESP32-FS       | Broadcast      | SAFETY      | SUPER_CRIT | Dados de segurança |
| 0x04100000 | ESP32-FS       | ESP32-S        | CMD         | CRITICAL   | Comandos para sensores |
| 0x04200000 | ESP32-FS       | ESP32-A        | CMD         | CRITICAL   | Inibição ESP32-A |
| 0x04300000 | ESP32-FS       | RaspberryPi    | DATA        | CRITICAL   | Estados segurança → RPi |
| 0x04400000 | ESP32-FS       | Broadcast      | EVENT       | SUPER_CRIT | Eventos de segurança |
| 0x04500000 | ESP32-FS       | Broadcast      | SYNC        | CRITICAL   | Sincronização temporal |
| 0x04600000 | ESP32-FS       | Broadcast      | STATE       | CRITICAL   | Estado ESP32-FS |
| 0x04E00000 | ESP32-FS       | Broadcast      | HEART       | HIGH       | Heartbeat ESP32-FS |
| 0x05000000 | ESP32-FS       | ESP32-FS_A     | SAFETY      | SUPER_CRIT | Comandos de emergência |
| 0x05100000 | ESP32-FS_A     | ESP32-FS       | DATA        | SUPER_CRIT | Feedback emergência |

## 6.2 Bus de Segurança

| CAN ID     | Grupo Origem   | Grupo Destino  | Tipo        | Prioridade | Descrição |
|------------|----------------|----------------|-------------|------------|-----------|
| 0x44000000 | ESP32-FS       | ESP32-FS_A     | SAFETY      | SUPER_CRIT | Comandos de emergência |
| 0x45000000 | ESP32-FS       | Broadcast      | EVENT       | SUPER_CRIT | Eventos de segurança |
| 0x46000000 | ESP32-FS       | Broadcast      | SYNC        | CRITICAL   | Sincronização |
| 0x50000000 | ESP32-FS_A     | ESP32-FS       | DATA        | SUPER_CRIT | Feedback atuadores emergência |
| 0x54000000 | ESP32-FS_A     | Broadcast      | STATE       | SUPER_CRIT | Estado ESP32-FS_A |
| 0x5E000000 | ESP32-FS_A     | Broadcast      | HEART       | SUPER_CRIT | Heartbeat ESP32-FS_A |

---

# 7. BITRATE por Tipo de Dado

| Tipo de Dado            | Bitrate (Dados) | Bitrate (Arbitragem) | Bus |
|------------------------|-----------------|---------------------|-----|
| Telemetria sensores    | 2 Mbps          | 500 kbps            | Operacional |
| Comandos de controlo   | 2 Mbps          | 500 kbps            | Operacional |
| Heartbeat / estados    | 500 kbps        | 500 kbps            | Operacional |
| Dados de atuadores     | 2 Mbps          | 500 kbps            | Operacional |
| Segurança / emergência | 5 Mbps          | 1 Mbps              | Segurança |
| Sincronização temporal | 5 Mbps          | 1 Mbps              | Ambos |
| Vídeo                  | 5 Mbps          | 1 Mbps              | Operacional |
| Debug / diagnóstico    | 500 kbps        | 500 kbps            | Operacional |

**NOTA:** O bitrate de arbitragem é sempre igual ou inferior ao bitrate de dados. Durante a fase de arbitragem, todos os nodos utilizam o bitrate mais baixo. Após a arbitragem, o nó vencedor pode alternar para o bitrate de dados superior (CAN FD).

---

# 8. Canais de Comunicação Locais (não-CAN)

A comunicação entre controladores e periféricos não utiliza CAN bus, mas sim interfaces seriais dedicadas:

| Interface | Grupo            | Periférico          | Bitrate    | Descrição |
|-----------|------------------|---------------------|------------|-----------|
| UART      | ESP32-S          | Sensores            | Variável   | Conforme sensor |
| SPI       | ESP32-S          | Sensores de alta vel| Até 10 MHz | IMU, barómetro |
| I2C       | ESP32-S          | Sensores de baixa vel| Até 400 kHz | Magnetómetro, temp |
| UART      | ESP32-A          | Atuadores           | Variável   | Conforme atuador |
| UART      | ESP32-FS         | Sensores supercrític| Variável   | GPS, IMU reserva |
| UART      | ESP32-FS_A       | Atuadores emergência| Variável   | PWM, sinais digitais |
| UART      | RaspberryPi      | GroundStation       | 115200     | Telemetria externa |
| UART      | RaspberryPi      | Implementos         | Variável   | Interface com implementos |

Estas interfaces estão documentadas em `HW-006` e `HW-004`.

---

# 9. Regras de Atribuição

## 9.1 Unicidade

Cada elemento físico deve possuir um CAN ID único e exclusivo dentro do seu bus.

## 9.2 Grupo > Elemento

A atribuição segue a hierarquia: Grupo → Elemento → Tipo de mensagem.

## 9.3 Broadcast

O CAN ID de broadcast (grupo destino = 0x0) é utilizado para mensagens que devem ser recebidas por todos os grupos no bus.

## 9.4 Segurança

Mensagens de segurança utilizam exclusivamente o bus dedicado de segurança, com CAN IDs no intervalo 0x40000000-0x5FFFFFFF.

## 9.5 Expansão

IDs reservados (0x6-0xF para grupo, 0x8-0xF para tipo) são mantidos para futuros grupos computacionais e tipos de mensagem.

---

# 10. Validação de CAN IDs

```cpp
// Validação em tempo de compilação
constexpr bool isValidCANGroup(uint8_t group) {
    return group <= 0x5; // 0x0 (reserved) a 0x5 (ESP32-FS_A)
}

constexpr bool isValidCANType(uint8_t type) {
    return type <= 0x7; // 0x0 (DATA) a 0x7 (SAFETY)
}

constexpr bool isSafetyBusID(uint32_t canID) {
    return (canID >= 0x40000000) && (canID <= 0x5FFFFFFF);
}
```

---

# 11. Referências

- SHARED-TLV — Protocolo TLV
- COM-001 — Arquitetura de Comunicação
- COM-008 — CAN Bus
- COM-007 — Comunicação entre Domínios Computacionais
- HW-006 — Interfaces de Comunicação
- HW-008 — Redundância e Isolamento de Hardware
