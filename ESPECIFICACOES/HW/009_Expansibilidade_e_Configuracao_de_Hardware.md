# HW-009 — Expansibilidade e Configuração de Hardware

| Campo | Valor |
| --- | --- |
| **Código** | HW-009 |
| **Título** | Expansibilidade e Configuração de Hardware |
| **Versão** | 2.0 |
| **Estado** | Em Desenvolvimento |
| **Autor** | ShegaPT |
| **Classificação** | Especificação de Hardware |
| **Referência** | docs/Esquemas/Arquitetura-Computacional.md |

---

# 1. Objetivo

O presente documento define como a plataforma AERUS-TELLUS se adapta a diferentes aeronaves de asa fixa — dimensões, sensores, atuadores, propulsão, rádios e implementos — sem reescrever o sistema: parametrização pré-compilação, código comum, crescimento horizontal (mais elementos no grupo), vertical (novos grupos) e funcional (novos módulos), com compatibilidade preservada.

Explica o que é configuração (características da aeronave), o que é arquitetura (responsabilidades e autoridade, inegociáveis) e como evoluir PCB, processadores e periféricos sem quebrar interfaces.

---

# 2. Âmbito

Abrange:

* configuração pré-compilação e código paramétrico;
* quantidade e distribuição de elementos por grupo e por PCB da família;
* escolha RP2040 vs. RP2350B/2354B, variante B, Flash/PSRAM e personalidades do COMPUTE-NODE;
* expansão (elementos, grupos, periféricos, rádios, implementos), cluster e GCV modular;
* validação da configuração, compatibilidade e escalabilidade.

Não abrange:

* valores de configuração de uma aeronave concreta (documentos de configuração por modelo);
* protocolo e mensagens (ver COM), sensores/atuadores concretos (ver SEN, ACT, IMP).

---

# 3. Descrição

## 3.1 Configuração antes da compilação, código comum sempre

```text
Características da aeronave
  │
  ▼
Configuração AERUS (sensores, atuadores, elementos, frequências, limites, redes, energia)
  │
  ▼
Validação (coerência, recursos, conflitos, arquitetura preservada)
  │
  ▼
Compilação → AERUS configurado → integração na aeronave
```

A mesma base compila modelos distintos:

```text
              AERUS (código comum)
                      │
         Configuração da aeronave
           ┌──────────┼──────────┐
           ▼          ▼          ▼
        Modelo A   Modelo B   Modelo C
        (mínimo)   (típico)   (redundante)
```

Configuração nunca altera a lógica fundamental: separação de domínios, autoridade do FailSafe, validação Voo→Atuador, isolamento da visão por Router e disciplina das cinco redes.

## 3.2 Grupos variáveis, arquitetura fixa

| Grupo | O que varia por aeronave | O que nunca varia |
| --- | --- | --- |
| Sensorial | Nº de COMPUTE-SENSORIAL (RP2040), distribuição por baías, Master dedicado ou acumulado | Aquisição→normalização→publicação com qualidade em R1 |
| Atuador | Nº de COMPUTE-ACTUATOR, versão RP2040 ou RP2350B por atuador | Validação e limites locais; retorno; estado seguro |
| Voo/Navegação/Missão/Cálculo | Carga e período por núcleo do cluster; Missão com mais ou menos planeamento | Distribuição inicial dos 8 núcleos; serviço de Cálculo por IPC |
| FailSafe | Nº de nós COMPUTE-NODE, sensores de reserva, diversidade | Autoridade máxima; avaliação independente; inibição |
| Visão (GCV) | Câmara, codecs, presença de NPU futura, antena 5,8 GHz | Módulo i.MX + Router + carrier; nada de píxeis em R1 |
| Comunicação | 2 ou 3 COMM-RF (5,8 GHz ± 2,4 GHz ± 868 MHz), potências, antenas | RJ45-RS como única fronteira; gestão por GCV/Master Geral |

Exemplo:

```text
Aeronave A (pequena): Sensorial 1 nó; Atuador 1; Cluster 1; GCV 1; COMM 5,8+2,4 GHz
Aeronave B (grande):  Sensorial 5 nós + Master; Atuador 3; Cluster 1;
                      FailSafe distribuído; GCV 1; COMM 5,8+2,4+868 MHz
```

## 3.3 Critérios de escolha de processador e PCB

| Decisão | Critério | Resultado típico |
| --- | --- | --- |
| Nó sensorial/atuador simples | ≤30 GPIO, 4 ADC, 16 PWM, 8 PIO e folga de CPU/memória | COMPUTE-SENSORIAL / COMPUTE-ACTUATOR em RP2040 |
| Nó exigente ou Master | FPU/DSP intensivo, >30 GPIO, 8 ADC, 24 PWM, 12 PIO, TrustZone, agregação | COMPUTE-NODE / COMPUTE-ACTUATOR em RP2350B/2354B |
| Flash empilhada | Restrição de área, arranque robusto, disponibilidade | RP2354B (2 MB) face a RP2350B + Flash externa |
| Cluster | Sempre que exista Voo+Navegação+Missão+Cálculo+Supervisão | COMPUTE-FLIGHT-CLUSTER 4 × RP2350B/2354B + Fabric + Flash/PSRAM |
| Visão | Sempre que exista câmara e vídeo | COMPUTE-VISION-CARRIER modular (módulo i.MX+LPDDR+eMMC+PMIC+MIPI + Router + Ethernet/CAN/Power/System-Connector) |
| Rádios | Por missão e alcance | COMM-RF 5,8 GHz (GCV via RJ45) + 2,4 GHz/868 MHz (Master Geral via RJ45) |

O COMPUTE-NODE é genérico: a personalidade (Master Sensorial, Comunicação, FailSafe, Navegação remota) é firmware + configuração, com certificação separada por personalidade quando exigível.

| Processador | Resumo para decisão |
| --- | --- |
| RP2040 | 2 × M0+ 133 MHz, 264 KB, 30 GPIO, 4 ADC, 16 PWM, 8 PIO — periferia determinística económica |
| RP2350B/2354B | 2 × M33 150 MHz, FPU/DSP, 520 KB, 48 GPIO, 8 ADC, 24 PWM, 12 PIO, TrustZone, SHA-256 — nó principal e cluster |
| i.MX 8M Plus MIMX8ML4DVNLZAB | 4 × A53 + M7 + GPU + ISP + NPU + VPU, MIPI CSI ×2, GbE ×2, CAN-FD ×2 — visão e IA embarcada |

## 3.4 Expansão sem rotura

* **Horizontal:** mais nós no grupo (ex.: SENSORIAL_05) sem alterar interfaces externas do grupo.
* **Vertical:** novo grupo apenas com responsabilidade, autoridade, interfaces, dependências, tempos e segurança declarados.
* **Funcional/física:** novos sensores, atuadores, COMM-RF, implementos e modos, com validação de impacto.

A complexidade interna do grupo permanece isolada: os restantes grupos continuam a falar com ele pelas mesmas mensagens R1/R2.

## 3.5 Configuração por domínio (checklist mínima)

Sensores (tipo, interface, nó responsável, frequências de aquisição/comunicação, calibração, redundância); atuadores (tipo, nó, limites, PWM, retorno, estado seguro); aerodinâmica e propulsão (massa, centragem, superfícies, motor/ESC, limites); redundância (fontes, nós, reservas FailSafe); comunicação (R1/R2/R3/R4/R5, períodos, prioridades); energia (derivações, proteções, cortes); módulos (ativos por modo para otimizar CPU/energia). Implementos como sistemas externos: o veículo configura apenas as interfaces e os dados mínimos de voo (massa, caudal, carga, estado).

## 3.6 Validação, compatibilidade e escalabilidade

Configuração inválida (sensor em falta, recurso em conflito, frequência incompatível, arquitetura violada) nunca produz compilação válida. Evolução de PCB/processador que preserve responsabilidade e interfaces é alteração de implementação; introduzir ou remover responsabilidades é alteração arquitetural com revisão das especificações. Interfaces estáveis, abstração de hardware, parametrização e versões controladas preservam compatibilidade ao longo do crescimento.

---

# 4. Exemplos

## Exemplo 1 — Crescer por sensores

```text
Nova sonda de ângulo de ataque → +1 COMPUTE-SENSORIAL_05 na asa
  → configuração declara nó, interface SPI, 100 Hz, calibração
  → R1 passa a incluir nova grandeza; Voo/Navegação consomem sem alterar código
```

## Exemplo 2 — Trocar atuação simples por exigente

```text
Flaps com sincronismo e diagnóstico → COMPUTE-ACTUATOR passa de RP2040 a RP2350B
  → mesma interface R1 (comando/estado); apenas a configuração e o firmware mudam
```

## Exemplo 3 — Adicionar 868 MHz a frota existente

```text
+1 COMM-RF 868 MHz via RJ45 ao Master Geral + antena na cauda
  → configuração declara banda, períodos e prioridades R5
  → R1/R2/R3/R4 inalterados; autonomia revista em ENE
```

---

# 5. Interfaces

| Interface de configuração | Conteúdo | Consumidor |
| --- | --- | --- |
| Mapa grupo↔elemento↔periférico | Que nó serve que sensor/atuador/rádio/câmara | Compilação, integração, manutenção |
| Orçamento de recursos | GPIO/ADC/PWM/PIO, memória, CPU, barramento e energia por nó | Validação pré-compilação |
| Períodos e prioridades R1/R2/R5 | Frequências, timeouts, descarte, anti-sobrecarga | COM + SYS |
| Energia e proteções | Derivações, fusíveis/eFuses, cortes, sequência NXP | HW-005 |
| Versões de PCB/firmware | COMPUTE-* e COMM-RF com revisões e personalidades | Rastreabilidade e ensaio |

---

# 6. Pontos em aberto

| # | Ponto em aberto | Resolução |
| --- | --- | --- |
| 1 | Formato do ficheiro de configuração por aeronave e ferramenta de validação | Projeto de ferramental |
| 2 | Matriz função→grupo→processador→núcleo→interface→protocolo→período→latência→prioridade→falha | SYS + COM + ensaio de carga |
| 3 | Escolha RP2350B vs. RP2354B por nó, Flash/PSRAM e mecanismo de arranque/atualização | Disponibilidade + ensaio |
| 4 | GCV: LPDDR/eMMC/PMIC finais, SO, pipeline, codecs e formato das deteções | NXP + COMM-RF 5,8 GHz |
| 5 | Critérios de introdução de novos grupos e de novas personalidades do COMPUTE-NODE | Arquitetura + SEC |
| 6 | Estratégia de ensaio por configuração (cobertura sem explosão combinatória) | Qualidade + certificação |

---

# 7. Referências

* HW-001 — Arquitetura de Hardware
* HW-002 — Grupos Computacionais
* HW-003 — Distribuição de Hardware
* HW-004 — Interfaces Elétricas
* HW-005 — Alimentação e Distribuição de Energia
* HW-006 — Interfaces de Comunicação
* HW-007 — Interfaces de Periféricos
* HW-008 — Redundância e Isolamento de Hardware
* docs/Esquemas/Arquitetura-Computacional.md
