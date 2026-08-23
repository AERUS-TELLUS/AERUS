# 04 — Módulos de Desenvolvimento CAN FD

| Campo             | Valor                              |
| ----------------- | ---------------------------------- |
| **Código**        | HW-CAN-004                         |
| **Título**        | Módulos de Desenvolvimento CAN FD  |
| **Versão**        | 1.0                                |
| **Estado**        | Em Desenvolvimento                 |
| **Autor**         | ShegaPT                            |
| **Classificação** | Documentação de Hardware           |

---

# 1. Objetivo

O presente documento detalha os módulos de desenvolvimento, placas de avaliação e HATs CAN FD candidatos a prototipagem do Aerus.

---

# 2. Critérios de Seleção

| Critério | Requisito |
|----------|-----------|
| CAN FD | Sim — até 5+ Mbps |
| CAN 2.0B | Sim — extended ID 29-bit |
| ESP32-S3 compatível | Preferencial |
| RaspberryPi compatível | Para o Grupo RPi |
| Isolamento | Disponível (ou acessível externamente) |
| Preço | Competitivo para protótipo |
| Disponibilidade | Em stock |

---

# 3. MCP2518FD Click (MIKROE-3060)

## 3.1 Resumo

| Campo | Valor |
|-------|-------|
| Fabricante | MikroElektronika |
| Part Number | MIKROE-3060 |
| Controlador | MCP2518FD |
| Transceiver | MCP2562FD |
| Interface | mikroBUS (SPI) |
| CAN FD | Sim — até 8 Mbps |
| Conector | DE-9 (DB9) macho |
| Alimentação | 3.3V ou 5V |
| Oscilador | 40 MHz onboard |
| Isolamento | Não |
| Preço | ~$30 |
| Compatibilidade | Qualquer placa com mikroBUS |

## 3.2 Vantagens

* Pronto a usar — controlador + transceiver + oscilador + conector;
* Suportado por biblioteca mikroSDK;
* Exemplo de código disponível;
* Tamanho compacto.

## 3.3 Desvantagens

* Sem isolamento galvânico;
* Conector DB9 — pode necessitar adaptação para o Aerus;
* Preço elevado para múltiplas unidades (~$30 cada).

## 3.4 Avaliação Aerus

**Útil para:** Fases iniciais de prototipagem e validação de software.

---

# 4. MCP251863 Click (MIKROE)

## 4.1 Resumo

| Campo | Valor |
|-------|-------|
| Fabricante | MikroElektronika |
| Part Number | MIKROE (verificar) |
| Controlador + Transceiver | MCP251863 (integrado) |
| Interface | mikroBUS (SPI) |
| CAN FD | Sim — até 8 Mbps |
| Conector | DE-9 (DB9) macho |
| Alimentação | 3.3V ou 5V |
| Oscilador | 40 MHz onboard |
| Isolamento | Não |
| Preço | ~$30 |
| Tamanho | L (57.15 × 25.4 mm) |

## 4.2 Vantagens

* Solução integrada — controlador + transceiver num chip;
* Menor footprint que MCP2518FD Click;
* Biblioteca mikroSDK incluída.

## 4.3 Avaliação Aerus

**Útil para:** Prototipagem rápida com menos componentes externos.

---

# 5. LilyGo T-2Can-FD

## 5.1 Resumo

| Campo | Valor |
|-------|-------|
| Fabricante | LilyGo (Xinyuan) |
| MCU | ESP32-S3-WROOM-1U |
| Flash | 16 MB |
| PSRAM | 8 MB (OPI) |
| CAN Bus 1 | MCP2518FD (SPI) — CAN FD |
| CAN Bus 2 | ESP32-S3 TWAI — CAN 2.0B |
| Wireless | WiFi 802.11 b/g/n + BT 5.0 LE |
| Alimentação | USB-C 5V, SMPS 7-24V |
| Preço | ~$25-30 |
| Schematic | [GitHub](https://github.com/Xinyuan-LilyGO/T-2Can) |

## 5.2 Características

* **Dual CAN:** CAN FD (MCP2518FD) + CAN 2.0 (TWAI integrado);
* ESP32-S3 completo — WiFi + BLE + USB + GPIO;
* Pinout bem documentado;
* Bibliotecas Longan_CANFD e PlatformIO suportadas;
* SMPS onboard com proteção contra inversão de polaridade;
* Botões BOOT e RST;
* LED indicador.

## 5.3 Avaliação Aerus

| Critério | Avaliação |
|----------|-----------|
| CAN FD | ✅ MCP2518FD + transceiver |
| Dual CAN | ✅ CAN FD + CAN 2.0 |
| ESP32-S3 | ✅ É um ESP32-S3 completo |
| Preço | ✅ ~$25-30 |
| Isolamento | ❌ Não — necessário para segurança |
| Compilação com Aerus | ⚠️ Pode ser usado como base para ESP32-S |

**Veredicto: EXCELENTE para prototipagem do ESP32-S e ESP32-A.**

---

# 6. 2-Channel Isolated CAN FD HAT for RaspberryPi

## 6.1 Resumo

| Campo | Valor |
|-------|-------|
| Controlador | MCP2518FD ×2 |
| Transceiver | MCP2562FD ×2 |
| Interface | SPI (RaspberryPi 40-pin GPIO) |
| CAN FD | Sim — 2 canais |
| Isolamento | 5kV elétrico |
| Proteções | Lightning, ESD, curto-circuito |
| Terminação | 120Ω configurável via jumper |
| Tensão operação | 5V (da RPi) ou externa 8-26V |
| Voltagem lógica | 3.3V / 5V (seletável via jumper) |
| Preço | ~$40-50 |
| Compatibilidade | Todas as RPi (40-pin GPIO) |

## 6.2 Características

* 2 canais CAN FD independentes;
* Breakout dos pins SPI para ligação a Arduino/STM32;
* Isolamento galvânico entre canais e RPi;
* Terminação 120Ω configurável;
* Exemplos para RaspberryPi e Arduino.

## 6.3 Avaliação Aerus

| Critério | Avaliação |
|----------|-----------|
| CAN FD | ✅ 2 canais |
| Isolamento | ✅ 5kV |
| RaspberryPi | ✅ HAT direto |
| Dual channel | ✅ Pode servir 2 CAN buses |
| Preço | ✅ ~$40 (R$200) |

**Veredicto: RECOMENDADO para RaspberryPi com isolamento integrado.**

---

# 7. Waveshare 2CH CAN FD HAT

## 7.1 Resumo

| Campo | Valor |
|-------|-------|
| Fabricante | Waveshare |
| Controlador | MCP2518FD ×2 |
| Transceiver | MCP2562FD ×2 |
| Interface | SPI |
| CAN FD | Sim — 2 canais |
| Isolamento | Não (versão padrão) |
| Preço | ~$30-40 |

## 7.2 Avaliação

Alternativa mais barata à versão isolada. Sem isolamento — adequada apenas para o bus operacional.

---

# 8. Comparação

| Módulo | Plataforma | CAN FD | Canais | Isolado | Preço | Recomendação |
|--------|-----------|--------|--------|---------|-------|-------------|
| MCP2518FD Click | mikroBUS | ✅ | 1 | ❌ | ~$30 | Prototipagem |
| MCP251863 Click | mikroBUS | ✅ | 1 | ❌ | ~$30 | Prototipagem |
| LilyGo T-2Can-FD | ESP32-S3 | ✅ | 2 | ❌ | ~$25-30 | **ESP32-S/A** |
| 2CH Isolated HAT | RaspberryPi | ✅ | 2 | ✅ | ~$40-50 | **RaspberryPi** |
| Waveshare 2CH HAT | RaspberryPi | ✅ | 2 | ❌ | ~$30-40 | RPi (sem isolação) |

---

# 9. Recomendação para Protótipo Aerus

| Grupo | Módulo | Justificação |
|-------|--------|-------------|
| RaspberryPi | 2CH Isolated CAN FD HAT | HAT direto, isolamento integrado |
| ESP32-S | LilyGo T-2Can-FD | ESP32-S3 completo, CAN FD, WiFi+BLE |
| ESP32-A | LilyGo T-2Can-FD | Idem |
| ESP32-FS | PCB custom (MCP2518FD + ISO1042) | Necessita isolamento no bus segurança |
| ESP32-FS_A | PCB custom (MCP2518FD + ISO1042) | Idem |

**Custo estimado dos módulos para protótipo:**

| Módulo | Qtd | Preço Unit | Total |
|--------|-----|-----------|-------|
| LilyGo T-2Can-FD | 2 | ~$27 | ~$54 |
| 2CH Isolated CAN FD HAT | 1 | ~$45 | ~$45 |
| **Total módulos** | | | **~$99** |

---

# 10. Referências

- [MCP2518FD Click](https://www.mikroe.com/mcp2518fd-click)
- [MCP251863 Click](https://www.mikroe.com/mcp251863-click)
- [LilyGo T-2Can-FD](https://wiki.lilygo.cc/products/industrial-series/t-2can-fd)
- [LilyGo T-2Can GitHub](https://github.com/Xinyuan-LilyGO/T-2Can)
- COM-008 — CAN Bus
- HW-CAN-001 — Controladores CAN FD
- HW-CAN-002 — Transceivers CAN FD
