# 01 — Controladores CAN FD

| Campo             | Valor                              |
| ----------------- | ---------------------------------- |
| **Código**        | HW-CAN-001                         |
| **Título**        | Controladores CAN FD               |
| **Versão**        | 1.0                                |
| **Estado**        | Em Desenvolvimento                 |
| **Autor**         | ShegaPT                            |
| **Classificação** | Documentação de Hardware           |

---

# 1. Objetivo

O presente documento detalha os controladores CAN FD candidatos a implementação no Aerus, com foco no MCP2518FD (controlador principal) e no MCP251863 (solução integrada controlador + transceiver).

---

# 2. Por que um Controlador Externo

O ESP32-S3 possui o controlador TWAI integrado, mas este suporta apenas CAN 2.0 (não CAN FD). O RaspberryPi 5 não possui qualquer controlador CAN integrado.

Para CAN FD, ambos necessitam de um controlador externo ligado por SPI.

```text
┌──────────────┐      SPI       ┌──────────────┐      CAN_H/CAN_L      ┌──────────┐
│  ESP32-S3 /  │ ──────────────→│  MCP2518FD   │ ─────────────────────→│   Bus    │
│  RaspberryPi │   MOSI/MISO/   │  (Controlador│   TXCAN/RXCAN        │  CAN FD  │
│              │   SCK/CS       │   CAN FD)    │                       │          │
└──────────────┘                └──────┬───────┘                       └──────────┘
                                       │
                                       │ TXCAN/RXCAN
                                       ▼
                                 ┌──────────────┐
                                 │  MCP2562FD   │
                                 │ (Transceiver)│
                                 └──────────────┘
```

---

# 3. MCP2518FD — Controlador Principal

## 3.1 Resumo

| Campo | Valor |
|-------|-------|
| Fabricante | Microchip Technology |
| Part Number | MCP2518FD |
| Interface | SPI (até 20 MHz) |
| CAN FD | Sim (ISO 11898-1:2015) |
| CAN 2.0B | Sim (retrocompatível) |
| Bitrate arbitragem | Até 1 Mbps |
| Bitrate dados | Até 8 Mbps |
| RAM | 2 KB |
| FIFOs | 31 (configuráveis TX/RX) |
| Filtros | 32 objetos de filtro/máscara |
| Timestamp | 32-bit |
| Oscilador externo | 2-40 MHz (recomendado: 40 MHz) |
| Alimentação | 2.7V a 5.5V |
| Corrente ativa | ~12 mA @ 5.5V, 40 MHz |
| Corrente sleep | ~10 µA |
| Temperatura | -40 a +125°C (Extended) ou -40 a +150°C (High) |
| Packages | SOIC-14, VDFN-14 (4.5×3 mm) |
| Funcional Safety | ISO 26262 — até ASIL B |
| Preço (unit) | ~$2.17-2.50 (Mouser/Digikey) |
| Preço (1000+) | ~$1.44-1.55 |
| Datasheet | [DS20006027B](https://ww1.microchip.com/downloads/aemDocuments/documents/OTH/ProductDocuments/DataSheets/External-CAN-FD-Controller-with-SPI-Interface-DS20006027B.pdf) |

## 3.2 Características Principais

* Suporta CAN 2.0B e CAN FD (mixed mode);
* 31 FIFOs configuráveis como TX ou RX;
* TX Queue para transmissão por prioridade;
* TX Event FIFO para confirmação de transmissão;
* ECC na RAM (1-bit correção, 2-bit deteção);
* SPI CRC para deteção de ruído na interface SPI;
* Modos: Normal FD, Normal CAN 2.0, Sleep, Low Power, Listen Only, Loopback, Configuration;
* Interrupt pins: INT, INT0/GPIO0, INT1/GPIO1 (active low);
* CLKO/SOF output;
* XSTBY para controlo automático de standby do transceiver;
* Disponível em versões Extended (-40 a +125°C) e High (-40 a +150°C).

## 3.3 Pinout (SOIC-14)

| Pin | Nome | Tipo | Descrição |
|-----|------|------|-----------|
| 1 | TXCAN | Output | Saída para transceiver CAN |
| 2 | RXCAN | Input | Entrada do transceiver CAN |
| 3 | CLKO/SOF | Output | Clock output / Start of Frame |
| 4 | INT | Output | Interrupt output (active low) |
| 5 | OSC2 | Output | Saída do oscilador |
| 6 | OSC1 | Input | Entrada do oscilador |
| 7 | VSS | Power | Ground |
| 8 | INT1/GPIO1 | I/O | RX Interrupt / GPIO |
| 9 | INT0/GPIO0/XSTBY | I/O | TX Interrupt / GPIO / Transceiver Standby |
| 10 | SCK | Input | SPI clock |
| 11 | SDI | Input | SPI data in (MOSI) |
| 12 | SDO | Output | SPI data out (MISO) |
| 13 | nCS | Input | SPI chip select (active low) |
| 14 | VDD | Power | Positive supply (2.7-5.5V) |

## 3.4 Circuito Típico

```text
                        3.3V                    5V
                         │                       │
                        ┌┴┐                     ┌┴┐
                        │ │10kΩ                 │ │10kΩ
                        └┬┘                     └┬┘
                         │                       │
              ┌──────────┼───────────────────────┼──────────┐
              │          │                       │          │
              │    ┌─────┴─────┐          ┌──────┴──────┐   │
              │    │  MCP2518FD │          │  MCP2562FD  │   │
              │    │           │          │  (Transcvr) │   │
              │    │   VDD─────┤──3.3V    │  VDD────5V  │   │
              │    │   VSS─────┤──GND     │  VIO───3.3V │   │
              │    │   nCS─────┤──GPIO    │  TXD───TXCAN│   │
              │    │   SCK─────┤──SPI_CLK │  RXD───RXCAN│   │
              │    │   SDI─────┤──SPI_MOSI│  STBY──XSTBY│   │
              │    │   SDO─────┤──SPI_MISO│             │   │
              │    │   INT─────┤──GPIO    │  CANH───120Ω│   │
              │    │   OSC1────┤──40MHz   │  CANL───    │   │
              │    │   OSC2────┤──40MHz   │             │   │
              │    └───────────┘          └─────────────┘   │
              │                                             │
              │    ┌───────────────────┐                    │
              │    │  Cristal 40 MHz   │                    │
              │    │  + 2×22pF caps    │                    │
              │    └───────────────────┘                    │
              │                                             │
              │    Decoupling: 100nF no VDD, 10µF no rail   │
              └─────────────────────────────────────────────┘
```

## 3.5 Driver Linux (RaspberryPi)

O MCP2518FD é suportado no kernel Linux principal desde a versão 5.10:

* Driver: `drivers/net/can/spi/mcp251xfd`
* Backports disponíveis em: `files.linux4microchip.com/pub/mcp251xfd/`

**Configuração em `/boot/firmware/config.txt`:**

```text
dtparam=spi=on
dtoverlay=mcp251xfd,spi0-0,oscillator=40000000,interrupt=12
```

**Verificação após reboot:**

```bash
dmesg | grep mcp251xfd
# Output esperado:
# mcp251xfd spi0.0 can0: MCP2517FD rev0.0 (...) successfully initialized.

ip link set can0 up type can bitrate 500000 dbitrate 2000000 fd on
```

## 3.6 Bibliotecas ESP-IDF

Para ESP32-S3, existem várias bibliotecas disponíveis:

* **MCP251XFD** (Emandhal) — Arduino/PlatformIO, completa
* **Longan_CANFD** (Longan Labs) — Arduino, simplificada
* **ESP-IDF nativa** — via SPI driver + registo manual

---

# 4. MCP251863 — Solução Integrada

## 4.1 Resumo

| Campo | Valor |
|-------|-------|
| Fabricante | Microchip Technology |
| Part Number | MCP251863 |
| Conteúdo | MCP2518FD (controlador) + ATA6563 (transceiver) |
| Interface | SPI (até 20 MHz) |
| CAN FD | Sim (ISO 11898-1:2015) |
| Bitrate arbitragem | Até 1 Mbps |
| Bitrate dados | Até 8 Mbps |
| RAM | 2 KB |
| Alimentação | VDD: 4.5-5.5V, VIO: 1.7-5.5V |
| Temperatura | -40 a +125°C (E) ou -40 a +150°C (H) |
| Package | VQFN-28 (5×5 mm), SSOP-28 |
| ESD (bus) | ±8 kV (IEC 61000-4-2) |
| Standby current | 12 µA |
| Preço (unit) | ~$2.17-2.39 (Microchip Direct) |
| Preço (1000+) | ~$1.44-1.55 |
| Datasheet | [DS20006624B](https://ww1.microchip.com/downloads/aemDocuments/documents/APID/ProductDocuments/DataSheets/MCP251863-External-CAN-FD-Controller-with-Integrated-Transceiver-DS20006624.pdf) |

## 4.2 Vantagens

* **Menor BOM** — Um chip em vez de dois;
* **Menor footprint** — VQFN-28 (5×5 mm) vs dois packages separados;
* **Menor complexidade de PCB** — Menos traços SPI, menos components;
* **Custo reduzido** — ~$2.20 vs ~$3.50 (controlador + transceiver separados);
* **Fail-safe integrado** — Overtemperature, short-circuit, undervoltage.

## 4.3 Desvantagens

* **Transceiver não isolado** — Não adequado para o bus de segurança;
* **Menos flexibilidade** — Não permite escolher transceiver diferente;
* **Package VQFN** — Mais difícil de soldar em prototipagem (vs SOIC).

## 4.4 Quando Usar

| Cenário | Componente |
|---------|-----------|
| Bus operacional (todos os Grupos) | MCP251863 (simplifica BOM) |
| Bus segurança (ESP32-FS → ESP32-FS_A) | MCP2518FD + ISO1042 (isolamento obrigatório) |
| Prototipagem com breadboard | MCP2518FD + MCP2562FD (SOIC, mais fácil) |

---

# 5. Comparação

| Característica | MCP2518FD | MCP251863 |
|---------------|-----------|-----------|
| Controlador CAN FD | Sim | Sim |
| Transceiver integrado | Não | Sim (ATA6563) |
| Interface | SPI | SPI |
| Bitrate dados | 8 Mbps | 8 Mbps |
| RAM | 2 KB | 2 KB |
| FIFOs | 31 | 31 |
| Temperatura | -40 a +150°C | -40 a +150°C |
| Package | SOIC-14 / VDFN-14 | VQFN-28 / SSOP-28 |
| Preço unit | ~$2.50 | ~$2.20 |
| Isolamento disponível | Com ISO1042 | Não |
| Driver Linux | Sim (mainline) | Não documentado |
| Avaliação Aerus | **Recomendado** | **Recomendado (operacional)** |

---

# 6. Avaliação para o Aerus

## 6.1 Recomendação

| Grupo | Componente | Justificação |
|-------|-----------|-------------|
| RaspberryPi | MCP2518FD | Driver Linux mainline, flexibilidade |
| ESP32-S | MCP2518FD ou MCP251863 | Ambos válidos; MCP251863 reduz BOM |
| ESP32-A | MCP2518FD ou MCP251863 | Idem |
| ESP32-FS (bus operacional) | MCP251863 | Simplifica design |
| ESP32-FS (bus segurança) | MCP2518FD + ISO1042 | Isolamento obrigatório |
| ESP32-FS_A | MCP2518FD + ISO1042 | Isolamento obrigatório |

## 6.2 Pontos de Atenção

* Oscilador externo obrigatório (40 MHz recomendado);
* Decoupling caps: 100nF ceramics no VDD, mais 10µF no rail;
* SPI traces curtos (<10cm recomendado);
* Pull-up no nCS se partilhado com outros dispositivos SPI;
* XSTBY pode controlar automaticamente o standby do transceiver;
* Temperatura -40 a +150°C (versão High) recomendada para voo.

---

# 7. Referências

- [MCP2518FD Datasheet](https://ww1.microchip.com/downloads/aemDocuments/documents/OTH/ProductDocuments/DataSheets/External-CAN-FD-Controller-with-SPI-Interface-DS20006027B.pdf)
- [MCP251863 Datasheet](https://ww1.microchip.com/downloads/aemDocuments/documents/APID/ProductDocuments/DataSheets/MCP251863-External-CAN-FD-Controller-with-Integrated-Transceiver-DS20006624.pdf)
- [MCP2518FD Product Page](https://www.microchip.com/en-us/product/MCP2518FD)
- [MCP251863 Product Page](https://www.microchip.com/en-us/product/mcp251863)
- [Linux Driver mcp251xfd](https://github.com/torvalds/linux/tree/master/drivers/net/can/spi/mcp251xfd)
- COM-008 — CAN Bus
- HW-CAN-000 — Panorama Geral
