# COM-001 — Arquitetura de Comunicação

| Campo | Valor |
|---|---|
| **Código** | COM-001 |
| **Título** | Arquitetura de Comunicação |
| **Versão** | 2.0 |
| **Estado** | Aprovado para implementação |
| **Autor** | ShegaPT |
| **Classificação** | Especificação de Comunicação |

---

# 1. Objectivo

O presente documento define a arquitetura geral de comunicação do sistema AERUS-TELLUS. Estabelece as cinco redes obrigatórias, a separação rigorosa entre domínio interno (embarcado) e domínio externo (ligações por radiofrequência), os princípios de encaminhamento e as garantias de determinismo, segurança e segregação.

Esta especificação substitui integralmente qualquer descrição anterior baseada noutras plataformas. Qualquer menção a Raspberry Pi, ESP32, RPi ou FS_A como entidades activas encontra-se revogada. Admite-se apenas uma nota histórica de migração (§16).

---

# 2. Princípios

* Cinco redes obrigatórias, sem excepções nem fusões implícitas.
* Separação física e lógica entre comunicação interna (embarcada) e comunicação externa (RF via RJ45-Privada RS).
* Protocolo TLV confinado ao CAN; o FABRIC e a RJ45-Privada RS possuem enquadramentos próprios (ver COM-002, Anexos A e B).
* Determinismo integral: memória estática, filas limitadas, latências majoradas.
* Segregação de segurança: a rede de emergência não partilha barramento com tráfego ordinário.
* Vídeo pesado jamais circula em CAN+TLV; circula exclusivamente no segmento RF de 5,8 GHz.
* Nomenclatura canónica de Grupos Computacionais (§3); proibição de entidades legadas como actores.

---

# 3. Nomenclatura canónica

| Abreviatura | Designação completa | Papel |
|---|---|---|
| G-SEN | Grupo Computacional Sensorial | Aquisição e pré-processamento sensorial |
| G-ACT | Grupo Computacional Atuador | Accionamento de actuadores nominais |
| G-CTV | Grupo Computacional Controlo de Voo | Leis de controlo e estabilização |
| G-NAV | Grupo Computacional Navegação | Estimação de posição, velocidade e atitude |
| G-MIS | Grupo Computacional Missão | Planeamento e gestão de missão |
| G-CAL | Grupo Computacional Cálculo | Cálculo intensivo auxiliar |
| G-FS | Grupo Computacional FailSafe / Supervisão | Supervisão, protecção e emergência |
| G-VIS | Grupo Computacional Visão (GCV) | Visão por computador, placa de vídeo |
| G-COM | Grupo Computacional Comunicação | Gestão de enlaces RF de comando/telemetria |
| MG | Master Geral (cluster 4×RP2350, 8 núcleos) | Orquestração central, fusão e decisão |
| AE | Atuação de Emergência (subsistema, não grupo) | Actuadores de último recurso comandados pelo G-FS |

Cada Grupo Computacional possui um elemento designado **Master de Grupo**, que é o único ponto de presença desse grupo na CAN-Principal. O MG é o orquestrador do sistema. O Router GCV é a função de encaminhamento sedeada no G-VIS que liga a CAN-Principal à RJ45-Privada RS do segmento de vídeo.

---

# 4. As cinco redes (visão obrigatória)

```
┌─────────────────────────────────────────────────────────────────┐
│                    AERUS — MODELO DE 5 REDES                    │
│                                                                 │
│  (1) CAN-Intra-Grupo × N                                        │
│      Um barramento dedicado POR Grupo Computacional.            │
│      Ex.: CAN-SEN, CAN-ACT, CAN-CTV, CAN-NAV, CAN-MIS,          │
│           CAN-CAL, CAN-FS, CAN-VIS, CAN-COM.                    │
│                                                                 │
│  (2) CAN-Principal (inter-masters)                              │
│      Masters de cada Grupo + Master Geral + Router GCV.         │
│                                                                 │
│  (3) CAN-FailSafe dedicada                                      │
│      G-FS ←→ Atuação de Emergência. SUPER_CRITICAL.             │
│      Sem descarte. Barramento fisicamente independente.         │
│                                                                 │
│  (4) INTERCONNECT FABRIC intra-cluster (dentro do MG)           │
│      4×RP2350, 8 núcleos. IPC determinístico de baixa latência. │
│                                                                 │
│  (5) RJ45-Privada RS (série, tipo RS-422/485 a confirmar)       │
│      Só existe onde houver RF:                                  │
│        a) GCV ←→ placa TX 5,8 GHz (vídeo 720p30);               │
│        b) MG  ←→ módulo RX 2,4 GHz + TX 868 MHz                 │
│           (comando/telemetria).                                 │
└─────────────────────────────────────────────────────────────────┘
```

| # | Rede | Meio | Participantes | Carga típica |
|---|---|---|---|---|
| 1 | CAN-Intra-Grupo | CAN-FD até 64 B | Elementos internos de cada grupo | TLV local (telemetria, comando local, estado) |
| 2 | CAN-Principal | CAN-FD até 64 B | Masters G-SEN/G-ACT/G-CTV/G-NAV/G-MIS/G-CAL/G-FS/G-VIS/G-COM + MG + Router GCV | TLV inter-masters (navegação, missão, saúde, sincronização) |
| 3 | CAN-FailSafe | CAN-FD até 64 B, dedicada | G-FS ←→ AE | Comandos de emergência, confirmações, heartbeat de segurança |
| 4 | FABRIC | SPI/DMA/PIO/shmem (a definir, ver COM-003) | 8 núcleos do MG | Quadros IPC (SENSOR_DATA, MATH_REQUEST, RESPONSE, NAVIGATION_, MISSION_, HEALTH_STATUS, SYSTEM_STATUS, TIME_SYNC, FAULT, HEARTBEAT), RPC entre núcleos |
| 5 | RJ45-Privada RS | Série ponto-a-ponto sobre RJ45 privada | GCV←→TX 5,8 GHz; MG←→RX 2,4 GHz+TX 868 MHz | Vídeo 720p30 (só 5,8 GHz); comando/telemetria série (só 2,4 GHz/868 MHz) |

Regra de ouro: **CAN+TLV nunca transporta vídeo pesado.** O CAN transporta, quando muito, descritores ou estado de vídeo (ex.: «stream activo/inactivo», «modo 720p30»), nunca fotogramas.

---

# 5. Diagrama geral das cinco redes

```
  ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐
  │ G-SEN  │ │ G-ACT  │ │ G-CTV  │ │ G-NAV  │ │ G-MIS  │
  │CAN-SEN │ │CAN-ACT │ │CAN-CTV │ │CAN-NAV │ │CAN-MIS │
  │interno │ │interno │ │interno │ │interno │ │interno │
  └───M────┘ └───M────┘ └───M────┘ └───M────┘ └───M────┘
       │          │          │          │          │
       └──────────┴─────┬────┴──────────┴──────────┘
                        │
  ┌────────┐      ┌─────┴──────────────────┐      ┌────────┐
  │ G-CAL  │      │    (2) CAN-PRINCIPAL   │      │  G-COM │
  │CAN-CAL │──M───┤  inter-masters         ├──M───│CAN-COM │
  └────────┘      │  + MG + Router GCV     │      └────────┘
                  └─────┬──────────┬───────┘
                        │          │
                 ┌──────┘          └──────┐
                 │  ┌──────────────┐     │
                 │  │ MG 4×RP2350  │     │  ┌────────┐
                 │  │ (4) FABRIC   │     │  │ G-VIS  │
                 │  │ 8 núcleos    │     └──┤ Router │
                 │  └──────┬───────┘        │  GCV   │
                 │         │                └───┬────┘
                 │         │ (5) RJ45-RS         │ (5) RJ45-RS
                 │         │ MG←→RX2,4+TX868     │ GCV←→TX5,8
                 │         ▼                     ▼
                 │   ┌───────────┐         ┌───────────┐
                 │   │ RF 2,4/868│         │ RF 5,8GHz │
                 │   │cmd/telem. │         │ vídeo     │
                 │   └───────────┘         │ 720p30    │
                 │                         └───────────┘
                 │
                 │  ┌──────────────────────┐
                 └──┤ G-FS                 │
                    │ CAN-FS interno (1)   │
                    └──────┬───────────────┘
                           │ (3) CAN-FAILSAFE dedicada
                           ▼
                    ┌──────────────┐
                    │ AE — Atuação │
                    │ de Emergência│
                    └──────────────┘
  Legenda: M = Master de Grupo (única presença na CAN-Principal).
```

---

# 6. Separação interno versus externo

| Domínio | Redes | Fronteira | Regra |
|---|---|---|---|
| Interno (embarcado) | (1) CAN-Intra-Grupo, (2) CAN-Principal, (3) CAN-FailSafe, (4) FABRIC | Placa / chicote interno | Todo o tráfego crítico de voo permanece a bordo; nenhuma decisão de estabilização depende de RF |
| Externo (RF) | (5) RJ45-Privada RS + enlaces RF | Conector RJ45 privada + módulos RF | A RJ45-Privada RS é o único acoplamento entre o sistema embarcado e o mundo RF; o Router CAN↔RJ45 (COM-003) é o único que atravessa a fronteira |

```
┌─────────────────── INTERNO ───────────────────┐   ┌──── EXTERNO ────┐
│ CAN-Intra × N │ CAN-Principal │ CAN-FailSafe    │   │                │
│               │ + MG (FABRIC) │                 │   │  RF 5,8 / 2,4  │
│               └──┬────────────┘                 │   │  / 868 MHz     │
│                  │ Router CAN↔RJ45 (COM-003)    │──→│  (5) RJ45-RS   │
│                  │ (única travessia autorizada) │←──│  série         │
└──────────────────┴─────────────────────────────┘   └────────────────┘
```

Consequência prática: a perda total de RF não provoca perda de controlo; provoca apenas perda de vídeo descendente e de comando/telemetria ascendente/descendente. O voo prossegue sob autoridade do G-CTV supervisionado pelo G-FS e orquestrado pelo MG.

---

# 7. Camadas por rede

## 7.1 Redes CAN (1, 2, 3) — três camadas

```
┌─────────────────────────────────────────┐
│ APLICAÇÃO: TLV                          │
│ START 0xAA │ MSG_ID │ COUNT │ FIELDS    │
│ + CRC8 (SMBUS 0x07) [+HMAC+SEQ, via SEC]│
└──────────────────┬──────────────────────┘
                   ▼
┌─────────────────────────────────────────┐
│ TRANSPORTE: CAN-FD, ID 29 bits          │
│ prioridade │ origem │ destino │ tipo    │
│ Payload até 64 B; fragmentação se >64 B │
└──────────────────┬──────────────────────┘
                   ▼
┌─────────────────────────────────────────┐
│ FÍSICA: CAN-FD, par entrançado 120 Ω    │
│ Transceivers ISO1050 / MCP2562FD /      │
│ controladores MCP2518FD (ver COM-008)   │
└─────────────────────────────────────────┘
```

## 7.2 FABRIC (4) — IPC intra-cluster

Enquadramento próprio (não é TLV): SOURCE / DESTINO / NÚCLEO / TIPO / REQ_ID / TIMESTAMP / COMPRIMENTO / PAYLOAD / CRC. Tipos: SENSOR_DATA, MATH_REQUEST, RESPONSE, NAVIGATION_, MISSION_, HEALTH_STATUS, SYSTEM_STATUS, TIME_SYNC, FAULT, HEARTBEAT. RPC entre núcleos com latência determinística. Tecnologia física (SPI/DMA/PIO/shmem) a definir no projecto detalhado; o protocolo lógico aqui especificado é invariante à tecnologia (ver COM-002 Anexo A e COM-003).

## 7.3 RJ45-Privada RS (5) — série ponto-a-ponto

Enquadramento série próprio (não é TLV nativo; encapsula TLV apenas no sub-caso comando/telemetria). Protocolo eléctrico série tipo RS-422/485, a confirmar no esquemático. Dois segmentos independentes: vídeo e comando/telemetria (ver §8 e COM-002 Anexo B).

---

# 8. Segmentos da RJ45-Privada RS

| Segmento | Extremidades | Conteúdo | Exemplo numérico |
|---|---|---|---|
| Vídeo | G-VIS (GCV) ←→ placa TX 5,8 GHz | Vídeo 720p30 (1280×720, 30 qps) | 720p30 H.264 ≈ 4–8 Mbit/s no ar; **zero bytes de vídeo** na CAN |
| Comando/telemetria | MG ←→ módulo RX 2,4 GHz + TX 868 MHz | Comando ascendente + telemetria descendente em série | 2,4 GHz: comando a 50 Hz (20 ms); 868 MHz: telemetria a 10 Hz + rajadas de evento; débitos série típicos 115 200–921 600 bit/s conforme esquemático |

Ambos os segmentos usam conectores RJ45 **privados** (rede fechada, sem Ethernet IP): o RJ45 é apenas o suporte mecânico do par série. É proibido ligar estes conectores a redes Ethernet convencionais.

---

# 9. Endereçamento e encaminhamento (resumo)

* CAN-Intra-Grupo: endereçamento local ao grupo; o Master de Grupo filtra e promove para a CAN-Principal apenas o que for inter-grupos.
* CAN-Principal: CAN-ID de 29 bits com origem = Master emissor, destino = Master destinatário ou difusão; o MG participa como Master orquestrador; o Router GCV participa apenas para descritores de vídeo/estado e encaminhamento de comando/telemetria autorizado.
* CAN-FailSafe: apenas dois interlocutores (G-FS e AE); sem encaminhamento, sem difusão para outras redes.
* FABRIC: endereçamento por (núcleo origem, núcleo destino, REQ_ID); RPC com correlação pedido/resposta.
* RJ45-RS: ponto-a-ponto sem endereçamento global; o Router CAN↔RJ45 traduz e polica (COM-003, COM-007).

O detalhe da matriz TX/RX e das regras de encaminhamento consta de COM-007.

---

# 10. Prioridades (resumo)

Cada rede possui o seu espaço de prioridades (COM-004). A CAN-FailSafe opera permanentemente em SUPER_CRITICAL sem descarte. A CAN-Principal arbitra por CAN-ID com mapeamento a partir do MSG_ID TLV. O FABRIC arbitra por tipo IPC e por núcleo (8 núcleos do MG com escalonamento determinístico). A RJ45-RS arbitra por direcção (comando ascendente prevalece sobre telemetria periódica; vídeo é fluxo contínuo isolado no seu segmento).

---

# 11. Tempo, eventos e integridade (resumo)

* Sincronização: raiz no Supervisor Cluster sedeado no MG; difusão TIME_SYNC para as CAN (COM-009).
* Eventos: sem atalho MISSÃO→ATUADOR; todo o comando de missão passa por validação do Controlo de Voo e supervisão do FailSafe (COM-005).
* Integridade: CAN-CRC nativo + CRC8 TLV + HMAC + SEQ nas CAN; CRC FABRIC no FABRIC; HMAC/TrustZone/SHA do RP2350 onde aplicável (COM-010).
* Timeouts: por rede, incluindo perda de 1×RP2350 do cluster (COM-006).

---

# 12. Segurança multi-camada (resumo)

| Camada | Mecanismo | Onde |
|---|---|---|
| 1 | CRC nativo CAN-FD (17 bits) | Redes 1–3 |
| 2 | CRC8 TLV (SMBUS 0x07) | Redes 1–3 (aplicação) |
| 3 | HMAC (32 B) | Redes 1–3, via módulo de segurança |
| 4 | CAN-ID + filtragem origem/destino | Redes 1–3 (transporte) |
| 5 | SEQ anti-repetição (4 B) | Redes 1–3, via módulo de segurança |
| F | CRC FABRIC | Rede 4 |
| R | Soma de verificação série + SEQ de enlace | Rede 5 |
| H | TrustZone / SHA do RP2350 | MG (rede 4) e Masters com RP2350 |

---

# 13. Fragmentação (só CAN)

Mensagens TLV superiores a 64 B são fragmentadas em múltiplos quadros CAN-FD. O FABRIC possui o seu próprio mecanismo de segmentação (não é fragmentação CAN). A RJ45-RS série não fragmenta TLV; encapsula e segmenta segundo o seu enquadramento. Ver COM-002 e COM-003.

Exemplo numérico: CAN-FD 64 B − sobrecarga de transporte ≈ 8–12 B ⇒ ≈ 52–56 B úteis para TLV; mensagem mínima TLV = 4 B (START+MSG_ID+COUNT+CRC8) ⇒ ≈ 48 B livres para campos por quadro.

---

# 14. Gestão das comunicações (resumo)

Três funções distintas, sem acumulação indevida (COM-003):

1. **Gestor CAN-TLV** — em cada Master de Grupo e no MG; valida, fragmenta, enfileira e entrega TLV nas redes 1–3.
2. **Gestor FABRIC** — dentro do MG; IPC/RPC determinístico entre os 8 núcleos.
3. **Router CAN↔RJ45** — no MG (comando/telemetria) e no Router GCV (vídeo/descritores); única travessia autorizada entre interno e externo.

É proibido implementar mecanismos paralelos de comunicação inter-grupos fora destas três funções.

---

# 15. Escalabilidade

* Adição de novo Grupo Computacional: atribui-se-lhe uma CAN-Intra-Grupo dedicada e um Master na CAN-Principal, sem alterar o TLV.
* Adição de elementos dentro de um grupo: confinada à CAN-Intra-Grupo respectiva.
* Novos MSG_ID / campos TLV: por extensão, sem quebra de compatibilidade (COM-002).
* Novo núcleo lógico no MG: por partição dos 8 núcleos físicos (COM-004).
* Novo segmento RF: apenas via nova RJ45-Privada RS dedicada, jamais por partilha do segmento de vídeo com comando.

---

# 16. Nota histórica de migração

> Em versões preliminares do projecto foram utilizados, a título experimental, Raspberry Pi e ESP32 (incluindo variantes e um elemento designado FS_A). Essas plataformas **não são entidades da presente arquitetura** e não possuem CAN-ID, endereço FABRIC nem presença na RJ45-Privada RS. Qualquer diagrama, tabela ou código que as refira como actores deve considerar-se revogado e ser migrado para a nomenclatura do §3 e para o modelo de 5 redes do §4.

---

# 17. Limites do documento

Este documento não detalha: estrutura integral do TLV (COM-002), comportamento dos gestores e do router (COM-003), prioridades e filas (COM-004), eventos (COM-005), tempos-limite e recuperação (COM-006), matriz TX/RX e encaminhamento (COM-007), parâmetros eléctricos do CAN (COM-008), sincronização (COM-009) nem integridade aprofundada (COM-010).

---

# 18. Referências

* COM-002 — Protocolo TLV (+ Anexos FABRIC e RJ45)
* COM-003 — Gestor de Mensagens (CAN-TLV + FABRIC + Router CAN↔RJ45)
* COM-004 — Prioridades e Filas (por rede + 8 núcleos)
* COM-005 — Eventos
* COM-006 — Timeouts e Recuperação
* COM-007 — Comunicação entre Domínios Computacionais
* COM-008 — CAN Bus
* COM-009 — Sincronização
* COM-010 — Integridade
