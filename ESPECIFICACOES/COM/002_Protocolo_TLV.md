# COM-002 — Protocolo TLV

| Campo | Valor |
|---|---|
| **Código** | COM-002 |
| **Título** | Protocolo TLV |
| **Versão** | 2.0 |
| **Estado** | Aprovado para implementação |
| **Autor** | ShegaPT |
| **Classificação** | Especificação de Comunicação |

---

# 1. Objectivo

O presente documento especifica o protocolo TLV (Type-Length-Value) **exclusivamente para as redes CAN** (CAN-Intra-Grupo, CAN-Principal e CAN-FailSafe). Define ainda, em anexos separados e normativos, o enquadramento do INTERCONNECT FABRIC (Anexo A) e o enquadramento da RJ45-Privada RS (Anexo B), para que jamais se confundam com TLV.

Regra estrutural: **TLV só existe em CAN.** O FABRIC usa quadros IPC próprios. A RJ45-Privada RS usa enquadramento série próprio. Qualquer transporte de TLV sobre RJ45 é apenas encapsulamento policiado pelo Router CAN↔RJ45 (COM-003), nunca TLV nativo no ar.

---

# 2. Princípios

* Estrutura fixa e determinística: START (0xAA) + MSG_ID + COUNT + FIELDS + CRC8; sem alocações dinâmicas.
* HMAC (32 B) e SEQ (4 B) acrescentados pelo módulo de segurança após serialização; não integram a estrutura base.
* CRC8 SMBUS (polinómio 0x07) obrigatório em todas as mensagens CAN.
* Little-endian para serialização numérica.
* Até 32 campos por mensagem; até 64 B por quadro CAN-FD com fragmentação transparente.
* **Proibição de vídeo pesado em TLV**: nenhum campo transporta fotogramas; o intervalo de campos de vídeo encontra-se revogado excepto para descritores de estado.
* Parser FSM byte-a-byte com temporização, protecção contra transbordo e reinicialização automática.

---

# 3. Formato da mensagem TLV (só CAN)

```
┌────────┬────────┬───────────┬──────────────┬───────┬────────────┬───────┐
│ START  │ MSG_ID │ COUNT     │ FIELDS       │ CRC8  │ HMAC (32B) │ SEQ   │
│ 1 B    │ 1 B    │ 1 B       │ variável     │ 1 B   │ opcional   │ 4Bopc │
│ 0xAA   │0x10-1F │ 0-32      │ ID(1)+LEN(1) │ SMBUS │ segurança  │ anti- │
│        │        │           │ +DATA(LEN)   │ 0x07  │            │repet. │
└────────┴────────┴───────────┴──────────────┴───────┴────────────┴───────┘
```

| Campo | Tamanho | Descrição |
|---|---|---|
| START | 1 B | Sincronização, sempre 0xAA (padrão 10101010) |
| MSG_ID | 1 B | Tipo de mensagem, 0x10–0x1F |
| COUNT | 1 B | Número de campos TLV, 0–32 |
| FIELDS | Variável | Cada campo: ID(1 B) + LEN(1 B) + DATA(LEN B) |
| CRC8 | 1 B | CRC8 SMBUS calculado sobre START…último byte de FIELDS |
| HMAC | 32 B | Opcional, gerido pelo módulo de segurança |
| SEQ | 4 B | Opcional, anti-repetição, gerido pelo módulo de segurança |

| Parâmetro | Valor |
|---|---|
| Tamanho mínimo | 4 B (START+MSG_ID+COUNT+CRC8) |
| Tamanho máximo serializado | 1024 B (antes de fragmentação; fragmentado em quadros ≤64 B) |
| Máximo de campos | 32 por mensagem |
| Máximo por campo | 32 B (regra geral); proibidos campos de 128 B de vídeo |

---

# 4. Campo TLV individual

```
[ID 1B] [LEN 1B] [DATA LEN bytes, little-endian]
```

Exemplo numérico — rolamento 1,0f (0x3F800000 em little-endian `00 00 80 3F`):

```
0x30 0x04 0x00 0x00 0x80 0x3F
│    │    └── DATA = 1.0f ──┘
│    LEN = 4
ID = 0x30 (FLD_ROLL)
```

Regras: ID sempre 1 B; LEN sempre 1 B; LEN=0 admite campo sem carga; dados numéricos sempre little-endian.

---

# 5. CRC8

Algoritmo CRC8 SMBUS: polinómio 0x07 (`x⁸+x²+x+1` na representação SMBUS), semente 0x00, sem reflexão, XOR de saída 0x00. Calculado sobre todos os bytes desde START até ao último byte de FIELDS.

```cpp
static const uint8_t CRC8_TABLE[256] = {
    0x00, 0x07, 0x0E, 0x09, 0x1C, 0x1B, 0x12, 0x15,
    0x38, 0x3F, 0x36, 0x31, 0x24, 0x23, 0x2A, 0x2D,
    // ... tabela completa de 256 entradas
};
uint8_t crc8_smbus(const uint8_t* d, size_t n) {
    uint8_t c = 0x00;
    for (size_t i = 0; i < n; ++i) c = CRC8_TABLE[c ^ d[i]];
    return c;
}
```

O receptor calcula o CRC8 e compara com o recebido; divergência implica descarte (na CAN-FailSafe, descarte com registo e reenvio supervisionado, jamais silêncio — ver COM-003 e COM-006).

---

# 6. HMAC e SEQ (camada de segurança)

* HMAC: 32 B, calculado sobre a mensagem TLV serializada (START…CRC8); chave partilhada gerida pelo módulo de segurança; obrigatório para mensagens CRITICAL e superiores.
* SEQ: contador crescente de 32 bits por emissor; o receptor rejeita SEQ repetido ou fora da janela (tamanho 1000, configurável); previne repetição de mensagens capturadas.
* Ambos são externos à estrutura `TLVMessage`; acrescentados após serialização e removidos antes da desserialização.

---

# 7. MSG_ID (0x10–0x1F)

| ID | Constante | Prioridade típica | Descrição |
|---|---|---|---|
| 0x10 | MSG_HEARTBEAT | HIGH | Batimento periódico |
| 0x11 | MSG_TELEMETRY | HIGH | Telemetria de sensores/voo/estado |
| 0x12 | MSG_COMMAND | CRITICAL | Comandos validados (nunca MISSÃO→ATUADOR directo) |
| 0x13 | MSG_ACK | CRITICAL | Confirmação de recepção |
| 0x14 | MSG_FAILSAFE | SUPER_CRITICAL | Activação/desactivação de emergência (só CAN-FailSafe e CAN-Principal para difusão de estado) |
| 0x15 | MSG_DEBUG | SUPER_LOW (dinâmica, ver COM-004) | Depuração |
| 0x16 | MSG_VIDEO_DESC | MEDIUM | **Descritor** de vídeo (estado do stream, modo 720p30); jamais fotogramas |
| 0x17 | MSG_SHELL_CMD | LOW | Comando de diagnóstico |
| 0x18 | MSG_SI_DATA | HIGH | Dados em unidades SI |
| 0x19 | MSG_STATE_BROADCAST | HIGH | Difusão de estado do grupo |
| 0x1A | MSG_ACTUATOR_FB | HIGH | Retorno de actuadores |
| 0x1B | MSG_SAFETY_DATA | SUPER_CRITICAL | Dados de segurança (G-FS) |
| 0x1C | MSG_SYNC_REQ | HIGH | Pedido de sincronização |
| 0x1D | MSG_SYNC_RESP | HIGH | Resposta de sincronização |
| 0x1E | MSG_CONFIG | MEDIUM | Configuração/parametrização |
| 0x1F | MSG_RESERVED | — | Reservado |

Validação: `isValidMsgID(id) = (id >= 0x10 && id <= 0x1F)`.

Nota de migração: o antigo `MSG_VIDEO` com carga de 128 B encontra-se **revogado**. Foi substituído por `MSG_VIDEO_DESC` (descritores curtos, ≤16 B). O vídeo 720p30 circula exclusivamente no segmento GCV↔TX 5,8 GHz (Anexo B).

---

# 8. Campos TLV (intervalos)

| Intervalo | Domínio |
|---|---|
| 0x20–0x2F | GPS / Navegação |
| 0x30–0x3F | IMU / Atitude |
| 0x40–0x4F | Estado de voo |
| 0x50–0x5F | Energia |
| 0x60–0x6F | Temperatura |
| 0x70–0x7F | Sistema |
| 0x80–0x8F | Actuadores |
| 0x90–0x9F | Sensores |
| 0xA1–0xAF | FailSafe / supervisão |
| 0xB0–0xBF | **Descritores** de vídeo/estado (proibida carga de fotograma) |

Comandos: 0xC0–0xCF básicos; 0xD0–0xDF controlo; 0xE0–0xEF avançados; 0xF0–0xFF navegação.

---

# 9. Conversão de dados e estruturas

Little-endian obrigatório. Funções: `floatToBytes/bytesToFloat`, `int32ToBytes/bytesToInt32`, `uint32ToBytes/bytesToUint32`, `uint16ToBytes/bytesToUint16`.

```cpp
struct TLVField   { uint8_t id, len, data[32]; };
struct TLVMessage { uint8_t start /*0xAA*/, msgID, tlvCount; TLVField tlvs[32]; uint8_t crc8; };
```

Sem `TLVVideoField` de 128 B: revogado.

---

# 10. Parser FSM

Estados: WAIT_START → WAIT_MSGID → WAIT_COUNT → WAIT_TLV_ID → WAIT_TLV_LEN → WAIT_TLV_DATA → WAIT_CHECKSUM. Erros: OVERFLOW, TIMEOUT (intervalo entre bytes), INVALID_START/MSGID, CHECKSUM, TLV_COUNT (>32), TLV_LEN (>32). Qualquer erro reinicia o parser; protecção contra transbordo por limite de 1024 B; temporização com relógio monotónico.

---

# 11. Construtor (exemplo)

```cpp
TLVBuilder b;
b.addFloat(FLD_ROLL, 0.12f);
b.addFloat(FLD_PITCH, -0.05f);
b.addInt32(FLD_GPS_LAT, 412345678);
b.addUint8(FLD_STATE, SYS_STATE_FLYING);
uint8_t buf[1024]; size_t n = b.build(MSG_TELEMETRY, buf, sizeof buf);
can_send(can_id_telemetria, buf, n); // fragmentado se >64 B
```

---

# 12. Fragmentação CAN-FD

Quadro CAN-FD: 64 B − sobrecarga ≈ 8–12 B ⇒ ≈ 52–56 B úteis; mensagem mínima 4 B ⇒ ≈ 48 B para campos por quadro. O primeiro fragmento contém o cabeçalho TLV completo; os seguintes apenas campos; o receptor reconstitui antes de validar; fragmento perdido implica mensagem perdida (com registo e, se CRITICAL+, reenvio supervisionado).

```
TLV: [START|MSG|COUNT|F1|F2|F3|F4|CRC8]
       ── quadro 1 (≤64B) ── ── quadro 2 ──
       [Frag0/1 + cabeçalho+F1+F2] [Frag1/1 + F3+F4+CRC8]
```

---

# 13. Constantes

| Constante | Valor |
|---|---|
| START_BYTE | 0xAA |
| MAX_TLV_FIELDS | 32 |
| MAX_TLV_DATA | 32 |
| MAX_MESSAGE_SIZE | 1024 |
| MIN_MESSAGE_SIZE | 4 |
| CRC8_POLYNOMIAL | 0x07 |

---

# Anexo A (normativo) — Enquadramento INTERCONNECT FABRIC (não é TLV)

O FABRIC intra-cluster do Master Geral utiliza quadros IPC próprios, determinísticos e de baixa latência. A tecnologia física (SPI/DMA/PIO/memória partilhada) é definida no projecto detalhado; o formato lógico é invariante.

```
┌────────┬─────────┬────────┬──────────┬────────┬───────────┬─────────────┬─────────┬─────┐
│ SOURCE │ DESTINO │ NÚCLEO │ TIPO     │ REQ_ID │ TIMESTAMP │ COMPRIMENTO │ PAYLOAD │ CRC │
│ 1 B    │ 1 B     │ 1 B    │ 1 B      │ 2 B    │ 4 B       │ 2 B         │ var.    │ 2 B │
└────────┴─────────┴────────┴──────────┴────────┴───────────┴─────────────┴─────────┴─────┘
```

| Campo | Descrição |
|---|---|
| SOURCE / DESTINO | Núcleo lógico de origem/destino (0–7) ou função (fusão, matemática, navegação, missão, supervisão) |
| NÚCLEO | Núcleo físico executor (0–7 nos 4×RP2350) |
| TIPO | SENSOR_DATA, MATH_REQUEST, RESPONSE, NAVIGATION_REQ/RESP, MISSION_REQ/RESP, HEALTH_STATUS, SYSTEM_STATUS, TIME_SYNC, FAULT, HEARTBEAT |
| REQ_ID | Correlaciona pedido RPC e resposta |
| TIMESTAMP | Relógio monotónico do cluster (para RPC e TIME_SYNC) |
| COMPRIMENTO | Tamanho do PAYLOAD |
| PAYLOAD | Dados binários little-endian (nunca TLV) |
| CRC | CRC-16 do cabeçalho+PAYLOAD |

Exemplo numérico: `MATH_REQUEST` do núcleo 2 ao núcleo 5, REQ_ID 0x0417, PAYLOAD 48 B (matriz de covariância 3×4 floats): quadro = 1+1+1+1+2+4+2+48+2 = 62 B; resposta `RESPONSE` com mesmo REQ_ID em <200 µs (objectivo de projecto; valor a confirmar em bancada).

RPC entre núcleos: chamada bloqueante com tempo-limite (COM-006) ou não-bloqueante com retorno posterior; sem alocação dinâmica; filas por núcleo (COM-004).

---

# Anexo B (normativo) — Enquadramento RJ45-Privada RS (não é TLV nativo)

A RJ45-Privada RS é uma ligação série ponto-a-ponto (protocolo eléctrico tipo RS-422/485, **a confirmar no esquemático**). O conector RJ45 é apenas suporte mecânico de rede privada; proibida ligação a Ethernet.

## B.1 Segmento GCV ←→ placa TX 5,8 GHz (vídeo 720p30)

Transporta o fluxo de vídeo 720p30 (1280×720, 30 qps, H.264 ≈ 4–8 Mbit/s) segundo o protocolo da placa TX. Nenhum byte deste fluxo é TLV. A CAN transporta apenas `MSG_VIDEO_DESC` (ex.: `stream_activo=1, modo=720p30, débito=6,2 Mbit/s`).

```
[G-VIS / GCV] ──RJ45-RS (série conf.)── [placa TX 5,8 GHz] ──ar── [RX solo] ── 720p30
```

## B.2 Segmento MG ←→ RX 2,4 GHz + TX 868 MHz (comando/telemetria)

Transporta comando ascendente (2,4 GHz, 50 Hz) e telemetria descendente (868 MHz, 10 Hz + eventos). Enquadramento série com soma de verificação e SEQ de enlace. Pode **encapsular** TLV validado pelo Router CAN↔RJ45, com tradução de endereços e policiamento (COM-003, COM-007).

```
[MG] ──RJ45-RS── [RX 2,4 GHz (cmd)]   [TX 868 MHz (telem.)] ──ar── [solo]
Exemplo: comando 20 ms (50 Hz), 24 B por trama ⇒ ≈ 9,6 kbit/s úteis; folga ampla a 115 200 bit/s.
```

É proibido injectar vídeo neste segmento e proibido injectar comando/telemetria no segmento de vídeo.

---

# 14. Nota histórica de migração

> Raspberry Pi, ESP32 (todas as variantes) e FS_A não são entidades deste protocolo e não possuem MSG_ID, campos TLV nem endereços próprios. Referências anteriores a esses nomes devem ler-se como designações provisórias dos actuais Grupos Computacionais (§COM-001 §3).

---

# 15. Referências

* COM-001 — Arquitetura de Comunicação
* COM-003 — Gestor de Mensagens
* COM-004 — Prioridades e Filas
* COM-008 — CAN Bus
* COM-010 — Integridade
