# hardware/CANBus — Documentação de Hardware CAN Bus

| Campo             | Valor                              |
| ----------------- | ---------------------------------- |
| **Projeto**       | Aerus                              |
| **Componente**    | CAN Bus Hardware                   |
| **Versão**        | 1.0                                |
| **Estado**        | Em Desenvolvimento                 |
| **Autor**         | ShegaPT                            |

---

# 1. Objetivo

Esta pasta contém toda a documentação técnica relativa ao hardware CAN Bus utilizado pelo sistema Aerus.

Inclui: componentes (controladores, transceivers, soluções isoladas), módulos de desenvolvimento, conectores, cabos, ferramentas de diagnóstico, esquemas de referência e listas de materiais (BOM) para prototipagem.

---

# 2. Requisitos do Aerus

| Requisito               | Valor                               |
|-------------------------|-------------------------------------|
| Protocolo               | CAN FD (Flexible Data-rate)         |
| Payload máximo          | 64 bytes                            |
| Bitrate dados           | Até 8 Mbps                          |
| Bitrate arbitragem      | 500 kbps – 1 Mbps                   |
| CAN ID                  | Extended 29-bit                     |
| Buses                   | 2 (operacional + segurança)         |
| Isolamento galvânico    | Na barreira de segurança (ESP32-FS) |
| Temperatura operacional | -40°C a +150°C                      |
| Terminação              | 120Ω em cada extremidade            |
| Impedância do cabo      | 120Ω ±10%                           |

---

# 3. Mapa de Decisão Rápida

```
Qual componente precisas?
│
├── Controlador CAN FD (SPI → CAN)
│   ├── Para todos os Grupos: MCP2518FD
│   └── Alternativa integrada: MCP251863 (controlador + transceiver)
│
├── Transceiver CAN FD (física do bus)
│   ├── Bus operacional: MCP2562FD ou TJA1044
│   └── Bus segurança (isolado): ISO1042
│
├── Módulo de prototipagem
│   ├── ESP32-S3 + CAN FD: LilyGo T-2Can-FD
│   ├── RaspberryPi + CAN FD: 2CH Isolated CAN FD HAT
│   └── Módulo mikroBUS: MCP2518FD Click ou MCP251863 Click
│
├── Conector
│   ├── Debug / protótipo: DB9 (CiA 303-1)
│   └── Instalação final: M12 A-coded 5-pin (IP67)
│
├── Cabo
│   ├── Protótipo: cabo CAN industrial 120Ω
│   └── Voo: cabo aerospace (Gore / Gigaflight)
│
└── Ferramenta de diagnóstico
    ├── Profissional: PCAN-USB FD (~€298)
    ├── Budget: Waveshare USB-CAN-FD (~$81)
    └── Ultra-budget: CANalyst-II (~$17-90)
```

---

# 4. Índice de Ficheiros

| Ficheiro | Conteúdo |
|----------|----------|
| [00_Panorama_Geral.md](00_Panorama_Geral.md) | Visão geral, requisitos, tabela comparativa CAN FD vs CAN |
| [01_Controladores_CAN_FD.md](01_Controladores_CAN_FD.md) | MCP2518FD, MCP251863 — specs, preços, compatibilidade |
| [02_Transceivers_CAN_FD.md](02_Transceivers_CAN_FD.md) | MCP2562FD, TJA1044, TCAN1042 — specs, preços |
| [03_Solucoes_Isoladas.md](03_Solucoes_Isoladas.md) | ISO1042, ISO1050, ADM3053 — isolamento galvânico |
| [04_Modulos_Desenvolvimento.md](04_Modulos_Desenvolvimento.md) | Click boards, HATs, placas ESP32+CAN FD |
| [05_Conectores.md](05_Conectores.md) | DB9, M12, terminais — pinout, especificações |
| [06_Cabos.md](06_Cabos.md) | Cabos industriais e aerospace |
| [07_Ferramentas_Diagnostico.md](07_Ferramentas_Diagnostico.md) | PCAN, Kvaser, analisadores CAN |
| [08_Esquemas_Referencia.md](08_Esquemas_Referencia.md) | Circuitos de referência ESP32+CAN FD |
| [09_BOM_Prototipagem.md](09_BOM_Prototipagem.md) | BOM, fornecedores, preços |

---

# 5. Referências

- COM-008 — CAN Bus (especificação)
- shared/CAN_IDS — Alocação de CAN IDs
- HW-006 — Interfaces de Comunicação
- HW-004 — Interfaces Elétricas
- HW-008 — Redundância e Isolamento de Hardware
- ISO 11898-1:2015 — CAN data link layer
- ISO 11898-2:2016 — CAN high-speed physical layer
