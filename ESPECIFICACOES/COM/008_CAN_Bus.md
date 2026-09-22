# COM-008 — CAN Bus

| Campo | Valor |
|---|---|
| **Código** | COM-008 |
| **Título** | CAN Bus |
| **Versão** | 2.0 |
| **Estado** | Aprovado para implementação |
| **Autor** | ShegaPT |
| **Classificação** | Especificação de Comunicação |

---

# 1. Objectivo

O presente documento especifica a camada física e de transporte das três redes CAN embarcadas: CAN-Intra-Grupo, CAN-Principal e CAN-FailSafe. Abrange topologia, CAN-ID, débitos, terminação, protecções, transceivers, controladores, bus-off e filtragem. **O CAN é exclusivamente embarcado e nunca transporta vídeo pesado.**

---

# 2. Princípios

* CAN-FD até 64 B por quadro, ID estendido de 29 bits, em barramento partilhado com terminação 120 Ω.
* Três redes fisicamente independentes; a FailSafe sem partilha com tráfego ordinário.
* Débitos diferenciados por criticidade; arbitragem determinística.
* Componentes: transceivers **ISO1050 / MCP2562FD**, controladores **MCP2518FD** (via SPI nos RP2350); soluções equivalentes apenas com justificação.
* Isolamento galvânico recomendado na FailSafe e no MG.
* Sem vídeo no CAN: apenas descritores curtos (`MSG_VIDEO_DESC`).

---

# 3. CAN-FD vs CAN clássico

| Característica | CAN clássico | CAN-FD (AERUS) |
|---|---|---|
| Carga máxima | 8 B | 64 B |
| Débito de dados | ≤1 Mbit/s | até 5–8 Mbit/s (projecto: 2–5 Mbit/s) |
| CRC | 15 bits | 17 bits |
| Comutação de débito (BRS) | Não | Sim |

Todos os nós do mesmo barramento são CAN-FD; proibida mistura com CAN clássico no mesmo par.

---

# 4. Topologia

## 4.1 CAN-Intra-Grupo (N instâncias)

Cada grupo possui o seu par entrançado terminado (120 Ω em cada extremo), com os elementos internos e o Master. Exemplo (G-SEN com 3 elementos + Master):

```
            CAN-SEN (120 Ω ── par ── 120 Ω)
  [SEN-0]──┬──[SEN-1]──┬──[SEN-2]──┬──[M-SEN]──(para a Principal)
```

Contenção confinada ao grupo; a Principal não vê tráfego intra-grupo desnecessário.

## 4.2 CAN-Principal

```
 120Ω                                                            120Ω
  ┌──┬──────┬──────┬──────┬──────┬──────┬──────┬──────┬──────┬──────┬──┐
     │      │      │      │      │      │      │      │      │      │
  M-SEN  M-ACT  M-CTV  M-NAV  M-MIS  M-CAL  M-FS  M-VIS  M-COM   MG
                                              (GCV)
```

## 4.3 CAN-FailSafe (dedicada)

```
 120Ω                                      120Ω
  ┌──┬──────────────────────────────────────┬──┐
     │                                      │
   [G-FS]                                [AE]
```
Isolamento físico total; chicote separado; sem outros nós.

---

# 5. CAN-ID (29 bits)

```
PRIORIDADE(3b,28–26) │ ORIGEM(4b,25–22) │ DESTINO(4b,21–18) │ TIPO(4b,17–14) │ RESERVA(14b,13–0=0)
```

| Campo | Valores | Notas |
|---|---|---|
| Prioridade | 0–5 (COM-004) | 0 fixa na FailSafe |
| Origem/Destino | Masters canónicos (COM-007) | 0x0 = difusão (só tipos autorizados) |
| Tipo | Telemetria/comando/segurança/sync/estado/descritor | Coerente com MSG_ID |
| Reserva | 0 | Expansão futura |

Exemplo numérico: prioridade 2, origem M-SEN (0x2), destino MG (0xA), tipo TELEM (0x2): `ID = (2<<26)|(2<<22)|(0xA<<18)|(2<<14) = 0x08888000`. (Valores de origem/destino exactos na tabela de alocação; o cálculo ilustra o método.)

---

# 6. Quadros e DLC

Quadro CAN-FD: SOF + arbitragem (29 b) + controlo + dados (0–64 B) + CRC 17 b + ACK + EOF. DLC não-linear acima de 8 B: 9→12, 10→16, 11→20, 12→24, 13→32, 14→48, 15→64.

Capacidade útil: 64 B − 8–12 B de sobrecarga ⇒ ≈ 52–56 B para TLV; mensagem mínima 4 B ⇒ ≈ 48 B de campos por quadro (ver COM-002 §12).

---

# 7. Débitos

| Fase | Intra-Grupo | Principal | FailSafe |
|---|---|---|---|
| Arbitragem | 500 kbit/s | 500 kbit/s | 1 Mbit/s |
| Dados | 2 Mbit/s (1 Mbit/s se chicote longo) | 2 Mbit/s | 5 Mbit/s |

| Tipo | Débito de dados efectivo |
|---|---|
| Telemetria, comando | 2 Mbit/s |
| Heartbeat, estado, sync | 500 kbit/s–2 Mbit/s |
| Emergência/segurança | 5 Mbit/s |
| Descritor de vídeo | 500 kbit/s |
| Fotogramas de vídeo | **Proibido (0 bit/s no CAN)** |

Comutação arbitragem→dados dentro do quadro (BRS). Exemplo: quadro de 64 B a 2 Mbit/s ⇒ ≈ 256 µs de dados + arbitragem; débito útil de telemetria a 50 Hz com 48 B ⇒ ≈ 19 kbit/s por fluxo — folga ampla.

---

# 8. Terminação e cablagem

Resistência 120 Ω ±1% (objectivo; mínimo ±5%), 1/4 W, em cada extremo; impedância do par 120 Ω ±10%; par entrançado blindado; stubs <30 cm; massa por ponto único. Topologia linear, sem estrela.

---

# 9. Bus-off e recuperação

ERROR_ACTIVE →(127)→ ERROR_PASSIVE →(255)→ BUS_OFF → espera 1 ms → 128×11 recessivos → ACTIVE; 10 tentativas espaçadas de 100 ms; após esgotamento, FAULT e degradação (COM-006). Contadores TX/RX, estado, último erro e estatísticas por barramento para diagnóstico.

---

# 10. Isolamento e protecção

* Isolamento galvânico ≥2500 V RMS recomendado no G-FS, na AE e nas interfaces do MG (transceiver isolado tipo **ISO1050** ou equivalente).
* Protecção: TVS bidireccional no par, fusível de sobrecorrente, imunidade ESD ≥8 kV contacto / 15 kV ar (IEC 61000-4-2).
* Temperatura −40…+125 °C; imunidade a transitórios de alimentação.

---

# 11. Transceivers e controladores

| Função | Componente de referência | Notas |
|---|---|---|
| Transceiver isolado | **ISO1050** | FailSafe, MG; isolamento integrado |
| Transceiver CAN-FD | **MCP2562FD** | Intra-Grupo e Principal; até 5 Mbit/s |
| Controlador CAN-FD | **MCP2518FD** (SPI) | Todos os Masters com RP2350; filtros hardware, FIFO, timestamps |
| Alternativas | TCAN1042 / TJA1463 / MCP2542FD | Só com equivalência demonstrada |

O RP2350 não possui CAN-FD nativo; usa-se MCP2518FD via SPI (com DMA onde disponível). É proibido bit-banging de CAN. Cada Master dimensiona SPI para débito de dados + margem de filtragem.

---

# 12. Fragmentação e filtragem

Fragmentação TLV em ≤64 B/quadro com índice/total (COM-002 §12, COM-003). Filtragem hardware por CAN-ID (aceitar apenas destino próprio + difusões autorizadas) + filtragem software por MSG_ID/origem/tipo/prioridade. Rejeição silenciosa com contadores, excepto segurança (com evento).

---

# 13. Monitorização

Registos: contadores de erro TX/RX, estado ACTIVE/PASSIVE/OFF, mensagens TX/RX, último erro, débito configurado, CAN-ID. Erros CRC/stuff/form/ACK/bit com respostas tipificadas (descarte, retransmissão, bus-off, auto-recuperação).

---

# 14. Nota histórica de migração

> Parágrafos anteriores sobre TWAI de ESP32 ou interfaces de Raspberry Pi encontram-se revogados. A presente especificação aplica-se a RP2350 + MCP2518FD + ISO1050/MCP2562FD nos Grupos do COM-001 §3.

---

# 15. Referências

* COM-001, COM-002, COM-003, COM-004, COM-006, COM-007, COM-010; ISO 11898-1/-2.
