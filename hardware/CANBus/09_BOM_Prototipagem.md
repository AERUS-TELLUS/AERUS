# 09 — BOM de Prototipagem CAN Bus

| Campo             | Valor                              |
| ----------------- | ---------------------------------- |
| **Código**        | HW-CAN-009                         |
| **Título**        | BOM de Prototipagem CAN Bus        |
| **Versão**        | 1.0                                |
| **Estado**        | Em Desenvolvimento                 |
| **Autor**         | ShegaPT                            |
| **Classificação** | Documentação de Hardware           |

---

# 1. Objetivo

O presente documento apresenta a lista de materiais (BOM) para prototipagem do CAN Bus no Aerus, com quantidades, preços estimados e fornecedores.

---

# 2. Cenário de Protótipo

O protótipo inicial inclui:

* 2× ESP32-S (sensores) — 1 canal CAN FD cada
* 1× RaspberryPi (orquestração) — 1 canal CAN FD
* 1× ESP32-A (actuadores) — 1 canal CAN FD
* 1× ESP32-FS (segurança) — 2 canais (operacional + segurança isolado)
* 1× ESP32-FS_A (emergência) — 1 canal CAN FD isolado
* 1× Ferramenta de debug (PCAN-USB FD)

---

# 3. BOM — Componentes CAN FD

## 3.1 Bus Operacional (não isolado)

| # | Componente               | Part Number       | Qtd | Preço Unit | Total       | Fornecedor     |
|---|--------------------------|-------------------|-----|------------|-------------|----------------|
| 1 | MCP2518FD-E/SL           | MCP2518FD-E/SLVAO | 5   | ~$2.50     | ~$12.50     | Mouser/Digikey |
| 2 | MCP2562FD-E/SN           | MCP2562FD-E/SN    | 4   | ~$1.00     | ~$4.00      | Mouser/Digikey |
| 3 | Cristal 40 MHz           | HC49S-40.000      | 5   | ~$0.50     | ~$2.50      | LCSC/Mouser    |
| 4 | Cap 22pF (cristal)       | 0402/0603 C0G     | 10  | ~$0.02     | ~$0.20      | LCSC           |
| 5 | Cap 100nF (decoupling)   | 0402/0603 MLCC    | 15  | ~$0.02     | ~$0.30      | LCSC           |
| 6 | Cap 10µF (bulk)          | 0805 MLCC         | 5   | ~$0.10     | ~$0.50      | LCSC           |
| 7 | Resistor 120Ω (term.)    | 0402/0603 1%      | 3   | ~$0.02     | ~$0.06      | LCSC           |
| 8 | Conector DB9 macho       | DE-9 macho        | 5   | ~$2.00     | ~$10.00     | Mouser         |
|   | **Subtotal operacional** |                   |     |            | **~$30.06** |                |

## 3.2 Bus Segurança (isolado)

| #  | Componente              | Part Number | Qtd | Preço Unit | Total       | Fornecedor     |
|----|-------------------------|-------------|-----|------------|-------------|----------------|
| 9  | ISO1042DWR              | ISO1042DWR  | 2   | ~$5.28     | ~$10.56     | Digikey/Mouser |
| 10 | B0505S-1WR3             | B0505S-1WR3 | 2   | ~$2.50     | ~$5.00      | LCSC/Mouser    |
| 11 | Cap 100nF (VCC1/VCC2)   | 0402/0603   | 4   | ~$0.02     | ~$0.08      | LCSC           |
| 12 | Cap 10µF (bulk 5V iso)  | 0805        | 2   | ~$0.10     | ~$0.20      | LCSC           |
|    | **Subtotal isolamento** |             |     |            | **~$15.84** |                |

## 3.3 Módulos de Desenvolvimento (alternativa ao BOM discreto)

| #  | Componente              | Qtd | Preço Unit | Total       | Notas                  |
|----|-------------------------|-----|------------|-------------|------------------------|
| 13 | LilyGo T-2Can-FD        | 2   | ~$27.00    | ~$54.00     | Para ESP32-S e ESP32-A |
| 14 | 2CH Isolated CAN FD HAT | 1   | ~$45.00    | ~$45.00     | Para RaspberryPi       |
|    | **Subtotal módulos**    |     |            | **~$99.00** |                        |

## 3.4 Ferramentas

| #  | Componente                | Qtd | Preço Unit | Total        | Notas     |
|----|---------------------------|-----|------------|--------------|-----------|
| 15 | PCAN-USB FD (IPEH-004022) | 1   | ~€298.00   | ~€298.00     | Debug CAN |
| 16 | Adaptador M12→DB9         | 1   | ~$39.00    | ~$39.00      | Opcional  |
|    | **Subtotal ferramentas**  |     |            | **~€337.00** |           |

## 3.5 Cabos

| #  | Componente                    | Qtd | Preço Unit | Total       | Notas     |
|----|-------------------------------|-----|------------|-------------|-----------|
| 17 | Cabo CAN 120Ω industrial (5m) | 2   | ~$5.00     | ~$10.00     | Protótipo |
| 18 | Cabo DB9 CAN (1m)             | 3   | ~$10.00    | ~$30.00     | Debug     |
|    | **Subtotal cabos**            |     |            | **~$40.00** |           |

---

# 4. Resumo de Custos

## 4.1 Cenário A: BOM Discreto (componentes separados)

| Categoria                  | Custo    |
|----------------------------|----------|
| Bus operacional (discreto) | ~$30     |
| Bus segurança (isolado)    | ~$16     |
| **Total hardware**         | **~$46** |

## 4.2 Cenário B: Módulos de Desenvolvimento

| Categoria               | Custo    |
|-------------------------|----------|
| LilyGo T-2Can-FD (×2)   | ~$54     |
| 2CH Isolated CAN FD HAT | ~$45     |
| **Total módulos**       | **~$99** |

## 4.3 Cenário C: Combinado (recomendado para protótipo)

| Categoria                                 | Custo            |
|-------------------------------------------|------------------|
| Módulos (RaspberryPi HAT + ESP32-S/A)     | ~$99             |
| ESP32-FS discreto (MCP2518FD + ISO1042)   | ~$20             |
| ESP32-FS_A discreto (MCP2518FD + ISO1042) | ~$15             |
| Cabos                                     | ~$40             |
| Ferramenta (PCAN-USB FD)                  | ~€298            |
| **Total protótipo**                       | **~$174 + €298** |

## 4.4 Total Estimado (protótipo completo)

| Item             | Custo (USD) | Custo (EUR) |
|------------------|-------------|-------------|
| Hardware CAN Bus | ~$174       | ~€160       |
| Ferramenta debug | —           | ~€298       |
| **TOTAL**        | **~$174**   | **~€458**   |

---

# 5. Fornecedores

## 5.1 Componentes

| Fornecedor       | Tipo                    | Vantagem                      | Site                |
|------------------|-------------------------|-------------------------------|---------------------|
| Mouser           | Distribuidor autorizado | Stock, rapidez, datasheets    | mouser.com          |
| Digikey          | Distribuidor autorizado | Stock, rapidez                | digikey.com         |
| LCSC             | Componentes             | Preço baixo, envio China      | lcsc.com            |
| Microchip Direct | Fabricante              | Amostras grátis, preço direto | microchipdirect.com |

## 5.2 Módulos e Ferramentas

| Fornecedor  | Tipo            | Notas                    |
|-------------|-----------------|--------------------------|
| Amazon      | Módulos         | Rapidez, devolução fácil |
| AliExpress  | Módulos budget  | Preço baixo, envio lento |
| Waveshare   | Módulos CAN     | Boa qualidade            |
| Mikroe      | Click boards    | Bibliotecas incluídas    |
| PEAK-System | Ferramentas CAN | Gold standard            |

## 5.3 Cabos

| Fornecedor | Tipo              | Notas                       |
|------------|-------------------|-----------------------------|
| L-com      | Cabos industriais | Barato, stock               |
| EDMO       | Cabos aerospace   | Gigaflight, Garmin approved |
| Gigaflight | Cabos aerospace   | Direto do fabricante        |

---

# 6. Notas de Compra

## 6.1 Quantidades para Protótipo

* 5× MCP2518FD (1 por grupo + 1 extra)
* 4× MCP2562FD (1 por grupo operacional)
* 2× ISO1042 (ESP32-FS + ESP32-FS_A)
* 2× B0505S-1WR3 (fonte isolada)
* 5× Cristal 40 MHz
* 5× Conector DB9
* 2× Cabo CAN industrial 5m
* 1× PCAN-USB FD

## 6.2 Amostras Grátis

A Microchip oferece amostras grátis do MCP2518FD e MCP251863 através do Microchip Direct.

## 6.3 Lead Times

| Componente       | Lead Time Típico          |
|------------------|---------------------------|
| MCP2518FD        | Em stock (Mouser/Digikey) |
| ISO1042          | 1-3 dias (Digikey)        |
| B0505S-1WR3      | 1-2 semanas (LCSC)        |
| PCAN-USB FD      | Em stock (PEAK)           |
| LilyGo T-2Can-FD | 1-2 semanas (AliExpress)  |
| 2CH Isolated HAT | Em stock (Waveshare)      |

---

# 7. Referências

- COM-008 — CAN Bus
- HW-CAN-000 — Panorama Geral
- HW-CAN-001 — Controladores CAN FD
- HW-CAN-002 — Transceivers CAN FD
- HW-CAN-003 — Soluções Isoladas
- HW-CAN-004 — Módulos de Desenvolvimento
- HW-CAN-005 — Conectores
- HW-CAN-006 — Cabos
- HW-CAN-007 — Ferramentas de Diagnóstico
