# SW-0xx — Políticas Temporais do Sistema Computacional

| Campo             | Valor                        |
| ----------------- | ---------------------------- |
| **Código**        | SW-0xx                       |
| **Título**        | Políticas Temporais          |
| **Versão**        | 1.0                          |
| **Estado**        | Em Desenvolvimento           |
| **Autor**         | ShegaPT                      |
| **Classificação** | Especificação de Software    |

---

# 1. Objetivo

O presente documento define as políticas temporais do programa do sistema **Aerus**, ou seja, as regras que determinam **quando** cada função executa, **durante quanto tempo** pode executar, **com que atraso máximo** tem de produzir resultado, **com que prioridade** disputa recursos e **o que acontece** quando falha o prazo.

O objetivo central é fechar formalmente a matriz exigida pela arquitetura computacional:

```text
FUNÇÃO
  ↓
GRUPO
  ↓
PROCESSADOR
  ↓
NÚCLEO
  ↓
INTERFACE
  ↓
PROTOCOLO
  ↓
PERIODICIDADE
  ↓
LATÊNCIA MÁXIMA
  ↓
PRIORIDADE
  ↓
COMPORTAMENTO EM FALHA
```

Esta matriz constitui o contrato temporal entre todos os grupos computacionais. Sem ela fechada, não é possível dimensionar o barramento interno, validar o determinismo, configurar os guardiões de tempo nem iniciar o desenho definitivo das placas de processamento.

O documento abrange:

* os 8 núcleos do **Master Geral** (agrupamento de 4 × RP2350, 2 núcleos cada);
* o **Grupo Computacional de Visão (GCV)**, baseado em i.MX 8M Plus mais supervisor RP2350;
* as três infraestruturas de transporte: **CAN-Principal** (CAN FD), **RJ45** (Ethernet) e **FABRIC** (interligação interna do Master Geral);
* os princípios de **determinismo**, de **execução sem sistema operativo no caminho crítico** e de **anti-inanição** (nenhuma função crítica pode ficar sem tempo de processador por culpa de uma função menos crítica).

---

# 2. Âmbito

## 2.1 Dentro do âmbito

* Mapeamento completo FUNÇÃO → GRUPO → PROCESSADOR → NÚCLEO → INTERFACE → PROTOCOLO → PERIODICIDADE → LATÊNCIA → PRIORIDADE → FALHA para:
  * Núcleo de Voo — 200 Hz;
  * Núcleo de Fusão — 200 Hz;
  * Núcleo de Navegação — 50 a 100 Hz;
  * Núcleo de Cálculo — sob pedido;
  * Núcleo de Missão — 10 a 50 Hz;
  * Núcleo de Planeamento — esporádico / sob pedido;
  * Núcleo de Supervisão — contínuo + periódico;
  * Núcleo de Diagnóstico — periódico lento + por evento;
  * GCV — captura e processamento a 720p60, difusão para a estação terrestre a 720p30.
* Definição de periodicidade, latência máxima, flutuação temporal admissível (*jitter*), prazo absoluto (*deadline*) e política de recuperação.
* Distinção entre execução **bare-metal** (sem sistema operativo, no Master Geral e no supervisor de visão) e execução **com sistema operativo Linux** (apenas no subsistema applicativo do GCV).
* Regras de anti-inanição entre núcleos e entre mensagens.
* Utilização temporal de cada interface: CAN-Principal, RJ45 e FABRIC.

## 2.2 Fora do âmbito

* Algoritmos concretos de controlo, fusão ou navegação (pertencem às especificações MAT, CTL e NAV).
* Estrutura binária das mensagens (pertence às especificações COM e ao caderno TLV/CAN).
* Esquemas elétricos, escolha final de reguladores e desenho de placas (pertencem às especificações HW).
* Pipeline interno de sensores e atuadores (pertencem às especificações SEN e ACT).
* Regras completas de certificação (pertencem às especificações CER e VAL).

## 2.3 Convenções terminológicas

* **Master Geral**: placa computacional principal constituída por 4 × RP2350, totalizando 8 núcleos Cortex-M33. Executa voo, fusão, navegação, cálculo, missão, planeamento, supervisão e diagnóstico. Todo o programa do Master Geral corre em bare-metal, sem sistema operativo.
* **Grupo Computacional de Visão (GCV)**: placa de visão constituída por um SoC i.MX 8M Plus (4 × Cortex-A53 + 1 × Cortex-M7 + GPU + ISP + NPU + motor de vídeo) mais um RP2350 supervisor. Trata vídeo, visão e inferência. É o único local onde existe Linux.
* **CAN-Principal**: rede CAN FD principal entre grupos (barramento operacional mais barramento dedicado de segurança).
* **RJ45**: ligação Ethernet por conector RJ45, proveniente do GCV, para vídeo, diagnóstico e manutenção.
* **FABRIC**: interligação interna de alta velocidade entre os 4 RP2350 do Master Geral (ligações ponto a ponto SPI + DMA + PIO, com arbitragem determinística).
* **Grupo Computacional Sensorial**, **Grupo Computacional de Atuadores**, **Grupo Computacional de Segurança**: restantes grupos periféricos, clientes temporais do Master Geral.

Não são utilizadas neste documento designações de placas de desenvolvimento ou de computadores de uso geral. A arquitetura é descrita exclusivamente por função, grupo e processador alvo (RP2040, RP2350, i.MX 8M Plus).

---

# 3. Descrição

## 3.1 Ideia fundamental: tempo como recurso reservado

Num sistema de voo autónomo, o tempo de processador e o tempo de barramento são recursos finitos. Se o núcleo de Missão demorar demasiado tempo a deliberar, o núcleo de Voo não pode atrasar o seu ciclo de 5 ms. Se o vídeo ocupar todo o CAN-Principal, os comandos de atuadores não podem esperar.

Por isso, cada função recebe uma **reserva temporal**: uma fatia garantida de processador, uma janela garantida de barramento e um prazo máximo garantido de resposta. As políticas temporais descrevem essas reservas e o que acontece quando são violadas.

Princípios gerais, herdados de SYS-008:

1. Separação entre aquisição (frequência do periférico) e comunicação (frequência do barramento).
2. Execução periódica para funções críticas; execução por evento apenas quando não prejudica as periódicas.
3. Referência temporal comum com tempo monotónico para prazos e tempo UTC apenas para registo.
4. Qualquer atraso é detetado, registado e tratado segundo a criticidade, nunca ignorado em silêncio.

## 3.2 Organização dos 8 núcleos do Master Geral

A distribuição de referência é a seguinte. É normativa para efeitos temporais, salvo revisão formal da matriz:

```text
RP2350 #1
├── Núcleo 0 → VOO (controlo de voo, 200 Hz)
└── Núcleo 1 → FUSÃO (fusão sensorial, 200 Hz)

RP2350 #2
├── Núcleo 0 → NAVEGAÇÃO (estimação e seguimento, 50–100 Hz)
└── Núcleo 1 → CÁLCULO (serviço matemático, sob pedido)

RP2350 #3
├── Núcleo 0 → MISSÃO (gestão de missão, 10–50 Hz)
└── Núcleo 1 → PLANEAMENTO (lógica e trajetórias, esporádico)

RP2350 #4
├── Núcleo 0 → SUPERVISÃO (guardião do agrupamento, contínuo)
└── Núcleo 1 → DIAGNÓSTICO (saúde e registos, 1–10 Hz + eventos)
```

Cada RP2350 alberga dois núcleos com memórias e periféricos partilhados apenas dentro do próprio encapsulamento. A comunicação entre RP2350 distintos faz-se sempre pela FABRIC, nunca por acesso direto à memória do vizinho. Isto simplifica a análise temporal: o tempo de comunicação inter-RP2350 é explícito e mensurável.

Cada núcleo executa predominantemente uma classe de trabalho. Pequenas tarefas auxiliares do mesmo nível de criticidade podem coexistir no mesmo núcleo, mas nunca uma tarefa de criticidade inferior no núcleo de uma tarefa superior sem mecanismo de quota (ver §3.8).

## 3.3 Matriz temporal normativa

Legenda das colunas:

* **FUNÇÃO**: responsabilidade lógica.
* **GRUPO**: grupo computacional lógico onde reside (todos os 8 primeiros residem no Master Geral; os 3 últimos no GCV).
* **PROCESSADOR**: dispositivo físico.
* **NÚCLEO**: núcleo concreto.
* **INTERFACE**: meio físico dominante dessa função (FABRIC para tráfego interno ao Master Geral; CAN-Principal para tráfego entre grupos; RJ45 para vídeo/diagnóstico; MIPI CSI para captura de câmara).
* **PROTOCOLO**: formato lógico dominante (IPC interno com tipos MATH_REQUEST/MATH_RESPONSE, NAVIGATION_REQUEST/RESPONSE, MISSION_REQUEST/RESPONSE, HEALTH_STATUS, TIME_SYNC, FAULT, HEARTBEAT; TLV sobre CAN FD para tráfego externo; RTP/H.264 ou equivalente sobre Ethernet para vídeo).
* **PERIODICIDADE**: frequência de ativação em regime estável.
* **LATÊNCIA MÁX.**: atraso máximo admissível entre o instante de ativação (ou de receção do pedido) e a disponibilização do resultado, incluindo comunicação. Entre parêntesis indica-se a flutuação máxima (*jitter*) admissível.
* **PRIORIDADE**: nível de prioridade global (SUPER_CRÍTICA, CRÍTICA, ALTA, MÉDIA, BAIXA, MUITO_BAIXA), coerente com COM-004. No barramento CAN-Principal traduz-se nos 3 bits de prioridade do identificador de 29 bits; na FABRIC traduz-se em fila dedicada; no processador traduz-se em nível de interrupção e ordem de escalonamento.
* **FALHA**: comportamento normado quando o prazo é excedido ou o núcleo/grupo deixa de responder.

| # | FUNÇÃO | GRUPO | PROCESSADOR | NÚCLEO | INTERFACE | PROTOCOLO | PERIODICIDADE | LATÊNCIA MÁX. | PRIORIDADE | FALHA |
|---|--------|-------|-------------|--------|-----------|-----------|---------------|---------------|------------|-------|
| F1 | Voo (estabilização + controlo + mistura para atuadores) | Grupo Computacional de Voo (no Master Geral) | RP2350 #1 | Núcleo 0 (Cortex-M33 @150 MHz, bare-metal) | FABRIC (interna) + CAN-Principal (saída para atuadores) | IPC interno + TLV/CAN FD para Grupo de Atuadores | **200 Hz** (período 5,0 ms, estrito) | **≤ 2,0 ms** cálculo; **≤ 4,5 ms** até comando validado no barramento (*jitter* ≤ 100 µs) | **CRÍTICA** (apenas Segurança é superior) | Abandona ciclo em atraso, reutiliza último estado válido da Fusão, assinala FAULT ao Supervisor; após N ciclos consecutivos perdidos, Supervisor solicita FailSafe ao Grupo de Segurança. Nunca bloqueia à espera de Missão ou Visão. |
| F2 | Fusão sensorial (combinação IMU + barómetro + GNSS + magnetómetro) | Grupo Computacional de Fusão (no Master Geral) | RP2350 #1 | Núcleo 1 (Cortex-M33, bare-metal) | FABRIC (entrada sensorial + saída para Voo/Navegação) | IPC interno + TLV/CAN FD (entrada do Grupo Sensorial) | **200 Hz** (período 5,0 ms, sincronizado com Voo, desfasado ~1 ms) | **≤ 2,5 ms** por ciclo (*jitter* ≤ 150 µs) | **CRÍTICA** | Em atraso, publica estimativa predita (propagação inercial) marcada como DEGRADADA; se dados sensoriais expirarem (>20 ms sem IMU), declara FUSÃO_INVÁLIDA; Voo passa a modo de contenção e Supervisor é notificado. |
| F3 | Navegação (posição, velocidade, seguimento de trajetória) como serviço | Grupo Computacional de Navegação (no Master Geral) | RP2350 #2 | Núcleo 0 (Cortex-M33, bare-metal) | FABRIC | IPC: NAVIGATION_REQUEST/RESPONSE; consome MATH_REQUEST/RESPONSE do Núcleo de Cálculo | **50 Hz nominal, 100 Hz em fases dinâmicas** (período 20 ms / 10 ms, configurável por modo) | **≤ 8 ms** a 50 Hz; **≤ 5 ms** a 100 Hz (*jitter* ≤ 500 µs) | **ALTA** | Em atraso, responde com última solução válida + indicador de envelhecimento; pedidos de Missão recebem NAV_AGED em vez de bloqueio; após 5 soluções consecutivas em falta, Supervisor degrada Missão para espera (loiter). Ver NAV-001. |
| F4 | Cálculo matemático (serviço: matrizes, geodesia, filtros, transformações) | Grupo Computacional de Cálculo (no Master Geral) | RP2350 #2 | Núcleo 1 (Cortex-M33 com FPU/DSP, bare-metal) | FABRIC | IPC: MATH_REQUEST → MATH_RESPONSE com identificador de pedido e prazo | **Sob pedido** (sem período fixo; tempo médio de serviço dimensionado para <1 ms por pedido típico) | **Prazo por classe**: pedidos de Voo/Fusão ≤ 1,5 ms; de Navegação ≤ 4 ms; de Missão/Planeamento ≤ 50 ms. Fila com deserção por prazo. | **Herda prioridade do requerente** (herança de prioridade) até CRÍTICA; pedidos de Missão nunca preemptam pedido de Voo em curso | Se prazo expira, responde MATH_TIMEOUT e liberta fila; requerente usa via degradada (valor anterior, modelo simplificado ou propagação). Nunca põe o requerente em espera indefinida. Estatística de prazos excedidos vai para Diagnóstico. |
| F5 | Missão (máquina de estados de missão, waypoints, modos) | Grupo Computacional de Missão (no Master Geral) | RP2350 #3 | Núcleo 0 (Cortex-M33, bare-metal) | FABRIC + CAN-Principal (telemetria de missão) | IPC: MISSION_REQUEST/RESPONSE; publica referências para Voo via Navegação/Planeamento | **10 Hz nominal, até 50 Hz em fases de aproximação** (período 100 ms / 20 ms) | **≤ 40 ms** a 10 Hz; **≤ 12 ms** a 50 Hz (*jitter* ≤ 2 ms, relaxado) | **MÉDIA** | Atraso de Missão nunca atrasa Voo: Voo continua com última referência válida. Missão em falta >500 ms congela avanço de waypoint e sinaliza MISSION_STALE; Supervisor pode ordenar espera. |
| F6 | Planeamento (geração e verificação de trajetórias, lógica de missão pesada) | Grupo Computacional de Planeamento (no Master Geral) | RP2350 #3 | Núcleo 1 (Cortex-M33, bare-metal) | FABRIC | IPC interno; consome Cálculo e Navegação; produz planos para Missão | **Esporádico / sob pedido** (tipicamente 1–5 Hz durante replaneamento; inativo em cruzeiro estável) | **Melhor esforço com baliza**: entrega parcial ≤ 200 ms; entrega completa ≤ 1 s; Missão nunca bloqueia à espera | **MÉDIA-BAIXA** (abaixo de Missão) | Interrompível a qualquer momento pelo Supervisor; resultado parcial verificável é preferível a resultado tardio perfeito. Falha de planeamento mantém plano anterior. |
| F7 | Supervisão (guardião do agrupamento: batimentos, guardiões de tempo, integridade, sincronização) | Grupo Computacional de Supervisão (no Master Geral) | RP2350 #4 | Núcleo 0 (Cortex-M33, bare-metal, maior nível de interrupção do agrupamento) | FABRIC (escuta todos) + CAN-Principal (ambos os barramentos via Grupo de Segurança) | HEARTBEAT, HEALTH_STATUS, TIME_SYNC, FAULT, SYSTEM_STATUS sobre IPC e TLV/CAN FD | **Contínuo**: batimento 100 Hz interno; verificação de prazos a cada 5 ms; difusão de saúde a 10 Hz | **Deteção ≤ 10 ms** para falha de Voo/Fusão; **≤ 50 ms** para restantes; difusão de FAULT ≤ 5 ms após deteção | **SUPER_CRÍTICA** no domínio do Master Geral (preempta qualquer outro núcleo via sinal FABRIC + linha dedicada quando existir) | Não possui modo degradado: ou supervisiona ou o agrupamento é declarado NÃO_SUPERVISIONADO e o Grupo de Segurança assume contenção. Falha do próprio Supervisor é detetada por guardião físico externo (watchdog) que reinicia o RP2350 #4. |
| F8 | Diagnóstico (monitorização de saúde, contadores, registos, telemetria lenta) | Grupo Computacional de Diagnóstico (no Master Geral) | RP2350 #4 | Núcleo 1 (Cortex-M33, bare-metal) | FABRIC (recolha) + CAN-Principal (telemetria) + RJ45 (descarga em solo, via GCV) | HEALTH_STATUS, LOG, DEBUG sobre IPC e TLV; ficheiros de registo via Ethernet em solo | **1 Hz periódico + 10 Hz para sinais resumidos + por evento** | **Sem prazo rígido**: melhor esforço; telemetria lenta pode atrasar até 1 s sem impacto operacional | **BAIXA / MUITO_BAIXA** (primeira a ser descartada sob carga) | Descarte controlado: perde registos antes de atrasar tráfego crítico. Falha de Diagnóstico nunca provoca FailSafe; apenas reduz observabilidade e é assinalada em solo. |
| F9 | Visão principal (captura + ISP + deteção + codificação a 720p60) | Grupo Computacional de Visão — processamento (no GCV) | i.MX 8M Plus (ISP+GPU+NPU+motor de vídeo; núcleos A53 com Linux) | Cortex-A53 (Linux) para pipeline; Cortex-M7 (bare-metal) para controlo de câmara e tempo real auxiliar | MIPI CSI (câmara → SoC) interno ao GCV | Interno V4L2/GStreamer ou equivalente; saída para supervisor via pasta partilhada / UART / Ethernet interna | **720p60** (período 16,66 ms por fotograma) | **Pipeline ≤ 50 ms** ponta a ponta; **flutuação admissível de vários ms** (não crítica para voo) | **MÉDIA no GCV; BAIXA no sistema de voo** (visão nunca preempta Voo/Fusão no CAN-Principal) | Perda de fotogramas é normal e esperada: descarta sem bloquear. Falha total de visão não afeta voo; apenas remove funcionalidade de perceção. Supervisor do GCV reinicia pipeline. |
| F10 | Vídeo secundário + telemetria de visão para a estação terrestre (720p30) | Grupo Computacional de Visão — difusão (no GCV) | i.MX 8M Plus (codificador) | Cortex-A53 (Linux) | **RJ45 / Ethernet** (via conector RJ45 da placa de visão) + eventual rádio externo (fora do âmbito) | H.264/H.265 sobre RTP/RTSP ou equivalente; telemetria TLV encapsulada | **720p30** derivada de 720p60 (divisão por 2) + telemetria 1–10 Hz | **Melhor esforço**: latência de 200–500 ms aceitável; rajadas toleradas | **BAIXA** (tráfego de RJ45 nunca entra no CAN-Principal salvo resumos de saúde a 1 Hz) | Congestionamento na RJ45 provoca redução de débito ou de fotogramas, nunca retransmissão agressiva que afete o voo. Falha de RJ45 não tem efeito operacional. |
| F11 | Supervisor de visão (guardião, energia, saúde, ponte para o sistema) | Grupo Computacional de Visão — supervisão (no GCV) | RP2350 supervisor (bare-metal) | Núcleo 0 supervisão + Núcleo 1 comunicação (ambos bare-metal) | CAN-Principal (resumos) + ligação interna ao SoC (UART/SPI/GPIO) + RJ45 (gestão) | TLV/CAN FD a 1–10 Hz (HEALTH_STATUS do GCV); watchdog físico sobre o SoC | **10 Hz** supervisão + batimento 1 Hz para o Master Geral | **Deteção de bloqueio do SoC ≤ 500 ms**; reinicialização ≤ 5 s | **ALTA para efeitos de supervisão; BAIXA para tráfego de dados** | Bloqueio do SoC leva a corte e reposição de energia comandada pelo supervisor; GCV declara-se VISÃO_INDISPONÍVEL; voo prossegue sem visão. Falha do próprio supervisor é detetada pelo Master Geral por ausência de batimento. |

Notas de leitura da matriz:

* As periodicidades de Voo e Fusão são estritas: 200 Hz significa 200 ativações por segundo com desvio máximo de 100 µs e 150 µs respetivamente. As restantes são nominais e podem adaptar-se ao modo (ver §3.6).
* As latências indicadas incluem o tempo de comunicação necessário (FABRIC ou CAN-Principal). O orçamento interno de cálculo é sempre inferior à latência ponta a ponta, reservando margem para transporte.
* A coluna FALHA é normativa: descreve o comportamento mínimo exigido, não uma sugestão.

## 3.4 Diagrama temporal de referência (Master Geral, regime estável)

```text
Tempo →  0 ms      5 ms     10 ms     15 ms     20 ms
         │         │         │         │         │
FUSÃO    ████      ████      ████      ████      ████   200 Hz
         ▓ desfasamento ~1 ms
VOO        ████      ████      ████      ████      ██   200 Hz
                                        ▲
NAVEGAÇÃO  ██████████                   ██████████     50 Hz
         (usa Fusão + Cálculo via FABRIC, sem bloquear Voo)
MISSÃO     ████████████████████████████████████████   10 Hz
         (publica referências; Voo valida antes de usar)

LEGENDA: █ = execução periódica; ▓ = deslocamento intencional para
         evitar contenção simultânea na FABRIC.
```

Desfasar Fusão e Voo em cerca de 1 ms evita que ambos disputem a FABRIC no mesmo instante e garante que o Voo dispõe quase sempre de uma estimativa fresca com cerca de 1 ms de idade, em vez de uma estimativa com quase 5 ms.

## 3.5 Interfaces temporais: FABRIC, CAN-Principal e RJ45

### 3.5.1 FABRIC — interligação interna do Master Geral

A FABRIC é a rede interna que liga os 4 RP2350. Conceptualmente:

```text
              ┌─────────────┐
              │  RP2350 #1  │  Voo + Fusão (crítico)
              │  Core0/Core1│
              └──────┬──────┘
                     │ FABRIC (ponto a ponto, full-duplex)
        ┌────────────┼────────────┐
        ▼            ▼            ▼
   ┌─────────┐ ┌─────────┐ ┌─────────┐
   │ RP2350  │ │ RP2350  │ │ RP2350  │
   │   #2    │ │   #3    │ │   #4    │
   │Nav+Calc │ │Mis+Plan │ │Sup+Diag │
   └─────────┘ └─────────┘ └─────────┘
```

Características temporais exigidas:

* Latência de mensagem curta (pedido/resposta de cálculo, estado de fusão) **inferior a 200 µs** ponta a ponta entre quaisquer dois RP2350, excluindo tempo de processamento.
* Largura de banda suficiente para sustentar 200 Hz × (estado de fusão + dados sensoriais resumidos) mais rajadas de MATH_REQUEST/RESPONSE sem fila persistente.
* Arbitragem determinística: tráfego de Voo/Fusão/Supervisão usa fila dedicada de alta prioridade; tráfego de Missão/Planeamento/Diagnóstico usa fila separada de baixa prioridade. A fila de baixa prioridade nunca bloqueia a de alta (sem inversão de prioridade sem herança).
* Sincronização temporal por TIME_SYNC difundido pelo Núcleo de Supervisão a 100 Hz, com carimbo monotónico comum. Todos os carimbos IPC usam essa base.
* Candidatas técnicas (a fechar em HW): SPI dedicado por par + DMA, PIO como árbitro, memória partilhada externa apenas para blocos grandes de planeamento (nunca para o ciclo de 5 ms).

A FABRIC **não é** um barramento partilhado genérico: é uma malha de ligações ponto a ponto com prioridades físicas ou lógicas separadas. Esta decisão é intencional para obter determinismo analisável.

### 3.5.2 CAN-Principal — rede entre grupos

O CAN-Principal é composto por dois barramentos CAN FD (operacional e de segurança), conforme COM-001/COM-008. Do ponto de vista temporal:

```text
BUS OPERACIONAL (CAN FD, arbitragem 500 kbit/s, dados até 2–5 Mbit/s):
┌───────────────────────────────────────────────────────────────┐
│ Grupo Sensorial → Master Geral (telemetria 50–200 Hz)         │
│ Master Geral → Grupo de Atuadores (comandos 200 Hz, CRÍTICA)  │
│ Master Geral ↔ Grupo de Segurança (estados 10 Hz + eventos)   │
│ GCV-supervisor → Master Geral (saúde 1 Hz, BAIXA)             │
└───────────────────────────────────────────────────────────────┘

BUS DE SEGURANÇA (dedicado, arbitragem 1 Mbit/s, dados até 5 Mbit/s):
┌───────────────────────────────────────────────────────────────┐
│ Grupo de Segurança ↔ Atuação de Emergência (SUPER_CRÍTICA)     │
│ Inibição do Grupo de Atuadores (SUPER_CRÍTICA, imediata)       │
└───────────────────────────────────────────────────────────────┘
```

Regras temporais:

* Comandos de Voo para atuadores (200 Hz) têm prioridade CRÍTICA e nunca esperam por telemetria de Missão ou de Visão.
* Mensagens de segurança (FAILSAFE, inibição) têm prioridade SUPER_CRÍTICA e são transmitidas de imediato, fora do ciclo periódico (orientadas a evento).
* Telemetria sensorial de alta taxa é agregada pelo Master Sensorial antes de entrar no CAN-Principal, para não saturar o barramento (ver SEN-001).
* Vídeo **nunca** circula no CAN-Principal. Apenas resumos de saúde do GCV (1 Hz, BAIXA) o utilizam.

### 3.5.3 RJ45 — Ethernet do GCV

A interface RJ45 pertence fisicamente à placa de visão e serve três propósitos, todos não críticos para o voo:

1. Difusão do fluxo secundário 720p30 para a estação terrestre (ou para rádio externo).
2. Descarga de registos e telemetria de Diagnóstico quando em solo.
3. Manutenção, atualização de modelos de visão e depuração.

```text
GCV (i.MX 8M Plus)
 ├── MIPI CSI ← câmara (720p60)
 ├── ISP/GPU/NPU → processamento + codificação
 ├── 720p60 → consumo interno (deteção, registo local)
 └── 720p60 ÷ 2 → 720p30 → RJ45 → estação terrestre / solo
RP2350 supervisor → CAN-Principal (apenas saúde a 1 Hz)
```

A RJ45 opera em melhor esforço. Congestionamento, perda de pacotes ou ausência de ligação não têm qualquer efeito sobre o voo. Esta separação física (vídeo na RJ45, controlo no CAN-Principal) é uma barreira arquitetónica contra inanição do barramento crítico por tráfego multimédia.

## 3.6 Bare-metal contra Linux no GCV: por que a distinção é vital

### 3.6.1 Master Geral: sempre bare-metal, sempre determinístico

Os 8 núcleos do Master Geral executam **sem sistema operativo**: um escalonador cooperativo/periódico mínimo, com interrupções vetorizadas, sem paginação, sem alocação dinâmica após inicialização, sem chamadas bloqueantes sem prazo.

Consequências:

* O tempo de resposta a uma interrupção é limitado e conhecido (dezenas de ciclos).
* O pior tempo de execução (WCET) de cada ciclo pode ser medido e orçamentado.
* Não existem processos em espaço de utilizador a disputar o processador de forma opaca.
* O programa cabe em SRAM interna (520 KB por RP2350), sem dependência de memória externa no caminho crítico.

É isto que permite garantir 200 Hz com flutuação de 100 µs.

### 3.6.2 GCV: Linux onde a flexibilidade vence, bare-metal onde o tempo importa

O GCV divide-se deliberadamente em dois domínios temporais:

```text
┌────────────────────────────────────────────────────────┐
│ GCV — DOMÍNIO NÃO DETERMINÍSTICO (Linux, Cortex-A53)   │
│                                                        │
│  Captura V4L2 → ISP → GPU/NPU → codificador → RJ45     │
│  720p60 → 720p30, deteção, registo                     │
│  Latência 200–500 ms aceitável, perda tolerada         │
│  Planeamento do SO (CFS), paginação, caches, rede:     │
│  TUDO opaco do ponto de vista temporal.                │
└───────────────────────────┬────────────────────────────┘
                            │ UART/SPI/GPIO (ponte estreita e auditável)
┌───────────────────────────▼────────────────────────────┐
│ GCV — DOMÍNIO DETERMINÍSTICO (bare-metal)              │
│                                                        │
│  Cortex-M7 do SoC + RP2350 supervisor                  │
│  Watchdog, energia, temperatura, saúde, TIME_SYNC,     │
│  ponte TLV/CAN FD a 1–10 Hz                            │
│  Prazos curtos e garantidos, sem Linux no caminho.     │
└────────────────────────────────────────────────────────┘
```

Explicação pormenorizada:

* **Linux é necessário** no GCV porque o processamento de vídeo exige pilha de câmara, controladores ISP/GPU/NPU, codificadores e pilha de rede. Reimplementar isto em bare-metal seria impraticável e frágil.
* **Linux não é determinístico**: o escalonador justo, a gestão de memória, as caches, o tráfego de rede e os controladores introduzem variações de latência de milissegundos a centenas de milissegundos, impossíveis de limitar de forma rigorosa. Por isso, **nenhuma função de voo depende temporalmente do Linux**.
* O **Cortex-M7** do próprio SoC pode correr firmware bare-metal para tarefas de tempo real auxiliar (controlo de exposição, carimbo temporal de fotogramas, sincronização com o Master Geral).
* O **RP2350 supervisor** corre sempre bare-metal e é o único interlocutor temporalmente fiável do GCV para o resto do sistema. Se o Linux bloquear, o supervisor deteta (ausência de batimento, temperatura, watchdog) e reinicia o SoC sem afetar o voo.

Regra de ouro: **o voo tem de ser seguro com o GCV completamente desligado**. A visão é aumento de capacidade, nunca requisito de segurança.

## 3.7 Determinismo ponta a ponta: como se obtém na prática

Determinismo significa que, perante as mesmas entradas e no mesmo modo, o sistema produz as mesmas saídas dentro da mesma janela temporal, com variação limitada e conhecida.

Medidas concretas exigidas:

1. **Períodos fixos com desfasamento intencional** (§3.4), evitando contenção simultânea.
2. **Sem alocação dinâmica** após arranque em qualquer núcleo do Master Geral e no supervisor do GCV. Toda a memória é estática ou de reserva fixa.
3. **Filas limitadas com deserção por prazo**: nenhuma fila cresce sem limite; mensagens expiradas são descartadas e contabilizadas.
4. **Herança de prioridade no Núcleo de Cálculo**: um pedido de Voo eleva temporariamente a prioridade do cálculo, impedindo inversão.
5. **Carimbos monotónicos em todas as mensagens IPC e TLV**, permitindo medir idade e descartar dados obsoletos em vez de os usar tarde.
6. **Orçamentos WCET por função**, medidos em protótipo e revistos a cada alteração de programa. A soma de WCET + tempo de FABRIC + margem tem de caber no período.
7. **Modos temporais**: cada modo de voo (solo, descolagem, cruzeiro, aproximação, emergência) pode ajustar Navegação 50/100 Hz e Missão 10/50 Hz, mas nunca Voo/Fusão 200 Hz. A mudança de modo é anunciada e transitória (ver §3.9).

## 3.8 Anti-inanição (anti-starvation): ninguém crítico fica sem vez

Inanição ocorre quando uma tarefa pronta nunca recebe processador ou barramento porque tarefas menos importantes a ultrapassam continuamente. As defesas são em camadas:

**a) Separação física de criticidades.**
Voo+Fusão residem no RP2350 #1, isolados de Missão+Planeamento no RP2350 #3. Mesmo que o planeamento entre em ciclo intenso, não rouba ciclos ao Voo porque são processadores distintos.

**b) Filas separadas por prioridade na FABRIC e no CAN-Principal.**
Cada nível de prioridade possui fila própria. O árbitro serve sempre a fila mais prioritária não vazia, mas com **quota mínima garantida** para as filas baixas (para que Diagnóstico não morra por completo) e **limite máximo** para as altas (para que uma rajada de Voo não impeça permanentemente o Diagnóstico de emitir um FAULT). Esquema de lotaria ponderada ou de quota cíclica com prioridade estrita para SUPER_CRÍTICA.

```text
FABRIC — arbitragem por núcleo de saída:

Fila SUPER_CRÍTICA / CRÍTICA (Voo, Fusão, Supervisão)
  │ servida primeiro, mas limitada a N pacotes por janela
  ▼
Fila ALTA (Navegação, Cálculo urgente)
  │ servida a seguir
  ▼
Fila MÉDIA/BAIXA (Missão, Planeamento, Diagnóstico, Visão-resumo)
  │ recebe quota mínima garantida por janela (anti-inanição)
  ▼
Saída física (SPI/DMA)
```

**c) Núcleo de Cálculo com deserção e herança.**
Pedidos com prazo expirado são descartados em vez de acumulados. Pedidos antigos de baixa prioridade nunca bloqueiam pedidos novos de alta prioridade por mais do que um quantum.

**d) Diagnóstico descartável.**
O Diagnóstico é a primeira vítima legítima: perde registos antes de atrasar qualquer outra função. Inversamente, o Supervisor nunca pode ser vítima: possui interrupção dedicada e janela reservada.

**e) Guardiões de tempo (watchdogs) em cascata.**
Cada núcleo possui guardião interno; cada RP2350 possui guardião de par; o RP2350 #4 supervisiona o agrupamento; um guardião físico externo supervisiona o RP2350 #4; o Grupo de Segurança supervisiona o Master Geral como um todo. Um núcleo bloqueado é reiniciado sem reiniciar os restantes, salvo se a falha for sistémica.

**f) Regra de não-bloqueio.**
Nenhuma função CRÍTICA ou ALTA bloqueia indefinidamente à espera de função MÉDIA ou inferior. Toda a espera possui prazo e via degradada (último valor válido, predição, modelo simplificado ou contenção).

## 3.9 Modos e transição temporal

| Modo | Voo | Fusão | Navegação | Missão | Planeamento | Notas |
|------|-----|-------|-----------|--------|-------------|-------|
| Solo / arranque | 200 Hz | 200 Hz | 50 Hz | 10 Hz | inativo | Ênfase em autoteste e sincronização. |
| Descolagem / aterragem | 200 Hz | 200 Hz | **100 Hz** | **50 Hz** | ativo (1–5 Hz) | Dinâmica rápida exige Navegação e Missão aceleradas. |
| Cruzeiro | 200 Hz | 200 Hz | 50 Hz | 10 Hz | esporádico | Poupança de FABRIC e de energia. |
| Emergência / FailSafe | 200 Hz | 200 Hz | 50 Hz (interna ao Grupo de Segurança quando assumido) | congelada | interrompido | Master Geral pode ser inibido; autoridade passa ao Grupo de Segurança. |

A transição de modo é anunciada pelo Supervisor com antecedência mínima de 2 períodos da função afetada e possui rampa (não há salto abrupto de 10 Hz para 50 Hz no mesmo ciclo sem aviso).

---

# 4. Exemplos ASCII

## 4.1 Sequência temporal de um ciclo de Voo com Fusão e Cálculo

```text
Tempo (ms, dentro de um período de 5 ms):

0,0 ── FUSÃO acorda (RP2350 #1 Core1)
0,0–2,0   lê resumo sensorial (FABRIC), executa fusão, publica ESTADO_FUSÃO
            │
1,0 ── VOO acorda (RP2350 #1 Core0, desfasado)
1,0–1,2     lê ESTADO_FUSÃO (idade ~1 ms, válido)
1,2–1,4     pede transformação ao CÁLCULO (MATH_REQUEST, FABRIC, prazo 1,5 ms)
1,4–2,2     CÁLCULO responde (MATH_RESPONSE, herança de prioridade)
2,2–3,0     VOO valida referência de MISSÃO/NAVEGAÇÃO (se expirada, usa anterior)
3,0–3,2     VOO emite COMANDO validado (FABRIC → CAN-Principal → Atuadores)
3,2–5,0     janela livre (margem, supervisão, diagnóstico oportunista)
5,0 ── próximo ciclo; se VOO não concluiu até 4,5 ms → ciclo ABANDONADO + FAULT
```

## 4.2 MATH_REQUEST com prazo e deserção

```text
NAVEGAÇÃO (ALTA)              CÁLCULO (herda ALTA)           MISSÃO (MÉDIA)
    │                               │                            │
    │── MATH_REQUEST(id=42,         │                            │
    │   prazo=4 ms) ───────────────►│                            │
    │                               │── executa (FPU/DSP)        │
    │── MATH_REQUEST(id=77,         │                            │
    │   prazo=50 ms) ──────────────►│── enfileirado (MÉDIA)      │
    │                               │                            │
    │◄── MATH_RESPONSE(id=42, OK) ──│ (preempta fila MÉDIA)      │
    │                               │── executa pedido 77        │
    │                               │── MATH_RESPONSE(id=77) ───►│
    │                               │                            │
    │  Se pedido 42 excedesse 4 ms: │── MATH_TIMEOUT + descarta  │
    │  NAVEGAÇÃO usaria predição e o CÁLCULO libertaria a fila.  │
```

## 4.3 Supervisão deteta núcleo mudo e isola

```text
SUPERVISÃO (RP2350 #4 Core0, 100 Hz interno):

  Espera HEARTBEAT de cada núcleo (FABRIC, 100 Hz) + CAN-Principal (10 Hz)
       │
       ├── VOO heartbeat OK, FUSÃO heartbeat OK → nada a fazer
       │
       ├── PLANEAMENTO sem heartbeat há 200 ms → LOG + reinicia Núcleo 1 do #3
       │   (voo não afetado)
       │
       └── VOO sem heartbeat há 10 ms (2 ciclos perdidos) → FAULT imediato
           → notifica Grupo de Segurança → avalia FailSafe
           → VOO tenta reinício local; se falhar, contenção.
```

## 4.4 GCV: 720p60 interno, 720p30 na RJ45, saúde no CAN-Principal

```text
CÂMARA (MIPI CSI, 720p60, 16,66 ms/fotograma)
  │
  ▼
i.MX 8M Plus (Linux) — ISP → deteção (NPU) → codificação
  │
  ├── 720p60 → registo local + consumo interno (melhor esforço, ≤50 ms)
  │
  └──÷2──► 720p30 → RJ45 → estação terrestre (200–500 ms aceitável)
              (congestionamento → baixa débito, nunca afeta CAN-Principal)

RP2350 supervisor (bare-metal, 10 Hz):
  observa SoC (batimento, temperatura, watchdog)
  publica GCV_HEALTH a 1 Hz no CAN-Principal (BAIXA)
  se SoC mudo >500 ms → corte e reposição de energia → VISÃO_INDISPONÍVEL
```

---

# 5. Interfaces

## 5.1 Resumo das interfaces por função

| Função | Entrada | Saída | Interface física | Protocolo | Cadência |
|--------|---------|-------|------------------|-----------|----------|
| Voo | Estado de Fusão + referência de Navegação/Missão + MATH_RESPONSE | Comandos validados para atuadores + estado de voo | FABRIC + CAN-Principal | IPC + TLV/CAN FD | 200 Hz |
| Fusão | Telemetria sensorial agregada + TIME_SYNC | Estado fundido 200 Hz | FABRIC + CAN-Principal (entrada) | IPC + TLV/CAN FD | 200 Hz |
| Navegação | Estado fundido + MATH_RESPONSE + referências de Missão | Solução de navegação + NAVIGATION_RESPONSE | FABRIC | IPC | 50–100 Hz |
| Cálculo | MATH_REQUEST de qualquer núcleo | MATH_RESPONSE ou MATH_TIMEOUT | FABRIC | IPC com id e prazo | Sob pedido |
| Missão | NAVIGATION_RESPONSE + planos + telemetria | Referências e MISSION_REQUEST | FABRIC + CAN-Principal | IPC + TLV | 10–50 Hz |
| Planeamento | Mapa/missão + Navegação + Cálculo | Planos verificados | FABRIC | IPC (blocos grandes via memória partilhada) | Esporádico |
| Supervisão | HEARTBEAT + HEALTH de todos | FAULT + TIME_SYNC + decisões | FABRIC + CAN-Principal | IPC + TLV | 100 Hz int. / 10 Hz difusão |
| Diagnóstico | Contadores e registos de todos | LOG/DEBUG/telemetria | FABRIC + CAN-Principal + RJ45 (solo) | IPC + TLV + ficheiros | 1–10 Hz + eventos |
| Visão 720p60 | MIPI CSI | Deteções + registo + 720p30 | Interna GCV + RJ45 | V4L2/GStreamer, RTP/H.264 | 60 fps |
| Supervisor GCV | Batimento SoC + sensores de placa | GCV_HEALTH + watchdog + energia | UART/SPI/GPIO + CAN-Principal | TLV/CAN FD 1 Hz | 10 Hz |

## 5.2 Requisitos de conetores e cablagem (resumo)

* CAN-Principal: par entrançado com terminação de 120 Ω em cada extremo, dois barramentos independentes, isolamento recomendado no domínio de segurança. Débito de arbitragem 500 kbit/s a 1 Mbit/s, dados até 5 Mbit/s.
* RJ45: Ethernet 100BASE-TX mínima, 1000BASE-T recomendada, apenas na placa de visão. Não partilha caminho com CAN-Principal.
* FABRIC: ligações curtas intra-placa entre RP2350, comprimento minimizado, blindagem e integridade de sinal conforme HW. Não exposta em conetor externo salvo depuração.

O detalhe elétrico pertence às especificações HW e COM; aqui fixa-se apenas o uso temporal de cada meio.

---

# 6. Pontos em Aberto

1. **Topologia definitiva da FABRIC**: número de linhas SPI, uso de PIO como árbitro, necessidade de memória partilhada externa e pinagem exata. Requer protótipo e medição de latência real ponta a ponta.
2. **Orçamentos WCET medidos**: os valores de latência deste documento são orçamentos de projeto. Têm de ser confirmados por medição em hardware à frequência nominal (150 MHz) com análise de pior caso.
3. **Escolha RP2350 contra RP2354** (com memória empilhada) e quantidade de PSRAM/flash por RP2350, sobretudo para Planeamento (mapas) e Diagnóstico (registos).
4. **Mecanismo de arranque e atualização**: sequência de boot dos 4 RP2350, sincronização inicial de relógios, atualização atómica de firmware sem dessincronizar o agrupamento.
5. **Codec e formato de transporte do 720p30**: H.264 contra H.265, encapsulamento RTP/RTSP, débito nominal e comportamento sob perda.
6. **Sistema operativo do GCV**: distribuição Linux, configuração de tempo real suave (PREEMPT_RT ou não), isolamento de núcleos A53 para captura contra codificação.
7. **Quotas exatas do árbitro da FABRIC**: N pacotes por janela por nível, quantum do Núcleo de Cálculo, limiares de deserção por classe de pedido.
8. **Limiares de FailSafe por atraso**: quantos ciclos de Voo/Fusão perdidos disparam contenção em cada modo, tempos de confirmação e histerese para evitar oscilação.
9. **Sincronização fina GNSS/tempo**: uso de pulso por segundo do recetor de navegação por satélite para disciplinar o TIME_SYNC do Supervisor quando disponível.
10. **Validação de carga máxima do CAN-Principal**: cálculo de ocupação do barramento a 200 Hz de comandos mais telemetria sensorial agregada mais estados, com margem para rajadas de segurança.

---

# 7. Referências

* SYS-002 — Arquitetura Computacional (domínios e autoridade).
* SYS-003 — Arquitetura de Software (modularidade e gestor de comunicações).
* SYS-005 — Fluxo Global de Informação (fluxos de informação, controlo e autoridade).
* SYS-008 — Gestão Temporal (referências, sincronização e modelo temporal).
* COM-001 — Arquitetura de Comunicação (camadas TLV/CAN FD).
* COM-004 — Prioridades e Filas.
* COM-006 — Tempos Limite e Recuperação.
* COM-008 — Rede CAN FD.
* SEN-001 — Cadeia Sensorial (fornecedora temporal da Fusão).
* CTL-001 — Lógica de Controlo (consumidora temporal do Voo).
* NAV-001 — Serviço de Navegação (consumidor temporal de Fusão e Cálculo).
* Docs/Esquemas/Arquitetura-Computacional — conceito de agrupamento de 8 núcleos e GCV.
* Documentação oficial RP2040, RP2350 e i.MX 8M Plus (características e limites elétricos).
