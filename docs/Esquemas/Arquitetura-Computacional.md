# Arquitetura Computacional Embarcada

## Sistema de Voo Autónomo — Aeromodelo / UAV Asa Fixa

**Estado:** Arquitetura conceptual
**Objetivo:** Definição da arquitetura computacional, distribuição de responsabilidades e seleção preliminar dos processadores/SoCs.

---

# 1. Visão geral

O sistema será concebido como uma **arquitetura computacional distribuída**, constituída por vários grupos computacionais independentes.

Cada grupo possui uma responsabilidade específica e pode ser constituído por uma ou mais PCBs especializadas.

A filosofia fundamental é:

> **Cada unidade computacional deve executar uma responsabilidade bem definida, possuir interfaces claramente delimitadas e poder funcionar de forma independente das restantes unidades sempre que possível.**

A arquitetura não deverá depender de um único processador central responsável por todas as tarefas.

Em vez disso, o sistema será dividido em:

* aquisição e normalização de sensores;
* processamento de sensores;
* controlo de atuadores;
* navegação;
* controlo de voo;
* cálculo matemático;
* gestão de missão;
* supervisão e segurança;
* visão computacional;
* comunicação;
* diagnóstico e monitorização.

---

# 2. Filosofia de processamento

A arquitetura utiliza três níveis principais de processamento:

| Processador                            | Papel principal                                                                                             |
| -------------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| **RP2040**                             | I/O, aquisição, normalização, pequenas tarefas determinísticas                                              |
| **RP2350**                             | Processamento embarcado mais complexo, masters de grupos e processamento determinístico de maior desempenho |
| **NXP i.MX 8M Plus — MIMX8ML4DVNLZAB** | Computação de visão, processamento multimédia, GPU, ISP e aceleração de IA                                  |

O objetivo não é utilizar o processador mais poderoso em todas as funções.

Cada tarefa deve utilizar o processador **adequado à sua natureza**.

---

# 3. RP2040

## 3.1 Função

O RP2040 será utilizado principalmente nas PCBs periféricas e nos grupos computacionais que necessitam de:

* aquisição de sensores;
* leitura de entradas;
* filtragem;
* calibração;
* normalização;
* conversão de unidades;
* geração de PWM;
* controlo de atuadores;
* interfaces SPI;
* interfaces I²C;
* interfaces UART;
* protocolos personalizados através de PIO;
* pequenas máquinas de estado;
* monitorização local.

O RP2040 não será utilizado como computador principal do sistema de voo.

---

## 3.2 Características relevantes

O RP2040 possui:

* 2 × ARM Cortex-M0+;
* até 133 MHz;
* 264 KB de SRAM;
* 30 GPIO;
* 4 entradas analógicas;
* 2 × UART;
* 2 × SPI;
* 2 × I²C;
* 16 canais PWM;
* USB 1.1;
* 8 state machines PIO;
* DMA;
* arquitetura de barramento AHB;
* funcionamento de baixo consumo.

Fonte principal: documentação oficial do Raspberry Pi.

---

## 3.3 Aplicações previstas

### PCB de sensores

```text
Sensor
  ↓
RP2040
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
Barramento do sistema
```

### PCB de atuadores

```text
Comando
  ↓
RP2040
  ↓
Validação
  ↓
Geração PWM / GPIO
  ↓
Atuador
  ↓
Feedback
  ↓
RP2040
  ↓
Estado normalizado
```

O objetivo é que o computador de voo receba informação já tratada, em vez de ter de lidar diretamente com sinais elétricos específicos de cada sensor ou atuador.

---

# 4. RP2350

## 4.1 Função

O RP2350 será utilizado quando uma função necessitar de:

* maior capacidade computacional;
* FPU;
* instruções DSP;
* maior quantidade de SRAM;
* maior número de interfaces;
* maior quantidade de PIO;
* segurança baseada em TrustZone;
* processamento paralelo;
* supervisão de outros dispositivos;
* execução de tarefas mais complexas em tempo real.

---

## 4.2 Características

O RP2350 disponibiliza:

* 2 núcleos ARM Cortex-M33 a até 150 MHz;

ou, alternativamente:

* 2 núcleos Hazard3 RISC-V;

além de:

* 520 KB de SRAM;
* FPU;
* instruções DSP;
* 16 canais DMA;
* 12 state machines PIO;
* 2 × UART;
* 2 × SPI;
* 2 × I²C;
* 24 canais PWM na variante B;
* ADC;
* USB 1.1;
* TrustZone;
* acelerador SHA-256;
* suporte a memória Flash externa;
* suporte a PSRAM externa.

A arquitetura do RP2350 é compatível com a filosofia de desenvolvimento do RP2040, embora seja substancialmente mais capaz.

---

# 5. Seleção da variante RP2350

Quando for necessária uma PCB personalizada, devem ser avaliadas principalmente:

### RP2350A

* QFN-60;
* 7 × 7 mm;
* 30 GPIO;
* 4 entradas analógicas.

### RP2350B

* QFN-80;
* 10 × 10 mm;
* 48 GPIO;
* 8 entradas analógicas;
* maior quantidade de PWM disponível.

### RP2354A / RP2354B

Variantes com 2 MB de Flash empilhada.

Para os computadores principais, a variante **RP2350B/RP2354B** deverá ser considerada prioritariamente devido ao maior número de GPIO e interfaces disponíveis.

A escolha definitiva dependerá da necessidade de Flash externa, número de GPIO e disponibilidade dos componentes.

---

# 6. Cluster principal de RP2350

## 6.1 Conceito

O computador principal do sistema será constituído por uma PCB contendo potencialmente:

**4 × RP2350**

Cada RP2350 possui dois núcleos.

Portanto:

```text
4 × RP2350
    ↓
4 × 2 cores
    ↓
8 cores computacionais
```

O objetivo não é fazer os quatro chips funcionarem como se fossem fisicamente um único SoC.

O objetivo é criar um:

> **cluster computacional distribuído de 8 núcleos especializados.**

---

# 7. Organização dos oito núcleos

Uma possível distribuição inicial é:

```text
RP2350 #1
├── Core 0 → Controlo de voo
└── Core 1 → Sensor Fusion

RP2350 #2
├── Core 0 → Navegação
└── Core 1 → Cálculo matemático

RP2350 #3
├── Core 0 → Gestão de missão
└── Core 1 → Planeamento / lógica de missão

RP2350 #4
├── Core 0 → Supervisão / Safety
└── Core 1 → Diagnóstico / Health Monitoring
```

Esta distribuição é apenas uma organização inicial.

A divisão definitiva deverá ser determinada após a definição das cargas computacionais.

---

# 8. Especialização dos núcleos

Cada núcleo poderá possuir uma função predominante.

Por exemplo:

```text
MISSION CORE
    │
    │ precisa de cálculo
    ▼
MATH CORE
    │
    │ executa operação
    ▼
RESULT
    │
    ▼
MISSION CORE
```

Outro exemplo:

```text
NAVIGATION CORE
    │
    ├── recebe sensores
    │
    ├── solicita operação matemática
    │
    └── solicita estado da missão
```

A intenção é evitar que cada núcleo implemente novamente todas as capacidades do sistema.

---

# 9. Comunicação entre os RP2350

Os RP2350 deverão ser tratados como nós computacionais independentes.

A comunicação deverá utilizar uma infraestrutura interna de alta velocidade.

Conceito:

```text
                 RP2350 #1
                    │
                    │
            ┌───────┴────────┐
            │                │
            ▼                ▼
       RP2350 #2        RP2350 #3
            │                │
            └───────┬────────┘
                    │
                    ▼
                RP2350 #4
```

A implementação definitiva da interligação deverá ser estudada separadamente.

Possibilidades a avaliar:

* SPI dedicado;
* múltiplos SPI;
* DMA;
* PIO;
* memória compartilhada externa;
* links ponto-a-ponto;
* FPGA/interconnect dedicado;
* combinação de várias técnicas.

O objetivo é obter uma comunicação **determinística e de baixa latência**.

---

# 10. IPC — Inter-Processor Communication

A comunicação interna deverá utilizar mensagens estruturadas.

Exemplo conceptual:

```text
SOURCE
DESTINATION
CORE
MESSAGE_TYPE
REQUEST_ID
TIMESTAMP
PAYLOAD_LENGTH
PAYLOAD
CRC
```

Tipos possíveis:

```text
SENSOR_DATA
ACTUATOR_DATA
MATH_REQUEST
MATH_RESPONSE
NAVIGATION_REQUEST
NAVIGATION_RESPONSE
MISSION_REQUEST
MISSION_RESPONSE
HEALTH_STATUS
SYSTEM_STATUS
TIME_SYNC
FAULT
HEARTBEAT
```

---

# 11. Chamada de funções entre núcleos

Uma operação que dependa de outro núcleo deverá ser tratada como uma operação IPC/RPC.

Exemplo:

```text
Mission Core
     │
     │ MATH_REQUEST
     ▼
Math Core
     │
     │ cálculo
     ▼
Math Core
     │
     │ MATH_RESPONSE
     ▼
Mission Core
```

Isto permite que o software seja organizado de forma modular.

Não se pretende que os oito núcleos sejam transparentes uns aos outros como cores dentro de um único SoC.

Pretende-se que sejam **serviços computacionais cooperantes**.

---

# 12. Supervisor do cluster

Um dos núcleos deverá possuir responsabilidade explícita de supervisão.

Funções possíveis:

* heartbeat dos restantes nós;
* watchdog;
* monitorização de latência;
* monitorização de erros;
* deteção de processador bloqueado;
* gestão de reinicialização;
* sincronização temporal;
* verificação da integridade das mensagens;
* gestão do estado do cluster.

A função de supervisor não deverá ser confundida com o computador de voo.

O supervisor existe para observar e proteger a infraestrutura computacional.

---

# 13. Princípio de isolamento

Nenhum grupo deverá depender desnecessariamente de outro grupo para executar uma função básica de segurança.

Exemplo:

```text
Sensor Group
    ↓
fornece dados

Flight Group
    ↓
controla voo

Mission Group
    ↓
planeia missão
```

Se o Mission Group falhar:

```text
Mission Group
      X
      │
      │
Flight Group
      │
      ▼
continua a controlar o voo
```

A missão pode ser interrompida sem necessariamente perder o controlo da aeronave.

---

# 14. Grupos computacionais do sistema

A arquitetura deverá ser dividida inicialmente nos seguintes grupos:

```text
SYSTEM
│
├── SENSOR GROUP
│
├── ACTUATOR GROUP
│
├── FLIGHT CONTROL GROUP
│
├── NAVIGATION GROUP
│
├── MISSION GROUP
│
├── COMPUTATION GROUP
│
├── SAFETY / SUPERVISOR GROUP
│
├── VISION GROUP
│
└── COMMUNICATION GROUP
```

Nem todos estes grupos necessitam obrigatoriamente de uma PCB própria.

A divisão física deverá ser determinada posteriormente.

---

# 15. Vision Group

O grupo de visão é diferente dos restantes.

Processamento de vídeo exige uma quantidade de largura de banda e memória muito superior à necessária para sensores ou controlo de voo.

Por isso, o processamento de visão não deverá ser baseado exclusivamente em RP2040/RP2350.

---

# 16. SoC de visão selecionado

## NXP i.MX 8M Plus

### Part Number de referência

```text
MIMX8ML4DVNLZAB
```

O `MIMX8ML4DVNLZAB` pertence à família **i.MX 8M Plus** da NXP.

Este SoC é adequado ao grupo de visão devido à combinação de:

* CPU;
* GPU;
* ISP;
* processamento multimédia;
* NPU;
* interfaces de câmera;
* Ethernet;
* CAN-FD;
* interfaces de alta velocidade.

---

# 17. Arquitetura interna do i.MX 8M Plus

O computador de visão será baseado conceptualmente em:

```text
                 i.MX 8M Plus

             ┌─────────────────┐
             │ Cortex-A53 ×4   │
             ├─────────────────┤
             │ Cortex-M7       │
             ├─────────────────┤
             │ GPU             │
             ├─────────────────┤
             │ ISP             │
             ├─────────────────┤
             │ NPU             │
             ├─────────────────┤
             │ Video Engine    │
             └─────────────────┘
```

Esta arquitetura permite separar:

* processamento geral;
* processamento em tempo real;
* processamento gráfico;
* processamento de imagem;
* inferência de IA;
* codificação/descodificação de vídeo.

---

# 18. Processamento da câmera

A arquitetura prevista é:

```text
CAMERA
   │
   │ MIPI CSI
   ▼
i.MX 8M Plus
   │
   ├── ISP
   │
   ├── CPU
   │
   ├── GPU
   │
   ├── NPU
   │
   └── Video Engine
```

A câmera anteriormente selecionada para o projeto deverá ser ligada diretamente ao subsistema de câmera do computador de visão.

---

# 19. 720p60

O sistema deverá manter como objetivo:

```text
Camera
  │
  ▼
720p60
  │
  ├── processamento primário
  │
  └── geração de stream secundário
```

O processamento de vídeo deverá ser realizado no i.MX 8M Plus.

O RP2350 não será responsável pela manipulação principal de todos os pixels do vídeo.

---

# 20. Stream secundário

A arquitetura poderá gerar:

```text
720p60
   │
   ├──────────────► processamento principal
   │
   └── conversão ─► 720p30
                       │
                       ▼
                 Ground Station
```

A redução de frame rate deverá reduzir a quantidade de dados necessária para o canal destinado à estação terrestre.

---

# 21. NPU

O i.MX 8M Plus possui uma NPU destinada a aceleração de inferência de redes neurais.

Isto abre a possibilidade de futuras funções como:

* deteção de objetos;
* classificação;
* segmentação;
* reconhecimento de padrões;
* identificação de obstáculos;
* análise agrícola;
* processamento de imagens para agricultura de precisão.

Estas funções deverão ser consideradas funcionalidades futuras, não requisitos obrigatórios da primeira versão.

---

# 22. GPU

A GPU do i.MX 8M Plus poderá ser utilizada para tarefas gráficas e computação compatível com as APIs suportadas pelo SoC.

Isto elimina a necessidade de instalar uma placa gráfica dedicada convencional.

A GPU está integrada no próprio SoC.

---

# 23. RP2350 no Vision Group

Apesar de o i.MX 8M Plus executar o processamento pesado, poderá existir um RP2350 dedicado à supervisão.

Arquitetura:

```text
                    CAMERA
                       │
                       ▼
               ┌───────────────┐
               │ i.MX 8M Plus  │
               │               │
               │ ISP           │
               │ GPU           │
               │ NPU           │
               │ Video         │
               │ Cortex-A53    │
               └───────┬───────┘
                       │
                       │
               ┌───────▼───────┐
               │    RP2350     │
               │               │
               │ Supervisor    │
               │ Watchdog      │
               │ Health        │
               │ Power control │
               │ Communication │
               └───────┬───────┘
                       │
                       ▼
                 SYSTEM BUS
```

---

# 24. Responsabilidades do RP2350 de visão

O RP2350 poderá tratar:

* watchdog do SoC;
* monitorização do estado do SoC;
* monitorização de temperatura;
* estado da câmera;
* estado do armazenamento;
* configuração;
* gestão de energia;
* inicialização;
* recuperação de falhas;
* comunicação com o restante sistema;
* telemetria;
* health monitoring.

O RP2350 não deverá ser utilizado como substituto do ISP/GPU/NPU do i.MX 8M Plus.

---

# 25. Alimentação

A aeronave disponibilizará externamente apenas:

```text
3.3 V
5 V
12 V
```

Estas serão as tensões de entrada disponíveis para as PCBs.

Não é necessário que todos os componentes utilizem diretamente uma destas três tensões.

---

# 26. Rails internas

Componentes complexos, particularmente o i.MX 8M Plus, necessitam de múltiplas tensões internas.

Portanto:

```text
ENTRADAS DA PCB

12 V
 │
 ├──────────────────────► cargas de 12 V
 │
 └──► reguladores

5 V
 │
 ├──────────────────────► periféricos
 │
 └──► reguladores

3.3 V
 │
 ├──────────────────────► I/O
 │
 └──► reguladores
```

Os reguladores/PMICs poderão gerar internamente as tensões necessárias.

---

# 27. Alimentação do i.MX 8M Plus

A PCB do computador de visão deverá possuir uma arquitetura de alimentação dedicada.

Conceito:

```text
12 V / 5 V / 3.3 V
        │
        ▼
Power Management
        │
        ├──► rails do i.MX 8M Plus
        ├──► LPDDR
        ├──► eMMC / armazenamento
        ├──► MIPI / periféricos
        └──► RP2350
```

O dimensionamento final do PMIC, reguladores, indutores, capacitores e sequenciamento deverá ser realizado diretamente a partir da documentação oficial da NXP.

---

# 28. Arquitetura física da Vision PCB

Uma solução modular preferencial é:

```text
┌────────────────────────────────────────────┐
│              VISION CARRIER PCB            │
│                                            │
│ Camera FFC                                 │
│     │                                      │
│     ▼                                      │
│ MIPI CSI                                   │
│     │                                      │
│     ▼                                      │
│ Vision Compute Module                      │
│                                            │
│ i.MX 8M Plus                               │
│ LPDDR                                      │
│ Storage                                    │
│ PMIC                                      │
│                                            │
│ RP2350 Supervisor                          │
│                                            │
│ Ethernet                                   │
│ CAN                                        │
│ Power                                      │
│ System Connector                           │
└────────────────────────────────────────────┘
```

Uma alternativa é colocar o i.MX 8M Plus diretamente na PCB.

A opção modular deverá ser considerada para reduzir a complexidade da primeira revisão da PCB.

---

# 29. Interligação dos grupos

O sistema deverá possuir um barramento de comunicação entre os grupos.

Conceito:

```text
                 SYSTEM BUS
                     │
        ┌────────────┼────────────┐
        │            │            │
        ▼            ▼            ▼
     SENSOR       FLIGHT       MISSION
     GROUP        GROUP        GROUP
        │            │            │
        └────────────┼────────────┘
                     │
                     ▼
                   VISION
                   GROUP
```

A tecnologia do barramento deverá ser definida posteriormente com base em:

* largura de banda;
* latência;
* determinismo;
* distância;
* quantidade de nós;
* redundância;
* integridade;
* requisitos de segurança.

---

# 30. Separação entre comunicação interna e comunicação externa

Deverão existir dois conceitos distintos:

### Comunicação interna

Comunicação entre:

* RP2040;
* RP2350;
* cluster de voo;
* Vision Group;
* outros grupos computacionais.

### Comunicação externa

Comunicação com:

* estação terrestre;
* telemetria;
* comando;
* manutenção;
* diagnóstico externo.

Não deverão ser tratados como o mesmo problema.

---

# 31. Hierarquia conceptual

A arquitetura global poderá ser representada como:

```text
                         SYSTEM
                            │
                 ┌──────────┴──────────┐
                 │                     │
                 ▼                     ▼
          COMPUTATIONAL           COMMUNICATION
             SYSTEM                  SYSTEM
                 │
       ┌─────────┼─────────┐
       │         │         │
       ▼         ▼         ▼
    SENSOR     FLIGHT    MISSION
    GROUP      GROUP     GROUP
       │         │         │
       │         ▼         │
       │    RP2350 ×4      │
       │    8 cores        │
       │         │         │
       └─────────┼─────────┘
                 │
                 ▼
             VISION GROUP
                 │
                 ▼
            i.MX 8M Plus
                 │
          ┌──────┼──────┐
          ▼      ▼      ▼
         ISP     GPU    NPU
```

---

# 32. Filosofia de redundância

A existência de vários processadores deverá ser utilizada também para aumentar a tolerância a falhas.

O objetivo não é simplesmente possuir mais capacidade de processamento.

Deverá ser possível identificar:

* processador indisponível;
* núcleo bloqueado;
* comunicação perdida;
* mensagens inválidas;
* latência excessiva;
* watchdog expirado;
* dados incoerentes;
* falha de periférico.

---

# 33. Falha de um RP2350

Exemplo:

```text
RP2350 #1 ─ OK
RP2350 #2 ─ OK
RP2350 #3 ─ FAULT
RP2350 #4 ─ OK
```

O sistema deverá conseguir:

1. detetar a falha;
2. identificar o nó afetado;
3. determinar quais serviços foram perdidos;
4. entrar num estado previamente definido;
5. manter as funções críticas que ainda sejam possíveis;
6. registar o evento;
7. informar os restantes grupos.

A possibilidade de recuperação automática deverá ser determinada para cada classe de falha.

---

# 34. Princípio fundamental de segurança

A computação de missão não deverá possuir autoridade irrestrita sobre o controlo físico da aeronave.

A arquitetura deverá manter separação entre:

```text
MISSION
   │
   │ solicita
   ▼
FLIGHT CONTROL
   │
   │ valida
   ▼
ACTUATOR
```

e não:

```text
MISSION
   │
   ▼
ACTUATOR
```

sem validação.

---

# 35. Distribuição preliminar dos processadores

| Grupo             | Processador preliminar | Responsabilidade                  |
| ----------------- | ---------------------- | --------------------------------- |
| Sensor simples    | RP2040                 | Aquisição e normalização          |
| Sensor complexo   | RP2350                 | Aquisição + processamento         |
| Atuadores         | RP2040/RP2350          | Controlo e feedback               |
| Flight Control    | RP2350                 | Controlo de voo                   |
| Sensor Fusion     | RP2350                 | Combinação de dados               |
| Navigation        | RP2350                 | Navegação                         |
| Math              | RP2350                 | Cálculo especializado             |
| Mission           | RP2350                 | Gestão da missão                  |
| Safety            | RP2350                 | Supervisão                        |
| Vision            | i.MX 8M Plus           | Vídeo/visão/IA                    |
| Vision Supervisor | RP2350                 | Supervisão do computador de visão |
| Comunicação       | RP2040/RP2350          | Interfaces específicas            |

---

# 36. Família de PCBs

A arquitetura deverá evoluir para uma família de PCBs padronizadas.

Exemplo:

```text
COMPUTE-SENSOR
└── RP2040

COMPUTE-ACTUATOR
└── RP2040/RP2350

COMPUTE-NODE
└── RP2350

COMPUTE-FLIGHT
└── 4 × RP2350

COMPUTE-VISION
└── i.MX 8M Plus
└── RP2350 Supervisor

COMPUTE-COMM
└── RP2040/RP2350
```

Cada PCB deverá possuir:

* identificação própria;
* versão de hardware;
* firmware próprio;
* interfaces documentadas;
* alimentação documentada;
* watchdog;
* diagnóstico;
* conector(es) normalizados.

---

# 37. Objetivo da arquitetura

O objetivo final é construir um sistema onde:

```text
RP2040
    ↓
I/O distribuído

RP2350
    ↓
Computação determinística distribuída

4 × RP2350
    ↓
Cluster computacional de 8 núcleos

i.MX 8M Plus
    ↓
Computação multimédia / visão / IA

Todos
    ↓
Sistema computacional distribuído
```

---

# 38. O que NÃO fazer

A arquitetura deverá evitar:

* colocar todas as responsabilidades num único MCU;
* utilizar RP2350 apenas porque existe espaço disponível;
* utilizar vários RP2350 sem uma função definida;
* tratar os quatro RP2350 como se fossem fisicamente um único SoC;
* enviar processamento pesado de vídeo para os RP2040/RP2350;
* misturar diretamente lógica de missão com acionamento físico;
* criar dependências desnecessárias entre grupos;
* utilizar o barramento externo como substituto da comunicação interna;
* assumir que 3.3 V, 5 V ou 12 V são suficientes para alimentar diretamente todos os componentes;
* desenhar a PCB do i.MX 8M Plus sem seguir os requisitos de layout da NXP.

---

# 39. Estado atual das decisões

## Confirmado conceptualmente

### RP2040

Utilização:

* sensores;
* atuadores;
* I/O;
* normalização;
* tarefas simples e determinísticas.

### RP2350

Utilização:

* masters de grupos;
* processamento complexo em tempo real;
* supervisão;
* cálculo;
* navegação;
* controlo;
* cluster computacional principal.

### 4 × RP2350

Utilização:

* computador principal;
* 8 núcleos;
* funções especializadas;
* comunicação entre processadores;
* processamento distribuído.

### MIMX8ML4DVNLZAB

Utilização:

* computador de visão;
* processamento de imagem;
* vídeo;
* GPU;
* ISP;
* NPU;
* processamento geral de visão.

### RP2350 adicional no Vision Group

Utilização:

* supervisor;
* watchdog;
* health monitoring;
* controlo;
* comunicação;
* recuperação.

### Alimentação

Entradas disponíveis:

```text
3.3 V
5 V
12 V
```

Rails adicionais poderão ser produzidas internamente pelas PCBs através de reguladores/PMICs.

---

# 40. Pontos ainda por definir

Os seguintes elementos não devem ser considerados fechados nesta fase:

## Cluster RP2350

* topologia física de comunicação;
* protocolo IPC;
* largura de banda;
* latência máxima;
* sincronização temporal;
* partilha de memória;
* recuperação de falhas;
* distribuição final dos oito núcleos;
* escolha RP2350 vs RP2354;
* quantidade de Flash;
* quantidade de PSRAM;
* mecanismo de boot;
* atualização de firmware.

## Vision Group

* memória LPDDR;
* armazenamento;
* PMIC;
* reguladores;
* conector MIPI;
* largura das pistas;
* impedância;
* layout DDR;
* layout MIPI;
* sistema operativo;
* pipeline de vídeo;
* codec;
* formato de transporte;
* processamento de IA;
* mecanismo de comunicação com o RP2350;
* mecanismo de comunicação com o sistema principal.

## Sistema global

* barramento principal;
* protocolo;
* redundância física;
* redundância de alimentação;
* sincronização;
* watchdogs;
* estados de emergência;
* política de falhas;
* gestão térmica;
* EMC/EMI;
* requisitos de certificação;
* estratégia de testes.

---

# 41. Próxima fase recomendada

Antes de iniciar o desenho definitivo das PCBs, a arquitetura deverá ser transformada em três documentos técnicos separados:

```text
01 — Arquitetura Computacional
02 — Arquitetura de Comunicação
03 — Arquitetura de Hardware
```

A seguir deverá ser definida uma matriz:

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

Só depois dessa matriz estar fechada deverá ser iniciado o desenho das PCBs.

---

# 42. Resumo da arquitetura

```text
                         UAV COMPUTING SYSTEM
                                  │
          ┌───────────────────────┼────────────────────────┐
          │                       │                        │
          ▼                       ▼                        ▼
    SENSOR/IO                  FLIGHT                   MISSION
       GROUP                    GROUP                    GROUP
          │                       │                        │
          ▼                       ▼                        ▼
      RP2040                 RP2350 ×4                  RP2350
                              │
                    ┌─────────┼─────────┐
                    │         │         │
                    ▼         ▼         ▼
                  RP2350   RP2350    RP2350
                    │         │         │
                    └─────────┼─────────┘
                              │
                       8 COMPUTATIONAL
                            CORES
                              │
                              ▼
                         SYSTEM BUS
                              │
                              ▼
                       VISION GROUP
                              │
                              ▼
                    MIMX8ML4DVNLZAB
                         i.MX 8M Plus
                              │
             ┌────────────────┼────────────────┐
             │                │                │
             ▼                ▼                ▼
            ISP              GPU              NPU
             │                │                │
             └────────────────┼────────────────┘
                              │
                              ▼
                         VIDEO / AI
                              │
                              ▼
                        RP2350 Supervisor
                              │
                              ▼
                         SYSTEM BUS
```

---

# 43. Princípio final

A arquitetura deverá seguir uma regra simples:

> **Não construir um computador grande para fazer tudo. Construir vários computadores pequenos e especializados que, em conjunto, formam o computador do veículo.**

O RP2040 será utilizado onde simplicidade, determinismo e baixo custo forem suficientes.

O RP2350 será utilizado onde forem necessários maior desempenho, DSP/FPU, mais memória e maior capacidade de controlo.

O cluster de quatro RP2350 será utilizado como um **sistema computacional cooperativo de oito núcleos**, com cada núcleo dedicado predominantemente a determinadas classes de trabalho.

O i.MX 8M Plus será utilizado onde a natureza do problema deixa de ser a de um microcontrolador e passa a ser a de um **computador de processamento multimédia/visão**, aproveitando CPU, GPU, ISP, NPU e aceleradores de vídeo.

O resultado pretendido é uma arquitetura modular, distribuída, monitorizável e preparada para redundância, em que cada grupo computacional possui responsabilidades claras e interfaces bem definidas.

