# 05 — Conectores CAN Bus

| Campo             | Valor                              |
| ----------------- | ---------------------------------- |
| **Código**        | HW-CAN-005                         |
| **Título**        | Conectores CAN Bus                 |
| **Versão**        | 1.0                                |
| **Estado**        | Em Desenvolvimento                 |
| **Autor**         | ShegaPT                            |
| **Classificação** | Documentação de Hardware           |

---

# 1. Objetivo

O presente documento detalha os conectores CAN Bus candidatos a implementação no Aerus.

---

# 2. Requisitos

| Requisito   | Valor                         |
|-------------|-------------------------------|
| Pinos       | Mínimo 2 (CAN_H, CAN_L) + GND |
| Impedância  | 120Ω (compatível com cabo)    |
| Temperatura | -40 a +150°C                  |
| Proteção    | IP67 (para instalação final)  |
| Robustez    | Resistente a vibração         |

---

# 3. DB9 (D-Sub 9) — Padrão CiA 303-1

## 3.1 Especificação

| Campo            | Valor                                   |
|------------------|-----------------------------------------|
| Norma            | CiA 303-1 / CiA 106                     |
| Pinos            | 9 (D-Sub macho na placa, fêmea no cabo) |
| Impedância       | 120Ω (quando com cabo blindado)         |
| Corrente por pin | 1A                                      |
| Temperatura      | -25 a +85°C (típico)                    |
| Preço            | ~$1-5 (conector)                        |

## 3.2 Pinout CAN (CiA 303-1)

| Pin | Sinal   | Descrição                                 |
|-----|---------|-------------------------------------------|
| 1   | —       | Não conectado / +5V opcional              |
| 2   | CAN_L   | CAN Low                                   |
| 3   | CAN_GND | CAN Ground                                |
| 4   | —       | Não conectado                             |
| 5   | —       | Não conectado                             |
| 6   | CAN_GND | CAN Ground (internamente ligado ao pin 3) |
| 7   | CAN_H   | CAN High                                  |
| 8   | —       | Não conectado                             |
| 9   | —       | Não conectado                             |

## 3.3 Vantagens

* Padrão amplamente utilizado em CAN/DeviceNet/CANopen;
* Disponibilidade global;
* Fácil debug — multímetro osciloscópio ligam diretamente;
* Usado por PEAK, Kvaser, e maioria das ferramentas CAN.

## 3.4 Desvantagens

* Não é IP67 — inadequado para instalação exposta;
* Tamanho relativamente grande;
* Pode soltar com vibração (sem travamento).

## 3.5 Avaliação Aerus

**RECOMENDADO para:** Debug, prototipagem, instalações internas.
**NÃO recomendado para:** Instalação final na aeronave (sem IP67).

---

# 4. M12 A-coded 5-pin

## 4.1 Especificação

| Campo | Valor                               |
|------------------|--------------------------|
| Norma            | IEC 61076-2-101          |
| Coding           | A-coded (geral)          |
| Pinos            | 5                        |
| IP               | IP67 / IP68              |
| Corrente por pin | 4A                       |
| Tensão           | Até 250V AC/DC           |
| Temperatura      | -25 a +85°C (típico)     |
| Preço            | ~$5-15 (conector + cabo) |

## 4.2 Pinout CAN (A-coded 5-pin)

| Pin | Sinal  | Descrição              |
|-----|--------|------------------------|
| 1   | V+     | Alimentação (opcional) |
| 2   | CAN_H  | CAN High               |
| 3   | CAN_L  | CAN Low                |
| 4   | GND    | Ground                 |
| 5   | SHIELD | Shield / Earth         |

## 4.3 Vantagens

* IP67/IP68 — adequado para ambientes hostis;
* Travamento roscado — resistente a vibração;
* Compacto;
* Suportado por binder, Amphenol, TE Connectivity;
* Usado em NMEA 2000 (marinha), DeviceNet, automação industrial.

## 4.4 Desvantagens

* Mais caro que DB9;
* Menos ferramentas com conector M12 diretamente;
* Necessita adaptador M12→DB9 para debug.

## 4.5 Avaliação Aerus

**RECOMENDADO para:** Instalação final na aeronave (IP67, robustez).

---

# 5. Terminais de Parafuso

## 5.1 Especificação

| Campo       | Valor                      |
|-------------|----------------------------|
| Tipo        | Screw terminal block       |
| Pinos       | 2 ou 3 (CAN_H, CAN_L, GND) |
| Passo       | 2.54mm / 3.5mm / 5.08mm    |
| Corrente    | 5-10A                      |
| Temperatura | -30 a +70°C (típico)       |
| Preço       | ~$0.50-2                   |

## 5.2 Vantagens

* Extremamente barato;
* Fácil de ligar/desligar;
* Adequado para prototipagem em breadboard/PCB.

## 5.3 Desvantagens

* Sem proteção IP;
* Solta facilmente com vibração;
* Não é padrão CAN.

## 5.4 Avaliação Aerus

**Útil para:** Prototipagem em laboratório. NÃO para instalação final.

---

# 6. Comparação

| Conector        | Pinos | IP   | Vibração | Preço  | Debug | Voo | Protótipo |
|-----------------|-------|------|----------|--------|-------|-----|-----------|
| DB9 (CiA 303-1) | 9     | Não  | Média    | ~$2-5  | ✅    | ⚠️  | ✅        |
| M12 A-coded     | 5     | IP67 | Alta     | ~$5-15 | ⚠️    | ✅  | ⚠️        |
| Terminais       | 2-3   | Não  | Baixa    | ~$0.50 | ✅    | ❌  | ✅        |

---

# 7. Recomendação Aerus

| Fase              | Conector          | Justificação                    |
|-------------------|-------------------|---------------------------------|
| Protótipo / Debug | DB9 (CiA 303-1)   | Padrão CAN, fácil debug         |
| Instalação final  | M12 A-coded 5-pin | IP67, robustez, vibração        |
| Adaptador         | M12 → DB9         | Para ligar ferramentas de debug |

---

# 8. Referências

- CiA 303-1 — CAN physical layer connector
- CiA 106 — CAN physical layer pinout
- IEC 61076-2-101 — M12 connectors
- COM-008 — CAN Bus
- HW-CAN-000 — Panorama Geral
