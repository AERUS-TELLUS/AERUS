# 00 — Panorama Geral do CAN Bus no Aerus

| Campo             | Valor                              |
| ----------------- | ---------------------------------- |
| **Código**        | HW-CAN-000                         |
| **Título**        | Panorama Geral CAN Bus             |
| **Versão**        | 1.0                                |
| **Estado**        | Em Desenvolvimento                 |
| **Autor**         | ShegaPT                            |
| **Classificação** | Documentação de Hardware           |

---

# 1. Objetivo

O presente documento fornece uma visão geral do CAN Bus no contexto do sistema Aerus, incluindo requisitos, comparação com alternativas, topologia e mapa de decisão para seleção de componentes.

---

# 2. O que é CAN Bus

O CAN (Controller Area Network) é um barramento serial robusto desenvolvido pela Bosch na década de 1980 para comunicação entre ECU em automóveis. O CAN FD (Flexible Data-rate) é a evolução que permite payloads maiores (até 64 bytes) e taxas de dados mais elevadas (até 8 Mbps).

**Características fundamentais:**

* Barramento partilhado (multi-master);
* Diferencial (CAN_H e CAN_L) — imunidade a ruído;
* Arbiter por prioridade (ID mais baixo vence);
* Deteção e sinalização de erros integrada;
* Born-off e auto-recovery;
* Padrão aberto (ISO 11898).

---

# 3. CAN FD vs CAN Clássico

| Característica | CAN Clássico (2.0) | CAN FD |
|----------------|-------------------|--------|
| Payload máximo | 8 bytes | 64 bytes |
| Bitrate de dados | Até 1 Mbps | Até 8 Mbps |
| Bitrate de arbitragem | Até 1 Mbps | Até 1 Mbps |
| CRC | 15-bit | 17-bit ou 21-bit |
| Controlo de erros | Básico | Melhorado |
| BRS (Bit Rate Switch) | Não | Sim |
| Retrocompatível | — | Sim (downward) |
| ISO | ISO 11898-1 | ISO 11898-1:2015 |

**Por que o Aerus escolhe CAN FD:**

* Uma mensagem TLV completa (até ~50 bytes) cabe num único frame;
* Reduz fragmentação e latência;
* Mantém compatibilidade com CAN clássico em buses separados;
* Suporta a taxa de atualização necessária para controlo de voo (50 Hz+).

---

# 4. Requisitos do Aerus

## 4.1 Requisitos de Comunicação

| Requisito | Valor | Origem |
|-----------|-------|--------|
| Protocolo | CAN FD | COM-008 |
| Payload máximo | 64 bytes | COM-008 |
| CAN ID | Extended 29-bit | COM-008, CAN_IDS |
| Buses | 2 (operacional + segurança) | COM-007, COM-008 |
| ESP32-FS | Ligado a ambos os buses | COM-007 |
| Fragmentação | Quando >52-56 bytes TLV | COM-008 §14 |
| Filtragem | Hardware + Software | COM-008 §15 |

## 4.2 Requisitos de Bitrate

| Tipo de Dado | Bitrate Dados | Bitrate Arbitragem | Bus |
|-------------|---------------|-------------------|-----|
| Telemetria sensores | 2 Mbps | 500 kbps | Operacional |
| Comandos de controlo | 2 Mbps | 500 kbps | Operacional |
| Heartbeat / estados | 500 kbps | 500 kbps | Operacional |
| Dados de atuadores | 2 Mbps | 500 kbps | Operacional |
| Segurança / emergência | 5 Mbps | 1 Mbps | Segurança |
| Sincronização temporal | 5 Mbps | 1 Mbps | Ambos |
| Debug / diagnóstico | 500 kbps | 500 kbps | Operacional |

## 4.3 Requisitos Elétricos

| Requisito | Valor | Origem |
|-----------|-------|--------|
| Terminação | 120Ω ±5%, 1/4W | COM-008 §8 |
| Impedância do cabo | 120Ω ±10% | COM-008 §8 |
| Isolamento galvânico | ≥2500 VRMS (segurança) | COM-008 §10 |
| CMC (segurança) | ≥100 V/µs | COM-008 §10 |
| Temperatura operacional | -40°C a +150°C | HW-002 |
| Proteção ESD (bus) | ≥8 kV contacto, ≥15 kV ar | COM-008 §11 |

## 4.4 Requisitos de Fiabilidade

| Requisito | Descrição |
|-----------|-----------|
| Born-off recovery | Auto-recuperação com máximo 10 tentativas |
| Heartbeat | Detectar perda de comunicação em <300 ms |
| Diagnóstico | Contadores de erro TX/RX, estado do bus |
| Redundância | Dois buses independentes |

---

# 5. Topologia do Aerus

## 5.1 Diagrama de Blocos

```text
                        BUS OPERACIONAL (120Ω term.)
    ┌──────────────────────────────────────────────────────────────────┐
    │                                                                  │
    │  ┌─────────┐  ┌─────────┐  ┌─────────────┐  ┌─────────┐       │
    │  │ESP32-S  │  │ESP32-S  │  │ RaspberryPi │  │ ESP32-A │       │
    │  │  _01    │  │  _02    │  │             │  │         │       │
    │  │ID:0x11  │  │ID:0x12  │  │  ID:0x01    │  │ ID:0x21 │       │
    │  │MCP2518FD│  │MCP2518FD│  │  MCP2518FD  │  │MCP2518FD│       │
    │  │MCP2562FD│  │MCP2562FD│  │  MCP2562FD  │  │MCP2562FD│       │
    │  └────┬────┘  └────┬────┘  └──────┬──────┘  └────┬────┘       │
    │       │            │              │              │              │
    │  ─────┴────────────┴──────────────┴──────────────┴─────        │
    │                                                                  │
    │                    ┌────────────────┐                           │
    │                    │    ESP32-FS    │                           │
    │                    │    ID:0x31     │                           │
    │                    │  MCP2518FD ×2  │                           │
    │                    │ MCP2562FD +    │                           │
    │                    │ ISO1042        │                           │
    │                    └───────┬────────┘                           │
    │                            │                                     │
    └────────────────────────────┼─────────────────────────────────────┘
                                 │
                       ┌─────────┴─────────┐
                       │  BUS SEGURANÇA     │ (120Ω term.)
    ┌──────────────────┼────────────────────┼───────────────────┐
    │                  │                    │                   │
    │  ┌───────────────┴──┐          ┌──────┴──────┐           │
    │  │     ESP32-FS     │          │  ESP32-FS_A │           │
    │  │     ID:0x31      │          │  ID:0x41    │           │
    │  │    ISO1042       │          │  ISO1042    │           │
    │  └──────────────────┘          └─────────────┘           │
    │                                                          │
    └──────────────────────────────────────────────────────────┘
```

## 5.2 Componentes por Grupo

| Grupo | Controlador | Transceiver | Bus | Notas |
|-------|------------|-------------|-----|-------|
| RaspberryPi | MCP2518FD | MCP2562FD | Operacional | Via SPI, driver Linux |
| ESP32-S_01 | MCP2518FD | MCP2562FD | Operacional | Via SPI |
| ESP32-S_02 | MCP2518FD | MCP2562FD | Operacional | Via SPI |
| ESP32-A | MCP2518FD | MCP2562FD | Operacional | Via SPI |
| ESP32-FS | MCP2518FD ×2 | MCP2562FD + ISO1042 | Ambos | Ponte entre buses |
| ESP32-FS_A | MCP2518FD | ISO1042 | Segurança | Isolado |

---

# 6. Por que não CAN Clássico

| Limitação CAN Clássico | Impacto no Aerus | CAN FD resolve |
|------------------------|------------------|----------------|
| Payload 8 bytes | Mensagens TLV fragmentadas em 3-8 frames | 64 bytes — cabe em 1 frame |
| 1 Mbps máximo | Throughput insuficiente para 50 Hz telemetry | Até 8 Mbps |
| CRC 15-bit | Menor deteção de erros | CRC 17/21-bit |
| Sem BRS | Sem flexibilidade de bitrate | BRS permite arbitragem lenta + dados rápidos |

---

# 7. Mapa de Componentes

## 7.1 Controladores CAN FD

| Componente | Fabricante | Interface | CAN FD | Bitrate Max | Temperatura | Preço | Recomendação |
|-----------|-----------|-----------|--------|-------------|-------------|-------|-------------|
| MCP2518FD | Microchip | SPI | Sim | 8 Mbps | -40 a +150°C | ~$2.50 | **Recomendado** |
| MCP251863 | Microchip | SPI | Sim | 8 Mbps | -40 a +150°C | ~$2.20 | Integrado (ctrl+txcvr) |
| MCP2517FD | Microchip | SPI | Sim | 8 Mbps | -40 a +150°C | ~$2.00 | Não recom. novos designs |

## 7.2 Transceivers CAN FD

| Componente | Fabricante | Tensão | CAN FD | Bitrate | Isolado | Temperatura | Preço | Recomendação |
|-----------|-----------|--------|--------|---------|---------|-------------|-------|-------------|
| MCP2562FD | Microchip | 5V | Sim | 8 Mbps | Não | -40 a +125°C | ~$1.00 | **Operacional** |
| TJA1044GT | NXP | 3.3/5V | Sim | 5 Mbps | Não | -40 a +150°C | ~$1.50 | Alternativa |
| TCAN1042 | TI | 5V | Sim | 5 Mbps | Não | -40 a +125°C | ~$1.50 | Alternativa |
| ISO1042 | TI | 1.8-5.5V | Sim | 5 Mbps | **Sim** | -40 a +125°C | ~$5.28 | **Segurança** |

## 7.3 Módulos de Desenvolvimento

| Módulo | Plataforma | Controlador | Transceiver | Preço | Notas |
|--------|-----------|-------------|-------------|-------|-------|
| MCP2518FD Click | mikroBUS | MCP2518FD | MCP2562FD | ~$30 | Prototipagem rápida |
| MCP251863 Click | mikroBUS | MCP251863 | Integrado | ~$30 | Solução integrada |
| LilyGo T-2Can-FD | ESP32-S3 | MCP2518FD + TWAI | MCP2562FD | ~$25 | Dual CAN, WiFi+BLE |
| 2CH Isolated CAN FD HAT | RaspberryPi | MCP2518FD ×2 | MCP2562FD | ~$40 | 5kV isolação |

## 7.4 Ferramentas

| Ferramenta | Fabricante | Canais | CAN FD | Isolado | Preço | Recomendação |
|-----------|-----------|--------|--------|---------|-------|-------------|
| PCAN-USB FD | PEAK | 1 | Sim | 500V | ~€298 | **Recomendado** |
| PCAN-USB Pro FD | PEAK | 2+2 LIN | Sim | 500V | ~€500+ | Profissional |
| Waveshare USB-CAN-FD | Waveshare | 1 | Sim | Não | ~$81 | Budget |
| CANalyst-II | Genérico | 2 | Não | Não | ~$17-90 | Ultra-budget |

---

# 8. Estimativa de Custos por Grupo

| Grupo | Controlador | Transceiver | Módulo/Dev | Custo Estimado |
|-------|------------|-------------|------------|----------------|
| RaspberryPi | MCP2518FD | MCP2562FD | HAT ou Click | ~$35-45 |
| ESP32-S (×2) | MCP2518FD | MCP2562FD | PCB custom | ~$8-12 cada |
| ESP32-A | MCP2518FD | MCP2562FD | PCB custom | ~$8-12 |
| ESP32-FS | MCP2518FD ×2 | MCP2562FD + ISO1042 | PCB custom | ~$20-30 |
| ESP32-FS_A | MCP2518FD | ISO1042 | PCB custom | ~$15-20 |
| Ferramenta debug | — | — | PCAN-USB FD | ~€298 |
| **Total protótipo** | | | | **~$130-180 + ferramenta** |

---

# 9. Fornecedores

| Fornecedor | Tipo | Site |
|-----------|------|------|
| Mouser | Distribuidor autorizado | mouser.com |
| Digikey | Distribuidor autorizado | digikey.com |
| LCSC | Componentes (preço baixo) | lcsc.com |
| Microchip Direct | Direto do fabricante | microchipdirect.com |
| Amazon | Módulos e acessórios | amazon.com |
| AliExpress | Módulos budget | aliexpress.com |

---

# 10. Referências

- COM-008 — CAN Bus (especificação)
- shared/CAN_IDS — Alocação de CAN IDs
- COM-007 — Comunicação entre Domínios Computacionais
- HW-006 — Interfaces de Comunicação
- HW-004 — Interfaces Elétricas
- ISO 11898-1:2015 — CAN data link layer
- ISO 11898-2:2016 — CAN high-speed physical layer
