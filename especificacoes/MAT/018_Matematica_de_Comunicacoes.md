# MAT-018 — Matemática de Comunicações

| Campo             | Valor                              |
| ----------------- | ---------------------------------- |
| **Código**        | MAT-018                            |
| **Título**        | Matemática de Comunicações         |
| **Versão**        | 1.0                                |
| **Estado**        | Em Desenvolvimento                 |
| **Autor**         | ShegaPT                            |
| **Classificação** | Especificação Matemática           |

---

# 1. Objetivo

O presente documento define as fórmulas e modelos matemáticos utilizados na análise, dimensionamento e monitorização dos sistemas de comunicação do Aerus, incluindo latência, perda de pacotes, throughput e fiabilidade do CAN FD.

---

# 2. Princípios

* modelos baseados em medição empírica e análise teórica;
* aplicáveis a CAN FD com payload até 64 bytes;
* consideração de dois buses (operacional e segurança);
* suporte a bitrate variável (500 kbps a 5 Mbps);
* independentes do hardware específico (transferíveis entre plataformas).

---

# 3. MAT-0144 — Latência de Comunicação / Erro de Sincronização Temporal

## 3.1 Descrição

Determina a latência total de uma mensagem desde a transmissão até à receção, incluindo todos os atrasos introduzidos pelas camadas físicas e de protocolo.

## 3.2 Fórmula

```text
T_latência = T_serialização + T_propagação + T_arbitragem + T_processamento

Onde:
  T_serialização = (N_bytes × 8) / Bitrate_dados
  T_propagação   = Distância / Velocidade_sinal (≈ 5 ns/m em cabo CAN)
  T_arbitragem   = Ncompeting × (8 / Bitrate_arbitragem)
  T_processamento = T_CRC + T_parser + T_dispatch
```

## 3.3 Componentes

| Componente       | Descrição |
|-----------------|-----------|
| T_serialização  | Tempo para colocar todos os bytes no bus |
| T_propagação    | Tempo de propagação do sinal no cabo |
| T_arbitragem    | Tempo de espera durante arbitragem (se houver concorrência) |
| T_processamento | Tempo de processamento no receptor (CRC + parser + dispatch) |

## 3.4 Exemplo CAN FD

```text
Dados: 40 bytes payload CAN FD
Bitrate dados: 2 Mbps
Bitrate arbitragem: 500 kbps
Distância: 5m
N_nodes concorrentes: 3

T_serialização = (40 × 8) / 2.000.000 = 160 µs
T_propagação   = 5 / 200.000.000 = 25 ns (desprezável)
T_arbitragem   = 3 × (8 / 500.000) = 48 µs
T_processamento ≈ 10 µs

T_latência_total ≈ 218 µs
```

## 3.5 Erro de Sincronização Temporal

```text
Δt_sync = |T_grupo_A - T_grupo_B|

Critérios:
  Δt_sync < 1 ms    → Sincronização aceitável
  Δt_sync < 100 µs  → Sincronização precisa
  Δt_sync > 10 ms   → Sincronização comprometida
```

## 3.6 Implementação

| Plataforma   | Função |
|-------------|--------|
| RaspberryPi  | `communication-latency-time-synchronization-error.py` |
| ESP32-FS     | `communication-latency-time-synchronization-error.cpp` |

---

# 4. MAT-0145 — Taxa de Perda de Pacotes

## 4.1 Descrição

Determina a taxa de mensagens perdidas ou corrompidas relativamente ao total transmitido.

## 4.2 Fórmula

```text
PLR = N_perdidas / N_transmitidas × 100%

Onde:
  N_perdidas = Mensagens que não chegaram ao destinatário ou falharam CRC
  N_transmitidas = Total de mensagens enviadas
```

## 4.3 Critérios

| PLR        | Classificação | Ação |
|-----------|---------------|------|
| < 0.01%   | Excelente     | Normal |
| 0.01-0.1% | Aceitável     | Monitorizar |
| 0.1-1%    | Degradado     | Investigar |
| > 1%      | Crítico       | Acionar segurança |

## 4.4 Componentes

```text
PLR_total = PLR_físico + PLR_protocolo + PLR_overflow

PLR_físico    = Erros de transmissão não recuperáveis (Born-off, CRC falhou)
PLR_protocolo = Mensagens descartadas por validação TLV (CRC8, estrutura)
PLR_overflow  = Mensagens descartadas por fila cheia
```

## 4.5 Implementação

| Plataforma   | Função |
|-------------|--------|
| RaspberryPi  | `packet-loss-rate.py` |
| ESP32-FS     | `packet-loss-rate.cpp` |

---

# 5. MAT-0146 — Cálculo de Taxa de Dados (Throughput)

## 5.1 Descrição

Determina a taxa efetiva de transmissão de dados úteis no bus CAN FD.

## 5.2 Fórmula

```text
Throughput = (N_bytes_úteis × 8) / T_ciclo_completo

Onde:
  T_ciclo_completo = T_SOF + T_arbitragem + T_dados + T_CRC + T_ACK + T_EOF + T_IFS
```

## 5.3 Componentes CAN FD

| Componente | Tamanho (bits) | Descrição |
|-----------|---------------|-----------|
| SOF       | 1             | Start of Frame |
| Arbitragem| 29            | CAN ID extendido |
| Control   | 23            | DLC + BRS + ESI |
| Data      | 0-512         | Payload (até 64 bytes) |
| CRC       | 20            | CRC CAN FD |
| ACK       | 2             | Acknowledge |
| EOF       | 7             | End of Frame |
| IFS       | 3             | Intermission |

## 5.4 Exemplo

```text
Payload: 40 bytes = 320 bits
Bitrate dados: 2 Mbps
Overhead total: ~84 bits

T_ciclo = (320 + 84) / 2.000.000 = 202 µs
Throughput_útil = (40 × 8) / 202 µs = 1.584 Mbps
Eficiência = 320 / 404 × 100% = 79.2%
```

## 5.5 Throughput Máximo Teórico

| Bitrate Dados | Payload | Throughput Efetivo | Eficiência |
|--------------|---------|-------------------|------------|
| 500 kbps     | 8 bytes | 263 kbps          | 52.6%      |
| 500 kbps     | 64 bytes| 435 kbps          | 87.0%      |
| 2 Mbps       | 8 bytes | 1.05 Mbps         | 52.6%      |
| 2 Mbps       | 64 bytes| 1.74 Mbps         | 87.0%      |
| 5 Mbps       | 8 bytes | 2.63 Mbps         | 52.6%      |
| 5 Mbps       | 64 bytes| 4.35 Mbps         | 87.0%      |

## 5.6 Implementação

| Plataforma   | Função |
|-------------|--------|
| RaspberryPi  | `data-rate-calculation.py` |
| ESP32-FS     | `data-rate-calculation.cpp` |

---

# 6. MAT-0153 — Throughput por Tipo de Dado

## 6.1 Descrição

Determina o throughput necessário para cada tipo de dado comunicado entre Grupos Computacionais.

## 6.2 Fórmula

```text
Throughput_necessário = N_campos × Tamanho_campo × Frequência

Onde:
  N_campos = Número de campos TLV por mensagem
  Tamanho_campo = Tamanho médio em bytes
  Frequência = Taxa de atualização (Hz)
```

## 6.3 Exemplo: Telemetria ESP32-S

```text
Campos: ROLL, PITCH, YAW, GPS_LAT, GPS_LON, GPS_ALT, BATT_V, BATT_A
       = 8 campos × ~5 bytes = 40 bytes

Frequência: 50 Hz

Throughput = 40 × 8 × 50 = 16.000 bps = 16 kbps
Com overhead CAN FD: ≈ 20 kbps
```

## 6.4 Exemplo: Comandos RaspberryPi → ESP32-A

```text
Campos: CMD_SET_ROLL, CMD_SET_PITCH, CMD_SET_YAW, CMD_SET_THROTTLE
       = 4 campos × 5 bytes = 20 bytes

Frequência: 50 Hz

Throughput = 20 × 8 × 50 = 8.000 bps = 8 kbps
Com overhead CAN FD: ≈ 10 kbps
```

---

# 7. MAT-0154 — Intervalo entre Heartbeats

## 7.1 Descrição

Determina o intervalo ótimo entre mensagens de heartbeat para deteção de perda de comunicação.

## 7.2 Fórmula

```text
T_heartbeat = T Esperado_mensagem × Fator_segurança

Onde:
  T Esperado_mensagem = Intervalo máximo aceitável entre mensagens
  Fator_segurança = 2.0 a 3.0 (recomendado: 3.0)
```

## 7.3 Critérios

| Grupo          | Heartbeat Recomendado | Timeout (3× heartbeat) |
|---------------|----------------------|----------------------|
| RaspberryPi   | 100 ms               | 300 ms               |
| ESP32-S       | 100 ms               | 300 ms               |
| ESP32-A       | 100 ms               | 300 ms               |
| ESP32-FS      | 50 ms                | 150 ms               |
| ESP32-FS_A    | 50 ms                | 150 ms               |

---

# 8. MAT-0155 — Eficiência de Fragmentação

## 8.1 Descrição

Determina a eficiência da transmissão quando mensagens TLV são fragmentadas em múltiplos frames CAN FD.

## 8.2 Fórmula

```text
Eficiência = Bytes_úteis / (N_fragmentos × 64)

Onde:
  Bytes_úteis = Tamanho total da mensagem TLV
  N_fragmentos = Número de frames CAN FD necessários
  64 = Payload máximo por frame CAN FD
```

## 8.3 Exemplo

```text
Mensagem TLV: 120 bytes
Espaço útil por frame: ~56 bytes (com overhead CAN)

N_fragmentos = ceil(120 / 56) = 3 frames
Bytes transmitidos = 3 × 64 = 192 bytes
Bytes úteis = 120 bytes

Eficiência = 120 / 192 = 62.5%
Overhead = 192 - 120 = 72 bytes (37.5%)
```

---

# 9. MAT-0156 — Capacidade do Bus

## 9.1 Descrição

Determina a carga máxima suportável pelo bus CAN FD sem degradação de performance.

## 9.2 Fórmula

```text
Carga_bus = Σ (Throughput_i × N_mensagens_i) / Throughput_máximo

Critérios:
  Carga < 30%   → Excelente
  Carga 30-60%  → Aceitável
  Carga 60-80%  → Marginal
  Carga > 80%   → Crítico (risco de perda de mensagens)
```

---

# 10. Referências

- COM-001 — Arquitetura de Comunicação
- COM-008 — CAN Bus
- SHARED-TLV — Definições do Protocolo TLV
- SHARED-CAN-IDS — Alocação de CAN IDs
- SYS-008 — Gestão Temporal
- MAT-0144 — Latência de Comunicação
- MAT-0145 — Taxa de Perda de Pacotes
- MAT-0146 — Cálculo de Taxa de Dados
- ISO 11898-1:2015 — CAN data link layer
