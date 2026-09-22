# 03 — Soluções Isoladas CAN FD

| Campo             | Valor                              |
| ----------------- | ---------------------------------- |
| **Código**        | HW-CAN-003                         |
| **Título**        | Soluções Isoladas CAN FD           |
| **Versão**        | 1.0                                |
| **Estado**        | Em Desenvolvimento                 |
| **Autor**         | ShegaPT                            |
| **Classificação** | Documentação de Hardware           |

---

# 1. Objetivo

O presente documento detalha as soluções de transceivers CAN FD com isolamento galvânico, necessárias para o bus de segurança do Aerus.

---

# 2. Por que Isolamento Galvânico

O isolamento galvânico separa eletricamente o domínio do microcontrolador do domínio do barramento CAN.

**No contexto do Aerus, é obrigatório para:**

* Bus de segurança (ESP32-FS ↔ ESP32-FS_A);
* Prevenção de correntes de terra entre Grupos;
* Proteção contra picos de tensão no bus;
* Separação entre domínio operacional e domínio de segurança.

```text
┌──────────────┐    ┌───────────────┐    ┌──────────────┐
│  MCP2518FD   │    │   ISO1042     │    │   Bus CAN    │
│  (Controller)│───→│  (Isolated    │───→│  (Segurança) │
│              │←───│  Transceiver) │←───│              │
└──────────────┘    └───────────────┘    └──────────────┘
     MCU Side         ║  Barreira  ║        Bus Side
                      ║  Galvânica ║
                      ║  5000 VRMS ║
```

**Requisitos do Aerus (COM-008 §10):**

| Parâmetro                            | Valor            |
|--------------------------------------|------------------|
| Tensão de isolamento                 | ≥2500 VRMS       |
| CMC (Common-Mode Transient Immunity) | ≥100 V/µs        |
| Temperatura                          | -40 a +125°C     |
| CAN FD                               | Sim — até 5 Mbps |

---

# 3. ISO1042 — Solução Recomendada

## 3.1 Resumo

| Campo                       | Valor                                 |
|-----------------------------|---------------------------------------|
| Fabricante                  | Texas Instruments                     |
| Part Number                 | ISO1042DWR                            |
| Tipo                        | Isolated CAN FD Transceiver           |
| Padrão                      | ISO 11898-2:2016                      |
| CAN FD                      | Sim — até 5 Mbps                      |
| CAN 2.0                     | Sim — até 1 Mbps                      |
| Isolamento                  | Galvânico (SiO₂ barrier)               |
| Tensão de isolamento        | 5000 VRMS (reinforced: 10 kVPK surge) |
| Working voltage             | 1060 VRMS                             |
| DC bus fault protection     | ±70 V                                 |
| Common-mode range           | ±30 V                                 |
| CMC                         | 100 kV/µs                             |
| ESD (bus, HBM)              | ±16 kV                                |
| Loop delay                  | 138 ns (typical)                      |
| Alimentação VCC1 (MCU side) | 1.71V a 5.5V                          |
| Alimentação VCC2 (bus side) | 4.5V a 5.5V                           |
| Temperatura                 | -40 a +125°C                          |
| Packages                    | SOIC-16 (DW), SOIC-8 (DWV)            |
| Versão automotive           | ISO1042-Q1                            |
| Preço (unit)                | ~$5.28 (Digikey)                      |
| Preço (1000+)               | ~$2.94-2.96                           |

**Datasheet** --- [ISO1042] --- (https://www.ti.com/lit/ds/symlink/iso1042.pdf)

## 3.2 Características

* Isolamento reforçado com SiO₂ (silicon dioxide);
* Baixo loop delay (138 ns) — adequado para CAN FD 5 Mbps;
* Proteção contra ±70V DC no bus;
* ESD ±16 kV nos pins do bus;
* CMC 100 kV/µs — imune a transientes rápidos;
* Alimentação VCC1 flexível (1.71-5.5V) — compatível com 1.8V, 2.5V, 3.3V e 5V;
* VCC2 fixo a 5V — maximiza SNR no bus;
* Modo standby (ISO1042-Q1);
* Versão automotive qualificada (-Q1) disponível.

## 3.3 Pinout (SOIC-16 DW)

| Pin | Nome | Descrição                           |
|-----|------|-------------------------------------|
| 1   | TXD  | Data input (MCU side)               |
| 2   | VCC1 | Supply voltage MCU side (1.71-5.5V) |
| 3   | RXD  | Data output (MCU side)              |
| 4   | GND1 | Ground MCU side                     |
| 5   | NC   | Not connected                       |
| 6   | NC   | Not connected                       |
| 7   | NC   | Not connected                       |
| 8   | NC   | Not connected                       |
| 9   | NC   | Not connected                       |
| 10  | NC   | Not connected                       |
| 11  | CANH | CAN High (bus side)                 |
| 12  | CANL | CAN Low (bus side)                  |
| 13  | GND2 | Ground bus side                     |
| 14  | VCC2 | Supply voltage bus side (4.5-5.5V)  |
| 15  | NC   | Not connected                       |
| 16  | NC   | Not connected                       |

**NOTA:** No package SOIC-8 (DWV), os pins são compactos. Verificar datasheet para pinout específico.

## 3.4 Circuito Típico

```text
     MCU Side                          Bus Side
  ┌─────────────┐                 ┌─────────────┐
  │             │                 │             │
  │  3.3V ──────┤ VCC1      CANH  ├────── Bus CAN_H
  │             │                 │             │
  │  GND1 ──────┤ GND1      CANL  ├────── Bus CAN_L
  │             │                 │             │
  │  GPIO ──────┤ TXD       VCC2  ├────── 5V    │
  │             │                 │             │
  │  GPIO ──────┤ RXD       GND2  ├────── GND2  │
  │             │                 │             │
  └─────────────┘                 └─────────────┘
       │                                 │
       ║        Barreira Galvânica       ║
       ║           (5000 VRMS)           ║
       ║                                 ║

  NOTAS:
  - VCC1 = 3.3V (alimentação do MCU)
  - VCC2 = 5V (alimentação do bus side)
  - GND1 e GND2 são ELÉTRICAMENTE SEPARADOS
  - 100nF decoupling em VCC1 e VCC2
  - 10µF bulk no rail de 5V
```

## 3.5 Requisitos de Alimentação

O ISO1042 requer **duas fontes de alimentação isoladas**:

| Alimentação     | Tensão | Origem                 |
|-----------------|--------|------------------------|
| VCC1 (MCU side) | 3.3V   | Fonte principal do MCU |
| VCC2 (bus side) | 5V     | Fonte isolada dedicada |

**Fontes de alimentação isoladas recomendadas:**

| Componente  | Fabricante     | Tensão              | Potência | Preço |
|-------------|----------------|---------------------|----------|-------|
| TPS55010-Q1 | TI             | 5V in → 5V out      | 1W       | ~$3-5 |
| SN6501      | TI             | 3.3/5V in → isolado | —        | ~$2-3 |
| B0505S-1WR3 | Murata/Mornsun | 5V in → 5V out      | 1W       | ~$2-3 |
| MEE3S505SC  | Mean Well      | 5V in → 5V out      | 3W       | ~$5-8 |

**Para prototipagem:** Um módulo isolado B0505S (~$2) é suficiente.
**Para voo:** Fonte isolada qualificada ( automotive grade).

---

# 4. ISO1050 — Alternativa (CAN Clássico)

## 4.1 Resumo

| Campo                | Valor                            |
|----------------------|----------------------------------|
| Fabricante           | Texas Instruments                |
| Part Number          | ISO1050DUBR                      |
| Tipo                 | Isolated CAN Transceiver         |
| Padrão               | ISO 11898-2                      |
| CAN FD               | **NÃO** — apenas CAN 2.0         |
| CAN 2.0              | Sim — até 1 Mbps                 |
| Isolamento           | Galvânico (SiO₂)                 |
| Tensão de isolamento | 5000 VRMS (DW) / 2500 VRMS (DUB) |
| CMC                  | 50 kV/µs                         |
| ESD                  | ±4 kV                            |
| Temperatura          | -40 a +105°C                     |
| Package              | SOIC-16 (DW), SOP-8 (DUB)        |
| Preço (unit)         | ~$3.36-4.03                      |

**Datasheet** --- [ISO1050] --- (https://www.ti.com/lit/ds/symlink/iso1050.pdf)

## 4.2 Avaliação

| Critério    | Avaliação                         |
|-------------|-----------------------------------|
| CAN FD      | ❌ NÃO suporta — apenas CAN 2.0   |
| CMC         | ⚠️ 50 kV/µs (inferior ao ISO1042) |
| ESD         | ⚠️ ±4 kV (inferior ao ISO1042)    |
| Temperatura | ⚠️ -40 a +105°C (inferior)        |

**Veredicto: NÃO RECOMENDADO para o Aerus. Não suporta CAN FD.**

---

# 5. ADM3053 — Alternativa Analog Devices

## 5.1 Resumo

| Campo                | Valor                    |
|----------------------|--------------------------|
| Fabricante           | Analog Devices           |
| Part Number          | ADM3053BRWZ              |
| Tipo                 | Isolated CAN Transceiver |
| Padrão               | ISO 11898-2              |
| CAN FD               | Sim — até 5 Mbps         |
| Isolamento           | Galvânico (iCoupler)     |
| Tensão de isolamento | 5000 VRMS                |
| CMC                  | ≥25 kV/µs                |
| Alimentação          | 3.3V ou 5V               |
| Temperatura          | -40 a +105°C             |
| Package              | SOIC-20                  |
| Preço (unit)         | ~$6-8 (Mouser)           |

## 5.2 Avaliação

| Critério    | Avaliação                             |
|-------------|---------------------------------------|
| CAN FD      | ✅ Sim — até 5 Mbps                   |
| Isolamento  | ✅ 5000 VRMS                          |
| CMC         | ✅ ≥25 kV/µs                          |
| Temperatura | ⚠️ -40 a +105°C (inferior ao ISO1042) |
| Preço       | ⚠️ ~$6-8 (mais caro que ISO1042)      |
| Package     | ⚠️ SOIC-20 (maior)                    |

**Veredicto: ALTERNATIVA VÁLIDA, mas ISO1042 é superior em temperatura e preço.**

---

# 6. Comparação

| Característica | ISO1042        | ISO1050        | ADM3053      |
|----------------|----------------|----------------|--------------|
| CAN FD         | ✅ 5 Mbps      | ❌ 1 Mbps      | ✅ 5 Mbps    |
| Isolamento     | 5000 VRMS      | 5000/2500 VRMS | 5000 VRMS    |
| CMC            | 100 kV/µs      | 50 kV/µs       | 25 kV/µs     |
| ESD (bus)      | ±16 kV         | ±4 kV          | ±8 kV        |
| Bus fault      | ±70V DC        | ±27V DC        | ±27V DC      |
| Temperatura    | -40 a +125°C   | -40 a +105°C   | -40 a +105°C |
| VCC1           | 1.71-5.5V      | 3.3/5V         | 3.3/5V       |
| Package        | SOIC-16/8      | SOIC-16/SOP-8  | SOIC-20      |
| Preço          | ~$5.28         | ~$3.36         | ~$6-8        |
| Qualificação   | -Q1 disponível | —              | —            |

---

# 7. Avaliação para o Aerus

## 7.1 Recomendação

| Bus                    | Componente              | Justificação                       |
|------------------------|-------------------------|------------------------------------|
| Operacional            | MCP2562FD (não isolado) | Sem necessidade de isolamento      |
| Segurança (ESP32-FS)   | **ISO1042**             | CAN FD + isolamento + CMC 100kV/µs |
| Segurança (ESP32-FS_A) | **ISO1042**             | Idem                               |

## 7.2 Quantidades para Protótipo

| Componente                  | Quantidade                | Custo       |
|-----------------------------|---------------------------|-------------|
| ISO1042DWR                  | 2 (ESP32-FS + ESP32-FS_A) | ~$10.56     |
| B0505S-1WR3 (fonte isolada) | 2                         | ~$4.00      |
| **Total isolamento**        |                           | **~$14.56** |

## 7.3 Pontos de Atenção

* GND1 e GND2 **não** devem ser ligados entre si;
* Ambos os lados necessitam de decoupling caps (100nF + 10µF);
* O cabo no bus de segurança deve ser twisted pair 120Ω shielded;
* A terminação 120Ω deve estar presente em ambas as extremidades do bus de segurança;
* Considerar ESD protection TVS nos pins CAN_H/CAN_L.

---

# 8. Referências

- [ISO1042 Datasheet](https://www.ti.com/lit/ds/symlink/iso1042.pdf)
- [ISO1050 Datasheet](https://www.ti.com/lit/ds/symlink/iso1050.pdf)
- [ADM3053 Product Page](https://www.analog.com/en/products/adm3053.html)
- COM-008 — CAN Bus §10 (Isolamento Galvânico)
- COM-007 — Comunicação entre Domínios Computacionais
- HW-CAN-000 — Panorama Geral
- HW-CAN-002 — Transceivers CAN FD
