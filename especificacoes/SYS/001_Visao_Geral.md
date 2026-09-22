# SYS-001 — Visão Geral do Sistema

| Campo             | Valor                    |
|-------------------|--------------------------|
| **Código**        | SYS-001                  |
| **Título**        | Visão Geral do Sistema   |
| **Versão**        | 2.0                      |
| **Estado**        | Em Desenvolvimento       |
| **Autor**         | ShegaPT                  |
| **Classificação** | Especificação de Sistema |

---

# 1. Objetivo

O presente documento estabelece a visão geral do sistema **AERUS**, ou seja, a definição da finalidade do sistema, da filosofia de desenvolvimento, do domínio de aplicação, dos princípios fundamentais e do enquadramento na arquitetura global do projeto.

Este documento constitui a porta de entrada conceptual de todo o sistema. Através da sua leitura, obtém-se uma compreensão completa do que o AERUS é, do que o AERUS não é, de como se organiza e de onde se encontra cada tema técnico nas restantes especificações.

Não se descrevem neste documento algoritmos concretos, esquemas elétricos, formatos de mensagens nem detalhes de implementação. Tais matérias encontram-se desenvolvidas nas respetivas especificações das séries SYS, HW, SW, COM, MAT, SEC, OPS e restantes.

---

# 2. Âmbito

O AERUS é um sistema autónomo de controlo de voo distribuído, destinado a aeronaves não tripuladas (UAV) de asa fixa.

O sistema foi concebido para proporcionar níveis elevados de precisão, segurança, modularidade e configurabilidade. Através de uma arquitetura distribuída por grupos computacionais especializados, permite-se a adaptação a aeronaves distintas e a domínios de aplicação distintos, sem alteração da arquitetura fundamental.

O domínio principal de aplicação é a agricultura de precisão. A arquitetura foi, contudo, definida de forma genérica, de modo a permitir a adaptação a outros contextos operacionais compatíveis com asa fixa, nomeadamente inspeção técnica, monitorização ambiental, vigilância, proteção civil ou outras missões especializadas.

Aplica-se o presente documento a todas as equipas e atividades que contribuam para o AERUS: conceção de sistema, hardware, software embarcado, comunicações, matemática de voo, segurança, operação e certificação.

---

# 3. Descrição Detalhada

## 3.1. Definição do sistema

Define-se o AERUS como uma plataforma autónoma de voo para aeronaves de asa fixa, responsável pela execução autónoma de todas as funções relacionadas com o voo: aquisição de dados, estimativa do estado, navegação, guiamento, controlo, monitorização e gestão da segurança operacional.

O AERUS não constitui um sistema dedicado a uma missão específica. Constitui antes uma plataforma de voo autónoma capaz de suportar perfis operacionais distintos através de parametrização e através da integração de implementos externos compatíveis.

O AERUS funciona de forma totalmente autónoma e independente da existência de qualquer implemento externo. A instalação de um implemento nunca constitui requisito para o funcionamento normal do sistema.

## 3.2. Filosofia de desenvolvimento

O desenvolvimento do AERUS baseia-se nos princípios seguintes:

- Segurança como prioridade absoluta.
- Arquitetura computacional distribuída, sem computador único responsável por tudo.
- Especialização funcional: cada unidade executa uma responsabilidade bem definida, com interfaces claramente delimitadas.
- Precisão elevada na estimativa do estado da aeronave, com utilização intensiva de modelos matemáticos.
- Modularidade funcional e evolução independente por grupo.
- Configurabilidade elevada por parâmetros, sem criação de versões específicas de código por aeronave.
- Separação estrita entre sistema de voo e sistemas de missão.
- Rastreabilidade e orientação para certificação.

Sempre que exista conflito entre desempenho, funcionalidade e segurança, prevalece a solução que maximize a segurança operacional.

A regra de síntese da arquitetura é a seguinte:

> Não se constrói um computador grande para fazer tudo. Constroem-se vários computadores pequenos e especializados que, em conjunto, formam o computador do veículo.

## 3.3. Organização computacional de alto nível

O sistema organiza-se em **Grupos Computacionais** independentes. Cada grupo possui uma responsabilidade específica e pode ser constituído por uma ou mais placas de circuito impresso (PCB) especializadas.

A nomenclatura normativa, de utilização obrigatória em toda a documentação, código, esquemas e comentários, é a seguinte:

| Designação normativa                          | Abreviatura admitida | Responsabilidade essencial                    |
|-----------------------------------------------|----------------------|-----------------------------------------------|
| Grupo Computacional Sensorial                 | GCSEN                | Aquisição, filtragem, normalização            |
| Grupo Computacional Atuador                   | GCATU                | Validação e acionamento físico                |
| Grupo Computacional de Controlo de Voo        | GCVOO                | Controlo e guiamento de voo                   |
| Grupo Computacional de Navegação              | GCNAV                | Estimativa de posição, atitude e velocidade   |
| Grupo Computacional de Missão                 | GCMIS                | Gestão e planeamento de missão                |
| Grupo Computacional de Cálculo                | GCALC                | Serviço matemático especializado              |
| Grupo Computacional FailSafe/Supervisão       | GCFS                 | Supervisão, segurança, modos de emergência    |
| Grupo Computacional de Visão (GCV)            | GCV                  | Vídeo, visão, aceleração por IA               |
| Grupo Computacional de Comunicação            | GCCOM                | Telemetria, telecomando, ligações RF          |
| Master Geral (Cluster)                        | MG                   | Computador principal: 4x RP2350, 8 núcleos    |

Não se utilizam, em caso algum, as designações antigas baseadas em nomes de plataformas comerciais ou siglas provisórias. A correspondência histórica encontra-se encerrada e não deve ser utilizada em novos documentos.

Do ponto de vista físico, aplicam-se dois tipos de módulo:

- **Módulo Menor**: baseado em RP2040. Destina-se a entrada/saída (I/O), aquisição, normalização, geração de PWM, máquinas de estado determinísticas e protocolos personalizados através de PIO.
- **Módulo Maior / Master de Grupo**: baseado em RP2350, com preferência pela variante RP2350B/RP2354B (maior número de GPIO, PWM e entradas analógicas). Destina-se a mestres de grupo, processamento embarcado complexo, supervisão e tarefas de tempo real com FPU e instruções DSP.

O **Master Geral** é um cluster constituído por 4x RP2350 ligados por uma rede interna dedicada designada por **INTERCONNECT FABRIC**. O conjunto disponibiliza 8 núcleos com especialização inicial:

```text
RP2350 #1 — Núcleo 0: Controlo de Voo | Núcleo 1: Fusão de Sensores
RP2350 #2 — Núcleo 0: Navegação       | Núcleo 1: Cálculo Matemático
RP2350 #3 — Núcleo 0: Gestão de Missão| Núcleo 1: Planeamento
RP2350 #4 — Núcleo 0: Supervisão/FailSafe | Núcleo 1: Diagnóstico
```

O **Grupo Computacional de Visão (GCV)** baseia-se no SoC NXP i.MX 8M Plus, referência MIMX8ML4DVNLZAB (CPU + GPU + ISP + NPU + motor de vídeo), com objetivo de 720p60 para processamento principal e 720p30 para a estação terrestre. Inclui ainda um Router RP2350 (admite-se RP2040 como alternativa de custo reduzido) para ligação à CAN-Principal e uma porta RJ45 privada para a placa de transmissão RF de 5.8 GHz.

## 3.4. Redes de comunicação

O sistema define **cinco redes** distintas, sem sobreposição de funções:

1. **CAN-Intra-Grupo**: existe uma por grupo. Liga os Módulos Menores ao Master do grupo. Utiliza protocolo TLV.
2. **CAN-Principal**: rede inter-masters. Liga entre si os Masters de Grupo, o Master Geral, o Router do GCV e o GCCOM.
3. **CAN-FailSafe dedicada**: rede física e logicamente separada, ao serviço exclusivo do Grupo Computacional FailSafe/Supervisão para ordens de emergência, inibições e estados de segurança.
4. **INTERCONNECT FABRIC intra-cluster**: rede interna dedicada do Master Geral (SPI dedicado / múltiplos SPI / DMA / PIO / memória partilhada, a fechar em HW). Utiliza mensagens IPC estruturadas com os campos SOURCE / DESTINO / NÚCLEO / TIPO / REQ_ID / TIMESTAMP / COMPRIMENTO / PAYLOAD / CRC. Tipos previstos: SENSOR_DATA, MATH_REQUEST, MATH_RESPONSE, NAVIGATION_REQUEST, NAVIGATION_RESPONSE, MISSION_REQUEST, MISSION_RESPONSE, HEALTH_STATUS, SYSTEM_STATUS, TIME_SYNC, FAULT, HEARTBEAT, entre outros.
5. **RJ45-Privada com protocolo série RS** (RS-422/485, a confirmar): ligações ponto-a-ponto sempre que exista equipamento de radiofrequência (RF). Aplica-se em dois casos normativos: GCV ↔ placa TX RF 5.8 GHz (vídeo para a estação terrestre) e Master Geral ↔ placa RX 2.4 GHz / TX 868 MHz (telecomando e telemetria). Nunca se liga RF diretamente a barramentos partilhados.

O detalhe de protocolos, formatos e gestão de filas encontra-se na série COM e é resumido em SYS-005.

## 3.5. Alimentação

A aeronave disponibiliza externamente apenas três tensões:

```text
3.3 V / 5 V / 12 V
```

Todas as tensões internas adicionais (rails do i.MX 8M Plus, LPDDR, memórias, núcleos, MIPI, periféricos) são geradas no interior de cada PCB através de reguladores e PMIC, com sequenciamento conforme a documentação oficial da NXP para o GCV. Não se pressupõe que 3.3 V, 5 V ou 12 V alimentem diretamente todos os componentes.

## 3.6. Princípios de autoridade e isolamento

Aplicam-se três princípios invioláveis:

1. **Cadeia de comando validada**: a MISSÃO solicita, o VOO valida, o ATUADOR executa. Nunca existe comando direto MISSÃO → ATUADOR sem validação pelo Controlo de Voo e sem verificação de envelope pelo Grupo Atuador.
2. **Isolamento**: nenhum grupo depende de outro para a sua função básica de segurança. Se o Grupo de Missão falhar, o Controlo de Voo mantém a aeronave em voo seguro.
3. **Redundância com deteção de falha**: a existência de vários processadores é utilizada para tolerância a falhas, com deteção explícita de falha de 1x RP2350 do cluster (identificação do nó, dos serviços perdidos, entrada em estado predefinido e registo do evento).

## 3.7. Implementos externos

Os implementos representam sistemas independentes, com hardware e software próprios, responsáveis pelas respetivas funções específicas (por exemplo, pulverização). A comunicação entre o AERUS e qualquer implemento ocorre exclusivamente através de interfaces normalizadas. Sempre que um implemento seja instalado, o AERUS identifica automaticamente as capacidades disponibilizadas e as variáveis relevantes para a execução segura da missão. O AERUS nunca assume o controlo interno do implemento. As especificações relativas a implementos encontram-se na série IMP.

## 3.8. Características gerais

O AERUS caracteriza-se por:

- Arquitetura computacional distribuída por grupos especializados.
- Separação entre aquisição, processamento, controlo, missão, visão, comunicação e segurança.
- Redundância funcional e supervisão permanente.
- Configurabilidade elevada e independência face a implementos.
- Preparação para expansão futura (novos sensores, atuadores, grupos, modos).
- Utilização intensiva de modelos matemáticos como serviço (Grupo de Cálculo).
- Suporte para múltiplas configurações de asa fixa por parametrização.

## 3.9. Estrutura das especificações

A documentação técnica encontra-se organizada por domínios:

```text
SYS — Sistema (visão, arquiteturas, fluxos, estados, modos, tempo, arranque)
HW  — Hardware (placas, interfaces, energia, redundância)
SW  — Software (módulos, políticas temporais, gestão de recursos)
COM — Comunicações (barramentos, TLV, gestores, prioridades, integridade)
MAT — Matemática (modelos de voo, fusão, navegação, controlo)
SEC — Segurança (FailSafe, FailSecure, políticas de falha)
OPS — Operação (checklists, procedimentos)
SEN/ACT/NAV/CTL/ENE/IMP/VAL/CER — domínios especializados
```

Cada domínio possui documentação própria, com evolução modular e coerência garantida pelas especificações SYS.

---

# 4. Exemplos

## Exemplo 1 — Leitura de um documento SYS

```text
Pretende-se saber quem valida um comando de missão antes da sua execução física.
Resposta: SYS-002 (Arquitetura Computacional) define a cadeia
MISSÃO → VOO → ATUADOR. SYS-005 (Fluxo Global de Informação)
detalha as mensagens. SEC define as políticas de rejeição.
```

## Exemplo 2 — Correspondência função → grupo → rede

| Função pretendida              | Grupo responsável              | Rede utilizada   |
|--------------------------------|--------------------------------|------------------|
| Leitura de pitot e normalização| Grupo Computacional Sensorial  | CAN-Intra-Grupo  |
| Decisão de leme                | GC de Controlo de Voo (no MG)  | INTERCONNECT FABRIC + CAN-Principal |
| Ordem de emergência            | GC FailSafe/Supervisão         | CAN-FailSafe     |
| Envio de vídeo para o solo     | GCV → TX 5.8 GHz               | RJ45-Privada (RS)|

## Exemplo 3 — Diagrama de alto nível

```text
                    AERUS — VISÃO GLOBAL
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
   GRUPOS DE              MASTER GERAL          GRUPOS DE
   AQUISIÇÃO/AÇÃO          (4x RP2350)         MISSÃO/VISÃO/COM
        │                  8 núcleos                │
        │                     │                     │
        └──────────► CAN-Principal ◄────────────────┘
                              │
                    CAN-FailSafe (dedicada, só segurança)
                              │
                    INTERCONNECT FABRIC (só intra-cluster)
                              │
                    RJ45-Privada RS (só onde há RF)
```

---

# 5. Interfaces Com Outros Documentos

| Documento | Relação com SYS-001 |
|-----------|---------------------|
| SYS-002 Arquitetura Computacional | Detalhamento dos grupos e do cluster aqui resumidos |
| SYS-003 Arquitetura de Software | Organização lógica do software de cada grupo |
| SYS-004 Arquitetura de Hardware | Organização física, processadores e PCBs |
| SYS-005 Fluxo Global de Informação | Detalhamento das 5 redes e dos fluxos |
| SYS-006 Gestão de Estados | Propriedade e sincronização de estados |
| SYS-007 Modos de Funcionamento | Sequência operacional global |
| SYS-008 Gestão Temporal | Referências e sincronização temporal |
| SYS-009 Arranque e Encerramento | Sequência de ativação e desligamento |
| HW, SW, COM, MAT, SEC, OPS | Desenvolvimento técnico de cada domínio |
| docs/Esquemas/Arquitetura-Computacional.md | Referência normativa de arquitetura que fundamenta SYS-001 a SYS-009 |

---

# 6. Estado / Pontos Em Aberto

- **Estado**: Em Desenvolvimento. A presente versão 2.0 reflete a migração normativa completa para RP2040 / RP2350 / i.MX 8M Plus e para as cinco redes.
- **Pontos em aberto**:
  - Fecho da topologia física da INTERCONNECT FABRIC (SPI / PIO / DMA / memória partilhada).
  - Confirmação do padrão série RS sobre RJ45-Privada (RS-422 face a RS-485) e pinagem.
  - Dimensionamento final de Flash/PSRAM por RP2350/RP2354 e mecanismo de boot e atualização.
  - Matriz função → grupo → processador → núcleo → interface → protocolo → periodicidade → latência → prioridade → comportamento em falha (pré-requisito para desenho de PCBs).
  - Estratégia de certificação, gestão térmica, EMC/EMI e ensaios ambientais.

