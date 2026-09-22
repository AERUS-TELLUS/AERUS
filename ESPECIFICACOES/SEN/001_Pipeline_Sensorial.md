# SEN-001 — Cadeia Sensorial

| Campo             | Valor                      |
| ----------------- | -------------------------- |
| **Código**        | SEN-001                    |
| **Título**        | Cadeia Sensorial           |
| **Versão**        | 1.0                        |
| **Estado**        | Em Desenvolvimento         |
| **Autor**         | ShegaPT                    |
| **Classificação** | Especificação de Sensores  |

---

# 1. Objetivo

O presente documento define a cadeia sensorial do sistema **Aerus**, ou seja, o caminho completo percorrido por uma grandeza física desde o elemento sensível até à disponibilidade dessa grandeza, já tratada e carimbada no tempo, no barramento principal do veículo (**CAN-Principal**).

A cadeia é executada no interior do **Grupo Computacional Sensorial** e segue obrigatoriamente a sequência:

```text
Sensor
  ↓
Aquisição
  ↓
Filtragem
  ↓
Calibração
  ↓
Normalização
  ↓
Validação
  ↓
Mensagem
  ↓
Master Sensorial (RP2350)
  ↓
CAN-Principal
```

Nenhuma etapa pode ser omitida em voo, nenhuma pode ser reordenada sem revisão formal e nenhum consumidor externo (fusão, navegação, segurança, missão) recebe dados que não tenham atravessado integralmente esta cadeia.

O documento estabelece para cada etapa a finalidade, as operações admissíveis, as frequências típicas, os critérios de rejeição e o comportamento em falha, de modo a que o Master Geral receba informação já tratada em vez de sinais elétricos em bruto.

---

# 2. Âmbito

## 2.1 Dentro do âmbito

* Todos os sensores de voo: unidades inerciais (acelerómetros, giroscópios), magnetómetros, sensores barométricos de pressão/altitude, recetores de navegação por satélite (GNSS), sensores de velocidade aerodinâmica (tubo de Pitot / pressão diferencial), sensores de temperatura, tensão e corrente, e sensores discretos de estado.
* Placas periféricas de aquisição baseadas em **RP2040** (aquisição, filtragem, calibração, normalização, validação e empacotamento local).
* **Master Sensorial** baseado em **RP2350** (agregação, sincronização temporal, verificação cruzada, formatação TLV e publicação no CAN-Principal).
* Interfaces locais (UART, SPI, I2C, ADC, PIO) e interface de saída (CAN FD com protocolo TLV).
* Nomenclatura oficial: **Grupo Computacional Sensorial** para o conjunto, **Elemento de Aquisição** para cada RP2040 periférico e **Master Sensorial** para o RP2350 agregador.

## 2.2 Fora do âmbito

* Algoritmos de fusão (MAT/NAV) e de controlo (CTL): a cadeia sensorial entrega dados normalizados; a interpretação é feita pelos consumidores.
* Atuadores e sua realimentação (ACT).
* Segurança e decisão de emergência (SEC): o Grupo de Segurança é consumidor dos dados sensoriais, não executor da cadeia.
* Detalhe elétrico de cada transdutor e desenho de placas (HW).
* Processamento de imagem e vídeo (GCV).

## 2.3 Convenção de nomes

Utiliza-se exclusivamente **Grupo Computacional Sensorial**. Não são utilizadas designações de plataformas de desenvolvimento ou de computadores de uso geral. Os processadores são identificados apenas como **RP2040** (periferia) e **RP2350** (Master Sensorial), coerentemente com a arquitetura computacional.

---

# 3. Descrição

## 3.1 Ideia fundamental: tratar cedo, transmitir pouco, carimbar sempre

A cadeia sensorial aplica o princípio de que **o processamento deve ocorrer tão próximo do sensor quanto possível**. Cada Elemento de Aquisição converte sinais elétricos em grandezas físicas com significado, filtra ruído, compensa erros sistemáticos e rejeita leituras implausíveis. O Master Sensorial agrega, sincroniza e publica. O Master Geral funde e decide.

Vantagens:

* Reduz tráfego no CAN-Principal (transmitem-se grandezas a 10–200 Hz agregadas, não amostras em bruto a quilohertz).
* Isola o Master Geral das particularidades de cada transdutor (o voo recebe m/s², rad/s, hPa e metros, nunca contagens de ADC).
* Permite substituir um sensor sem alterar o voo, desde que a interface normalizada se mantenha.
* Torna cada etapa testável isoladamente.

## 3.2 Topologia do Grupo Computacional Sensorial

```text
                        GRUPO COMPUTACIONAL SENSORIAL
                                     │
        ┌────────────────────────────┼────────────────────────────┐
        │                            │                            │
        ▼                            ▼                            ▼
┌───────────────┐            ┌───────────────┐            ┌───────────────┐
│ ELEMENTO DE   │            │ ELEMENTO DE   │            │ ELEMENTO DE   │
│ AQUISIÇÃO #1  │            │ AQUISIÇÃO #2  │            │ AQUISIÇÃO #n  │
│   (RP2040)    │            │   (RP2040)    │            │   (RP2040)    │
│ IMU + Mag     │            │ Baro + Pitot  │            │ GNSS + discre-│
│ SPI/I2C/PIO   │            │ I2C/SPI/ADC   │            │ tos/UART      │
└───────┬───────┘            └───────┬───────┘            └───────┬───────┘
        │ Aquisição→…→Mensagem       │                            │
        │ (cadeia local completa)    │                            │
        └────────────────────────────┼────────────────────────────┘
                                     │ ligação interna do grupo
                                     │ (UART/SPI/CAN local + TLV)
                                     ▼
                          ┌─────────────────────┐
                          │  MASTER SENSORIAL   │
                          │     (RP2350)        │
                          │  agregação + tempo  │
                          │  + verificação      │
                          └──────────┬──────────┘
                                     │ TLV sobre CAN FD
                                     ▼
                               CAN-PRINCIPAL
                                     │
                    ┌────────────────┼────────────────┐
                    ▼                ▼                ▼
              Fusão 200 Hz    Navegação 50–100 Hz  Segurança (contínuo)
              (Master Geral)  (Master Geral)       (Grupo de Segurança)
```

Cada Elemento de Aquisição é autónomo: se o Master Sensorial reiniciar, os elementos continuam a adquirir e a reter as últimas amostras válidas com carimbo local. Se um elemento falhar, os restantes continuam e o Master assinala degradação parcial em vez de silêncio total.

## 3.3 As sete etapas, em pormenor

### Etapa 1 — Aquisição

**Onde:** Elemento de Aquisição (RP2040), junto ao sensor.
**O que faz:** lê o sinal elétrico ou digital e obtém uma amostra em bruto com carimbo monotónico imediato.

Operações típicas:

* Leitura ADC com sobreamostragem (ex.: barómetro e Pitot a centenas de hertz, com média por hardware quando disponível).
* Leitura SPI rápida para IMU (tipicamente 1–8 kHz de amostras internas, decimadas para 200–1000 Hz locais).
* Leitura I2C para magnetómetro e sensores lentos (10–100 Hz).
* Receção UART de sentenças do recetor GNSS (posição/velocidade/tempo a 1–10 Hz, mais pulso por segundo para disciplina temporal quando disponível).
* Captura PIO para protocolos particulares (contagem de impulsos, PWM de sensores, interfaces dedicadas).
* Uso de DMA para não ocupar o processador durante transferências SPI/I2C/UART.

Cada amostra recebe imediatamente um **carimbo monotónico local** (tempo desde arranque do RP2040, resolução de microssegundos). Sem carimbo, a amostra é inválida.

Frequências de aquisição (valores de referência, a afinar por sensor):

| Sensor | Aquisição local | Observações |
|--------|-----------------|-------------|
| IMU (acelerómetro + giroscópio) | 1000 Hz decimados para 200–400 Hz | Núcleo duro do voo; nunca abaixo de 200 Hz. |
| Magnetómetro | 50–100 Hz | Compensação de inclinação feita a jusante com atitude da Fusão quando disponível; localmente apenas calibração dura/macia. |
| Barómetro | 50–100 Hz com sobreamostragem | Média móvel curta para remover ruído acústico. |
| Pitot / pressão diferencial | 50–100 Hz | Proteção contra saturação e contra inversão. |
| GNSS | 5–10 Hz (solução) + 1 Hz (pulso temporal) | Atraso de transporte conhecido e carimbado; nunca usado como única fonte de atitude. |
| Temperatura / tensão / corrente | 10–50 Hz | Essencial para compensação e para diagnóstico energético. |

Falha nesta etapa: ausência de resposta, erro de paridade/CRC do sensor, saturação persistente. O elemento declara AMOSTRA_AUSENTE e propaga o estado em vez de inventar valores.

### Etapa 2 — Filtragem

**Onde:** Elemento de Aquisição (RP2040).
**O que faz:** atenua ruído sem destruir a dinâmica útil nem introduzir atraso excessivo.

Ferramentas admitidas (conforme MAT-013 e MAT-017):

* Média móvel curta (2–8 amostras) para barómetro e Pitot.
* Filtro mediano de 3–5 amostras para rejeitar picos isolados (ex.: perturbação eletromagnética momentânea).
* Passa-baixo de primeira ou segunda ordem com frequência de corte documentada por sensor (ex.: corte a ~40–80 Hz para IMU de voo, preservando a banda de controlo a 200 Hz).
* Rejeição de 50 Hz da rede apenas em ensaios em solo (nunca como dependência de voo).

Proibido nesta etapa: filtros com atraso de grupo superior a meio período de publicação sem declaração explícita; filtros adaptativos não determinísticos; qualquer filtro que exija alocação dinâmica.

Cada filtro possui parâmetros fixos por compilação (ou por configuração validada em solo) e o seu atraso nominal é documentado para que a Fusão possa compensar.

### Etapa 3 — Calibração

**Onde:** Elemento de Aquisição (RP2040).
**O que faz:** remove erros sistemáticos conhecidos do exemplar concreto.

Operações:

* Subtração de desvio de zero (*offset*) medido em solo (ex.: giroscópio em repouso, Pitot com velocidade nula).
* Aplicação de fator de escala de laboratório (contagens → volt → pascal → m/s).
* Compensação térmica por tabela ou polinómio (sobretudo barómetro e IMU de baixo custo).
* Calibração dura/macia do magnetómetro (esfera de calibração, executada em procedimento dedicado, nunca em voo).
* Verificação de validade da calibração (soma de verificação e versão). Se a calibração estiver ausente ou corrompida, os dados saem marcados como NÃO_CALIBRADOS e a Fusão trata-os como degradados.

A calibração é específica do exemplar (sensor + placa + posição na aeronave). Trocar um sensor sem carregar a sua calibração é tratado como falha de configuração, não como ruído.

### Etapa 4 — Normalização

**Onde:** Elemento de Aquisição (RP2040).
**O que faz:** converte para unidades do Sistema Internacional e para referenciais documentados, independentemente do fabricante.

Regras:

* Acelerómetros em m/s², giroscópios em rad/s, magnetómetro em µT, pressão em hPa/Pa, temperatura em °C, tensão em V, corrente em A, posição GNSS em graus decimais + metros de altitude, velocidade em m/s.
* Eixos segundo convenção única da aeronave (ex.: X para a frente, Y para a direita, Z para baixo, documentada em HW/SYS). A rotação sensor→aeronave é parâmetro de montagem, não código disperso.
* Representação em vírgula flutuante de 32 bits ou em inteiro de escala fixa documentada, sempre com campo de unidade implícita fixa por tipo de mensagem (nunca ambígua).
* Resolução e gama declaradas (ex.: ±16 g, ±2000 °/s) para que a Validação conheça os limites.

Após esta etapa, dois sensores de marcas diferentes produzem mensagens indistinguíveis do ponto de vista do consumidor. É esta a abstração que permite evoluir o hardware sem reescrever o voo.

### Etapa 5 — Validação

**Onde:** Elemento de Aquisição (RP2040), com segunda verificação no Master Sensorial (§3.4).
**O que faz:** decide, amostra a amostra, se o valor pode ser confiado.

Testes obrigatórios, por ordem:

1. **Limites físicos**: valor dentro da gama do sensor e da aeronave (ex.: pressão positiva, temperatura plausível, aceleração abaixo do limite estrutural). Fora → REJEITADA.
2. **Taxa de variação**: salto entre amostras consecutivas compatível com a física (ex.: variação de pressão correspondente a subida impossível → REJEITADA ou MARCADA).
3. **Congelamento**: valor idêntico durante N amostras além do esperado (sensor bloqueado) → CONGELADO.
4. **Tempo**: idade da amostra dentro da janela (ex.: IMU com mais de 20 ms é OBSOLETA para a Fusão a 200 Hz).
5. **Coerência local**: quando existem fontes redundantes no mesmo elemento (ex.: dois barómetros), divergência excessiva → DIVERGENTE.

Resultado da validação é um **estado por grandeza**, nunca apenas o valor:

```text
VÁLIDA | DEGRADADA (usável com cautela) | REJEITADA | CONGELADA | AUSENTE | OBSOLETA
```

Amostras REJEITADAS não seguem para Mensagem como se fossem boas: ou são omitidas (com contador de omissões) ou seguem marcadas como inválidas, conforme o tipo. O silêncio enganador é proibido: ausência prolongada gera mensagem explícita de estado.

### Etapa 6 — Mensagem

**Onde:** Elemento de Aquisição (RP2040).
**O que faz:** empacota grandezas já validadas em mensagens TLV com carimbo, sequência e integridade.

Conteúdo mínimo por mensagem:

```text
CABEÇALHO: origem (elemento), sequência, carimbo monotónico, versão de calibração
CORPO TLV: uma ou mais grandezas normalizadas + estado de cada uma
RODAPÉ: CRC + (quando aplicável) autenticação e anti-repetição
```

Cadências locais (elemento → Master Sensorial):

* IMU resumida: 200 Hz (ou 400 Hz em configuração de alta dinâmica).
* Baro/Pitot/magnetómetro: 50–100 Hz.
* GNSS: 5–10 Hz.
* Casa de máquinas (tensão/corrente/temperatura/estados): 10 Hz + evento imediato em anomalia.

As mensagens locais usam o mesmo formato TLV do CAN-Principal, para que a validação e o registo sejam uniformes. O transporte interno do grupo (UART/SPI/CAN local) é detalhe de placa; o conteúdo lógico é idêntico.

### Etapa 7 — Master Sensorial (RP2350) → CAN-Principal

**Onde:** Master Sensorial (RP2350, bare-metal).
**O que faz:** agrega, sincroniza, verifica e publica.

Funções:

1. **Agregação**: combina mensagens dos vários elementos num conjunto coerente por ciclo (ex.: pacote inercial a 200 Hz + pacote aerométrico a 50 Hz + pacote GNSS a 5 Hz, cada um na sua cadência, sem forçar tudo à mesma taxa).
2. **Sincronização temporal**: traduz carimbos locais para a base temporal comum do veículo (TIME_SYNC do Supervisor), compensa atrasos de transporte conhecidos e marca a idade de cada grandeza. A Fusão precisa de saber se a atitude tem 2 ms ou 12 ms.
3. **Verificação cruzada**: compara fontes redundantes ou complementares (ex.: altitude barométrica contra altitude GNSS; velocidade Pitot contra velocidade GNSS; atitude propagada contra magnetómetro). Divergência persistente gera alerta de integridade sem bloquear a publicação (publica-se o melhor com estado DEGRADADO).
4. **Formatação final TLV** e publicação no CAN-Principal nas cadências contratadas com o Master Geral e com o Grupo de Segurança (ver §4.2).
5. **Gestão de modo**: em solo, publica a taxa completa para calibração; em cruzeiro, pode decimar telemetria lenta; em emergência, prioriza IMU+baro e silencia o acessório.
6. **Registo local resumido**: contadores de amostras, rejeições, congelamentos e idades máximas, enviados ao Diagnóstico a 1–10 Hz.

O Master Sensorial nunca inventa dinâmica: não filtra novamente com atraso significativo nem prediz além de compensação de transporte documentada. A predição é tarefa da Fusão.

---

# 4. Exemplos ASCII

## 4.1 Cadeia completa para um acelerómetro (caso feliz)

```text
Transdutor MEMS
  │ sinal analógico/digital em bruto (1000 Hz internos)
  ▼
AQUISIÇÃO (RP2040, SPI + DMA, carimbo imediato t0)
  │ contagens + t0
  ▼
FILTRAGEM (média curta + passa-baixo a 60 Hz, atraso 3 ms documentado)
  │ contagens filtradas + t0
  ▼
CALIBRAÇÃO (offset do exemplar + escala + compensação térmica a 35 °C)
  │ m/s² ainda no referencial do sensor
  ▼
NORMALIZAÇÃO (rotação sensor→aeronave: X frente, Y direita, Z baixo)
  │ ax, ay, az em m/s² no referencial da aeronave + t0
  ▼
VALIDAÇÃO (|a| dentro de ±16 g, Δ entre amostras plausível, idade < 5 ms)
  │ ax, ay, az + estado=VÁLIDA + t0
  ▼
MENSAGEM (TLV: origem=AQ1, seq=12345, t0, ax, ay, az, estado, CRC)
  │ 200 Hz para o Master Sensorial (UART/SPI/CAN local)
  ▼
MASTER SENSORIAL (RP2350: traduz t0→tempo comum T, verifica redundância,
  agrega com gyro+mag+baro, publica TLV no CAN-Principal a 200 Hz)
  │
  ▼
CAN-PRINCIPAL → Fusão (consome a 200 Hz) + Segurança (escuta) + registo
```

## 4.2 Publicação agregada do Master Sensorial (três cadências independentes)

```text
Tempo →  0 ms    5 ms   10 ms   15 ms   20 ms   25 ms ...

Pacote INERCIAL (200 Hz, pequeno, prioritário):
 █████   █████   █████   █████   █████   █████  IMU + estado + T

Pacote AEROMÉTRICO (50 Hz, médio):
 ████████████████████                    ████████████████████
 baro + Pitot + temp + estado + T         (repete a cada 20 ms)

Pacote GNSS + LENTOS (5–10 Hz, maior):
 ████████████████████████████████████████████████
 lat/lon/alt/vel + tensão/corrente + contadores + T (a cada 100–200 ms)

LEGENDA: cada █ respeita a sua cadência; nenhum pacote espera pelo mais
lento. A Fusão usa o mais recente de cada tipo com a respetiva idade.
```

## 4.3 Caso de falha: Pitot congelado em voo

```text
Pitot lê sempre 42 Pa durante 2 s (vento real varia)
  │
  ▼
VALIDAÇÃO no Elemento #2: Δ=0 durante 100 amostras → CONGELADO
  │
  ├── Elemento continua a publicar, mas com estado=CONGELADO (não omite em
  │   silêncio; o consumidor sabe que não deve confiar)
  │
  ▼
MASTER SENSORIAL: compara Pitot (congelado) com GNSS (velocidade varia)
  → DIVERGENTE → publica Pitot=CONGELADO + velocidade GNSS como alternativa
  + alerta INTEGRIDADE_PITOT ao Diagnóstico e à Segurança
  │
  ▼
FUSÃO: ignora Pitot, estima velocidade por GNSS+IMU (modo degradado),
       assinala AR_DEGRADADO; MISSÃO limita envolvente (velocidade conservadora)
  │
  ▼
Solo: registo mostra congelamento exato + carimbos → substituição do sensor.
```

## 4.4 Formato lógico de mensagem (esquemático, sem valores binários)

```text
+--------------------------------------------------------------+
| INÍCIO | ID_MENSAGEM | CONTADOR_TLV |                          |
|--------------------------------------------------------------|
| Campo: ORIGEM (elemento + versão de calibração)              |
| Campo: SEQ + CARIMBO_COMUM (tempo do veículo)                |
| Campo: ACEL_X/Y/Z (m/s²) + ESTADO                            |
| Campo: GYRO_X/Y/Z (rad/s) + ESTADO                           |
| ... (apenas grandezas daquela cadência)                      |
|--------------------------------------------------------------|
| CRC + autenticação/sequência anti-repetição (quando aplicável)|
+--------------------------------------------------------------+
  Transporte: TLV sobre CAN FD no CAN-Principal;
              mesmo TLV sobre UART/SPI/CAN local dentro do grupo.
```

---

# 5. Interfaces

## 5.1 Interface Sensor ↔ Elemento de Aquisição (RP2040)

| Sensor | Ligação típica | Taxa | Notas |
|--------|----------------|------|-------|
| IMU | SPI rápida + interrupção de dado pronto + DMA | 1–8 kHz internos | Linha de dado pronto obrigatória para carimbo preciso. |
| Magnetómetro | I2C (ou SPI) | 50–100 Hz | Afastado de correntes fortes; calibração dedicada. |
| Barómetro | I2C/SPI com sobreamostragem | 50–100 Hz | Orifício estático protegido; média curta. |
| Pitot | SPI/ADC diferencial | 50–100 Hz | Dreno anti-condensação; teste pré-voo de sopro. |
| GNSS | UART + pulso por segundo | 5–10 Hz + 1 Hz | Antena com plano de massa; pulso disciplina o tempo. |
| Tensão/corrente/temp. | ADC + I2C | 10–50 Hz | Divisores e sensores calibrados por exemplar. |
| Discretos (chaves, peso nas rodas, portas) | GPIO com anti-ressalto | Por evento + 10 Hz | Sempre com estado explícito, nunca implícito. |

Todas as ligações incluem deteção de ausência (timeout), deteção de erro de transmissão (CRC/paridade do sensor quando existir) e isolamento contra um periférico em curto que impeça os restantes (alimentação comutável por sensor crítico quando aplicável em HW).

## 5.2 Interface Master Sensorial (RP2350) ↔ CAN-Principal

* Meio: CAN FD, barramento operacional (telemetria) com escuta pelo Grupo de Segurança; mensagens de integridade com prioridade ALTA, comandos inexistentes (o Grupo Sensorial nunca comanda, apenas publica).
* Protocolo: TLV (mesmo dicionário do sistema), com identificadores de mensagem por tipo de pacote (inercial, aerométrico, GNSS/lentos, estado/integridade).
* Cadências contratadas (regime de voo):
  * Inercial resumido: 200 Hz, prioridade ALTA, prazo de entrega < 3 ms após aquisição.
  * Aerométrico: 50 Hz, prioridade ALTA, prazo < 10 ms.
  * GNSS/lentos: 5–10 Hz, prioridade MÉDIA, prazo < 100 ms.
  * Integridade/estado do grupo: 10 Hz + evento imediato, prioridade ALTA em anomalia.
* Segurança: CRC por mensagem, sequência anti-repetição, autenticação quando exigida por SEC; qualquer falha de integridade descarta a mensagem e incrementa contador (nunca usa dado suspeito).
* Carga: dimensionada para caber no orçamento do CAN-Principal sem impedir comandos de voo a 200 Hz (ver SW-0xx e COM-008). A agregação no Master é justamente o mecanismo que garante essa cabimento.

## 5.3 Interface com consumidores

| Consumidor | O que recebe | Cadência de consumo | O que faz em falta |
|------------|--------------|---------------------|-------------------|
| Fusão (Master Geral, 200 Hz) | Inercial + aerométrico + idade | 200 Hz | Prediz por inércia breve; depois declara degradada. |
| Navegação (Master Geral, 50–100 Hz) | GNSS + aerométrico + idade | 50–100 Hz | Mantém última solução + envelhecimento. |
| Segurança (contínuo) | Todos + integridade | Contínuo | Avalia independentemente; pode pedir FailSafe. |
| Missão/Diagnóstico | Lentos + contadores | 10 Hz / 1 Hz | Congela ou regista lacuna. |
| GCV (visão) | Baro/GNSS resumidos a baixa taxa (quando útil) | 1–10 Hz | Prossegue sem eles. |

Nenhum consumidor configura o sensor diretamente em voo. Pedidos de alteração (ex.: mudar taxa GNSS) vão ao Master Sensorial como pedido de modo, nunca como acesso direto ao transdutor.

---

# 6. Pontos em Aberto

1. **Atribuição definitiva sensor→elemento**: quantos Elementos de Aquisição, que sensores em cada um, redundâncias (IMU dupla? barómetro duplo?) e isolamento físico entre elementos críticos.
2. **Transporte interno do grupo**: UART contra SPI contra CAN local entre RP2040 e RP2350, débitos, isolamento e conetores. Requer protótipo e medição de latência.
3. **Parâmetros de filtragem por sensor**: frequências de corte, janelas de média/mediana e atrasos nominais, a confirmar por ensaio de vibração real da célula.
4. **Procedimentos de calibração**: bancada de IMU/magnetómetro/barómetro/Pitot, periodicidade de recalibração, armazenamento versionado e soma de verificação.
5. **Disciplina temporal fina**: uso do pulso por segundo do GNSS para corrigir deriva entre Master Sensorial e Supervisor do Master Geral; tolerância de deriva sem GNSS.
6. **Redundância e votação**: com dois IMU ou dois barómetros, votação por média ponderada, por mediana ou por seleção; limiares de divergência e histerese.
7. **Deteção de gelo/bloqueio de Pitot e de tomada estática**: testes de plausibilidade adicionais e sensores de apoio (temperatura, humidade) para declarar suspeita antes do congelamento total.
8. **Ensaio de compatibilidade eletromagnética**: posicionamento de magnetómetro e de eletrónica de potência para não corromper a cadeia na etapa de aquisição.
9. **Orçamento de ocupação do CAN-Principal**: cálculo fechado com tamanhos TLV reais e margens para rajadas de segurança.
10. **Ferramentas de solo**: aplicação de calibração, visualização de estados por grandeza, rejeição de lote de sensores e rastreabilidade por número de série.

---

# 7. Referências

* SYS-002 — Arquitetura Computacional (domínios e autoridade).
* SYS-005 — Fluxo Global de Informação (aquisição e distribuição).
* SYS-008 — Gestão Temporal (aquisição contra comunicação, carimbos e prazos).
* SW-0xx — Políticas Temporais (cadências e latências exigidas à cadeia).
* COM-001 — Arquitetura de Comunicação (TLV sobre CAN FD).
* COM-008 — Rede CAN FD (transporte do CAN-Principal).
* MAT-013 — Processamento de Sinal (filtros).
* MAT-014 — Fusão de Sensores (consumidor a jusante).
* MAT-017 — Matemática de Sensores (calibração e modelos).
* NAV-001 — Serviço de Navegação (consumidor de GNSS/aerométricos).
* Docs/Esquemas/Arquitetura-Computacional (§ RP2040/RP2350 e cadeia periférica).
