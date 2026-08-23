# COM-002 — Protocolo TLV

| Campo             | Valor                              |
| ----------------- | ---------------------------------- |
| **Código**        | COM-002                            |
| **Título**        | Protocolo TLV                      |
| **Versão**        | 1.0                                |
| **Estado**        | Em Desenvolvimento                 |
| **Autor**         | ShegaPT                            |
| **Classificação** | Especificação de Comunicação       |

---

# 1. Objetivo

O presente documento define a especificação do protocolo TLV (Type-Length-Value) utilizado pelo sistema Aerus para todas as mensagens trocadas entre Grupos Computacionais.

O TLV constitui a camada de aplicação completa e autónoma de comunicação. O CAN FD é exclusivamente o canal de transporte — o TLV não depende nem conhece o meio utilizado.

---

# 2. Princípios

* protocolo completo, seguro e autónomo;
* estrutura fixa e determinística (sem alocações dinâmicas);
* validação em tempo real (parser byte-a-byte);
* CRC8 para integridade na camada de aplicação;
* HMAC para autenticação (via módulo Security);
* SEQ para anti-replay;
* extensível (novos IDs sem alterar a estrutura);
* little-endian para serialização numérica;
* compatível com qualquer meio serial (CAN FD, UART, SPI, I2C).

---

# 3. Formato da Mensagem

## 3.1 Estrutura Completa

```text
┌─────────┬─────────┬───────────┬─────────────────┬─────────┬──────────────┬─────────┐
│ START   │ MSG ID  │ TLV COUNT │ TLV FIELDS      │ CRC8    │ HMAC (32B)   │ SEQ (4B)│
│ (1 byte)│ (1 byte)│ (1 byte)  │ (variável)      │ (1 byte)│ (opcional)   │ (opç.)  │
├─────────┼─────────┼───────────┼─────────────────┼─────────┼──────────────┼─────────┤
│ 0xAA    │ 0x10-1F │ 0-32      │ ID(1)+LEN(1)+N  │ CRC-8   │ Segurança    │ Anti-   │
│         │         │           │                 │ SMBUS   │ (módulo      │ replay  │
│         │         │           │                 │ 0x07    │ Security)    │         │
└─────────┴─────────┴───────────┴─────────────────┴─────────┴──────────────┴─────────┘
```

**NOTA:** O HMAC e o SEQ são geridos pelo módulo `Security/` e NÃO fazem parte da estrutura `TLVMessage`. São acrescentados após a serialização.

## 3.2 Campos

| Campo      | Tamanho    | Descrição |
|-----------|------------|-----------|
| START     | 1 byte     | Byte de sincronização (0xAA) |
| MSG ID    | 1 byte     | Tipo de mensagem (0x10-0x1F) |
| TLV COUNT | 1 byte     | Número de campos TLV (0-32) |
| TLV FIELDS| Variável   | Campos TLV: ID(1) + LEN(1) + DATA(N) |
| CRC8      | 1 byte     | CRC8 SMBUS (polinómio 0x07) |
| HMAC      | 32 bytes   | Opcional, gerido pelo módulo Security |
| SEQ       | 4 bytes    | Opcional, anti-replay, gerido pelo Security |

## 3.3 Tamanhos

| Parâmetro         | Valor |
|------------------|-------|
| Tamanho mínimo   | 4 bytes (START + MSGID + COUNT + CRC8) |
| Tamanho máximo   | 1024 bytes (serializado, sem HMAC/SEQ) |
| Máximo de TLVs   | 32 por mensagem |
| Máximo de payload por TLV | 32 bytes (normal) ou 128 bytes (vídeo) |

---

# 4. Formato TLV Individual

Cada campo TLV é serializado de forma compacta:

```text
[ID (1 byte)] [LEN (1 byte)] [DATA (LEN bytes)]
```

## 4.1 Exemplo

Um campo de rotação (float = 1.0f):

```text
0x30 0x04 0x00 0x00 0x80 0x3F
│    │    └─────┴─────┴─────┘
│    │           │
│    LEN=4       DATA=1.0f (little-endian: 0x3F800000)
│
ID=0x30 (FLD_ROLL)
```

## 4.2 Regras

* ID é sempre 1 byte (uint8_t);
* LEN é sempre 1 byte (uint8_t), representando o número de bytes de DATA;
* DATA é Little-endian para dados numéricos;
* LEN=0 indica campo sem payload (apenas ID).

---

# 5. CRC8

## 5.1 Algoritmo

O CRC8 utilizado é o CRC8 SMBUS com polinómio 0x07.

```text
Polinómio: x⁸ + x⁷ + x⁶ + x⁴ + x² + 1 (0x07)
Seed: 0x00
Refin: false
Refout: false
XorOut: 0x00
```

## 5.2 Cálculo

O CRC8 é calculado sobre todos os bytes da mensagem desde START até ao último byte TLV:

```text
CRC8 = CRC8(START + MSG_ID + TLV_COUNT + TLV_FIELDS)
```

## 5.3 Tabela de Lookup

A implementação deve utilizar uma tabela de lookup para eficiência:

```cpp
static const uint8_t CRC8_TABLE[256] = {
    0x00, 0x07, 0x0E, 0x09, 0x1C, 0x1B, 0x12, 0x15,
    0x38, 0x3F, 0x36, 0x31, 0x24, 0x23, 0x2A, 0x2D,
    // ... tabela completa (256 entradas)
};
```

## 5.4 Validação

O receptor calcula o CRC8 sobre os bytes recebidos e compara com o CRC8 recebido. Se forem diferentes, a mensagem é descartada.

---

# 6. HMAC (Opcional)

## 6.1 Descrição

O HMAC (Hash-based Message Authentication Code) de 32 bytes é gerido pelo módulo `Security/` após a serialização da mensagem TLV.

## 6.2 Função

* autenticação do remetente (apenas módulos autorizados podem gerar HMAC válido);
* integridade adicional (qualquer alteração invalida o HMAC);
* proteção contra injeção de mensagens falsificadas.

## 6.3 Implementação

* o HMAC é calculado sobre a mensagem TLV serializada (START até CRC8);
* a chave é partilhada entre os módulos autorizados;
* o algoritmo é definido pelo módulo Security (ex: HMAC-SHA256 truncado para 32 bytes);
* o HMAC é opcional — a sua presença é indicada por flag externa ao TLV.

## 6.4 Nota

O HMAC NÃO faz parte da estrutura `TLVMessage`. É acrescentado após a serialização e removido antes da desserialização.

---

# 7. SEQ (Anti-Replay)

## 7.1 Descrição

O SEQ (Sequence Number) de 4 bytes é gerido pelo módulo `Security/` para prevenir ataques de replay.

## 7.2 Função

* cada mensagem possui um SEQ único e crescente;
* o接收or verifica se o SEQ é superior ao último SEQ válido;
* mensagens com SEQ inferior ou igual são descartadas (possível replay);
* o SEQ é reiniciado a cada sessão ou reinicialização.

## 7.3 Implementação

* o SEQ é calculado como um contador 32-bit crescente;
* cada módulo mantém o último SEQ válido por remetente;
* mensagens com SEQ fora da janela aceitável são descartadas;
* o SEQ é opcional — a sua presença é indicada por flag externa ao TLV.

---

# 8. IDs de Mensagem (MsgID)

```text
ID      Constante           Descrição
─────────────────────────────────────────────────────────────
0x10    MSG_HEARTBEAT       Heartbeat periódico (todos os grupos)
0x11    MSG_TELEMETRY       Dados de telemetria (sensores, voo, estado)
0x12    MSG_COMMAND         Comandos (RaspberryPi → periféricos)
0x13    MSG_ACK             Confirmação de receção
0x14    MSG_FAILSAFE        Ativação/desativação FailSafe/FailSecure
0x15    MSG_DEBUG           Debug (prioridade dinâmica)
0x16    MSG_VIDEO           Dados de vídeo (streaming)
0x17    MSG_SHELL_CMD       Comando shell remoto (diagnóstico)
0x18    MSG_SI_DATA         Dados em unidades SI
0x19    MSG_STATE_BROADCAST Broadcast de estado do grupo
0x1A    MSG_ACTUATOR_FB     Feedback de atuadores
0x1B    MSG_SAFETY_DATA     Dados de segurança (ESP32-FS only)
0x1C    MSG_SYNC_REQ        Pedido de sincronização temporal
0x1D    MSG_SYNC_RESP       Resposta de sincronização
0x1E    MSG_CONFIG          Dados de configuração/parametrização
0x1F    MSG_RESERVED        Reservado para expansão futura
```

## 8.1 Validação

```cpp
constexpr bool isValidMsgID(uint8_t id) {
    return (id >= 0x10) && (id <= 0x1F);
}
```

---

# 9. IDs de Campos TLV

A tabela completa de IDs de campos TLV encontra-se em `shared/TLV_DEFINITIONS` §10.

## 9.1 Resumo dos Intervalos

| Intervalo  | Domínio |
|-----------|---------|
| 0x20-0x2F | GPS / Navegação |
| 0x30-0x3F | IMU / Atitude |
| 0x40-0x4F | Estado de Voo |
| 0x50-0x5F | Energia |
| 0x60-0x6F | Temperatura |
| 0x70-0x7F | Sistema |
| 0x80-0x8F | Atuadores |
| 0x90-0x9F | Sensores |
| 0xA1-0xAF | Failsafe |
| 0xB0-0xBF | Vídeo |

## 9.2 Validação

```cpp
constexpr bool isValidFieldID(uint8_t id) {
    return (id >= 0x20 && id <= 0x7F) ||
           (id >= 0xA1 && id <= 0xFF);
}
```

---

# 10. IDs de Comando

A tabela completa de IDs de comando encontra-se em `shared/TLV_DEFINITIONS` §11.

## 10.1 Resumo dos Intervalos

| Intervalo  | Tipo |
|-----------|------|
| 0xC0-0xCF | Comandos Básicos |
| 0xD0-0xDF | Comandos de Controlo |
| 0xE0-0xEF | Comandos Avançados |
| 0xF0-0xFF | Comandos de Navegação |

---

# 11. Conversão de Dados

## 11.1 Little-Endian

Todos os dados numéricos são serializados em **little-endian** (byte menos significativo primeiro).

| Tipo      | Tamanho | Exemplo (1.0f) |
|-----------|---------|----------------|
| float     | 4 bytes | 0x00 0x00 0x80 0x3F |
| int32_t   | 4 bytes | Conforme valor |
| uint32_t  | 4 bytes | Conforme valor |
| uint16_t  | 2 bytes | Conforme valor |
| uint8_t   | 1 byte  | Conforme valor |

## 11.2 Funções de Conversão

| Função                                | Descrição             |
| --------------------------------------|-----------------------|
| `floatToBytes()` / `bytesToFloat()`   | Conversão de float    |
| `int32ToBytes()` / `bytesToInt32()`   | Conversão de int32_t  |
| `uint32ToBytes()` / `bytesToUint32()` | Conversão de uint32_t |
| `uint16ToBytes()` / `bytesToUint16()` | Conversão de uint16_t |

---

# 12. Estruturas de Dados

## 12.1 TLVField

| Campo  | Tipo        | Tamanho | Descrição |
| ------ | ----------- | ------- | --------- |
| `id`   | uint8_t     | 1 byte  | Identificador do campo |
| `len`  | uint8_t     | 1 byte  | Comprimento do payload |
| `data` | uint8_t[32] | 32 bytes max | Payload do campo |

## 12.2 TLVVideoField

| Campo  | Tipo         | Tamanho | Descrição |
| ------ | ------------ | ------- | --------- |
| `id`   | uint8_t      | 1 byte  | Identificador do campo |
| `len`  | uint8_t      | 1 byte  | Comprimento do payload |
| `data` | uint8_t[128] | 128 bytes max | Payload de vídeo |

## 12.3 TLVMessage

| Campo      | Tipo         | Tamanho       | Descrição |
| ---------- | ------------ | ------------- | --------- |
| `start`    | uint8_t      | 1 byte        | Byte de sincronização (0xAA) |
| `msgID`    | uint8_t      | 1 byte        | Identificador do tipo de mensagem |
| `tlvCount` | uint8_t      | 1 byte        | Número de campos TLV |
| `tlvs`     | TLVField[32] | Até 32 campos | Campos TLV |
| `crc8`     | uint8_t      | 1 byte        | CRC8 SMBUS |

---

# 13. Parser FSM

## 13.1 Estados

| Estado                  | Descrição |
|------------------------|-----------|
| PARSER_WAIT_START      | Aguarda START_BYTE (0xAA) |
| PARSER_WAIT_MSGID      | Aguarda e valida msgID |
| PARSER_WAIT_TLVCOUNT   | Aguarda número de TLVs |
| PARSER_WAIT_TLV_ID     | Aguarda ID do TLV atual |
| PARSER_WAIT_TLV_LEN    | Aguarda comprimento do payload |
| PARSER_WAIT_TLV_DATA   | Acumula bytes do payload |
| PARSER_WAIT_CHECKSUM   | Aguarda CRC8 e valida |

## 13.2 Fluxo

```text
WAIT_START ──(0xAA)──→ WAIT_MSGID ──(msgID válido)──→ WAIT_TLVCOUNT
                                               |           │
                                        (tlvCount==0)  (tlvCount>0)
                                               ↓           ↓
                                         WAIT_CHECKSUM   WAIT_TLV_ID
                                               ↑              │
                                               │              ↓
                                         (após CRC)    WAIT_TLV_LEN
                                               ↑              │
                                               │              ↓
                                         (último TLV)   WAIT_TLV_DATA
                                               ↑              │
                                               └──────────────┘
```

## 13.3 Códigos de Erro

| Erro                       | Descrição |
|---------------------------|-----------|
| PARSER_OK                 | Sem erro |
| PARSER_ERR_OVERFLOW       | Buffer interno excedido |
| PARSER_ERR_TIMEOUT        | Gap entre bytes excedeu timeout |
| PARSER_ERR_INVALID_START  | START_BYTE ou msgID inválido |
| PARSER_ERR_CHECKSUM       | CRC8 inválido |
| PARSER_ERR_TLV_COUNT      | tlvCount > MAX_TLV_FIELDS |
| PARSER_ERR_TLV_LEN        | LEN > MAX_TLV_VIDEO_DATA |

## 13.4 Características de Segurança

* **Timeout automático** — gap entre bytes excede maxFrameGapMicros → parser reinicia;
* **Proteção contra overflow** — rawOffset < MAX_MESSAGE_SIZE;
* **Validação em tempo real** — cada byte é validado à medida que chega;
* **Reset automático em erro** — qualquer erro reinicia o parser;
* **Fallback** — millis()*1000 quando esp_timer_get_time() não disponível.

---

# 14. TLVBuilder

## 14.1 Interface Fluente

O TLVBuilder facilita a construção de mensagens:

```cpp
TLVBuilder builder;
builder.addFloat(FLD_ROLL, 0.12f);
builder.addFloat(FLD_PITCH, -0.05f);
builder.addInt32(FLD_GPS_LAT, 412345678);
builder.addUint8(FLD_STATE, SYS_STATE_FLYING);
builder.addUint8(FLD_MODE, MODE_STABILIZE);

uint8_t buffer[MAX_MESSAGE_SIZE];
size_t len = builder.build(MSG_TELEMETRY, buffer, sizeof(buffer));
```

## 14.2 Métodos Disponíveis

| Método              | Tipo      | Descrição |
|--------------------|-----------|-----------|
| `addFloat()`       | float     | Campo de 4 bytes |
| `addInt32()`       | int32_t   | Campo de 4 bytes |
| `addUint32()`      | uint32_t  | Campo de 4 bytes |
| `addUint16()`      | uint16_t  | Campo de 2 bytes |
| `addUint8()`       | uint8_t   | Campo de 1 byte |
| `addBytes()`       | uint8_t[] | Campo de N bytes |
| `build()`          | —         | Serializa a mensagem completa |

---

# 15. Validação em Tempo de Compilação

| Função                  | Descrição                                              |
| ----------------------- | ------------------------------------------------------ |
| `isValidMsgID(id)`      | Verifica se o ID está no intervalo 0x10-0x1F           |
| `isValidFieldID(id)`    | Verifica se está nos intervalos reservados (0x20-0xFF) |

---

# 16. Constantes

| Constante             | Valor   | Descrição                                   |
| ----------------------|---------|---------------------------------------------|
| `START_BYTE`          | 0xAA    | Byte de sincronização (padrão 10101010)     |
| `PROTOCOL_VERSION_STR`| "3.0.0" | Versão do protocolo (Aerus)                 |
| `MAX_TLV_FIELDS`      | 32      | Número máximo de campos por mensagem        |
| `MAX_TLV_DATA`        | 32      | Tamanho máximo de payload normal (bytes)    |
| `MAX_TLV_VIDEO_DATA`  | 128     | Tamanho máximo de payload de vídeo (bytes)  |
| `MAX_MESSAGE_SIZE`    | 1024    | Tamanho máximo de uma mensagem serializada  |
| `MIN_MESSAGE_SIZE`    | 4       | Tamanho mínimo (START + MSGID + COUNT + CRC)|
| `CRC8_POLYNOMIAL`     | 0x07    | Polinómio CRC8 SMBUS                        |

---

# 17. Segurança e Robustez

| Mecanismo                  | Descrição |
|---------------------------|-----------|
| START_BYTE = 0xAA         | Padrão binário 10101010, facilmente distinguível de ruído |
| CRC8 SMBUS (0x07)         | Deteta erros de 1-2 bits, rajadas ≤8 bits |
| HMAC (32 bytes)           | Autenticação do remetente via módulo Security |
| SEQ (4 bytes)             | Anti-replay, previne reenvio de mensagens capturadas |
| CAN CRC nativo (17-bit)   | Proteção física contra erros de transmissão |
| CAN ID + assinatura       | Identificação e autenticação no nível de transporte |
| Intervalos de IDs seguros | 0x20-0x7F e 0xA1-0xFF evitam colisão com ASCII de controlo |
| Limites máximos           | Previnem buffer overflow e alocações dinâmicas |
| Parser com timeout        | Recupera automaticamente de streams corrompidos |
| Reset automático em erro  | Qualquer erro reinicia o parser para a próxima mensagem |
| Sem alocações dinâmicas   | Toda a memória é estática – comportamento determinístico |

---

# 18. Exemplo: Construir e Enviar

```cpp
// Construir mensagem de telemetria
TLVBuilder builder;
builder.addFloat(FLD_ROLL, 0.12f);
builder.addFloat(FLD_PITCH, -0x05f);
builder.addFloat(FLD_YAW, 1.57f);
builder.addInt32(FLD_GPS_LAT, 412345678);
builder.addInt32(FLD_GPS_LON, -82345678);
builder.addUint8(FLD_STATE, SYS_STATE_FLYING);
builder.addUint8(FLD_MODE, MODE_STABILIZE);

uint8_t buffer[MAX_MESSAGE_SIZE];
size_t len = builder.build(MSG_TELEMETRY, buffer, sizeof(buffer));

// Enviar via CAN FD
can_send(CAN_ID_TELEMETRY, buffer, len);
```

---

# 19. Exemplo: Receber e Processar

```cpp
Parser parser;

void onCANFrame(const uint8_t* data, size_t len) {
    for (size_t i = 0; i < len; i++) {
        if (parser.feed(data[i])) {
            TLVMessage* msg = parser.getMessage();

            if (msg->msgID == MSG_COMMAND) {
                for (uint8_t i = 0; i < msg->tlvCount; i++) {
                    switch (msg->tlvs[i].id) {
                        case CMD_SET_ROLL:
                            float roll = bytesToFloat(msg->tlvs[i].data);
                            break;
                        case CMD_SET_HEADING:
                            float heading = bytesToFloat(msg->tlvs[i].data);
                            break;
                    }
                }
            }

            parser.acknowledge();
        }
    }
}
```

---

# 20. Fragmentação CAN FD

Quando uma mensagem TLV excede o payload máximo de um frame CAN FD (64 bytes), deverá ser fragmentada.

## 20.1 Espaço Disponível

```text
Espaço CAN FD = 64 bytes
Overhead CAN FD ≈ 8-12 bytes
Espaço TLV ≈ 52-56 bytes

Mensagem mínima = START(1) + MSGID(1) + COUNT(1) + CRC8(1) = 4 bytes
Espaço para FIELDS ≈ 48 bytes mínimo por frame
```

## 20.2 Regras

* o primeiro fragmento contém o cabeçalho TLV completo;
* os fragmentos seguintes contêm apenas campos TLV;
* o接收or reconstrói a mensagem antes de processar;
* fragmento perdido → mensagem inteira descartada;
* timeout entre fragmentos = timeout normal.

---

# 21. Referências

- SHARED-TLV — Definições do Protocolo TLV
- SHARED-CAN-IDS — Alocação de CAN IDs
- COM-001 — Arquitetura de Comunicação
- COM-003 — Gestor de Mensagens
- COM-004 — Prioridades e Filas
- COM-008 — CAN Bus
- COM-010 — Integridade
- SYS-003 — Arquitetura de Software
- SEC — Especificações de Segurança
