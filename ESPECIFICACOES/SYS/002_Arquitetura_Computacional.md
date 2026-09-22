# SYS-002 — Arquitetura Computacional

| Campo             | Valor                     |
|-------------------|---------------------------|
| **Código**        | SYS-002                   |
| **Título**        | Arquitetura Computacional |
| **Versão**        | 2.0                       |
| **Estado**        | Em Desenvolvimento        |
| **Autor**         | ShegaPT                   |
| **Classificação** | Especificação de Sistema  |

---

# 1. Objetivo

O presente documento define a arquitetura computacional do sistema **AERUS**. Estabelece-se a organização lógica dos grupos computacionais, as respetivas responsabilidades, os níveis de autoridade, os fluxos de informação e de decisão, bem como os princípios fundamentais de funcionamento.

Este documento constitui a referência principal para todas as especificações de hardware, software, comunicações, segurança, navegação e matemática. Qualquer decisão de conceção deve ser confrontada com o aqui definido.

---

# 2. Âmbito

Aplica-se o presente documento a todos os grupos computacionais do AERUS, aos respetivos mestres de grupo, ao Master Geral, ao Grupo Computacional de Visão e às redes que os interligam.

Abrange-se a definição funcional de cada grupo, a filosofia de processamento por níveis (RP2040 / RP2350 / i.MX 8M Plus), a organização do cluster de 4x RP2350, a hierarquia de autoridade e as regras de isolamento e redundância.

Não se definem neste documento esquemas elétricos, valores de componentes, algoritmos concretos nem formatos binários de mensagens. Tais matérias pertencem às séries HW, SW, COM e MAT.

---

# 3. Descrição Detalhada

## 3.1. Princípios arquitetónicos

A arquitetura computacional baseia-se nos princípios seguintes:

- Distribuição funcional por grupos especializados.
- Separação de responsabilidades com interfaces claramente delimitadas.
- Isolamento entre funções críticas, de modo que a falha de um grupo não impeça a função básica de segurança de outro.
- Modularidade e escalabilidade (um grupo pode ter uma ou várias PCB sem alteração da arquitetura).
- Processamento paralelo e determinístico onde a criticidade o exija.
- Supervisão permanente por núcleo dedicado e por grupo dedicado.
- Segurança por autoridade hierárquica, com supremacia do FailSafe.
- Preparação para certificação através de rastreabilidade.

Filosofia de processamento por níveis:

| Nível | Processador | Papel principal |
|-------|-------------|-----------------|
| I/O e aquisição | **RP2040** (Módulo Menor) | Aquisição, filtragem, normalização, PWM, PIO, pequenas máquinas de estado |
| Processamento embarcado e mestres | **RP2350** (Módulo Maior / Master de Grupo), preferência RP2350B/RP2354B | FPU, DSP, mais SRAM, mais PIO, TrustZone, supervisão, tempo real complexo |
| Visão e multimédia | **NXP i.MX 8M Plus MIMX8ML4DVNLZAB** | ISP, GPU, NPU, motor de vídeo, 720p60 + 720p30 |

O objetivo não consiste na utilização do processador mais potente em todas as funções. Cada tarefa utiliza o processador adequado à sua natureza.

## 3.2. Grupos computacionais normativos

Define-se que o AERUS se organiza nos grupos seguintes. A lista é fechada na presente versão; versões futuras podem aditar grupos, sem alteração retroativa dos existentes.

```text
SYSTEM
│
├── Grupo Computacional Sensorial
├── Grupo Computacional Atuador
├── Grupo Computacional de Controlo de Voo
├── Grupo Computacional de Navegação
├── Grupo Computacional de Missão
├── Grupo Computacional de Cálculo
├── Grupo Computacional FailSafe/Supervisão
├── Grupo Computacional de Visão (GCV)
├── Grupo Computacional de Comunicação
└── Master Geral (Cluster 4x RP2350)
```

Cada grupo representa um domínio funcional, não um equipamento físico específico. Um grupo pode ser constituído por uma ou mais PCB. A divisão física definitiva consta de SYS-004 e HW.

### 3.2.1. Grupo Computacional Sensorial

Responsável pela aquisição e processamento primário da informação dos sensores:

- Aquisição de sinais (analógicos, digitais, SPI, I2C, UART, PIO).
- Sincronização temporal da amostra e aposição de timestamp.
- Conversão de sinais e conversão de unidades.
- Validação primária, filtragem inicial e normalização.
- Cálculos preliminares e distribuição para os consumidores.

Estrutura típica: Módulos Menores RP2040 junto aos sensores + um Master de Grupo RP2350 que agrega, valida e publica na CAN-Principal. A comunicação interna do grupo processa-se na respetiva CAN-Intra-Grupo com mensagens TLV.

O número de unidades depende da quantidade, localização e distribuição dos sensores na aeronave.

### 3.2.2. Grupo Computacional Atuador

Responsável pelo controlo normal dos atuadores (motores, servomecanismos, superfícies, trem, iluminação, dispositivos de missão mecânica).

Recebe comandos de alto nível, independentes da tecnologia de cada atuador, exclusivamente do Grupo Computacional de Controlo de Voo (através do Master Geral). Compete-lhe:

- Validação dos comandos recebidos e verificação de conformidade com o envelope operacional.
- Conversão de comandos lógicos em protocolos físicos (PWM, GPIO, barramentos dedicados).
- Acionamento e monitorização contínua do estado (posição, velocidade, rotação, corrente, tensão, telemetria).
- Publicação de feedback normalizado.

Estrutura típica: Módulos Menores RP2040 junto aos atuadores + Master RP2350. Nunca se gera diretamente, fora deste grupo, o sinal físico de atuador.

### 3.2.3. Grupo Computacional de Controlo de Voo

Responsável pelo controlo e guiamento da aeronave em funcionamento normal. Reside como núcleo especializado no interior do Master Geral (RP2350 #1, Núcleo 0), com apoio da Fusão de Sensores no núcleo gémeo.

Funções: leis de controlo, guiamento, estabilização, gestão do envelope, validação de solicitações provenientes da Missão antes de qualquer envio ao Atuador.

### 3.2.4. Grupo Computacional de Navegação

Responsável pela estimativa de posição, velocidade, atitude e tempo, com fusão de GNSS, inerciais, barometria, magnetometria e referências de visão quando disponíveis. Reside no Master Geral (RP2350 #2, Núcleo 0), com recurso ao Grupo de Cálculo para operações pesadas através de IPC.

### 3.2.5. Grupo Computacional de Missão

Responsável pela gestão e planeamento da missão (fases, waypoints, lógica de missão agrícola, gestão de implementos ao nível de solicitação). Reside no Master Geral (RP2350 #3, Núcleos 0 e 1: gestão e planeamento). Não possui autoridade direta sobre atuadores. Toda a intenção de missão é expressa como solicitação ao Controlo de Voo.

### 3.2.6. Grupo Computacional de Cálculo

Serviço matemático especializado partilhado. Reside no Master Geral (RP2350 #2, Núcleo 1). Serve pedidos MATH_REQUEST de qualquer núcleo através da INTERCONNECT FABRIC e devolve MATH_RESPONSE. Evita-se, desta forma, a duplicação de bibliotecas pesadas em todos os núcleos. Inclui álgebra, geodesia, filtros, otimização e funções de apoio à fusão e à navegação (detalhe em MAT).

### 3.2.7. Grupo Computacional FailSafe/Supervisão

Domínio responsável pela segurança, com a mais elevada autoridade computacional. Possui duas materializações complementares:

- Núcleo de Supervisão/FailSafe no Master Geral (RP2350 #4, Núcleo 0) + Núcleo de Diagnóstico (RP2350 #4, Núcleo 1).
- Lógica de supervisão distribuída com rede dedicada CAN-FailSafe, através da qual pode inibir grupos, ativar controlo de emergência e impor estados de segurança.

Responsabilidades: monitorização contínua de sensores, estados e heartbeats; execução independente de modelos de avaliação de segurança; deteção de anomalias; decisão de entrada em FailSafe/FailSecure; supervisão da integridade global; gestão de reinicialização e sincronização temporal de emergência.

Nenhum outro domínio se sobrepõe a decisões de segurança.

### 3.2.8. Grupo Computacional de Visão (GCV)

Grupo distinto dos restantes, pois o processamento de vídeo exige largura de banda e memória muito superiores às de sensores ou controlo.

Baseia-se no SoC NXP i.MX 8M Plus MIMX8ML4DVNLZAB (4x Cortex-A53 + Cortex-M7 + GPU + ISP + NPU + motor de vídeo), com câmara ligada por MIPI CSI, processamento principal a 720p60 e geração de fluxo secundário a 720p30 para a estação terrestre.

Inclui um Router RP2350 (admite-se RP2040 como alternativa económica) que assegura: watchdog do SoC, monitorização de estado e temperatura, gestão de energia e arranque, recuperação de falhas, telemetria de saúde e ligação à CAN-Principal. A saída de vídeo para RF processa-se por RJ45 privada com protocolo série RS para a placa TX 5.8 GHz. O RP2350 nunca substitui ISP/GPU/NPU.

### 3.2.9. Grupo Computacional de Comunicação

Responsável pelas interfaces de telecomando e telemetria: recetor RF 2.4 GHz e emissor 868 MHz, ligados ao Master Geral por RJ45 privada com protocolo série RS; ligação à CAN-Principal para distribuição de telecomandos validados e recolha de telemetria; gestão de prioridades, filas e integridade (detalhe em COM). Não se trata telecomando como ordem direta a atuador: todo o telecomando é encaminhado como solicitação ao Controlo de Voo.

### 3.2.10. Master Geral (Cluster 4x RP2350)

O computador principal é uma PCB com 4x RP2350 (preferência RP2350B/RP2354B), ou seja, 8 núcleos cooperantes ligados por INTERCONNECT FABRIC dedicada:

```text
RP2350 #1
├── Núcleo 0 → Controlo de Voo
└── Núcleo 1 → Fusão de Sensores

RP2350 #2
├── Núcleo 0 → Navegação
└── Núcleo 1 → Cálculo Matemático

RP2350 #3
├── Núcleo 0 → Gestão de Missão
└── Núcleo 1 → Planeamento / Lógica de Missão

RP2350 #4
├── Núcleo 0 → Supervisão / FailSafe
└── Núcleo 1 → Diagnóstico / Health Monitoring
```

Não se trata o conjunto como se fosse fisicamente um único SoC. Trata-se de serviços computacionais cooperantes, com chamadas entre núcleos sob a forma de IPC/RPC. Exemplo:

```text
Núcleo de Missão ──MATH_REQUEST──► Núcleo de Cálculo
Núcleo de Cálculo ──MATH_RESPONSE─► Núcleo de Missão
```

A distribuição acima é inicial; a divisão definitiva resulta do fecho das cargas computacionais.

## 3.3. Módulos Menores e Maiores

- **Módulo Menor (RP2040)**: 2x Cortex-M0+ até 133 MHz, 264 KB SRAM, 30 GPIO, ADC, 2x UART, 2x SPI, 2x I2C, 16 PWM, USB, 8 máquinas PIO, DMA. Utilização: aquisição, normalização, PWM, I/O determinístico.
- **Módulo Maior (RP2350)**: 2x Cortex-M33 até 150 MHz (ou 2x Hazard3 RISC-V), 520 KB SRAM, FPU, DSP, 16 DMA, 12 PIO, TrustZone, SHA-256, Flash/PSRAM externa. Variantes: RP2350A (QFN-60, 30 GPIO) e RP2350B (QFN-80, 48 GPIO, 24 PWM, 8 analógicas); RP2354A/B com 2 MB Flash empilhada. Para mestres e cluster, prioriza-se RP2350B/RP2354B.

Fluxo típico de sensor e de atuador com Módulo Menor:

```text
Sensor → RP2040 → Aquisição → Filtragem → Calibração
→ Normalização → Validação → Mensagem TLV → CAN-Intra-Grupo

Comando validado → RP2040 → Validação → PWM/GPIO → Atuador
→ Feedback → RP2040 → Estado normalizado → CAN-Intra-Grupo
```

## 3.4. Hierarquia de autoridade

A autoridade representa capacidade de decisão, não prioridade de comunicação.

- **Nível 0 (supremo)**: Grupo Computacional FailSafe/Supervisão.
- **Nível 1**: Master Geral nas funções de Controlo de Voo, Navegação, Missão e Cálculo (com precedência interna do Voo sobre a Missão); Grupo de Visão e Grupo de Comunicação na respetiva esfera técnica.
- **Nível 2**: Grupo Computacional Sensorial e Grupo Computacional Atuador (executam e informam; não decidem missão nem segurança).

Qualquer domínio pode solicitar emergência ao FailSafe; a solicitação não constitui ordem. O FailSafe valida o estado global, confirma ou rejeita, comunica a decisão e regista o evento, com intervalo mínimo de reavaliação para evitar degradação.

## 3.5. Fluxo de decisão

Distingue-se informação (dados), comandos (controlo normal) e decisões (segurança).

- MISSÃO solicita → VOO valida → ATUADOR executa (com verificação de envelope no Atuador).
- Proíbe-se o caminho direto MISSÃO → ATUADOR sem validação.
- Decisões de segurança pertencem exclusivamente ao FailSafe.

## 3.6. Isolamento e redundância

Isolamento: se o Grupo de Missão falhar, o Controlo de Voo mantém o voo seguro; a missão interrompe-se sem perda de controlo.

Redundância: perante falha de 1x RP2350 do cluster (exemplo: RP2350 #3 em falha, restantes OK), o sistema deve: detetar a falha por heartbeat/watchdog/latência, identificar o nó e os serviços perdidos, entrar em estado predefinido, manter funções críticas possíveis, registar o evento e informar os restantes grupos. A recuperação automática depende da classe de falha (ver SEC e SYS-006).

## 3.7. O que não fazer

- Não concentrar todas as responsabilidades num único microcontrolador.
- Não utilizar RP2350 apenas por disponibilidade de espaço, nem multiplicar RP2350 sem função definida.
- Não tratar os quatro RP2350 como um único SoC físico.
- Não enviar vídeo pesado para RP2040/RP2350.
- Não misturar lógica de missão com acionamento físico.
- Não criar dependências desnecessárias entre grupos.
- Não utilizar o barramento externo como substituto da comunicação interna.
- Não pressupor alimentação direta universal a partir de 3.3/5/12 V.
- Não desenhar a PCB do i.MX 8M Plus sem observância dos requisitos de layout da NXP.

---

# 4. Exemplos

## Exemplo 1 — Cadeia de comando correta e incorreta

```text
CORRETO:
MISSÃO (solicita subida) → VOO (valida envelope) → ATUADOR (verifica limites, gera PWM)

INCORRETO (proibido):
MISSÃO ──► ATUADOR (sem validação — nunca permitido)
```

## Exemplo 2 — Pedido matemático entre núcleos

```text
NÚCLEO DE NAVEGAÇÃO          NÚCLEO DE CÁLCULO
       │                              │
       │── MATH_REQUEST (ID=41) ──────►│  (INTERCONNECT FABRIC)
       │                              │  cálculo de matriz
       │◄── MATH_RESPONSE (ID=41) ────│  + CRC OK
       │                              │
```

## Exemplo 3 — Falha de 1x RP2350

```text
RP2350 #1 ─ OK (Voo + Fusão)
RP2350 #2 ─ OK (Navegação + Cálculo)
RP2350 #3 ─ FALHA (Missão + Planeamento)
RP2350 #4 ─ OK (Supervisão + Diagnóstico)

Ação: Supervisão deteta por falta de HEARTBEAT,
declara perda de serviço de Missão,
mantém Voo + Navegação + FailSafe,
informa GCCOM e GCV, regista FAULT.
```

## Exemplo 4 — Tabela função → processador

| Função | Processador | Localização |
|--------|-------------|-------------|
| Aquisição simples | RP2040 | Junto ao sensor/atuador |
| Master de grupo | RP2350B/RP2354B | Cabeça de grupo |
| Controlo/Fusão/Nav/Cálculo/Missão/Supervisão | 4x RP2350 | Master Geral |
| Vídeo/IA | MIMX8ML4DVNLZAB | GCV |
| Supervisão de visão | RP2350 (ou RP2040) | Router do GCV |

---

# 5. Interfaces Com Outros Documentos

| Documento | Relação |
|-----------|---------|
| SYS-001 Visão Geral | Enquadramento conceptual aqui detalhado |
| SYS-003 Software | Projeção lógica desta arquitetura em módulos |
| SYS-004 Hardware | Materialização física (PCBs, variantes, PMIC) |
| SYS-005 Fluxo de Informação | Redes e mensagens que concretizam os fluxos |
| SYS-006 Estados | Propriedade e supervisão de estados por grupo |
| COM | Protocolos TLV, CAN, IPC, prioridades, integridade |
| MAT | Modelos servidos pelo Grupo de Cálculo |
| SEC | Políticas FailSafe/FailSecure e autoridade |
| docs/Esquemas/Arquitetura-Computacional.md | Fonte normativa (capítulos 1–43) |

---

# 6. Estado / Pontos Em Aberto

- **Estado**: Em Desenvolvimento, versão 2.0 com nomenclatura normativa e cluster 4x RP2350 fechados a nível conceptual.
- **Pontos em aberto**:
  - Distribuição definitiva dos 8 núcleos após medição de cargas.
  - Topologia física da INTERCONNECT FABRIC, largura de banda e latência máxima.
  - Quantidades de Flash/PSRAM, escolha RP2350 face a RP2354, boot e atualização.
  - Mecanismo IPC exato e partilha de memória (se existir).
  - Sistema operativo e pipeline do GCV, codec e formato de transporte do 720p30.
  - Matriz completa função → núcleo → interface → protocolo → periodicidade → latência → prioridade → falha.

