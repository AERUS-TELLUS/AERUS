# 07 — Ferramentas de Diagnóstico CAN Bus

| Campo             | Valor                              |
| ----------------- | ---------------------------------- |
| **Código**        | HW-CAN-007                         |
| **Título**        | Ferramentas de Diagnóstico CAN Bus |
| **Versão**        | 1.0                                |
| **Estado**        | Em Desenvolvimento                 |
| **Autor**         | ShegaPT                            |
| **Classificação** | Documentação de Hardware           |

---

# 1. Objetivo

O presente documento detalha as ferramentas de diagnóstico CAN Bus candidatas a utilização no desenvolvimento e manutenção do Aerus.

---

# 2. Requisitos

| Requisito | Valor |
|-----------|-------|
| CAN FD | Sim — até 5+ Mbps |
| CAN 2.0B | Sim — extended ID 29-bit |
| SocketCAN (Linux) | Preferencial |
| Isolamento galvânico | Preferencial |
| Software | Aberto ou com boa documentação |
| Preço | Conforme orçamento |

---

# 3. PCAN-USB FD — Recomendado

## 3.1 Resumo

| Campo | Valor |
|-------|-------|
| Fabricante | PEAK-System (HMS Networks) |
| Part Number | IPEH-004022 (USB-A) / IPEH-004023 (USB-C) |
| Interface | USB 2.0 (compatível 1.1/3.0) |
| CAN | 1 canal |
| CAN FD | Sim — até 12 Mbps |
| CAN 2.0 | Sim — até 1 Mbps |
| Transceiver | NXP TJA1044GT |
| Isolamento | 500V galvânico |
| Conector CAN | D-Sub 9 macho (CiA 106) |
| Terminação | Configurável (solder jumper) |
| Timestamp | 1 µs resolução |
| FPGA | Sim (controller implementado em FPGA) |
| Temperatura operação | -40 a +85°C |
| Temperatura armazenamento | -40 a +100°C |
| Software incluído | PCAN-View (monitor CAN) |
| API | PCAN-Basic, PCAN-Developer 5 |
| Drivers | Windows 10/11, Linux (SocketCAN) |
| Preço | ~€298 (PEAK) / ~$368 (GridConnect) |
| Datasheet | [PEAK Product Page](https://www.peak-system.com/products/hardware/external-pc-interfaces/pcan-usb-fd) |

## 3.2 Características

* **FPGA CAN FD controller** — performance consistente;
* **Galvanic isolation 500V** — proteção do PC;
* **SocketCAN** — funciona como interface CAN padrão no Linux;
* **PCAN-View** — monitor CAN em tempo real;
* **PCAN-Basic API** — para desenvolvimento de software customizado;
* **Bit Rate Calculation Tool** — auxilia no cálculo de bit timing;
* **CAN FD Frame Analyzer** — análise de frames CAN FD;
* **Error generation** — induz erros para teste de robustez;
* **Bus load measurement** — incluindo error frames e overload frames;
* Disponível com USB-A ou USB-C.

## 3.3 Software

### PCAN-View (incluído)
* Monitor CAN em tempo real;
* Envio/receção de mensagens CAN;
* Filtros e máscaras;
* Trace/gravador de mensagens;

### PCAN-Basic API
* Biblioteca para desenvolvimento em C/C++/Python/.NET;
* Controlo total da interface CAN;
* Leitura/escrita de mensagens;
* Eventos e interrupts;

### SocketCAN (Linux)
```bash
# Instalar can-utils
sudo apt-get install can-utils

# Configurar interface
sudo ip link set can0 up type can bitrate 500000 dbitrate 2000000 fd on

# Monitorizar
candump can0

# Enviar mensagem
cansend can0 0123#DEADBEEF

# Estatísticas
canstat can0
```

## 3.4 Avaliação Aerus

| Critério | Avaliação |
|----------|-----------|
| CAN FD | ✅ Até 12 Mbps |
| Extended ID | ✅ 29-bit |
| SocketCAN | ✅ nativo Linux |
| Isolamento | ✅ 500V |
| Qualidade | ✅ Gold standard |
| Preço | ⚠️ ~€298 — elevado |

**Veredicto: RECOMENDADO como ferramenta principal de debug.**

---

# 4. PCAN-USB Pro FD — Profissional

## 4.1 Resumo

| Campo | Valor |
|-------|-------|
| Fabricante | PEAK-System |
| Canais | 2× CAN FD + 2× LIN |
| Interface | USB 2.0 |
| CAN FD | Sim — até 12 Mbps |
| LIN | Sim — até 20 kbps |
| Isolamento | 500V por canal CAN |
| Conector | 2× D-Sub 9 |
| Case | Alumínio robusto |
| Temperatura | -40 a +85°C |
| Preço | ~€500+ |

## 4.2 Vantagens

* 2 canais CAN FD independentes — testa operacional + segurança simultaneamente;
* 2 canais LIN — útil para debug;
* Case de alumínio — robusto;
* Isolamento por canal.

## 4.3 Avaliação Aerus

**Ideal para:** Laboratório de desenvolvimento com múltiplos buses.
**Custo-benefício:** Elevado para uso esporádico.

---

# 5. Kvaser USBcan Pro

## 5.1 Resumo (2xHS v2)

| Campo | Valor |
|-------|-------|
| Fabricante | Kvaser AB |
| Part Number | KV-01201-5 |
| Canais | 2 |
| CAN FD | Sim — até 8 Mbps |
| Isolamento | Sim |
| Interface | USB |
| API | Kvaser CANlib |
| Preço | ~$500+ |

## 5.2 Resumo (5xCAN)

| Campo | Valor |
|-------|-------|
| Part Number | KV-01524-1 |
| Canais | 5 |
| CAN FD | Sim — até 8 Mbps |
| MagiSync | Sim (sincronização automática) |
| t programming | Sim (programação em tempo real) |
| Preço | ~$1,885 |

## 5.3 Avaliação Aerus

* Excelente qualidade e fiabilidade;
* CANlib é uma API robusta e bem documentada;
* Preço elevado — alternativa ao PCAN;
* **Kvaser USBcan Pro 5xCAN** seria ideal para testar todos os buses simultaneamente.

---

# 6. Waveshare USB-CAN-FD — Budget

## 6.1 Resumo

| Campo | Valor |
|-------|-------|
| Fabricante | Waveshare |
| Interface | USB |
| CAN FD | Sim |
| CAN 2.0 | Sim |
| Isolamento | Não |
| Preço | ~$81 |
| Compatibilidade | Windows, Linux |

## 6.2 Avaliação

* Boa relação qualidade/preço;
* Sem isolamento galvânico;
* Adequado para desenvolvimento e debug em laboratório.

---

# 7. CANalyst-II — Ultra-Budget

## 7.1 Resumo

| Campo | Valor |
|-------|-------|
| Tipo | USB to CAN analyzer |
| Canais | 2 |
| CAN FD | Não (apenas CAN 2.0) |
| Isolamento | Não |
| Software | PC software incluído |
| Preço | ~$17-90 (versão) |
| Disponibilidade | AliExpress, eBay |

## 7.2 Versões

* Standard (~$17): básico, CAN 2.0 apenas;
* Pro (~$90): melhorias, suporte CANopen/DeviceNet;
* Extreme (~$66): funcionalidades avançadas.

## 7.3 Avaliação

* **NÃO suporta CAN FD** — limitação crítica;
* Útil apenas para CAN 2.0;
* Preço extremamente baixo;
* Boa opção para testes básicos e aprendizagem.

---

# 8. ZLG USBCANFD-100U

## 8.1 Resumo

| Campo | Valor |
|-------|-------|
| Fabricante | ZLG (Zhiyuan Electronics) |
| Canais | 2 CAN FD |
| CAN FD | Sim |
| Isolamento | Sim |
| Software | PCAN-Explorer compatível |
| Preço | ~$218-361 |
| Compatibilidade | Linux, Windows |

## 8.2 Avaliação

* Boa alternativa ao PCAN com preço inferior;
* 2 canais CAN FD;
* Isolamento integrado;
* Menos documentação em inglês que PEAK/Kvaser.

---

# 9. Comparação

| Ferramenta | Canais | CAN FD | Isolado | SocketCAN | Preço | Recomendação |
|-----------|--------|--------|---------|-----------|-------|-------------|
| PCAN-USB FD | 1 | ✅ 12 Mbps | ✅ 500V | ✅ | ~€298 | **Recomendado** |
| PCAN-USB Pro FD | 2+2LIN | ✅ 12 Mbps | ✅ 500V | ✅ | ~€500+ | Profissional |
| Kvaser 2xHS v2 | 2 | ✅ 8 Mbps | ✅ | ⚠️ | ~$500+ | Alternativa |
| Waveshare USB-CAN-FD | 1 | ✅ | ❌ | ⚠️ | ~$81 | Budget |
| CANalyst-II | 2 | ❌ | ❌ | ❌ | ~$17-90 | Ultra-budget |
| ZLG USBCANFD-100U | 2 | ✅ | ✅ | ⚠️ | ~$218 | Alternativa |

---

# 10. Recomendação Aerus

| Uso | Ferramenta | Custo |
|-----|-----------|-------|
| Desenvolvimento principal | PCAN-USB FD | ~€298 |
| Testes multi-bus | PCAN-USB Pro FD | ~€500+ |
| Budget | Waveshare USB-CAN-FD | ~$81 |
| Aprendizagem | CANalyst-II | ~$17-90 |

**Investimento mínimo recomendado:** 1× PCAN-USB FD (~€298)

---

# 11. Referências

- [PEAK-System PCAN-USB FD](https://www.peak-system.com/products/hardware/external-pc-interfaces/pcan-usb-fd)
- [Kvaser USBcan Pro](https://kvaser.com/product/kvaser-usbcan-pro-2xhs-v2/)
- [Waveshare USB-CAN-FD](https://www.waveshare.com/)
- [linux-can/can-utils](https://github.com/linux-can/can-utils)
- COM-008 — CAN Bus
- HW-CAN-000 — Panorama Geral
