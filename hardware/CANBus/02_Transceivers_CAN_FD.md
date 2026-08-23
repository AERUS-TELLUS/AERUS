# 02 — Transceivers CAN FD

| Campo             | Valor                              |
| ----------------- | ---------------------------------- |
| **Código**        | HW-CAN-002                         |
| **Título**        | Transceivers CAN FD                |
| **Versão**        | 1.0                                |
| **Estado**        | Em Desenvolvimento                 |
| **Autor**         | ShegaPT                            |
| **Classificação** | Documentação de Hardware           |

---

# 1. Objetivo

O presente documento detalha os transceivers CAN FD candidatos a implementação no Aerus, incluindo especificações, preços, compatibilidade e avaliação.

---

# 2. Função do Transceiver

O transceiver CAN é a interface entre o controlador CAN (digital) e o barramento CAN (analógico diferencial).

```text
┌──────────────┐  TXCAN/RXCAN  ┌──────────────┐  CAN_H/CAN_L  ┌──────────┐
│  MCP2518FD   │ ─────────────→│  MCP2562FD   │ ─────────────→│   Bus    │
│ (Controlador │ ←─────────────│ (Transceiver)│ ←─────────────│  CAN FD  │
│   digital)   │               │  (analógico) │               │          │
└──────────────┘               └──────────────┘               └──────────┘
```

**Responsabilidades do transceiver:**

* Converter sinais digitais (TXD/RXD) em diferenciais (CAN_H/CAN_L);
* Detecção de dominant/recessive;
* Proteção contra curto-circuito e sobretensão no bus;
* Modo standby (baixo consumo);
* Deteção de erros físicos.

---

# 3. MCP2562FD — Transceiver Recomendado (Operacional)

## 3.1 Resumo

| Campo              | Valor                                        |
|--------------------|----------------------------------------------|
| Fabricante         | Microchip Technology                         |
| Part Number        | MCP2562FD                                    |
| Padrão             | ISO 11898-2:2016                             |
| CAN FD             | Sim — até 8 Mbps                             |
| CAN 2.0            | Sim — até 1 Mbps (retrocompatível)           |
| Alimentação VDD    | 4.5V a 5.5V                                  |
| Pin VIO            | Sim (1.8V a 5.5V) — interface direta com MCU |
| Standby mode       | Sim (via STBY pin)                           |
| Nós máximos no bus | 112                                          |
| Temperatura        | -40 a +125°C                                 |
| Package            | SOIC-8                                       |
| Preço (unit)       | ~$1.01 (Newark)                              |
| Preço (1000+)      | ~$0.70 estimado                              |

**Datasheet** --- [DS20005284] --- (https://ww1.microchip.com/downloads/aemDocuments/documents/APID/ProductDocuments/DataSheets/MCP2561-2FD-High-Speed-CAN-Flexible-Data-Rate-Transceiver-DS20005284.pdf) |

## 3.2 Características

* Loop Delay Symmetry — suporta CAN FD data rates elevados;
* VIO pin — permite interface direta com MCU a 3.3V sem level shifter;
* Modo standby com corrente reduzida;
* Proteção contra curto-circuito em CAN_H e CAN_L;
* Proteção térmica;
* Zero load no bus quando desligado;
* Retrocompatível com MCP2562 (drop-in replacement).

## 3.3 Pinout (SOIC-8)

| Pin | Nome | Descrição                    |
|-----|------|------------------------------|
| 1   | TXD  | Data input from controller   |
| 2   | VSS  | Ground                       |
| 3   | VDD  | Supply voltage (5V)          |
| 4   | RXD  | Data output to controller    |
| 5   | VIO  | I/O voltage level (1.8-5.5V) |
| 6   | CANL | CAN Low                      |
| 7   | CANH | CAN High                     |
| 8   | STBY | Standby input (active high)  |

## 3.4 Avaliação Aerus

| Critério                  | Avaliação                            |
|---------------------------|--------------------------------------|
| CAN FD 5+ Mbps            | ✅ Suporta até 8 Mbps                |
| Interface 3.3V            | ✅ Via VIO pin                       |
| Temperatura               | ✅ -40 a +125°C                      |
| Disponibilidade           | ✅ Amplamente disponível             |
| Preço                     | ✅ ~$1.00                            |
| Compatibilidade MCP2518FD | ✅ Par recomendado pela Microchip    |
| Isolamento                | ❌ Não — usar ISO1042 para segurança |

**Veredicto: RECOMENDADO para bus operacional.**

---

# 4. TJA1044GT — Alternativa NXP

## 4.1 Resumo

| Campo                | Valor                                   |
|----------------------|-----------------------------------------|
| Fabricante           | NXP Semiconductors                      |
| Part Number          | TJA1044GT/3Z                            |
| Família              | Mantis                                  |
| Padrão               | ISO 11898-2:2016, SAE J2284-1 a J2284-5 |
| CAN FD               | Sim — até 5 Mbps                        |
| CAN 2.0              | Sim — até 1 Mbps                        |
| Alimentação VCC      | 4.5V a 5.5V                             |
| Pin VIO              | Sim (3.3V a 5V)                         |
| Standby mode         | Sim (com wake-up por CAN)               |
| Loop delay (TXD→RXD) | 210 ns                                  |
| Temperatura          | -40 a +150°C                            |
| Package              | SOIC-8 (SOT96-1) ou HVSON8 (SOT782-1)   |
| AEC-Q100             | Sim                                     |
| Preço (unit)         | ~$1.00-1.50 (Mouser/Digikey)            |

**Datasheet** --- [TJA1044] --- (https://www.nxp.com/docs/en/data-sheet/TJA1044.pdf) |

## 4.2 Características

* Família Mantis — terceira geração CAN transceiver da NXP;
* Excelente EMC (sem CMC necessário em muitas aplicações);
* Comportamento passivo ideal quando alimentação desligada;
* Wake-up passivo e ativo no bus;
* Proteção ESD: 8 kV (IEC e HBM) nos pins do bus;
* Proteção contra transientes automotivos;
* AEC-Q100 qualificado — adequado para automóvel e aerospacial;
* Suportado no PCAN-USB FD da PEAK (referência de mercado).

## 4.3 Avaliação Aerus

| Critério                  | Avaliação                              |
|---------------------------|----------------------------------------|
| CAN FD 5+ Mbps            | ✅ Até 5 Mbps                          |
| Interface 3.3V            | ✅ Via VIO                             |
| Temperatura               | ✅ -40 a +150°C (melhor que MCP2562FD) |
| Qualificação              | ✅ AEC-Q100                            |
| EMC                       | ✅ Excelente, menos CMC necessário     |
| Preço                     | ✅ ~$1.00-1.50                         |
| Compatibilidade MCP2518FD | ✅ Compatível                          |
| Isolamento                | ❌ Não                                 |

**Veredicto: ALTERNATIVA VÁLIDA. Melhor temperatura e EMC que MCP2562FD.**

---

# 5. TCAN1042 — Alternativa TI

## 5.1 Resumo

| Campo        | Valor             |
|--------------|-------------------|
| Fabricante   | Texas Instruments |
| Part Number  | TCAN1042DR        |
| Padrão       | ISO 11898-2:2016  |
| CAN FD       | Sim — até 5 Mbps  |
| CAN 2.0      | Sim — até 1 Mbps  |
| Alimentação  | 4.5V a 5.5V       |
| Pin VIO      | Sim (1.8V a 5.5V) |
| Standby mode | Sim               |
| Temperatura  | -40 a +125°C      |
| Package      | SOIC-8            |
| Preço (unit) | ~$1.00-1.50       |

**Datasheet** --- [TCAN1042] --- (https://www.ti.com/lit/ds/symlink/tcan1042.pdf) |

## 5.2 Características

* Família TCAN da TI — amplamente utilizada em automóvel;
* Proteção integrada contra ESD e transientes;
* Modo standby com wake-up;
* Bundle version disponível (TCAN1042B — com proteções adicionais).

## 5.3 Avaliação Aerus

| Critério        | Avaliação                |
|-----------------|--------------------------|
| CAN FD 5+ Mbps  | ✅ Até 5 Mbps            |
| Interface 3.3V  | ✅ Via VIO               |
| Temperatura     | ✅ -40 a +125°C          |
| Preço           | ✅ ~$1.00-1.50           |
| Disponibilidade | ✅ Amplamente disponível |
| Isolamento      | ❌ Não                   |

**Veredicto: ALTERNATIVA VÁLIDA. Equivalente ao MCP2562FD.**

---

# 6. Comparação

| Característica    | MCP2562FD      | TJA1044GT       | TCAN1042      |
|-------------------|----------------|-----------------|---------------|
| Fabricante        | Microchip      | NXP             | TI            |
| CAN FD Mbps       | 8              | 5               | 5             |
| VIO pin           | Sim            | Sim             | Sim           |
| Standby           | Sim            | Sim (wake-up)   | Sim (wake-up) |
| Temperatura       | -40 a +125°C   | -40 a +150°C    | -40 a +125°C  |
| AEC-Q100          | Recomendado    | Sim             | Sim           |
| ESD (bus)         | Proteção       | 8 kV            | Proteção      |
| EMC               | Bom            | Excelente       | Bom           |
| Package           | SOIC-8         | SOIC-8 / HVSON8 | SOIC-8        |
| Preço             | ~$1.00         | ~$1.00-1.50     | ~$1.00-1.50   |
| Compat. MCP2518FD | ✅ Par oficial | ✅              | ✅            |

---

# 7. Circuito de Ligação

## 7.1 MCP2562FD com MCP2518FD

```text
                MCP2518FD                    MCP2562FD
              ┌───────────┐               ┌───────────┐
              │           │               │           │
    3.3V ─────┤ VDD       │               │ VDD  5V───┤──── 5V
              │           │               │           │
    GND ──────┤ VSS       │               │ VSS  GND──┤──── GND
              │           │               │           │
    GPIO ─────┤ nCS       │               │           │
              │           │               │           │
    SPI_CLK ──┤ SCK       │               │           │
              │           │               │           │
    SPI_MOSI ─┤ SDI       │               │           │
              │           │               │           │
    SPI_MISO ─┤ SDO       │               │           │
              │           │               │           │
              │      TXCAN├───────────────┤TXD        │
              │           │               │           │
              │      RXCAN├───────────────┤RXD        │
              │           │               │           │
    3.3V ─────┤ VIO ──────┤               │           │
              │           │               │           │
              │    XSTBY  ├──┐            │           │
              └───────────┘  │            │           │
                             │    STBY────┤           │
                             └────────────┘           │
                                                      │
                                        CANH──────────┤──── Bus CAN_H
                                        CANL──────────┤──── Bus CAN_L
                                                      │
                                              120Ω────┤──── (terminação)
```

## 7.2 Notas de Implementação

* VIO do MCP2518FD ligado a 3.3V (alimentação do MCU);
* VDD do MCP2562FD ligado a 5V (alimentação do transceiver);
* VIO do MCP2562FD ligado a 3.3V (compatibilidade com MCP2518FD);
* XSTBY pode controlar automaticamente STBY do transceiver;
* 120Ω de terminação apenas nas extremidades do bus;
* TCs de 100nF próximos dos pins de alimentação de cada chip.

---

# 8. Referências

- [MCP2562FD Datasheet](https://ww1.microchip.com/downloads/aemDocuments/documents/APID/ProductDocuments/DataSheets/MCP2561-2FD-High-Speed-CAN-Flexible-Data-Rate-Transceiver-DS20005284.pdf)
- [TJA1044 Datasheet](https://www.nxp.com/docs/en/data-sheet/TJA1044.pdf)
- [TCAN1042 Datasheet](https://www.ti.com/lit/ds/symlink/tcan1042.pdf)
- COM-008 — CAN Bus
- HW-CAN-001 — Controladores CAN FD
- HW-CAN-000 — Panorama Geral
