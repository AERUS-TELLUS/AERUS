# MAT-018 — Matemática de Comunicações

| Campo             | Valor                              |
| ----------------- | ---------------------------------- |
| **Código**        | MAT-018                            |
| **Título**        | Matemática de Comunicações         |
| **Versão**        | 2.0                                |
| **Estado**        | Em Desenvolvimento                 |
| **Autor**         | ShegaPT                            |
| **Classificação** | Especificação Matemática           |

> **Nota de arquitectura (v2.0):** reescrita completa da plataforma. As fórmulas MAT-0144/0145/0146/0153/0154/0155/0156 são preservadas. A execução passa para o **Grupo Computacional de Cálculo (Math Core RP2350#2-C1)** como serviço de análise **MATH_REQUEST / MATH_RESPONSE**, com **implementação local redundante onde determinístico** (contadores, CRC, gestão de filas no próprio Grupo Comunicação e em cada mestre de grupo). Descrevem-se as **5 redes formais**: CAN-Intra, CAN-Principal, CAN-FailSafe, FABRIC e RJ45-RS. **Vídeo nunca circula no CAN. RF é sempre via RJ45. Missão nunca comanda o actuador directamente.**

---

# 1. Objectivo

O presente documento define as fórmulas e modelos matemáticos utilizados na análise, dimensionamento e monitorização dos sistemas de comunicação do Aerus, incluindo latência, perda de pacotes, throughput, carga de barramento e eficiência de fragmentação.

Vamos explicar a intenção com uma analogia: se os Grupos Computacionais fossem cidades, as redes seriam as estradas. Precisamos de saber quanto tempo demora uma carta (latência), quantas cartas se perdem (PLR), quantas cartas por hora a estrada aguenta (throughput/carga) e o que acontece quando a carta é demasiado grande para um envelope (fragmentação). Sem estes números, não conseguimos prometer determinismo — e sem determinismo não há voo autónomo seguro.

Este documento fixa a matemática dessas estradas para as 5 redes formais, mantendo compatibilidade com o protocolo TLV e o CAN FD.

---

# 2. Princípios

* Modelos baseados em medição empírica e análise teórica; cada estimativa deve ser confirmada em bancada.
* Aplicáveis a CAN FD com payload até 64 bytes nos três barramentos CAN.
* FABRIC como rede determinística interna do agrupamento principal (pedidos MATH, navegação, fusão, missão-voo).
* RJ45-RS como única porta para radiofrequência (regra RF=RJ45).
* **Vídeo nunca no CAN** — vídeo apenas em rede de alta capacidade (interna da Visão GCV e RJ45-RS para o solo).
* Cinco redes separadas por função, com orçamentos próprios de latência e carga.
* Independentes da placa concreta (transferíveis entre revisões de hardware que mantenham os Grupos formais).
* Serviço central de análise no Math Core + contabilidade local determinística em cada grupo.

## 2.1 Os 5 Grupos/Redes numa imagem

```text
                    ┌── CAN-Intra ── (dentro de cada grupo: periférico ↔ mestre)
                    │
  Grupo Sensorial ──┼── CAN-Principal ── (entre grupos operacionais)
  Grupo Atuador ────┼── CAN-Principal
  Master Geral ─────┼── CAN-Principal + FABRIC (interna 4×RP2350)
    │  ├─ Núcleo Voo / Fusão / Navegação / Missão / Segurança / Diagnóstico
    │  └─ Math Core RP2350#2-C1 (serviço MATH + análise de comunicações)
  Grupo FailSafe ───┼── CAN-FailSafe (dedicado) + escuta do Principal
  Grupo Visão GCV ──┼── CAN-Principal (apenas supervisão/telemetria) + RJ45-RS (vídeo/RF)
  Grupo Comunicação ┼── CAN-Principal + RJ45-RS (porta RF)
                    │
                    └── RJ45-RS ── Ethernet para modems externos:
                                   TX vídeo 5.8 GHz / RX comando 2.4 GHz / TX telemetria 868 MHz
```

Descrição curta de cada uma (detalhe na secção 3):

1. **CAN-Intra** — CAN FD dentro de cada Grupo (ex. placa de aquisição ↔ mestre do Grupo Sensorial; controlador ↔ mestre do Grupo Atuador). Tráfego local, determinístico, de baixo volume.
2. **CAN-Principal** — CAN FD operacional entre grupos (Sensorial ↔ Master ↔ Atuador ↔ Comunicação ↔ Cálculo ↔ supervisor da Visão). Telemetria, comandos validados, heartbeats, estados, pedidos MATH inter-grupos.
3. **CAN-FailSafe** — CAN FD dedicado à segurança (FailSafe ↔ actuação de emergência). Tráfego mínimo, prioridade máxima, funcional mesmo se o Principal falhar.
4. **FABRIC** — interligação ponto-a-ponto interna do agrupamento principal (os 4 microcontroladores do Master Geral). Pedidos MATH_REQUEST/RESPONSE, fusão, navegação, missão→voo. Latência de dezenas de microssegundos.
5. **RJ45-RS** — Ethernet ponto-a-ponto (conector RJ45) entre Grupo Comunicação / Visão GCV e os modems RF externos. Único caminho para RF: transmissão de vídeo a 5.8 GHz e recepção de comando a 2.4 GHz / transmissão de telemetria a 868 MHz. Regra RF=RJ45.

---

# 3. As 5 redes — topologia, latência, throughput e carga

## 3.1 Tabela-resumo (valores nominais de projecto; confirmar em bancada)

| Rede | Meio | Topologia | Bitrate arb. / dados | Latência típica 40 B | Throughput útil típico | Carga-alvo | Tráfego permitido |
| ---- | ---- | --------- | -------------------- | -------------------- | ---------------------- | ---------- | ----------------- |
| CAN-Intra | CAN FD par entrançado + 120 Ω | Barramento curto intra-grupo (< 1 m) | 500 kbps / 2 Mbps | 150–350 µs | ~1,5 Mbps | < 30 % | Aquisição local, PWM/estado local, heartbeat local |
| CAN-Principal | CAN FD par entrançado + 120 Ω | Barramento partilhado inter-grupos (< 5 m) | 500 kbps / 2 Mbps | 200–600 µs (+ arbitragem) | ~1,5 Mbps | < 60 % (alerta a 60–80 %, crítico > 80 %) | Telemetria, comandos validados Voo→Atuador, heartbeats, MATH inter-grupos. **Sem vídeo.** |
| CAN-FailSafe | CAN FD isolado + 120 Ω | Barramento dedicado segurança (< 2 m) | 1 Mbps / 5 Mbps | 60–200 µs | ~4 Mbps | < 30 % | Ordens de emergência, estados de segurança, heartbeat rápido. **Sem vídeo, sem telemetria corrente.** |
| FABRIC | SPI/DMA/PIO ponto-a-ponto + CRC | Malha interna do agrupamento (cm) | N/A ( relógio dedicado, > 10 Mbps efectivos) | 10–50 µs por IPC | > 10 Mbps | < 50 % | MATH_REQUEST/RESPONSE, NAV/ FUSÃO / MISSÃO↔VOO, TIME_SYNC, HEALTH. Não sai da placa do Master. |
| RJ45-RS | Ethernet 100BASE-TX via RJ45 | Ponto-a-ponto ao modem RF | 100 Mbps full-duplex | 0,5–5 ms (inclui modem) | até ~90 Mbps úteis | < 70 % | **TX vídeo 5.8 GHz**, **RX comando 2.4 GHz**, **TX telemetria 868 MHz**. Único caminho RF. |

Como ler a tabela: a latência CAN inclui serialização + arbitragem + processamento (ver MAT-0144). A latência FABRIC é dominada pelo IPC e pelo tempo de cálculo no Math Core. A latência RJ45-RS é dominada pelo modem RF e pelo empacotamento Ethernet, não pelo fio.

## 3.2 CAN-Intra — o «corredor dentro de casa»

Cada Grupo possui o seu barramento interno curto. Exemplo no Grupo Sensorial: várias placas de aquisição enviam amostras filtradas ao mestre do grupo; o mestre agrega e publica no CAN-Principal. Exemplo no Grupo Atuador: o mestre recebe o comando validado do Núcleo de Voo (via Principal), distribui aos controladores locais e recolhe feedback.

* Distância < 1 m → propagação desprezável (< 5 ns).
* Arbitragem reduzida (poucos nós) → `T_arbitragem` pequeno.
* Orçamento: 40 bytes a 2 Mbps ≈ 160 µs de serialização + ~48 µs de arbitragem com 3 competidores + ~10 µs de processamento ≈ **218 µs** (exemplo didáctico idêntico ao cálculo de MAT-0144, agora aplicado ao Intra).

## 3.3 CAN-Principal — a «auto-estrada operacional»

Barramento partilhado por: Grupo Sensorial, Grupo Atuador, Master Geral (via um dos seus controladores de bus), Grupo Comunicação, Math Core (via controlador do Master) e supervisor da Visão GCV (apenas para supervisão/telemetria, nunca vídeo).

* Bitrate: 500 kbps arbitragem / 2 Mbps dados (configuração nominal; segurança/emergência neste bus pode subir pontualmente, mas o tráfego crítico de segurança vive no FailSafe).
* Carga orçamentada pela soma de throughputs (MAT-0156). Meta: **< 60 %**. Entre 60–80 % é marginal (replanear períodos); acima de 80 % é crítico (risco de perda).
* **Proibido vídeo neste bus** (ver secção 10). Um único stream de vídeo esgotaria o bus e mataria o determinismo dos comandos.

## 3.4 CAN-FailSafe — a «via de emergência sempre livre»

Barramento dedicado entre o Grupo FailSafe e a actuação de emergência. O Grupo FailSafe escuta ainda o Principal (para observar), mas ordena apenas pelo FailSafe.

* Bitrate: 1 Mbps arbitragem / 5 Mbps dados → serialização de 40 bytes ≈ 64 µs.
* Latência total típica < 200 µs, com prioridade SUPER_CRITICAL nos identificadores.
* Carga mantida **< 30 %** por desenho: poucos nós, mensagens curtas, heartbeats rápidos (50 ms) e ordens esporádicas. Se este bus degradar, o sistema declara emergência (ver MAT-0154 e SEC).

## 3.5 FABRIC — o «elevador interno» do agrupamento

Ligações ponto-a-ponto dedicadas entre os 4 microcontroladores do Master Geral (relógios SPI dedicados, DMA, PIO, CRC por mensagem IPC). Não é um barramento partilhado: cada par pode falar sem arbitrar com o resto do veículo.

* Latência IPC: 10–50 µs + tempo de cálculo no destino. Um `MATH_REQUEST` simples (ex. norma de vector) completa-se tipicamente em < 100 µs; um cálculo em `double` mais pesado Orçamenta-se caso a caso.
* Throughput efectivo > 10 Mbps, com carga-alvo < 50 % para preservar determinismo.
* Tráfego: `MATH_REQUEST/RESPONSE`, `NAVIGATION_REQUEST/RESPONSE`, `MISSION_REQUEST/RESPONSE`, `SENSOR_DATA` agregada interna, `TIME_SYNC`, `HEARTBEAT`, `FAULT`, `HEALTH_STATUS`.
* A FABRIC nunca sai da placa do Master; para falar com outros grupos, o Master usa o CAN-Principal através do seu controlador de bus.

## 3.6 RJ45-RS — a «porta para o exterior» (regra RF=RJ45)

Todo o equipamento de radiofrequência é externo ao bus de voo e liga-se **apenas por Ethernet via conector RJ45** ao Grupo Comunicação (comando/telemetria) e à Visão GCV (vídeo):

* **TX vídeo a 5.8 GHz** — origem: Visão GCV (processamento + codificação no SoC de visão); transporte até ao modem por Ethernet RJ45; emissão pelo modem 5.8 GHz para a estação terrestre (ex. 720p30 secundário; o 720p60 primário permanece interno).
* **RX comando a 2.4 GHz** — recepção pelo modem 2.4 GHz; entrega por Ethernet RJ45 ao Grupo Comunicação; validação (CRC/HMAC/SEQ) e reencaminhamento via CAN-Principal ao Master Geral.
* **TX telemetria a 868 MHz** — origem: Master Geral → CAN-Principal → Grupo Comunicação → Ethernet RJ45 → modem 868 MHz → solo.

**Regra RF=RJ45 (obrigatória):** nenhum módulo RF é ligado por UART/SPI/I2C directamente ao bus de voo ou a qualquer núcleo. Todo o RF entra/sai por RJ45 Ethernet no Grupo Comunicação (e, para vídeo, na Visão GCV). Isto isola interferência, permite substituir modems sem alterar o voo e impede que um modem defeituoso inunde o CAN.

Orçamentos RJ45-RS: fio a 100 Mbps full-duplex é abundante; o gargalo é o enlace RF (largura, alcance, interferência). Dimensionar vídeo 720p30 codificado a 2–6 Mbps + telemetria a dezenas de kbps + comando a poucos kbps, mantendo o fio < 70 % e o enlace RF dentro da margem do fabricante com retransmissão e buffer.

---

# 4. MAT-0144 — Latência de Comunicação / Erro de Sincronização Temporal

## 4.1 Descrição

Determina a latência total de uma mensagem desde a transmissão até à recepção, incluindo todos os atrasos introduzidos pelas camadas físicas e de protocolo. Aplica-se por rede: CAN-Intra, CAN-Principal, CAN-FailSafe, FABRIC e RJ45-RS (neste último, somando o atraso do modem RF).

## 4.2 Fórmula (preservada)

```text
T_latência = T_serialização + T_propagação + T_arbitragem + T_processamento

Onde:
  T_serialização = (N_bytes × 8) / Bitrate_dados
  T_propagação   = Distância / Velocidade_sinal (≈ 5 ns/m em cabo CAN; ≈ 5 ns/m em par Ethernet)
  T_arbitragem   = Ncompeting × (8 / Bitrate_arbitragem)   [apenas redes CAN; 0 na FABRIC ponto-a-ponto e no RJ45 full-duplex]
  T_processamento = T_CRC + T_parser + T_dispatch (+ T_modem em RJ45-RS)
```

## 4.3 Componentes

| Componente       | Descrição |
|-----------------|-----------|
| T_serialização  | Tempo para colocar todos os bytes no meio |
| T_propagação    | Tempo de propagação do sinal no cabo (quase sempre desprezável a bordo) |
| T_arbitragem    | Tempo de espera durante arbitragem CAN (se houver concorrência; zero na FABRIC/RJ45) |
| T_processamento | CRC + parser TLV + encaminhamento (+ modem e codificação em RJ45-RS) |

## 4.4 Exemplos por rede (40 bytes úteis)

**CAN-Principal / CAN-Intra a 2 Mbps / 500 kbps, 5 m, 3 competidores:**

```text
T_serialização = (40 × 8) / 2.000.000 = 160 µs
T_propagação   = 5 / 200.000.000 = 25 ns (desprezável)
T_arbitragem   = 3 × (8 / 500.000) = 48 µs
T_processamento ≈ 10 µs

T_latência_total ≈ 218 µs
```

**CAN-FailSafe a 5 Mbps / 1 Mbps, 2 m, 1 competidor:**

```text
T_serialização = 320 / 5.000.000 = 64 µs
T_arbitragem   = 1 × (8 / 1.000.000) = 8 µs
T_processamento ≈ 10 µs
T_latência_total ≈ 82 µs (+ margem → orçamentar < 200 µs)
```

**FABRIC (IPC ponto-a-ponto, sem arbitragem):**

```text
T_serialização ≈ (40 × 8) / 20.000.000 (SPI 20 MHz ex.) = 16 µs
T_arbitragem   = 0
T_processamento ≈ 10–30 µs
T_latência_total ≈ 26–46 µs (+ tempo de cálculo no Math Core, orçamentado por operação)
```

**RJ45-RS (Ethernet + modem):**

```text
T_fio ≈ (1400 × 8) / 100.000.000 = 112 µs por frame Ethernet cheio
T_modem = 0,5–5 ms (codificação, interleaving, acesso ao RF — ver datasheet do modem)
T_latência_total ≈ T_fio + T_modem + T_processamento
→ orçamentar 5–20 ms para comando/telemetria; 50–200 ms para vídeo conforme codec e buffer.
```

## 4.5 Erro de Sincronização Temporal (preservado)

```text
Δt_sync = |T_grupo_A - T_grupo_B|

Critérios:
  Δt_sync < 1 ms    → Sincronização aceitável
  Δt_sync < 100 µs  → Sincronização precisa (exigida na FABRIC para fusão/voo)
  Δt_sync > 10 ms   → Sincronização comprometida (declarar degradação)
```

A sincronização fina faz-se na FABRIC via `TIME_SYNC` (ver COM-009); os grupos externos disciplinam-se pelo CAN-Principal.

## 4.6 Implementação (v2.0 — corrige plataforma)

| Função | Prestador de referência | Implementação local redundante |
|--------|-------------------------|--------------------------------|
| Medição/agregação de latência e `Δt_sync` | Grupo de Cálculo (Math Core RP2350#2-C1): `communication-latency-time-synchronization-error` servido via MATH_REQUEST | Grupo Comunicação (contadores por rede, CRC, parser, dispatch) + cada mestre de grupo (timestamp de emissão/recepção). O ciclo crítico usa sempre os contadores locais; o Math Core consolida estatística e tendências. |

Nenhuma medição do ciclo crítico depende de ida à rede: o timestamp é aposto localmente e a análise pesada vai ao Math Core de forma assíncrona.

---

# 5. MAT-0145 — Taxa de Perda de Pacotes (preservada)

## 5.1 Descrição

Determina a taxa de mensagens perdidas ou corrompidas relativamente ao total transmitido. Calcula-se **por rede** (Intra, Principal, FailSafe, FABRIC, RJ45-RS), nunca como média global — uma média esconderia uma via de emergência degradada.

## 5.2 Fórmula

```text
PLR = N_perdidas / N_transmitidas × 100%

Onde:
  N_perdidas = Mensagens que não chegaram ao destinatário ou falharam CRC
  N_transmitidas = Total de mensagens enviadas (na janela de observação)
```

## 5.3 Critérios

| PLR        | Classificação | Acção |
|-----------|---------------|------|
| < 0.01%   | Excelente     | Normal |
| 0.01-0.1% | Aceitável     | Monitorizar |
| 0.1-1%    | Degradado     | Investigar (isolar rede; ver carga em MAT-0156) |
| > 1%      | Crítico       | Acionar segurança (via Grupo FailSafe; em Principal degradado, FailSafe assume) |

Na CAN-FailSafe, qualquer PLR > 0,1 % sustentado deve ser tratado como crítico (margem mais exigente que a tabela genérica).

## 5.4 Componentes

```text
PLR_total(rede) = PLR_físico + PLR_protocolo + PLR_overflow

PLR_físico    = Erros de transmissão não recuperáveis (bus-off, CRC CAN falhou, erro Ethernet/FABRIC)
PLR_protocolo = Mensagens descartadas por validação TLV (CRC8, estrutura, HMAC/SEQ em RJ45-RS)
PLR_overflow  = Mensagens descartadas por fila cheia (sinal de sub-dimensionamento — rever MAT-0156)
```

## 5.5 Implementação (v2.0)

| Função | Prestador de referência | Local redundante |
|--------|-------------------------|------------------|
| Estatística PLR por rede | Grupo de Cálculo: `packet-loss-rate` via MATH_REQUEST (janelas, médias, tendências) | Grupo Comunicação + cada mestre (contadores determinísticos TX/RX/CRC/overflow por rede). RJ45-RS inclui contadores do modem. |

---

# 6. MAT-0146 — Cálculo de Taxa de Dados / Throughput (preservada)

## 6.1 Descrição

Determina a taxa efectiva de transmissão de dados úteis no CAN FD (aplica-se a Intra, Principal e FailSafe; para FABRIC e RJ45-RS ver 6.6).

## 6.2 Fórmula

```text
Throughput = (N_bytes_úteis × 8) / T_ciclo_completo

Onde:
  T_ciclo_completo = T_SOF + T_arbitragem + T_dados + T_CRC + T_ACK + T_EOF + T_IFS
```

## 6.3 Componentes CAN FD

| Componente | Tamanho (bits) | Descrição |
|-----------|---------------|-----------|
| SOF       | 1             | Start of Frame |
| Arbitragem| 29            | Identificador estendido |
| Control   | 23            | DLC + BRS + ESI |
| Data      | 0-512         | Payload (até 64 bytes) |
| CRC       | 20            | CRC CAN FD |
| ACK       | 2             | Acknowledge |
| EOF       | 7             | End of Frame |
| IFS       | 3             | Intermission |

## 6.4 Exemplo (preservado, agora etiquetado CAN-Principal)

```text
Payload: 40 bytes = 320 bits
Bitrate dados: 2 Mbps
Overhead total: ~84 bits

T_ciclo = (320 + 84) / 2.000.000 = 202 µs
Throughput_útil = (40 × 8) / 202 µs = 1.584 Mbps
Eficiência = 320 / 404 × 100% = 79.2%
```

## 6.5 Throughput Máximo Teórico CAN FD (preservado)

| Bitrate Dados | Payload | Throughput Efectivo | Eficiência |
|--------------|---------|-------------------|------------|
| 500 kbps     | 8 bytes | 263 kbps          | 52.6%      |
| 500 kbps     | 64 bytes| 435 kbps          | 87.0%      |
| 2 Mbps       | 8 bytes | 1.05 Mbps         | 52.6%      |
| 2 Mbps       | 64 bytes| 1.74 Mbps         | 87.0%      |
| 5 Mbps       | 8 bytes | 2.63 Mbps         | 52.6%      |
| 5 Mbps       | 64 bytes| 4.35 Mbps         | 87.0%      |

Leitura didáctica: payloads maiores são mais eficientes (o overhead dilui-se), mas aumentam a latência de cada frame. Para comandos a 50 Hz preferimos frames curtos e frequentes; para telemetria agregada, frames cheios.

## 6.6 Extensão a FABRIC e RJ45-RS

* **FABRIC:** `Throughput ≈ relógio_SPI × eficiência_DMA (≈ 70–90 %)`. A 20 MHz, esperar > 10 Mbps úteis. Orçamentar com medição, não apenas cálculo.
* **RJ45-RS (fio):** `Throughput_fio ≈ 100 Mbps × eficiência_Ethernet (≈ 90 %)`. O limite real é o enlace RF (ver datasheets 5.8 GHz / 2.4 GHz / 868 MHz).

## 6.7 Implementação (v2.0)

| Função | Referência | Local |
|--------|------------|-------|
| Cálculo de throughput e eficiência | Grupo de Cálculo: `data-rate-calculation` via MATH_REQUEST | Grupo Comunicação (medição de débito por rede, por tipo de mensagem). |

---

# 7. MAT-0153 — Throughput por Tipo de Dado (preservada, exemplos corrigidos)

## 7.1 Descrição

Determina o throughput necessário para cada tipo de dado comunicado entre Grupos Computacionais.

## 7.2 Fórmula

```text
Throughput_necessário = N_campos × Tamanho_campo × Frequência

Onde:
  N_campos = Número de campos TLV por mensagem
  Tamanho_campo = Tamanho médio em bytes
  Frequência = Taxa de actualização (Hz)
```

Somar depois o overhead CAN FD (≈ 25 % em payloads de 40 B; ver 6.4) ou o overhead Ethernet/IP em RJ45-RS.

## 7.3 Exemplo: Telemetria do Grupo Sensorial → Master Geral (via CAN-Principal)

```text
Campos: ROLL, PITCH, YAW, GPS_LAT, GPS_LON, GPS_ALT, BATT_V, BATT_A
       = 8 campos × ~5 bytes = 40 bytes

Frequência: 50 Hz

Throughput = 40 × 8 × 50 = 16.000 bps = 16 kbps
Com overhead CAN FD: ≈ 20 kbps no CAN-Principal
```

Este é o maior consumidor corrente do Principal. Multiplicar pelo número de publicadores e somar heartbeats para obter a carga (MAT-0156).

## 7.4 Exemplo: Comandos Núcleo de Voo → Grupo Atuador (via CAN-Principal)

```text
Campos: CMD_SET_ROLL, CMD_SET_PITCH, CMD_SET_YAW, CMD_SET_THROTTLE
       = 4 campos × 5 bytes = 20 bytes

Frequência: 50 Hz

Throughput = 20 × 8 × 50 = 8.000 bps = 8 kbps
Com overhead CAN FD: ≈ 10 kbps no CAN-Principal
```

Nota arquitectónica: estes comandos são emitidos **pelo Núcleo de Voo após validação**, nunca pelo Núcleo de Missão directamente (ver secção 11). O Grupo Atuador valida novamente o envelope antes de converter em sinais físicos.

## 7.5 Exemplo: Pedido MATH na FABRIC (Núcleo de Navegação → Math Core)

```text
Pedido: 16 bytes + resposta: 32 bytes = 48 bytes por transacção
Frequência: 100 Hz (ex. malha de navegação apoiada)

Throughput_FABRIC ≈ 48 × 8 × 100 = 38,4 kbps (+ overhead IPC ≈ 50 kbps)
→ negligenciável face aos > 10 Mbps da FABRIC; o limite é a latência, não o débito.
```

---

# 8. MAT-0154 — Intervalo entre Heartbeats (preservado, tabela corrigida)

## 8.1 Descrição

Determina o intervalo óptimo entre mensagens de heartbeat para detecção de perda de comunicação, por rede e por grupo.

## 8.2 Fórmula

```text
T_heartbeat = T Esperado_mensagem × Fator_segurança

Onde:
  T Esperado_mensagem = Intervalo máximo aceitável entre mensagens
  Fator_segurança = 2.0 a 3.0 (recomendado: 3.0)
```

Timeout = 3 × heartbeat. Ultrapassado o timeout, declara-se perda do grupo/rede e o Grupo FailSafe avalia.

## 8.3 Heartbeats recomendados (v2.0 — nomenclatura formal)

| Grupo / Núcleo | Rede de heartbeat | Heartbeat | Timeout (3×) |
|---------------|-------------------|-----------|--------------|
| Grupo Sensorial (mestre) | CAN-Principal (+ Intra local) | 100 ms | 300 ms |
| Grupo Atuador (mestre) | CAN-Principal (+ Intra local) | 100 ms | 300 ms |
| Núcleo de Voo / Fusão / Navegação / Missão (Master Geral) | CAN-Principal (externo) + FABRIC (interno, 20 ms) | 100 ms ext. / 20 ms int. | 300 ms ext. |
| Grupo Comunicação | CAN-Principal + RJ45-RS (estado do enlace) | 100 ms | 300 ms |
| Supervisor da Visão GCV | CAN-Principal (telemetria de saúde; vídeo nunca) | 200 ms | 600 ms |
| Grupo FailSafe | CAN-FailSafe (rápido) + escuta do Principal | 50 ms | 150 ms |
| Actuação de emergência (par do FailSafe) | CAN-FailSafe | 50 ms | 150 ms |
| Math Core (saúde do serviço) | FABRIC (+ Principal para outros grupos) | 100 ms | 300 ms |

A detecção rápida vive sempre em implementação local (cada grupo conta os seus timeouts); o Math Core consolida disponibilidade e MTBF de forma assíncrona.

---

# 9. MAT-0155 — Eficiência de Fragmentação (preservada)

## 9.1 Descrição

Determina a eficiência da transmissão quando mensagens TLV são fragmentadas em múltiplos frames CAN FD (Intra/Principal/FailSafe). Na FABRIC e em RJ45-RS a fragmentação segue regras próprias do IPC/Ethernet, mas a fórmula de eficiência é análoga.

## 9.2 Fórmula

```text
Eficiência = Bytes_úteis / (N_fragmentos × 64)

Onde:
  Bytes_úteis = Tamanho total da mensagem TLV
  N_fragmentos = Número de frames CAN FD necessários
  64 = Payload máximo por frame CAN FD
```

## 9.3 Exemplo (preservado)

```text
Mensagem TLV: 120 bytes
Espaço útil por frame: ~56 bytes (com overhead CAN)

N_fragmentos = ceil(120 / 56) = 3 frames
Bytes transmitidos = 3 × 64 = 192 bytes
Bytes úteis = 120 bytes

Eficiência = 120 / 192 = 62.5%
Overhead = 192 - 120 = 72 bytes (37.5%)
```

Lição didáctica: mensagens grandes e frequentes matam a eficiência e a latência. Preferir mensagens curtas e frequentes no CAN; reservar mensagens grandes para RJ45-RS ou para a FABRIC (onde o custo é menor).

---

# 10. MAT-0156 — Capacidade do Barramento / Carga (preservada e estendida às 5 redes)

## 10.1 Descrição

Determina a carga suportada por cada rede sem degradação.

## 10.2 Fórmula

```text
Carga_rede = Σ (Throughput_i × N_mensagens_i) / Throughput_máximo(rede)

Critérios (CAN):
  Carga < 30%   → Excelente
  Carga 30-60%  → Aceitável (meta do Principal)
  Carga 60-80%  → Marginal (replanear períodos/prioridades)
  Carga > 80%   → Crítico (risco de perda; aliviar imediatamente)

Critérios (FailSafe / FABRIC / RJ45-RS):
  FailSafe > 30 % → Crítico (este bus deve andar sempre folgado)
  FABRIC > 50 % → Marginal (preservar determinismo IPC)
  RJ45-RS (fio) > 70 % → Marginal; o limite real é o enlace RF.
```

## 10.3 Orçamento-exemplo do CAN-Principal

```text
Telemetria Sensorial 50 Hz ........... 20 kbps
Comandos Voo→Atuador 50 Hz ........... 10 kbps
Heartbeats/estados (6 publicadores) .. ~6 kbps
Pedidos MATH inter-grupos ............ ~5 kbps
Margem/eventos ....................... ~5 kbps
─────────────────────────────────────────────
Total ≈ 46 kbps / 1584 kbps (40 B a 2 Mbps) ≈ 3 % → Excelente
```

Mesmo duplicando publicadores e adicionando o Grupo Comunicação, mantemo-nos confortavelmente abaixo de 30 %. É assim que deve ser: o Principal foi dimensionado para andar folgado. Se um dia for preciso vídeo, ele **não** vai para aqui — vai para RJ45-RS.

## 10.4 Implementação (v2.0)

A contabilidade de carga por rede é feita localmente no Grupo Comunicação e em cada mestre (contadores determinísticos); o Math Core consolida orçamentos, projecções e alertas de tendência via `MATH_REQUEST`.

---

# 11. Regra de comando — Missão → Voo → Atuador (nunca directo)

Esta é a regra de ouro do movimento, com fundamento em segurança (ver docs de Arquitectura Computacional §34):

```text
CORRECTO                        ERRADO (proibido)

Núcleo Missão                   Núcleo Missão
   │ MISSION_REQUEST                │ comando físico
   │ (referência: rumo/alt/vel)     │ (PWM directo)
   ▼                                ▼
Núcleo Voo                      Grupo Atuador
   │ valida envelope                 X (nunca acontece)
   │ calcula lei de controlo
   │ (usa Math Core se preciso)
   │ CMD validado via CAN-Principal
   ▼
Grupo Atuador
   │ valida de novo + converte
   │ para PWM/GPIO
   ▼
Actuador físico → feedback
```

**Passo a passo com redes e matemática:**

1. **Missão → Voo (FABRIC):** o Núcleo de Missão (Master, placa principal) envia `MISSION_REQUEST` (ex. «manter 80 m, rumo 090, 18 m/s») via FABRIC ao Núcleo de Voo. Latência IPC < 50 µs. Nenhum PWM é gerado aqui.
2. **Voo calcula (FABRIC + local):** o Núcleo de Voo valida a referência contra o envelope (velocidade de perda, limites de atitude, energia). Se precisar de cálculo pesado, envia `MATH_REQUEST` ao Math Core (FABRIC) e recebe `MATH_RESPONSE`. O ciclo rápido (200 Hz) usa cópias locais determinísticas para norma/produtos; o pedido ao Math Core é assíncrono ou em ciclo mais lento.
3. **Voo → Atuador (CAN-Principal):** o Núcleo de Voo publica `CMD_SET_*` validado a 50 Hz via CAN-Principal (≈ 10 kbps, latência ≈ 218 µs para 40 B). Prioridade CRITICAL no identificador.
4. **Atuador executa (CAN-Intra + físico):** o mestre do Grupo Atuador valida o envelope uma segunda vez, distribui via CAN-Intra aos controladores e gera PWM/GPIO. Recolhe feedback (corrente, posição) e publica estado no Principal.
5. **Supervisão (CAN-FailSafe em paralelo):** o Grupo FailSafe observa Principal + sensores críticos. Se detectar anomalia (PLR crítico, timeout, envelope violado), ordena pela via dedicada FailSafe, com autoridade máxima, sem depender do Principal.

**Porquê nunca directo?** Porque a Missão pensa em objectivos («ir para ali») e o Voo pensa em limites físicos («posso ir assim sem cair»). Misturar os dois seria dar a um estratega o manche do avião. A validação dupla (Voo + Atuador) é a rede de segurança.

---

# 12. Sem vídeo no CAN — justificação matemática

Um frame 720p, mesmo comprimido, representa megabits por segundo de forma sustained. O CAN-Principal útil ronda 1,5 Mbps a 2 Mbps com 40 B. Ou seja:

```text
Vídeo 720p30 a 4 Mbps  >  Throughput_útil_CAN-Principal (~1,5 Mbps)
→ um só vídeo saturaria > 250 % do bus → PLR crítico → comandos perdidos.
```

Por isso, por teorema e por regra:

* **CAN-Intra / Principal / FailSafe: proibido vídeo.** Estes buses transportam apenas telemetria, comandos, estados, heartbeats e MATH inter-grupos.
* **Vídeo vive em:** processamento interno da Visão GCV (MIPI → SoC) e transporte para o solo via **RJ45-RS → modem 5.8 GHz** (stream secundário codificado, ex. 2–6 Mbps).
* O supervisor da Visão participa no CAN-Principal apenas com saúde/telemetria (200 ms), nunca com pixels.

---

# 13. Orçamento MATH_REQUEST / MATH_RESPONSE

Todo o pedido ao Math Core deve ser orçamentado como `T_total = T_ida + T_cálculo + T_volta`:

| Caso | Ida | Cálculo (exemplo) | Volta | Total típico |
| ---- | --- | ----------------- | ----- | ------------ |
| Norma local (ciclo rápido) | 0 (local) | < 1 µs | 0 | < 1 µs — não vai à rede |
| Norma via Math Core (validação cruzada) | FABRIC ~30 µs | ~5 µs | ~30 µs | < 100 µs |
| Logaritmo / gaussiana (`double`, sob pedido) | FABRIC ~30 µs | 20–200 µs | ~30 µs | < 300 µs |
| Pedido inter-grupos (Sensorial → Math Core) | Principal ~220 µs | idem | ~220 µs | < 1 ms |

Regra: nada do ciclo de 200 Hz (5 ms) pode depender de ida à rede no caminho crítico. O ciclo usa o local; a rede valida em pano de fundo.

---

# 14. Regra RF=RJ45 — detalhe e válvulas

1. Nenhum modem RF é alimentado ou comandado pelo bus de voo; a sua alimentação e dados passam pelo Grupo Comunicação / Visão GCV via RJ45.
2. Formatos: Ethernet 100BASE-TX, conector RJ45 bloqueável. Futuro: redundância de porta.
3. Segurança: todo o comando recebido por 2.4 GHz é validado (CRC8 TLV + HMAC 32 B + SEQ anti-replay) antes de entrar no CAN-Principal. Telemetria para 868 MHz é assinada na origem.
4. Energia: modems alimentados a 5 V / 12 V conforme datasheet, com filtragem própria; o PMIC da placa de comunicação sequencia o arranque para não perturbar o CAN.
5. Diagnóstico: o Grupo Comunicação publica no Principal a saúde de cada enlace (RSSI, SNR, PLR do modem, débito) a 1 Hz; o Math Core consolida tendência.

Mapeamento físico:

```text
Visão GCV ──RJ45──► modem TX 5.8 GHz ──► solo (vídeo)
Comunicação ──RJ45──► modem TX 868 MHz ──► solo (telemetria)
Solo ──► modem RX 2.4 GHz ──RJ45──► Comunicação ──CAN-Principal──► Master Geral
```

---

# 15. Distribuição computacional e energia (v2.0)

* **Referência analítica:** Grupo de Cálculo (Math Core RP2350#2-C1) — detém as implementações de referência de latência/PLR/throughput/carga e serve-as via `MATH_REQUEST`.
* **Execução determinística:** cada mestre de grupo e o Grupo Comunicação detêm contadores/estimadores locais (TX/RX, CRC, filas, timestamps) — é a implementação local redundante onde determinístico. Sem ela, a detecção de timeout não seria determinística.
* **Alimentação:** todas as PCBs partem de **3,3 V / 5 V / 12 V**; PMIC/reguladores locais geram os rails internos (núcleos, transceivers CAN FD, PHY Ethernet, modems). O dimensionamento do PMIC segue os datasheets dos fabricantes.

---

# 16. Limites do Documento

Este documento não define: estrutura completa do TLV; tabela completa de identificadores CAN; parâmetros eléctricos finos; driver CAN/Ethernet; implementação do gestor de comunicações; valores finais de timeout por missão (a calibrar em bancada/voo). Esses elementos vivem em COM-001…COM-010 e nos manuais de hardware.

---

# 17. Referências

- COM-001 — Arquitectura de Comunicação
- COM-008 — CAN Bus (Intra / Principal / FailSafe)
- COM-007 — Comunicação entre Domínios Computacionais
- COM-009 — Sincronização
- SHARED-TLV — Definições do Protocolo TLV
- SHARED-CAN-IDS — Alocação de identificadores CAN
- SYS-008 — Gestão Temporal
- MAT-0144 — Latência de Comunicação
- MAT-0145 — Taxa de Perda de Pacotes
- MAT-0146 — Cálculo de Taxa de Dados
- MAT-0153 — Throughput por Tipo de Dado
- MAT-0154 — Intervalo entre Heartbeats
- MAT-0155 — Eficiência de Fragmentação
- MAT-0156 — Capacidade do Barramento
- Grupo Computacional de Cálculo (Math Core RP2350#2-C1) — serviço MATH_REQUEST / MATH_RESPONSE
- ISO 11898-1:2015 — CAN data link layer
