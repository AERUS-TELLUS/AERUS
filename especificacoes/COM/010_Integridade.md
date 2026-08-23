# COM-010 — Integridade

| Campo             | Valor                              |
| ----------------- | ---------------------------------- |
| **Código**        | COM-010                            |
| **Título**        | Integridade                        |
| **Versão**        | 1.0                                |
| **Estado**        | Em Desenvolvimento                 |
| **Autor**         | ShegaPT                            |
| **Classificação** | Especificação de Comunicação       |

---

# 1. Objetivo

O presente documento define a arquitetura de proteção multi-camada de integridade do sistema Aerus, estabelecendo os mecanismos de deteção de erros, autenticação, anti-replay e validação em cada camada da pilha de comunicação.

A integridade é implementada em cinco camadas independentes, cada uma protegendo contra tipos específicos de erros ou ataques, garantindo que as mensagens recebidas são idênticas às transmitidas, autênticas e atuais.

---

# 2. Princípios

* proteção multi-camada (5 camadas independentes);
* cada camada protege contra um tipo específico de ameaça;
* validação sequencial no receiver (de camada 1 a camada 5);
* falha em qualquer camada resulta em descarte imediato;
* zero falsos positivos — validação é determinística;
* hardware CRC nativo + software CRC8 + Security (HMAC/SEQ);
* Determinismo — sem Alocações dinâmicas, sem dependências externas.

---

# 3. Visão Geral das Camadas

## 3.1 Diagrama de Camadas

```text
┌──────────────────────────────────────────────────────────────────┐
│  CAMADA 5: SEQ (Anti-Replay)                                     │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  TLV SEQ (4 bytes) — gerido pelo Security                  │ │
│  │  Protege contra: reenvio de mensagens capturadas           │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  CAMADA 4: CAN ID + Assinatura (Identificação)                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  CAN ID (29 bits) + Assinatura (Security)                  │ │
│  │  Protege contra: identificação falsa, injeção              │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  CAMADA 3: HMAC (Autenticação)                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  TLV HMAC (32 bytes) — gerido pelo Security                │ │
│  │  Protege contra: mensagens falsificadas, alteração         │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  CAMADA 2: CRC8 TLV (Aplicação)                                 │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  CRC8 SMBUS (0x07) — calculado sobre TLV serializado       │ │
│  │  Protege contra: corrupção na camada de aplicação          │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  CAMADA 1: CRC CAN FD (Física)                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  CRC nativo CAN FD (17-bit) — hardware CAN controller     │ │
│  │  Protege contra: erros de transmissão no canal físico      │ │
│  └────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────┘
```

## 3.2 Tabela Resumo

| Camada | Mecanismo | Tamanho | Origem | Protege contra |
|--------|-----------|---------|--------|----------------|
| 1 | CRC CAN FD | 17 bits | Hardware CAN | Erros de transmissão física |
| 2 | CRC8 TLV | 1 byte | Software | Corrupção na camada de aplicação |
| 3 | HMAC | 32 bytes | Security | Mensagens falsificadas |
| 4 | CAN ID + Assinatura | 29 bits + variável | CAN + Security | Identificação falsa, injeção |
| 5 | SEQ | 4 bytes | Security | Reenvio de mensagens capturadas |

---

# 4. Camada 1: CRC CAN FD (Física)

## 4.1 Descrição

O CRC nativo do CAN FD é calculado pelo controlador CAN hardware sobre todo o frame (ID + payload). É a primeira linha de defesa contra erros de transmissão no canal físico.

## 4.2 Características

| Parâmetro | Valor |
|-----------|-------|
| Tamanho | 17 bits |
| Polinómio | x¹⁷ + x¹⁶ + x¹⁴ + x¹³ + x¹¹ + x⁴ + x³ + x + 1 |
| Proteção | ID + payload + stuff bits |
| Cálculo | Automático pelo hardware CAN |
| Detecção | Erros de 1-2 bits, rajadas ≤16 bits |

## 4.3 Mecanismo

```text
┌─────────────────────────────────────────────────────────────┐
│  CAMADA 1: CRC CAN FD                                        │
│                                                              │
│  Transmissor:                                                │
│  1. Controlador CAN calcula CRC sobre ID + payload          │
│  2. CRC inserido no frame CAN FD                             │
│  3. Frame transmitido no bus                                 │
│                                                              │
│  Receiver:                                                   │
│  1. Controlador CAN calcula CRC sobre ID + payload recebido │
│  2. Compara com CRC recebido                                │
│  3. Se diferentes → Erro CAN, frame descartado              │
│  4. Incremento de error counter                             │
│  5. Possível born-off se erros consecutivos                 │
│                                                              │
│  Taxa de detecção: > 99.9999% para erros até 16 bits       │
└─────────────────────────────────────────────────────────────┘
```

## 4.4 Ação em caso de falha

| Condição | Ação |
|---------|------|
| CRC CAN inválido | Frame descartado pelo hardware |
| Error counter incrementado | Transição ERROR ACTIVE → PASSIVE → BUS OFF |
| Born-off | Auto-recovery (ver `COM-008` §9) |
| Log | Erro registado para diagnóstico |

---

# 5. Camada 2: CRC8 TLV (Aplicação)

## 5.1 Descrição

O CRC8 TLV é calculado sobre a mensagem TLV serializada (START até último byte TLV), protegendo contra corrupção de dados na camada de aplicação.

## 5.2 Algoritmo

| Parâmetro | Valor |
|-----------|-------|
| Polinómio | 0x07 (SMBUS) |
| Tamanho | 1 byte (8 bits) |
| Seed | 0x00 |
| Refin | false |
| Refout | false |
| XorOut | 0x00 |

## 5.3 Cálculo

```text
┌─────────────────────────────────────────────────────────────┐
│  CAMADA 2: CRC8 TLV                                          │
│                                                              │
│  Transmissor:                                                │
│  1. Serializar TLV: START + MSG_ID + COUNT + FIELDS         │
│  2. Calcular CRC8 sobre todos os bytes serializados         │
│  3. Acrescentar CRC8 ao final da mensagem                   │
│                                                              │
│  Mensagem:                                                   │
│  ┌─────────┬─────────┬───────────┬─────────────┬─────────┐ │
│  │ START   │ MSG_ID  │ TLV_COUNT │ TLV_FIELDS  │ CRC8    │ │
│  │ (0xAA)  │ (1B)    │ (1B)      │ (variável)  │ (1B)    │ │
│  └─────────┴─────────┴───────────┴─────────────┴─────────┘ │
│                          │                                   │
│                    CRC8 calculado                            │
│                    sobre esta região                         │
│                                                              │
│  Receiver:                                                   │
│  1. Extrair CRC8 recebido                                    │
│  2. Calcular CRC8 sobre bytes recebidos (excluindo CRC8)   │
│  3. Comparar CRC8 calculado com recebido                    │
│  4. Se diferentes → Mensagem corrompida, descartar          │
│  5. Incremento de rx_crc_errors[origem]                     │
└─────────────────────────────────────────────────────────────┘
```

## 5.4 Tabela de Lookup

```cpp
static const uint8_t CRC8_TABLE[256] = {
    0x00, 0x07, 0x0E, 0x09, 0x1C, 0x1B, 0x12, 0x15,
    0x38, 0x3F, 0x36, 0x31, 0x24, 0x23, 0x2A, 0x2D,
    // ... 256 entradas completas
};

uint8_t crc8_smbus(const uint8_t* data, size_t len) {
    uint8_t crc = 0x00;
    for (size_t i = 0; i < len; i++) {
        crc = CRC8_TABLE[crc ^ data[i]];
    }
    return crc;
}
```

## 5.5 Capacidade de Deteção

| Tipo de erro | Deteção |
|-------------|---------|
| Erro de 1 bit | 100% |
| Erro de 2 bits | 100% |
| Erro de rajada ≤8 bits | 100% |
| Erro de rajada >8 bits | ~99.6% |
| Erros aleatórios | ~99.6% |

---

# 6. Camada 3: HMAC (Autenticação)

## 6.1 Descrição

O HMAC (Hash-based Message Authentication Code) de 32 bytes é gerido pelo módulo `Security/` para autenticar a origem e integridade da mensagem.

## 6.2 Características

| Parâmetro | Valor |
|-----------|-------|
| Tamanho | 32 bytes (256 bits) |
| Algoritmo | HMAC-SHA256 (ou equivalente definido pelo Security) |
| Chave | Partilhada entre módulos autorizados |
| Cálculo | Sobre mensagem TLV serializada (START até CRC8) |

## 6.3 Mecanismo

```text
┌─────────────────────────────────────────────────────────────┐
│  CAMADA 3: HMAC                                              │
│                                                              │
│  Transmissor:                                                │
│  1. Serializar TLV completo                                  │
│  2. Calcular HMAC-SHA256 sobre TLV serializado              │
│  3. HMAC = HMAC-SHA256(chave_secreta, TLV)                  │
│  4. Acrescentar HMAC (32 bytes) após CRC8                   │
│                                                              │
│  Mensagem completa:                                          │
│  ┌─────────┬─────────┬──────┬───────┬──────────┬─────────┐ │
│  │ START   │ MSG_ID  │COUNT │ FIELDS│ CRC8     │ HMAC    │ │
│  └─────────┴─────────┴──────┴───────┴──────────┴─────────┘ │
│                                          │           │       │
│                                     CRC8 sobre   HMAC sobre │
│                                     TLV          TLV        │
│                                                              │
│  Receiver:                                                   │
│  1. Extrair HMAC recebido (32 bytes)                         │
│  2. Calcular HMAC sobre TLV recebido (sem HMAC)             │
│  3. Comparar HMAC calculado com recebido                     │
│  4. Se diferentes → Mensagem falsificada, descartar         │
│  5. Alerta de segurança                                     │
└─────────────────────────────────────────────────────────────┘
```

## 6.4 Opcionalidade

* HMAC é opcional — a sua presença é indicada por flag externa ao TLV;
* mensagens sem HMAC são aceites mas com menor nível de confiança;
* mensagens CRITICAL+ devem SEMPRE incluir HMAC;
* a chave é gerida pelo módulo Security (ver `SEC/`).

---

# 7. Camada 4: CAN ID + Assinatura (Identificação)

## 7.1 Descrição

O CAN ID de 29 bits transporta informação de origem, destino e prioridade, permitindo identificar e autenticar a fonte da mensagem no nível de transporte.

## 7.2 Estrutura do CAN ID

```text
┌─────────────────────────────────────────────────────────────┐
│  CAN ID Extended (29 bits)                                    │
│                                                              │
│  PRIORIDADE │ GRUPO_ORIGEM │ GRUPO_DESTINO │ TIPO_MSG      │
│   (3 bit)   │   (4 bit)    │    (4 bit)    │  (4 bit)      │
│    28-26    │    25-22     │     21-18     │   17-14       │
│                                                              │
│  Bits 13-0: Reservados (zeros)                               │
│                                                              │
│  Validação:                                                  │
│  ├── Grupo origem deve ser conhecido                         │
│  ├── Grupo destino deve ser este nó ou broadcast             │
│  ├── Prioridade deve ser consistente com MSG_ID             │
│  └── Tipo de mensagem deve ser válido                        │
└─────────────────────────────────────────────────────────────┘
```

## 7.3 Filtros

| Filtro | Descrição | Ação |
|--------|-----------|------|
| Acceptance Filter | Aceitar apenas CAN IDs deste nó + broadcast | Hardware CAN |
| Origem Filter | Verificar se origem é conhecida | Software |
| Destino Filter | Verificar se destino é este nó | Software |
| Prioridade Filter | Verificar consistência CAN/TLV | Software |

## 7.4 Assinatura (Security)

O módulo Security pode adicionar uma assinatura ao CAN ID para autenticação adicional:

```text
┌─────────────────────────────────────────────────────────────┐
│  ASSINATURA DE CAN ID                                         │
│                                                              │
│  CAN ID (29 bits) + Signature (8 bits)                       │
│                                                              │
│  Signature = truncated_HMAC(chave, CAN_ID + timestamp)      │
│                                                              │
│  Validação:                                                  │
│  ├── CAN ID recebido                                         │
│  ├── Signature recebida                                      │
│  ├── Calcular truncated_HMAC sobre CAN ID + timestamp       │
│  └── Comparar com signature recebida                         │
│                                                              │
│  NOTA: Assinatura é opcional e implementada pelo Security.   │
└─────────────────────────────────────────────────────────────┘
```

---

# 8. Camada 5: SEQ (Anti-Replay)

## 8.1 Descrição

O SEQ (Sequence Number) de 4 bytes é gerido pelo módulo `Security/` para prevenir ataques de replay — reenvio de mensagens válidas capturadas.

## 8.2 Mecanismo

```text
┌─────────────────────────────────────────────────────────────┐
│  CAMADA 5: SEQ (ANTI-REPLAY)                                 │
│                                                              │
│  Transmissor:                                                │
│  1. Cada módulo mantém contador SEQ crescente                │
│  2. SEQ = counter++;                                         │
│  3. SEQ acrescentado ao final da mensagem                    │
│                                                              │
│  Mensagem completa:                                          │
│  ┌──────┬───────┬──────┬───────┬──────────┬──────┬───────┐ │
│  │START │MSG_ID │COUNT │FIELDS │ CRC8     │ HMAC │ SEQ   │ │
│  └──────┴───────┴──────┴───────┴──────────┴──────┴───────┘ │
│                                                     4 bytes │
│                                                              │
│  Receiver:                                                   │
│  1. Extrair SEQ recebido                                     │
│  2. Verificar SEQ > último SEQ válido deste remetente       │
│  3. Se SEQ ≤ último → Mensagem replay, descartar           │
│  4. Se SEQ fora da janela → Possível replay, descartar     │
│  5. Se válido → Atualizar último SEQ válido                 │
│                                                              │
│  Janela aceitável:                                           │
│  último_SEQ < SEQ ≤ último_SEQ + WINDOW_SIZE                │
│  WINDOW_SIZE = 1000 (configurável)                          │
└─────────────────────────────────────────────────────────────┘
```

## 8.3 Regras

| Regra | Descrição |
|-------|-----------|
| SEQ crescente | Cada mensagem possui SEQ superior à anterior |
| Janela aceitável | SEQ deve estar dentro da janela de 1000 |
| Reset | SEQ é reiniciado a cada reinicialização |
| Por remetente | Cada remetente possui SEQ independente |

---

# 9. Sequência de Validação no Receiver

## 9.1 Fluxo Completo

```text
┌─────────────────────────────────────────────────────────────┐
│  SEQUÊNCIA DE VALIDAÇÃO NO RECEIVER                          │
│                                                              │
│  Frame CAN FD recebido                                       │
│  │                                                           │
│  ▼                                                           │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  CAMADA 1: CRC CAN FD                                │    │
│  │  └─→ Verificar CRC nativo (hardware)                 │    │
│  │      └─→ FALHA: Frame descartado pelo hardware       │    │
│  │          incremento error_counter                     │    │
│  └─────────────────────┬───────────────────────────────┘    │
│                        │(sucesso)                            │
│                        ▼                                     │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  CAMADA 4: CAN ID                                    │    │
│  │  └─→ Verificar filtros de CAN ID                     │    │
│  │      ├── Origem conhecida?                           │    │
│  │      ├── Destino é este nó ou broadcast?             │    │
│  │      └── Prioridade consistente?                     │    │
│  │      └─→ FALHA: Frame descartado + log               │    │
│  └─────────────────────┬───────────────────────────────┘    │
│                        │(sucesso)                            │
│                        ▼                                     │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  CAMADA 2: CRC8 TLV                                  │    │
│  │  └─→ Parser TLV extrai mensagem                      │    │
│  │  └─→ Calcular CRC8 sobre TLV serializado             │    │
│  │  └─→ Comparar com CRC8 recebido                      │    │
│  │      └─→ FALHA: Mensagem descartada + incremento     │    │
│  └─────────────────────┬───────────────────────────────┘    │
│                        │(sucesso)                            │
│                        ▼                                     │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  CAMADA 3: HMAC (se presente)                        │    │
│  │  └─→ Calcular HMAC sobre TLV recebido                │    │
│  │  └─→ Comparar com HMAC recebido                      │    │
│  │      └─→ FALHA: Mensagem descartada + alerta seg.    │    │
│  └─────────────────────┬───────────────────────────────┘    │
│                        │(sucesso)                            │
│                        ▼                                     │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  CAMADA 5: SEQ (se presente)                         │    │
│  │  └─→ Verificar SEQ > último_SEQ_valido               │    │
│  │  └─→ Verificar SEQ dentro da janela                  │    │
│  │      └─→ FALHA: Mensagem descartada + alerta seg.    │    │
│  └─────────────────────┬───────────────────────────────┘    │
│                        │(sucesso)                            │
│                        ▼                                     │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  ENTREGA AO MÓDULO DE APLICAÇÃO                      │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

## 9.2 Resumo de Falhas

| Camada | Mecanismo | Falha | Ação |
|--------|-----------|-------|------|
| 1 | CRC CAN FD | Erro físico | Descarte hardware |
| 4 | CAN ID | Origem/destino inválido | Descarte + log |
| 2 | CRC8 TLV | Corrupção | Descarte + incremento |
| 3 | HMAC | Falsificação | Descarte + alerta segurança |
| 5 | SEQ | Replay | Descarte + alerta segurança |

---

# 10. Cenários de Ataque e Defesa

## 10.1 Tabela de Ameaças

| Ameaça | Camada que protege | Mecanismo |
|--------|-------------------|-----------|
| Erro de transmissão | Camada 1 (CRC CAN) | CRC nativo 17-bit |
| Corrupção de dados | Camada 2 (CRC8 TLV) | CRC8 SMBUS |
| Mensagem falsificada | Camada 3 (HMAC) | HMAC-SHA256 |
| Injeção de mensagem | Camada 4 (CAN ID) | Filtros de CAN ID |
| Replay de mensagem | Camada 5 (SEQ) | Contador crescente |
| Ataque man-in-the-middle | Camada 3 + 4 | HMAC + CAN ID |
| Eliminação de mensagem | Camada 5 (SEQ) | Gap no SEQ detectável |
| Ataque de negação de serviço | Camada 1 (CRC CAN) | Born-off detection |

## 10.2 Diagrama de Defesa

```text
┌─────────────────────────────────────────────────────────────┐
│  CENÁRIO: ATACANTE CAPTURA MENSAGEM                          │
│                                                              │
│  1. Atacante captura frame CAN FD válido                     │
│  2. Atacante reenvia o frame                                  │
│                                                              │
│  Defesa:                                                     │
│  ├── Camada 1 (CRC CAN): Frame é válido (mesmos bits)       │
│  ├── Camada 4 (CAN ID): CAN ID é válido                     │
│  ├── Camada 2 (CRC8): CRC8 é válido                         │
│  ├── Camada 3 (HMAC): HMAC é válido (mesma chave)           │
│  └── Camada 5 (SEQ): SEQ ≤ último_SEQ → REPLAY DETETADO    │
│                                                              │
│  Resultado: Mensagem DESCARTADA (replay detetado)           │
└─────────────────────────────────────────────────────────────┘
```

---

# 11. Gestão de Erros

## 11.1 Contadores

Cada nó mantém contadores independentes por camada:

```cpp
typedef struct {
    // Camada 1: CRC CAN
    uint32_t can_crc_errors;
    uint32_t can_bus_off_count;
    
    // Camada 2: CRC8 TLV
    uint32_t crc8_errors[MAX_GROUPS];
    uint32_t crc8_errors_total;
    
    // Camada 3: HMAC
    uint32_t hmac_errors[MAX_GROUPS];
    uint32_t hmac_errors_total;
    
    // Camada 4: CAN ID
    uint32_t invalid_canid_count;
    uint32_t unknown_origin_count;
    
    // Camada 5: SEQ
    uint32_t replay_detected_count;
    uint32_t seq_out_of_window_count;
    
    // Totais
    uint32_t total_messages_rx;
    uint32_t total_messages_tx;
    uint32_t total_messages_discarded;
} IntegrityStats;
```

## 11.2 Ações por Tipo de Erro

| Tipo de erro | Contador | Ação | Severidade |
|-------------|---------|------|-----------|
| CRC CAN | `can_crc_errors` | Log + incremento | Baixa |
| CRC8 TLV | `crc8_errors[g]` | Descarte + log | Média |
| HMAC inválido | `hmac_errors[g]` | Descarte + alerta segurança | Alta |
| CAN ID inválido | `invalid_canid_count` | Descarte + log | Média |
| Replay detetado | `replay_detected_count` | Descarte + alerta segurança | Alta |
| SEQ fora da janela | `seq_out_of_window_count` | Descarte + log | Média |

---

# 12. Considerações de Segurança

## 12.1 Chaves

| Parâmetro | Descrição |
|-----------|-----------|
| Chave HMAC | Partilhada entre módulos autorizados |
| Rotação de chaves | Definida pelo módulo Security |
| Armazenamento | Em memória segura (se disponível) |
| Distribuição | Via canal seguro (fora do CAN) |

## 12.2 Limitações

| Limitação | Impacto | Mitigação |
|-----------|---------|-----------|
| CRC8 8-bit | Rajadas >8 bits podem passar | Camada 1 (CRC CAN) compensa |
| HMAC opcional | Mensagens sem HMAC são menos seguras | CRITICAL+ devem incluir HMAC |
| SEQ resetável | Após reinicialização, janela reinicia | Timestamp no SEQ ajuda |
| CAN ID spoofing | Atacante pode falsificar CAN ID | HMAC + CAN ID combinação |

---

# 13. Integração com Outros Módulos

## 13.1 Dependências

| Módulo | Relação com Integridade |
|--------|------------------------|
| COM-002 (Protocolo TLV) | Define CRC8 e estrutura TLV |
| COM-003 (Gestor de Mensagens) | Implementa validação sequencial |
| COM-008 (CAN Bus) | CRC nativo CAN FD |
| SEC (Segurança) | Gere HMAC, SEQ e chaves |
| SYS-006 (Gestão de Estados) | Reage a alertas de integridade |

## 13.2 Diagrama de Integração

```text
┌─────────────────────────────────────────────────────────────┐
│  INTEGRAÇÃO DE INTEGRIDADE                                    │
│                                                              │
│  ┌──────────┐     ┌──────────────┐     ┌──────────────┐    │
│  │  COM-008  │────►│  INTEGRIDADE │◄────│  COM-002     │    │
│  │  CAN Bus  │     │    MODULE    │     │  TLV         │    │
│  └──────────┘     └──────┬───────┘     └──────────────┘    │
│                           │                                  │
│                           ▼                                  │
│                    ┌──────────────┐                          │
│                    │  COM-003     │                          │
│                    │  Gestor Msg  │                          │
│                    └──────┬───────┘                          │
│                           │                                  │
│                           ▼                                  │
│                    ┌──────────────┐                          │
│                    │  SEC         │                          │
│                    │  Segurança   │                          │
│                    └──────────────┘                          │
└─────────────────────────────────────────────────────────────┘
```

---

# 14. Limites do Documento

Este documento não define:

* implementação do módulo Security (ver `SEC/`);
* detalhes de implementação do CAN Bus (ver `COM-008`);
* implementação do Gestor de Mensagens (ver `COM-003`);
* protocolo TLV completo (ver `COM-002`);
* gestão temporal (ver `COM-009`);
* gestão de estados (ver `SYS-006`).

---

# 15. Referências

- COM-001 — Arquitetura de Comunicação
- COM-002 — Protocolo TLV
- COM-003 — Gestor de Mensagens
- COM-004 — Prioridades e Filas
- COM-008 — CAN Bus
- COM-009 — Sincronização
- SHARED-TLV — Definições do Protocolo TLV
- SHARED-CAN-IDS — Alocação de CAN IDs
- SYS-003 — Arquitetura de Software
- SYS-006 — Gestão de Estados
- SEC — Especificações de Segurança
- ISO 11898-1:2015 — CAN data link layer
