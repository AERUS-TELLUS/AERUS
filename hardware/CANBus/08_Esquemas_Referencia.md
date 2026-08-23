# 08 — Esquemas de Referência CAN Bus

| Campo             | Valor                              |
| ----------------- | ---------------------------------- |
| **Código**        | HW-CAN-008                         |
| **Título**        | Esquemas de Referência CAN Bus     |
| **Versão**        | 1.0                                |
| **Estado**        | Em Desenvolvimento                 |
| **Autor**         | ShegaPT                            |
| **Classificação** | Documentação de Hardware           |

---

# 1. Objetivo

O presente documento apresenta os circuitos de referência para implementação do CAN Bus no Aerus, incluindo ligação ESP32-S3 + MCP2518FD, circuito isolado, e ligação RaspberryPi.

---

# 2. ESP32-S3 + MCP2518FD + MCP2562FD (Operacional)

## 2.1 Diagrama de Ligação

```text
                          ESP32-S3
                    ┌─────────────────┐
                    │                 │
                    │  GPIO10 ────────┤── MOSI (SPI)
                    │  GPIO11 ────────┤── MISO (SPI)
                    │  GPIO12 ────────┤── SCK (SPI)
                    │  GPIO13 ────────┤── CS (MCP2518FD)
                    │  GPIO14 ────────┤── INT (MCP2518FD)
                    │  GPIO15 ────────┤── XSTBY (MCP2518FD)
                    │                 │
                    │  3.3V ──────────┤── VDD (MCP2518FD)
                    │  GND ───────────┤── VSS (MCP2518FD)
                    │                 │
                    └────────┬────────┘
                             │
                             │ SPI + Control
                             ▼
                    ┌─────────────────┐
                    │   MCP2518FD     │
                    │                 │
                    │  VDD ── 3.3V    │
                    │  VSS ── GND     │
                    │  nCS ── GPIO13  │
                    │  SCK ── GPIO12  │
                    │  SDI ── GPIO10  │
                    │  SDO ── GPIO11  │
                    │  INT ── GPIO14  │
                    │  XSTBY ─ GPIO15 │
                    │                 │
                    │  OSC1 ─┐        │
                    │  OSC2 ─┤ 40MHz  │
                    │        └┤ 22pF  │
                    │         ┤ 22pF  │
                    │         └GND    │
                    │                 │
                    │  TXCAN ────────┐│
                    │  RXCAN ───────┘│
                    └─────────────────┘
                             │
                    TXCAN/RXCAN
                             │
                             ▼
                    ┌─────────────────┐
                    │   MCP2562FD     │
                    │                 │
                    │  VDD ── 5V      │
                    │  VSS ── GND     │
                    │  VIO ── 3.3V    │
                    │  TXD ── TXCAN   │
                    │  RXD ── RXCAN   │
                    │  STBY ─ XSTBY   │
                    │                 │
                    │  CANH ──┬─ 120Ω ┬── Bus CAN_H
                    │  CANL ──┤       └── Bus CAN_L
                    └─────────┤
                              │
                         100nF─┴─GND
                         10µF ─┴─GND (no rail 5V)
```

## 2.2 Componentes

| Componente | Valor | Qtd | Notas |
|-----------|-------|-----|-------|
| MCP2518FD-E/SL | Controlador CAN FD | 1 | SOIC-14 |
| MCP2562FD-E/SN | Transceiver CAN FD | 1 | SOIC-8 |
| Cristal 40 MHz | Oscilador | 1 | HC49 ou SMD |
| Capacitor 22pF | Load caps cristal | 2 | C0G/NP0 |
| Capacitor 100nF | Decoupling | 3 | MLCC, 0402/0603 |
| Capacitor 10µF | Bulk | 1 | Tantalo ou MLCC |
| Resistor 120Ω | Terminação | 1 | 1%, 1/4W |
| Conector DB9 | CAN bus | 1 | Macho |
| Header SPI | Ligação ESP32 | 1 | 2×5 pinos |

## 2.3 Notas de PCB

* MCP2518FD e MCP2562FD: manter o mais próximo possível;
* Traços SPI: curtos (<10cm), evitar cruzamentos;
* Cristal: perto do OSC1/OSC2, GND plane nearby;
* Decoupling: 100nF o mais próximo possível dos pins VDD;
* CAN_H/CAN_L: differential pair, impedância controlada 120Ω;
* Terminação 120Ω: apenas num extremo do bus (se múltiplos nodos).

---

# 3. ESP32-FS + MCP2518FD + ISO1042 (Segurança — Isolado)

## 3.1 Diagrama de Ligação

```text
                          ESP32-FS
                    ┌─────────────────┐
                    │                 │
                    │  SPI_MOSI ──────┤── MOSI (MCP2518FD #1)
                    │  SPI_MISO ──────┤── MISO (MCP2518FD #1)
                    │  SPI_CLK ───────┤── SCK (MCP2518FD #1)
                    │  CS_OPER ───────┤── nCS (MCP2518FD #1 - operacional)
                    │  CS_SAFE ───────┤── nCS (MCP2518FD #2 - segurança)
                    │  INT_OPER ──────┤── INT (MCP2518FD #1)
                    │  INT_SAFE ──────┤── INT (MCP2518FD #2)
                    │                 │
                    │  3.3V ──────────┤── VDD (ambos MCP2518FD)
                    │  GND ───────────┤── VSS (ambos MCP2518FD)
                    │                 │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
              ▼              │              ▼
   ┌──────────────────┐     │     ┌──────────────────┐
   │   MCP2518FD #1   │     │     │   MCP2518FD #2   │
   │  (Operacional)   │     │     │   (Segurança)    │
   │                  │     │     │                  │
   │  TXCAN ─────┐    │     │     │    ┌───── TXCAN  │
   │  RXCAN ────┘│    │     │     │    │──── RXCAN   │
   └─────────────┼────┘     │     └────┼─────────────┘
                 │          │          │
                 ▼          │          ▼
   ┌──────────────────┐     │     ┌──────────────────┐
   │   MCP2562FD      │     │     │    ISO1042       │
   │  (Operacional)   │     │     │   (Isolado)      │
   │                  │     │     │                  │
   │  TXD ── TXCAN    │     │     │  TXD ── TXCAN    │
   │  RXD ── RXCAN    │     │     │  RXD ── RXCAN    │
   │  VDD ── 5V       │     │     │                  │
   │  VIO ── 3.3V     │     │     │  VCC1 ── 3.3V    │
   │                  │     │     │  GND1 ── GND     │
   │  CANH ───────────┼──┐  │     │  VCC2 ── 5V ISO  │
   │  CANL ───────────┼──┤  │     │  GND2 ── GND ISO │
   └──────────────────┘  │  │     │                  │
                         │  │     │  CANH ───────────┼──┐
                    120Ω─┤  │     │  CANL ───────────┼──┤
                         │  │     └──────────────────┘  │
                         │  │                            │
                    ┌────┴──┴──── Bus OPERACIONAL ───────┤
                    │                                     │
                    │  ┌──────────────────┐               │
                    │  │ Fonte Isolada    │               │
                    │  │ B0505S-1WR3      │               │
                    │  │                  │               │
                    │  │ 5V ──┐    ┌── 5V ISO            │
                    │  │      │DCDC│     │               │
                    │  │ GND ─┘    └── GND ISO           │
                    │  └──────────────────┘               │
                    │                                     │
                    │  ┌──── 120Ω ──── Bus SEGURANÇA ────┘
                    │  │
               ┌────┴──┴────┐
               │  ESP32-FS_A│
               │  (via bus  │
               │  segurança)│
               └────────────┘
```

## 3.2 Componentes Adicionais

| Componente | Valor | Qtd | Notas |
|-----------|-------|-----|-------|
| MCP2518FD-E/SL | Controlador CAN FD | 2 | Um por bus |
| ISO1042DWR | Transceiver isolado | 1 | Bus segurança |
| B0505S-1WR3 | Fonte DC-DC isolada | 1 | 5V→5V isolado |
| Capacitor 100nF | Decoupling (lado MCU) | 2 | ISO1042 VCC1 |
| Capacitor 100nF | Decoupling (lado bus) | 2 | ISO1042 VCC2 |
| Capacitor 10µF | Bulk (lado bus) | 1 | Rail 5V isolado |

## 3.3 Notas Importantes

* **GND1 e GND2 do ISO1042 NÃO devem ser ligados** — é a barreira galvânica;
* A fonte isolada B0505S fornece 5V separado para o lado do bus;
* Ambos os MCP2518FD partilham o SPI — usar CS separado (CS_OPER, CS_SAFE);
* O ESP32-FS pode ler ambos os buses e tomar decisões de segurança.

---

# 4. RaspberryPi + MCP2518FD HAT

## 4.1 Via HAT (2CH Isolated CAN FD HAT)

```text
                    RaspberryPi 5
                ┌──────────────────┐
                │                  │
                │  GPIO10 (MOSI) ──┤── SPI MOSI
                │  GPIO9 (MISO) ───┤── SPI MISO
                │  GPIO11 (SCLK) ──┤── SPI SCLK
                │  GPIO7 (CE0) ────┤── CS0 (CAN0)
                │  GPIO8 (CE1) ────┤── CS1 (CAN1)
                │  GPIO25 ─────────┤── INT0
                │  GPIO24 ─────────┤── INT1
                │                  │
                │  3.3V ───────────┤── VCC HAT
                │  5V ─────────────┤── Power HAT
                │  GND ────────────┤── GND HAT
                │                  │
                │  40-pin GPIO ────┤
                └────────┬─────────┘
                         │
                         ▼
                ┌──────────────────┐
                │  2CH Isolated    │
                │  CAN FD HAT      │
                │                  │
                │  MCP2518FD ×2    │
                │  MCP2562FD ×2    │
                │  5kV Isolation   │
                │                  │
                │  CAN0 ── DB9/120Ω│
                │  CAN1 ── DB9/120Ω│
                └──────────────────┘
```

## 4.2 Configuração Linux

```bash
# /boot/firmware/config.txt
dtparam=spi=on
dtoverlay=mcp251xfd,spi0-0,oscillator=40000000,interrupt=25
dtoverlay=mcp251xfd,spi0-1,oscillator=40000000,interrupt=24

# Após reboot
sudo ip link set can0 up type can bitrate 500000 dbitrate 2000000 fd on
sudo ip link set can1 up type can bitrate 1000000 dbitrate 5000000 fd on
```

---

# 5. Referências

- [MCP2518FD Datasheet — Typical Application](https://ww1.microchip.com/downloads/aemDocuments/documents/OTH/ProductDocuments/DataSheets/External-CAN-FD-Controller-with-SPI-Interface-DS20006027B.pdf)
- [ISO1042 Datasheet — Application Info](https://www.ti.com/lit/ds/symlink/iso1042.pdf)
- [ESP32-S3 Hardware Design Guidelines](https://docs.espressif.com/projects/esp-hardware-design-guidelines/en/latest/esp32s3/)
- [CANFDZeroHAT (GitHub)](https://github.com/generationmake/CANFDZeroHAT)
- COM-008 — CAN Bus
- HW-CAN-001 — Controladores CAN FD
- HW-CAN-002 — Transceivers CAN FD
- HW-CAN-003 — Soluções Isoladas
