# TLV_DEFINITIONS — Protocolo TLV do Aerus

| Campo             | Valor                              |
| ----------------- | ---------------------------------- |
| **Código**        | SHARED-TLV                         |
| **Título**        | Definições do Protocolo TLV        |
| **Versão**        | 1.0                                |
| **Estado**        | Em Desenvolvimento                 |
| **Autor**         | ShegaPT                            |
| **Classificação** | Protocolo Partilhado               |

---

# 1. Objetivo

O presente documento define o protocolo de comunicação TLV (Type-Length-Value) utilizado pelo sistema Aerus para todas as trocas de informação entre Grupos Computacionais.

O protocolo constitui a camada de aplicação de todas as mensagens transmitidas entre os diferentes domínios computacionais, independentemente do meio de transporte utilizado (CAN FD, UART, SPI ou I2C).

O TLV é um protocolo completo, seguro e autónomo. O CAN FD constitui exclusivamente o canal de transporte. O CRC e a integridade do CAN são complementares ao CRC16 e HMAC do TLV, não substitutos.

---

# 2. Princípios

O protocolo TLV do Aerus baseia-se nos seguintes princípios:

* segurança por desenho (CRC8, HMAC, anti-replay);
* determinismo (sem alocações dinâmicas);
* extensibilidade (novos IDs sem alterar a estrutura);
* validação em tempo real (parser byte-a-byte);
* compatibilidade com qualquer meio serial (CAN FD, UART, SPI, I2C);
* independência do meio de transporte;
* versionamento semântico (MAJOR.MINOR.PATCH).

---

# 3. Formato da Mensagem no Canal

A mensagem serializada é composta pelos seguintes campos, transmistidos consecutivamente no meio de transporte:

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

---

# 4. Formato TLV Individual

Cada campo TLV é serializado de forma compacta:

```text
[ID (1 byte)] [LEN (1 byte)] [DATA (LEN bytes)]
```

**Exemplo:** Um campo de rotação (float) seria:

```text
0x30 0x04 0x00 0x00 0x80 0x3F
│    │    └─────┴─────┴─────┘
│    │           │
│    LEN=4       DATA=1.0f (little-endian)
│
ID=0x30 (FLD_ROLL)
```

---

# 5. Constantes

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

# 6. Estruturas de Dados

## TLVField

Campos TLV padrão para dados normais:

| Campo  | Tipo        | Tamanho      | Descrição              |
| ------ | ----------- | ------------ | ---------------------- |
| `id`   | uint8_t     | 1 byte       | Identificador do campo |
| `len`  | uint8_t     | 1 byte       | Comprimento do payload |
| `data` | uint8_t[32] | 32 bytes max | Payload do campo       |

## TLVVideoField

Campos TLV para dados de vídeo (payload estendido):

| Campo  | Tipo         | Tamanho       | Descrição              |
| ------ | ------------ | ------------- | ---------------------- |
| `id`   | uint8_t      | 1 byte        | Identificador do campo |
| `len`  | uint8_t      | 1 byte        | Comprimento do payload |
| `data` | uint8_t[128] | 128 bytes max | Payload de vídeo       |

## TLVMessage

Mensagem TLV completa (antes de HMAC e SEQ):

| Campo      | Tipo         | Tamanho       | Descrição                         |
| ---------- | ------------ | ------------- | --------------------------------- |
| `start`    | uint8_t      | 1 byte        | Byte de sincronização (0xAA)      |
| `msgID`    | uint8_t      | 1 byte        | Identificador do tipo de mensagem |
| `tlvCount` | uint8_t      | 1 byte        | Número de campos TLV              |
| `tlvs`     | TLVField[32] | Até 32 campos | Campos TLV                        |
| `crc8`     | uint8_t      | 1 byte        | CRC8 SMBUS                        |

---

# 7. Funções de Conversão (Little-Endian)

| Função                                | Descrição             |
| --------------------------------------|-----------------------|
| `floatToBytes()` / `bytesToFloat()`   | Conversão de float    |
| `int32ToBytes()` / `bytesToInt32()`   | Conversão de int32_t  |
| `uint32ToBytes()` / `bytesToUint32()` | Conversão de uint32_t |
| `uint16ToBytes()` / `bytesToUint16()` | Conversão de uint16_t |

Todos os dados numéricos são serializados em **little-endian**.

---

# 8. Validação em Tempo de Compilação

| Função                  | Descrição                                              |
| ----------------------- | ------------------------------------------------------ |
| `isValidMsgID(id)`      | Verifica se o ID está no intervalo 0x10-0x1F           |
| `isValidFieldID(id)`    | Verifica se está nos intervalos reservados (0x20-0xFF) |

---

# 9. IDs de Mensagem (MsgID)

```text
ID      Constante           Descrição
───────────────────────────────────────────────────────────────────────
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

---

# 10. IDs de Campos TLV (Campos de Dados)

## 10.1 GPS / Navegação (0x20-0x2F)

| ID        | Constante      | Tipo     | Descrição                          |
| --------- | -------------- | -------- | ---------------------------------- |
| 0x20      | FLD_GPS_LAT    | int32_t  | Latitude (graus × 10⁷)             |
| 0x21      | FLD_GPS_LON    | int32_t  | Longitude (graus × 10⁷)            |
| 0x22      | FLD_GPS_ALT    | int32_t  | Altitude GPS (mm)                  |
| 0x23      | FLD_GPS_SPEED  | uint16_t | Velocidade GPS (cm/s)              |
| 0x24      | FLD_GPS_SATS   | uint8_t  | Número de satélites                |
| 0x25      | FLD_GPS_LINK   | uint8_t  | Qualidade do link GPS (%)          |
| 0x26      | FLD_GPS_HDOP   | uint16_t | HDOP (precisão horizontal ×100)    |
| 0x27      | FLD_GPS_VDOP   | uint16_t | VDOP (precisão vertical ×100)      |
| 0x28      | FLD_GPS_FIX    | uint8_t  | Tipo de fix (0=Nenhum, 2=2D, 3=3D) |
| 0x29      | FLD_GPS_COURSE | uint16_t | Rumo GPS (centésimas de grau)      |
| 0x2A-0x2F | Reservado      |          | Expansão futura                    |

## 10.2 IMU / Atitude (0x30-0x3F)

| ID      | Constante       | Tipo  | Descrição                      |
| ------- | --------------- | ----- | ------------------------------ |
| 0x30    | FLD_ROLL        | float | Ângulo de rolamento (rad)      |
| 0x31    | FLD_PITCH       | float | Ângulo de inclinação (rad)     |
| 0x32    | FLD_YAW         | float | Ângulo de guinada (rad)        |
| 0x33    | FLD_VX          | float | Velocidade linear X (m/s)      |
| 0x34    | FLD_VY          | float | Velocidade linear Y (m/s)      |
| 0x35    | FLD_VZ          | float | Velocidade linear Z (m/s)      |
| 0x36    | FLD_HEADING     | float | Rumo magnético (graus)         |
| 0x37    | FLD_ROLL_RATE   | float | Velocidade angular roll (°/s)  |
| 0x38    | FLD_PITCH_RATE  | float | Velocidade angular pitch (°/s) |
| 0x39    | FLD_YAW_RATE    | float | Velocidade angular yaw (°/s)   |
| 0x3A    | FLD_ACC_X       | float | Aceleração linear X (m/s²)     |
| 0x3B    | FLD_ACC_Y       | float | Aceleração linear Y (m/s²)     |
| 0x3C    | FLD_ACC_Z       | float | Aceleração linear Z (m/s²)     |
| 0x3D    | FLD_MAG_X       | float | Campo magnético X (µT)         |
| 0x3E    | FLD_MAG_Y       | float | Campo magnético Y (µT)         |
| 0x3F    | FLD_MAG_Z       | float | Campo magnético Z (µT)         |

## 10.3 Estado de Voo (0x40-0x4F)

| ID        | Constante        | Tipo     | Descrição                  |
| --------- | ---------------- | -------- | -------------------------- |
| 0x40      | FLD_ALT_GPS      | float    | Altitude GPS (m)           |
| 0x41      | FLD_ALT_BARO     | float    | Altitude barométrica (m)   |
| 0x42      | FLD_VEL_GPS      | float    | Velocidade GPS (m/s)       |
| 0x43      | FLD_VEL_CALC     | float    | Velocidade por fusão (m/s) |
| 0x44      | FLD_LOOP_TIME    | uint16_t | Tempo do último loop (µs)  |
| 0x45      | FLD_CLIMB_RATE   | float    | Taxa de subida (m/s)       |
| 0x46      | FLD_GROUND_SPEED | float    | Velocidade terrestre (m/s) |
| 0x47      | FLD_AIRSPEED     | float    | Velocidade do ar (m/s)     |
| 0x48      | FLD_WIND_SPEED   | float    | Velocidade do vento (m/s)  |
| 0x49      | FLD_WIND_DIR     | float    | Direção do vento (graus)   |
| 0x4A      | FLD_FLIGHT_TIME  | uint32_t | Tempo de voo (segundos)    |
| 0x4B      | FLD_DIST_HOME    | uint32_t | Distância ao home (metros) |
| 0x4C-0x4F | Reservado        |          | Expansão futura            |

## 10.4 Energia (0x50-0x5F)

| ID        | Constante        | Tipo  | Descrição                   |
| --------- | ---------------- | ----- | --------------------------- |
| 0x50      | FLD_BATT_V       | float | Tensão da bateria (V)       |
| 0x51      | FLD_BATT_A       | float | Corrente (A)                |
| 0x52      | FLD_BATT_W       | float | Potência (W)                |
| 0x53      | FLD_BATT_CHG     | float | Carga consumida (Ah)        |
| 0x54      | FLD_BATT_SOC     | float | Estado de carga (0-1)       |
| 0x55      | FLD_BATT_TEMP    | float | Temperatura da bateria (°C) |
| 0x56      | FLD_BATT_REMAIN  | float | Energia restante (Wh)       |
| 0x57      | FLD_ESC1_CURRENT | float | Corrente ESC1 (A)           |
| 0x58      | FLD_ESC2_CURRENT | float | Corrente ESC2 (A)           |
| 0x59      | FLD_ESC3_CURRENT | float | Corrente ESC3 (A)           |
| 0x5A      | FLD_ESC4_CURRENT | float | Corrente ESC4 (A)           |
| 0x5B-0x5F | Reservado        |       | Expansão futura             |

## 10.5 Temperatura (0x60-0x6F)

| ID        | Constante        | Tipo  | Descrição                    |
| --------- | ---------------- | ----- | ---------------------------- |
| 0x60      | FLD_TEMP1        | float | Temperatura ESC1 (°C)        |
| 0x61      | FLD_TEMP2        | float | Temperatura ESC2 (°C)        |
| 0x62      | FLD_TEMP3        | float | Temperatura ESC3 (°C)        |
| 0x63      | FLD_TEMP4        | float | Temperatura ESC4 (°C)        |
| 0x64      | FLD_ESP1_TEMP    | float | Temperatura ESP1 (°C)        |
| 0x65      | FLD_ESP2_TEMP    | float | Temperatura ESP2 (°C)        |
| 0x66      | FLD_ESP3_TEMP    | float | Temperatura ESP3 (°C)        |
| 0x67      | FLD_ESP4_TEMP    | float | Temperatura ESP4 (°C)        |
| 0x68      | FLD_RPI_TEMP     | float | Temperatura RaspberryPi (°C) |
| 0x69      | FLD_AMBIENT_TEMP | float | Temperatura ambiente (°C)    |
| 0x6A-0x6F | Reservado        |       | Expansão futura              |

## 10.6 Sistema (0x70-0x7F)

| ID        | Constante       | Tipo     | Descrição                            |
| --------- | --------------- | -------- | ------------------------------------ |
| 0x70      | FLD_STATE       | uint8_t  | Estado do sistema (SystemState)      |
| 0x71      | FLD_MODE        | uint8_t  | Modo de voo (FlightMode)             |
| 0x72      | FLD_ERRORS      | uint32_t | Mapa de bits de erros                |
| 0x73      | FLD_RX_LINK     | uint8_t  | Qualidade RX (%)                     |
| 0x74      | FLD_TX_LINK     | uint8_t  | Qualidade TX (%)                     |
| 0x75      | FLD_ESP1_LOAD   | uint8_t  | Carga CPU ESP1 (%)                   |
| 0x76      | FLD_ESP2_LOAD   | uint8_t  | Carga CPU ESP2 (%)                   |
| 0x77      | FLD_RPI_LOAD    | uint8_t  | Carga CPU RaspberryPi (%)            |
| 0x78      | FLD_UPTIME      | uint32_t | Tempo desde inicialização (segundos) |
| 0x79      | FLD_GROUPS_OK   | uint8_t  | Mapa de bits: grupos operacionais    |
| 0x7A      | FLD_BUS0_STATUS | uint8_t  | Estado do bus operacional            |
| 0x7B      | FLD_BUS1_STATUS | uint8_t  | Estado do bus de segurança           |
| 0x7C-0x7F | Reservado       |          | Expansão futura                      |

## 10.7 Atuadores (0x80-0x8F)

| ID        | Constante        | Tipo     | Descrição                 |
| --------- | ---------------- | -------- | ------------------------- |
| 0x80      | FLD_ACT_SERVO1   | uint16_t | Posição servo 1 (µs PWM)  |
| 0x81      | FLD_ACT_SERVO2   | uint16_t | Posição servo 2 (µs PWM)  |
| 0x82      | FLD_ACT_SERVO3   | uint16_t | Posição servo 3 (µs PWM)  |
| 0x83      | FLD_ACT_SERVO4   | uint16_t | Posição servo 4 (µs PWM)  |
| 0x84      | FLD_ACT_MOTOR1   | uint16_t | RPM motor 1               |
| 0x85      | FLD_ACT_MOTOR2   | uint16_t | RPM motor 2               |
| 0x86      | FLD_ACT_MOTOR3   | uint16_t | RPM motor 3               |
| 0x87      | FLD_ACT_MOTOR4   | uint16_t | RPM motor 4               |
| 0x88      | FLD_ACT_THROTTLE | float    | Throttle atual (0-1)      |
| 0x89      | FLD_ACT_FB_FLAGS | uint8_t  | Flags de feedback         |
| 0x8A      | FLD_ACT_HEALTH   | uint8_t  | Saúde do atuador (0-100%) |
| 0x8B-0x8F | Reservado        |          | Expansão futura           |

## 10.8 Sensores (0x90-0x9F)

| ID        | Constante           | Tipo    | Descrição                   |
| --------- | ------------------- | ------- | --------------------------- |
| 0x90      | FLD_SNS_GPS_HEALTH  | uint8_t | Saúde GPS (0-100%)          |
| 0x91      | FLD_SNS_IMU_HEALTH  | uint8_t | Saúde IMU (0-100%)          |
| 0x92      | FLD_SNS_BARO_HEALTH | uint8_t | Saúde barómetro (0-100%)    |
| 0x93      | FLD_SNS_MAG_HEALTH  | uint8_t | Saúde magnetómetro (0-100%) |
| 0x94      | FLD_SNS_AIRSPEED    | float   | Velocidade do ar (m/s)      |
| 0x95      | FLD_SNS_MAG_DECL    | float   | Declinação magnética (rad)  |
| 0x96      | FLD_SNS_VIBRATION   | float   | Nível de vibração (g)       |
| 0x97      | FLD_SNS_PRESSURE    | float   | Pressão atmosférica (Pa)    |
| 0x98      | FLD_SNS_HUMIDITY    | float   | Humidade relativa (%)       |
| 0x99-0x9F | Reservado           |         | Expansão futura             |

## 10.9 Failsafe (0xA1-0xAF)

| ID        | Constante       | Tipo     | Descrição                                 |
| --------- | --------------- | -------- | ----------------------------------------- |
| 0xA1      | FLD_FS_REASON   | uint8_t  | Razão (FailsafeReason)                    |
| 0xA2      | FLD_FS_ACTION   | uint8_t  | Ação (FailsafeAction)                     |
| 0xA3      | FLD_FS_STATE    | uint8_t  | Estado (1=ativo, 0=inativo)               |
| 0xA4      | FLD_FS_TIMEOUT  | uint32_t | Tempo limite da condição de failsafe (ms) |
| 0xA5      | FLD_FS_ATTEMPTS | uint8_t  | Tentativas de recuperação                 |
| 0xA6-0xAF | Reservado       |          | Expansão futura                           |

## 10.10 Vídeo (0xB0-0xBF)

| ID        | Constante          | Tipo      | Descrição                |
| --------- | ------------------ | --------- | ------------------------ |
| 0xB0      | FLD_VIDEO_FRAME_ID | uint16_t  | Número do frame          |
| 0xB1      | FLD_VIDEO_CHUNK_ID | uint8_t   | Índice do chunk          |
| 0xB2      | FLD_VIDEO_TOTAL    | uint8_t   | Total de chunks no frame |
| 0xB3      | FLD_VIDEO_PAYLOAD  | uint8_t[] | Dados de vídeo crus      |
| 0xB4-0xBF | Reservado          |           | Expansão futura          |

---

# 11. IDs de Comando (0xC0–0xFF)

## 11.1 Comandos Básicos (0xC0–0xCF)

| ID        | Constante          | Parâmetros           | Descrição                      |
| --------- | ------------------ | -------------------- | ------------------------------ |
| 0xC0      | CMD_ARM            | Nenhum               | Armar motores                  |
| 0xC1      | CMD_DISARM         | Nenhum               | Desarmar motores               |
| 0xC2      | CMD_SET_MODE       | uint8_t (FlightMode) | Mudar modo de voo              |
| 0xC3      | CMD_REBOOT         | Nenhum               | Reiniciar controlador          |
| 0xC4      | CMD_SHUTDOWN       | Nenhum               | Desligamento controlado        |
| 0xC5      | CMD_EMERGENCY_STOP | Nenhum               | Paragem de emergência imediata |
| 0xC6      | CMD_UPLOAD_CONFIG  | Config TLV           | Upload de configuração de voo  |
| 0xC7-0xCF | Reservado          |                      | Expansão futura                |

## 11.2 Comandos de Controlo (0xD0–0xDF)

| ID      | Constante           | Parâmetros              | Descrição |
|---------|---------------------|-------------------------|-----------|
| 0xD0    | CMD_SET_ALT_TARGET  | float (metros)          | Definir altitude alvo |
| 0xD1    | CMD_SET_THROTTLE    | float (0-1)             | Definir throttle |
| 0xD2    | CMD_SET_ROLL        | float (graus)           | Definir ângulo de roll |
| 0xD3    | CMD_SET_PITCH       | float (graus)           | Definir ângulo de pitch |
| 0xD4    | CMD_SET_YAW         | float (°/s)             | Definir velocidade de yaw |
| 0xD5    | CMD_SET_HEADING     | float (graus)           | Definir heading desejado |
| 0xD6    | CMD_SET_BANK_ANGLE  | float (graus)           | Definir ângulo de inclinação |
| 0xD7    | CMD_SET_ALT_SPEED   | float (m/s)             | Definir velocidade de subida/descida |
| 0xD8-0xDF | Reservado          |                         | Expansão futura |

## 11.3 Comandos Avançados (0xE0–0xEF)

| ID        | Constante          | Parâmetros           | Descrição                    |
| --------- | ------------------ | -------------------- | ---------------------------- |
| 0xE0      | CMD_SENSOR_CALIB   | Nenhum               | Calibrar sensores            |
| 0xE1      | CMD_ACTUATOR_CALIB | Nenhum               | Calibrar atuadores           |
| 0xE2      | CMD_SET_PARAM      | ID param + valor     | Definir parâmetro            |
| 0xE3      | CMD_GET_ALL        | Nenhum               | Pedir telemetria completa    |
| 0xE4      | CMD_INHIBIT_ACT    | uint8_t (ID atuador) | Inibir atuador específico    |
| 0xE5      | CMD_QUERY_STATE    | uint8_t (ID grupo)   | Pedir estado de um grupo     |
| 0xE6      | CMD_SET_SAFETY_LIM | Limites TLV          | Definir limites de segurança |
| 0xE7-0xEF | Reservado          |                      | Expansão futura              |

## 11.4 Comandos de Navegação (0xF0–0xFF)

| ID        | Constante           | Parâmetros             | Descrição                          |
| --------- | ------------------- | ---------------------- | ---------------------------------- |
| 0xF0      | CMD_NEXT_WAYPOINTS  | Lista TLV de waypoints | Enviar waypoints                   |
| 0xF1      | CMD_RTL             | Nenhum                 | Return To Land                     |
| 0xF2      | CMD_SET_POSITION    | lat, lon, alt          | Definir posição alvo               |
| 0xF3      | CMD_SET_HOME        | lat, lon, alt          | Definir posição de regresso (home) |
| 0xF4      | CMD_CLEAR_WAYPOINTS | Nenhum                 | Limpar lista de waypoints          |
| 0xF5-0xFF | Reservado           |                        | Expansão futura                    |

---

# 12. Enums de Suporte

## 12.1 PriorityLevel

| Valor | Constante      | Descrição                 |
| ----- | -------------- | ------------------------- |
| 0     | SUPER_CRITICAL | Nunca descartado          |
| 1     | CRITICAL       | Sempre transmitido        |
| 2     | HIGH           | Prioridade alta           |
| 3     | MEDIUM         | Prioridade normal         |
| 4     | LOW            | Pode ser atrasado         |
| 5     | SUPER_LOW      | Descartável se necessário |

## 12.2 SystemState

| Valor | Constante     | Descrição          |
| ----- | ------------- | ------------------ |
| 0     | SYS_BOOTING   | A arrancar         |
| 1     | SYS_IDLE      | Inativo            |
| 2     | SYS_READY     | Pronto para operar |
| 3     | SYS_FLYING    | Em voo             |
| 4     | SYS_LANDING   | Em aterragem       |
| 5     | SYS_EMERGENCY | Emergência ativa   |
| 6     | SYS_ERROR     | Estado de erro     |

## 12.3 FlightMode

| Valor | Constante      | Descrição        |
| ----- | -------------- | ---------------- |
| 0     | MODE_MANUAL    | Manual           |
| 1     | MODE_STABILIZE | Estabilizado     |
| 2     | MODE_AUTO      | Automático       |
| 3     | MODE_RTL       | Return To Launch |
| 4     | MODE_LOITER    | Loiter           |
| 5     | MODE_GUIDED    | Guiado           |
| 6     | MODE_FBWA      | Fly-By-Wire A    |
| 7     | MODE_FBWB      | Fly-By-Wire B    |
| 8     | MODE_CIRCLE    | Circular         |

## 12.4 FailsafeReason

| Valor | Constante          | Descrição                      |
| ----- | ------------------ | ------------------------------ |
| 0     | FS_NONE            | Sem razão                      |
| 1     | FS_BATTERY_LOW     | Bateria baixa                  |
| 2     | FS_BATTERY_CRIT    | Bateria crítica                |
| 3     | FS_LINK_LOST       | Perda de link                  |
| 4     | FS_GPS_LOST        | Perda de GPS                   |
| 5     | FS_SENSOR_FAIL     | Falha de sensor                |
| 6     | FS_ACTUATOR_FAIL   | Falha de atuador               |
| 7     | FS_COMM_LOST       | Perda de comunicação           |
| 8     | FS_OVERSpeed       | Velocidade excessiva           |
| 9     | FS_TILT_ANGLE      | Ângulo de inclinação excessivo |
| 10    | FS_ALTITUDE        | Altitude fora de limites       |
| 11    | FS_PILOT_INPUT     | Entrada do piloto inválida     |
| 12    | FS_MANUAL_OVERRIDE | Substituição manual            |

## 12.5 FailsafeAction

| Valor | Constante        | Descrição          |
| ----- | ---------------- | ------------------ |
| 0     | ACTION_NONE      | Nenhuma ação       |
| 1     | ACTION_LOITER    | Loiter no local    |
| 2     | ACTION_RTL       | Return To Launch   |
| 3     | ACTION_LAND      | Aterragem          |
| 4     | ACTION_DESCEND   | Descida controlada |
| 5     | ACTION_TERMINATE | Terminar voo       |
| 6     | ACTION_HOVER     | Manter altitude    |

---

# 13. Fragmentação CAN FD

Quando uma mensagem TLV excede o payload máximo de um frame CAN FD (64 bytes), deverá ser fragmentada em múltiplos frames.

## 13.1 Cálculo do Espaço Disponível

```text
Espaço CAN FD = 64 bytes
Sobrecarga CAN FD = DLC + CAN ID + flags ≈ 8-12 bytes (depende da implementação)
Espaço TLV = 64 - Overhead ≈ 52-56 bytes para payload TLV

Mensagem TLV mínima = START(1) + MSGID(1) + COUNT(1) + CRC8(1) = 4 bytes
Espaço restante para FIELDS = 52 - 4 = 48 bytes mínimo por frame
```

## 13.2 Estrutura de Fragmentação

| Campo               | Tamanho  | Descrição                           |
| ------------------- | -------- | ----------------------------------- |
| Índice do Fragmento | 1 byte   | Índice do fragmento (iniciado em 0) |
| Total de Fragmentos | 1 byte   | Total de fragmentos                 |
| Payload TLV         | Variável | Dados do TLV neste fragmento        |

## 13.3 Regras

* O primeiro fragmento contém o cabeçalho TLV completo (START + MSGID + COUNT + CRC8);
* Os fragmentos seguintes contêm apenas campos TLV;
* O recetor reconstrói a mensagem completa antes de processar;
* Se qualquer fragmento for perdido, a mensagem inteira é descartada;
* O timeout entre fragmentos é o mesmo que o timeout normal entre mensagens.

---

# 14. Segurança e Robustez

| Mecanismo                 | Descrição                                                  |
| ------------------------- | ---------------------------------------------------------- |
| START_BYTE = 0xAA         | Padrão binário 10101010, facilmente distinguível de ruído  |
| CRC8 SMBUS (0x07)         | Deteta erros de 1-2 bits, rajadas ≤8 bits                  |
| HMAC (32 bytes)           | Autenticação do remetente via módulo Security              |
| SEQ (4 bytes)             | Anti-replay, previne reenvio de mensagens capturadas       |
| CAN CRC nativo (17-bit)   | Proteção física contra erros de transmissão                |
| CAN ID + assinatura       | Identificação e autenticação no nível de transporte        |
| Intervalos de IDs seguros | 0x20-0x7F e 0xA1-0xFF evitam colisão com ASCII de controlo |
| Limites máximos           | Previnem transbordamento de buffer e alocações dinâmicas   |
| Parser com timeout        | Recupera automaticamente de streams corrompidos            |
| Reset automático em erro  | Qualquer erro reinicia o parser para a próxima mensagem    |
| Sem alocações dinâmicas   | Toda a memória é estática – comportamento determinístico   |

---

# 15. Parser FSM (Máquina de Estados)

O parser reconstrói mensagens TLV a partir de um fluxo contínuo de bytes.

## 15.1 Estados

| Estado               | Descrição                      |
| -------------------- | ------------------------------ |
| PARSER_WAIT_START    | Aguarda START_BYTE (0xAA)      |
| PARSER_WAIT_MSGID    | Aguarda e valida msgID         |
| PARSER_WAIT_TLVCOUNT | Aguarda número de TLVs         |
| PARSER_WAIT_TLV_ID   | Aguarda ID do TLV atual        |
| PARSER_WAIT_TLV_LEN  | Aguarda comprimento do payload |
| PARSER_WAIT_TLV_DATA | Acumula bytes do payload       |
| PARSER_WAIT_CHECKSUM | Aguarda CRC8 e valida          |

## 15.2 Fluxo

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

## 15.3 Códigos de Erro

| Erro                     | Descrição                       |
| ------------------------ | ------------------------------- |
| PARSER_OK                | Sem erro                        |
| PARSER_ERR_OVERFLOW      | Buffer interno excedido         |
| PARSER_ERR_TIMEOUT       | Gap entre bytes excedeu timeout |
| PARSER_ERR_INVALID_START | START_BYTE ou msgID inválido    |
| PARSER_ERR_CHECKSUM      | CRC8 inválido                   |
| PARSER_ERR_TLV_COUNT     | tlvCount > MAX_TLV_FIELDS       |
| PARSER_ERR_TLV_LEN       | LEN > MAX_TLV_VIDEO_DATA        |

## 15.4 Características de Segurança

* **Timeout automático** — Se o gap entre bytes exceder maxFrameGapMicros, o parser reinicia;
* **Proteção contra transbordamento de buffer** — Verifica rawOffset < MAX_MESSAGE_SIZE;
* **Validação em tempo real** — Cada byte é validado à medida que chega;
* **Reset automático em erro** — Qualquer erro faz o parser reiniciar, pronto para a próxima mensagem;
* **Fallback para não-ESP32** — Timeout usando millis()*1000 quando esp_timer_get_time() não disponível.

---

# 16. TLVBuilder (Interface Fluente)

O TLVBuilder facilita a construção de mensagens com interface fluente:

```cpp
TLVBuilder builder;
builder.addFloat(FLD_ROLL, 0.12f);
builder.addFloat(FLD_PITCH, -0.05f);
builder.addInt32(FLD_GPS_LAT, 412345678);
builder.addUint8(FLD_STATE, SYS_STATE_FLYING);
builder.addUint8(FLD_MODE, MODE_STABILIZE);

uint8_t buffer[MAX_MESSAGE_SIZE];
size_t len = builder.build(MSG_TELEMETRY, buffer, sizeof(buffer));

// Enviar via CAN FD, UART, ou outro meio serial
can_send(buffer, len);
```

---

# 17. Exemplo: Receber e Processar

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

# 18. Observações Finais

* O protocolo TLV é **simbiotico** — todos os componentes dependem dele para funcionar em conjunto;
* Qualquer alteração AFETA todo o sistema;
* O CAN FD constitui exclusivamente o canal de transporte — o TLV é autónomo;
* Debug e telemetria podem ser priorizados dinamicamente conforme o estado do sistema;
* Mensagens podem ser transmitidas via CAN FD, UART, SPI, I2C, ou qualquer meio serial confiável;
* Os arquivos .h e .cpp devem ser incluídos em todos os Grupos Computacionais conforme a arquitetura modular;
* A versão semântica (MAJOR.MINOR.PATCH) deve ser atualizada sempre que existam alterações incompatíveis.

---

# 19. Referências

- SHARED-CAN-IDS — Alocação de CAN IDs
- COM-001 — Arquitetura de Comunicação
- COM-002 — Protocolo TLV
- COM-008 — CAN Bus
- HW-006 — Interfaces de Comunicação
- SYS-003 — Arquitetura de Software
- SEC — Especificações de Segurança
