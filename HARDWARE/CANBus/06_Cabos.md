# 06 — Cabos CAN Bus

| Campo             | Valor                              |
| ----------------- | ---------------------------------- |
| **Código**        | HW-CAN-006                         |
| **Título**        | Cabos CAN Bus                      |
| **Versão**        | 1.0                                |
| **Estado**        | Em Desenvolvimento                 |
| **Autor**         | ShegaPT                            |
| **Classificação** | Documentação de Hardware           |

---

# 1. Objetivo

O presente documento detalha os cabos CAN Bus candidatos a implementação no Aerus, desde cabos industriais para prototipagem até cabos aerospaciais para voo.

---

# 2. Requisitos

| Requisito   | Valor                          | Origem             |
|-------------|--------------------------------|--------------------|
| Impedância  | 120Ω ±10%                      | COM-008 §8         |
| Tipo        | Twisted pair (par entrelaçado) | ISO 11898-2        |
| Blindagem   | Recomendado (foil + braid)     | Boa prática        |
| AWG         | 22-26 AWG                      | Conforme distância |
| Temperatura | -55 a +150°C (voo)             | HW-002             |
| Comprimento | Conforme topologia             | —                  |

---

# 3. Cabos Industriais

## 3.1 CAN BUS Bulk Cable (TKD/L-com)

| Campo       | Valor                  |
|-------------|------------------------|
| Modelo      | 2003675-F              |
| Impedância  | 120Ω                   |
| AWG         | 24 AWG (stranded)      |
| Pares       | 1                      |
| Blindagem   | SF/UTP double shielded |
| Jacket      | PVC, UL CMX, violeta   |
| Tensão      | 300V                   |
| Temperatura | -10 a +70°C            |
| Preço       | ~$0.85/pé              |
| Fornecedor  | L-com, Mouser          |

### Características

* Dupla blindagem (foil + braid) — boa proteção EMI;
* Cor roxa — identificação canônica CAN;
* Conforme ISO 11898;
* Flexível, adequado para instalações industriais.

### Limitações

* Temperatura máxima 70°C — inadequado para voo;
* Sem certificação aerospacial.

### Avaliação Aerus

**RECOMENDADO para:** Prototipagem, testes em laboratório, instalações internas.
**NÃO recomendado para:** Voo (temperatura insuficiente).

---

## 3.2 CAB BUS Cable (Phoenix Contact)

| Campo       | Valor                         |
|-------------|-------------------------------|
| Impedância  | 120Ω                          |
| AWG         | 22 AWG                        |
| Blindagem   | Braid                         |
| Jacket      | LSZH (Low Smoke Zero Halogen) |
| Temperatura | -30 a +80°C                   |

### Avaliação Aerus

Adequado para prototipagem. LSZH é uma vantagem para ambientes fechados.

---

# 4. Cabos Aerospace

## 4.1 Gigaflight GF120T-24CANB

| Campo               | Valor                                     |
|---------------------|-------------------------------------------|
| Fabricante          | Gigaflight                                |
| Part Number         | GF120T-24CANB                             |
| Aprovação           | **Garmin approved**                       |
| AWG                 | 24 AWG stranded                           |
| Impedância          | 120Ω                                      |
| Condutores          | Silver-plated HSCA                        |
| Isolação            | FEP (Fluoropolymer) interna + externa     |
| Blindagem           | Tin-plated copper braid, 92% min          |
| Jacket              | Tefzel (ETFE), laser markable             |
| Temperatura         | -55 a +150°C                              |
| Peso                | 17.5 lb/1000ft (26 kg/1000m)              |
| Diâmetro            | 3.56 mm                                   |
| Capacidade de dobra | 19.3 mm                                   |
| Impedância          | 120Ω                                      |
| Capacitância        | 11.5 pF/ft (37.7 pF/m)                    |
| Atenuação           | 1 MHz: 1.0 dB/100ft, 10 MHz: 2.7 dB/100ft |
| Tensão dielétrica   | 1.5 kV RMS                                |
| Preço               | ~$5-10/pé (contactar fornecedor)          |
| Fornecedor          | EDMO, Gigaflight direto                   |

### Características

* **Aprovado pela Garmin** para sistemas CAN Bus de aviação;
* Design dual-wall insulation —解决了 120Ω impedance + contact extraction issue;
* Laser wire markable — identificação permanente;
* Silver-plated conductors — máxima condutividade;
* ETFE (Tefzel) jacket — resistente a químicos, UV, abrasão;
* Qualificado para aviação.

### Avaliação Aerus

**RECOMENDADO para:** Instalação final na aeronave. Qualificação Garmin é um grande diferencial.

---

## 4.2 PIC D10226-0

| Campo       | Valor                                    |
|-------------|------------------------------------------|
| Fabricante  | PIC Wire & Cable                         |
| Part Number | D10226-0                                 |
| AWG         | 26 AWG                                   |
| Impedância  | 120Ω                                     |
| Condutores  | Silver-plated high strength copper alloy |
| Isolação    | FEP (foamed Fluoropolymer)               |
| Blindagem   | Silver-plated copper braid               |
| Jacket      | ETFE, laser markable                     |
| Temperatura | -65 a +200°C                             |
| Burn test   | EN3475-503                               |
| Preço       | Contactar fornecedor                     |

### Características

* Temperatura extremamente elevada (-65 a +200°C);
* Teste de queima conformidade;
* Alternativa ao Gigaflight.

### Avaliação Aerus

**Alternativa válida** ao Gigaflight. Temperatura superior.

---

## 4.3 Gore CAN Bus Cables

| Campo           | Valor                           |
|-----------------|---------------------------------|
| Fabricante      | W. L. Gore & Associates         |
| Tipo            | 120Ω controlled impedance       |
| Aplicação       | Aerospace & Defense             |
| Características | High speed, lifetime durability |
| Certificações   | Várias (verificar modelo)       |
| Preço           | Premium — contactar fornecedor  |

### Características

* Líder em cabos aerospaciais;
* Performance superior em EMI/RFI shielding;
* Durabilidade de longo prazo.

### Avaliação Aerus

**Opção premium** — ideal para sistemas críticos. Preço significativamente superior.

---

## 4.4 TE Raychem CHEMINAX

| Campo       | Valor                     |
|-------------|---------------------------|
| Fabricante  | TE Connectivity (Raychem) |
| Modelo      | 2022Y1422-9X              |
| AWG         | 22 AWG                    |
| Impedância  | 120Ω                      |
| Temperatura | -65 a +200°C              |
| Condutores  | 19 strands of AWG 34      |

### Avaliação Aerus

Alternativa industrial/aerospacial de alta temperatura.

---

# 5. Comparação

| Cabo                     | AWG   | Impedância | Temp         | Blindagem | Certificação| Preço/pé| Uso      |
|--------------------------|-------|------------|--------------|-----------|-------------|---------|----------|
| TKD 2003675-F            | 24    | 120Ω       | -10 a +70°C  | SF/UTP    | UL CMX      | ~$0.85  |Protótipo |
| Gigaflight GF120T-24CANB | 24    | 120Ω       | -55 a +150°C | Braid 92% | **Garmin**  | ~$5-10  | **Voo**  |
| PIC D10226-0             | 26    | 120Ω       | -65 a +200°C | Braid     | EN3475      | ~$5-8   | Voo      |
| Gore Aerospace           | 24-26 | 120Ω       | Variável     | Premium   | Multi       | ~$10+   | Premium  |
| TE Raychem               | 22    | 120Ω       | -65 a +200°C | Braid     | MIL-spec    | ~$8-12  | Voo      |

---

# 6. Recomendação Aerus

| Fase             | Cabo                     | Justificação                        |
|------------------|--------------------------|-------------------------------------|
| Protótipo / Lab  | TKD 2003675-F            | Barato, acessível, funciona         |
| Instalação final | Gigaflight GF120T-24CANB | Aprovado Garmin, -55 a +150°C       |
| Alternativa voo  | PIC D10226-0             | Temperatura superior (-65 a +200°C) |

---

# 7. Comprimentos Típicos

| Trecho                            | Distância Estimada | Cabo                      |
|-----------------------------------|--------------------|---------------------------|
| ESP32-S → ESP32-S (mesmo grupo)   | <0.5m              | Protótipo ou aerospace    |
| ESP32-S → RaspberryPi             | 0.5-2m             | Conforme instalação       |
| ESP32-FS → ESP32-FS_A (segurança) | 0.5-3m             | **Aerospace obrigatório** |
| Diagnostic port                   | 0.5m               | DB9 com cabo industrial   |

---

# 8. Referências

- [Gigaflight CAN Bus Cables](https://www.gigaflightinc.com/gf-cables/gf120t-24canb/)
- [PIC D10226-0](https://picwire.com/Product/D10226-0)
- [Gore CAN Bus Cables](https://www.gore.com/resources/data-sheet-gore-can-bus-cables-aerospace-defense)
- [L-com CAN Bus Cable](https://www.l-com.com/can-bus-controller-area-network-bulk-cable-1-pair-120-ohm-24awg-stranded-300v-sf-utp-double-shielded-ul-cmx-pvc-violet-per-foot-2003675-f)
- ISO 11898-2 — CAN physical layer
- COM-008 — CAN Bus §8 (Terminação)
