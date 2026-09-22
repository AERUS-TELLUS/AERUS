# HW-008 — Redundância e Isolamento de Hardware

| Campo | Valor |
| --- | --- |
| **Código** | HW-008 |
| **Título** | Redundância e Isolamento de Hardware |
| **Versão** | 2.0 |
| **Estado** | Em Desenvolvimento |
| **Autor** | ShegaPT |
| **Classificação** | Especificação de Hardware |
| **Referência** | docs/Esquemas/Arquitetura-Computacional.md |

---

# 1. Objetivo

O presente documento define os princípios de redundância e isolamento de hardware do sistema AERUS-TELLUS: onde duplicar com proveito (sensores, nós, vias de atuação, supervisão), onde não duplicar (comando simultâneo do mesmo atuador, píxeis, tudo-por-defeito) e como isolar domínios (energia, comunicação, processamento, atuação, sensores, térmica e EMC) para que uma falha localizada não se propague a todo o veículo.

Explica como o cluster de 4 × RP2350 degrada com graça, como o Grupo FailSafe/Supervisão mantém autoridade independente e como a arquitetura distingue continuar a missão, degradar, abortar e executar emergência.

---

# 2. Âmbito

Abrange:

* redundância de sensores, computacional, de atuação, de energia e de comunicação;
* degradação do Master Geral (perda de um RP2350/núcleo) e do GCV;
* independência e autoridade do FailSafe, sensores de reserva e via de emergência;
* isolamento elétrico, físico, térmico e eletromagnético; falhas comuns; massa e complexidade.

Não abrange:

* algoritmos de fusão/votação (ver MAT, SEN) nem procedimentos de emergência (ver SEC);
* dimensionamento elétrico e proteções por derivação (ver HW-004, HW-005);
* protocolo e tempos (ver HW-006, COM, SYS).

---

# 3. Descrição

## 3.1 Princípio: redundância suficiente, nunca indiscriminada

> Redundância suficiente para manter ou recuperar uma função crítica, sem duplicar tudo nem criar novos pontos únicos de falha.

Antes de duplicar, avaliar: que risco se reduz, que falha se cobre, que independência real se obtém (não é redundância útil duplicar o que partilha sensor, energia, ligação, configuração ou ambiente de falha), que massa, consumo, volume, cablagem e manutenção se pagam e se existe recuperação mais simples por outro domínio (tipicamente o FailSafe).

## 3.2 Redundância de sensores

Sensores cuja falha induza decisão errada ou emergência desnecessária são candidatos a redundância:

```text
Grandeza ─┬──► Sensor A ──► COMPUTE-SENSORIAL_01 (RP2040) ──┐
          └──► Sensor B ──► COMPUTE-SENSORIAL_02 (RP2040) ──┼──► R1 ─► comparação
```

Independência a procurar, conforme criticidade: posições distintas, nós distintos, interfaces distintas, fabricantes/tecnologias distintos, derivações de energia distintas. A comparação (divergência, degradação, validação cruzada, continuidade com fontes restantes) é consumida por SEN/MAT/SEC; aqui garante-se apenas que as fontes chegam independentes e datadas.

## 3.3 Redundância computacional e degradação do cluster

Não se duplica integralmente o sistema. Duplica-se seletivamente: N nós sensoriais, Master Sensorial quando o volume o exigir, nós FailSafe distribuídos, núcleos com funções sobrepostas no cluster.

Falha de um RP2350 do Master Geral:

```text
RP2350 #1 ─ OK     RP2350 #2 ─ OK
RP2350 #3 ─ FALHA  RP2350 #4 ─ OK (supervisor)
  → supervisor deteta por heartbeat/timeout/CPU presa/latência/CRC
  → identifica serviços perdidos → entra em estado predefinido
  → mantém funções críticas possíveis → regista → informa R1/R5
  → redistribui o essencial (ex.: Missão suspende; Voo+Navegação+Cálculo preservados)
```

A possibilidade de retomar o nó (reinicialização seletiva) é decidida por classe de falha; nunca à custa de perturbar o voo. Falha do GCV (i.MX ou Router): o Router isola o SoC (corte e reinicialização), publica indisponibilidade em R1 e o veículo prossegue sem visão — a visão nunca é crítica para manter o voo.

Não se adota, como regra, comando simultâneo do mesmo atuador por dois COMPUTE-ACTUATOR: gera conflito e complexidade. Cada atuador tem um responsável normal; a reserva é a via de emergência do FailSafe:

```text
Normal:     Missão ─pede─► Voo ─valida─► ACTUATOR ─► atuador (+feedback)
Emergência: FailSafe ─inibe normal─► via mínima ─► atuador crítico
```

Falha do atuador em si não se mascara com eletrónica: deteta-se por retorno e decide-se (outro atuador, reconfiguração, cancelamento, aterragem) conforme consequência — sem automatismo cego para regresso.

## 3.4 FailSafe, sensores de reserva e autoridade

O Grupo FailSafe/Supervisão (núcleo supervisor no cluster + nós COMPUTE-NODE com GPS/IMU/barómetro/temperatura de reserva, de fabricantes quando possível distintos) é a camada independente de proteção. Em operação normal, as reservas alimentam avaliação e baliza e permanecem fora do lacete primário; se os principais falharem ou divergirem, suportam o mínimo para emergência (incluindo regresso quando os dados o permitirem, sem garantia universal).

Autoridade:

```text
FailSafe avalia por si (sensores + feedback + estados + R1/R5)
  ├── aceita pedido da Missão/Voo → executa procedimento
  └── recusa → mantém operação e regista
```

O domínio normal pode pedir emergência; nunca a impõe. O FailSafe pode inibir o Atuador normal; o normal nunca inibe o FailSafe.

## 3.5 Isolamento entre domínios

| Eixo | Medidas |
| --- | --- |
| Energia | Derivações independentes e protegidas por domínio; FailSafe em derivação própria; potência separada da digital (HW-005) |
| Comunicação | R1 partilhado mas com prioridades e deteção; R2 confinado ao cluster; R3 confinado ao GCV; R4/R5 sem acesso direto a R1/R2; via de emergência independente do caminho normal |
| Processamento | Núcleos com funções predominantes; TrustZone no RP2350B; SoC de visão isolado pelo Router; nenhum grupo acede a memória alheia sem IPC |
| Atuação/sensores | Responsável único por atuador; reservas independentes; condicionamento junto ao nó |
| Física/térmica/EMC | Posições separadas (baía vs. cauda), blindagem, filtragem, dissipação e monitorização; sem ponto único previsível que derrube normal + segurança |

Falhas comuns a caçar ativamente: mesmos sensores/energia/comunicação para principal e reserva; mesma configuração errada replicada; mesmo ambiente (calor, água, vibração) a atingir redundâncias gémeas. O que não for eliminável, declara-se e trata-se na análise de segurança.

## 3.6 Degradação controlada e localização de falhas

Perder uma fonte não é sinónimo de emergência: com fontes restantes coerentes, degrada-se (suspende-se missão, reduz-se envelope, adia-se TX) e prossegue-se. Cada falha localiza-se (componente, função, dependentes, reservas, continuidade, procedimento) e regista-se com tempo e contexto para manutenção.

Toda a redundância paga-se em massa, consumo, volume, cablagem e manutenção — por isso varia por aeronave (HW-009) e nunca se aplica por rotina.

---

# 4. Exemplos

## Exemplo 1 — Divergência de IMU

```text
IMU principal vs. IMU de reserva divergem além do limiar
  → FailSafe publica FAULT prioritário, Voo usa fonte sã, Missão suspende
  → aterragem preventiva se a divergência persistir; registo para troca do sensor
```

## Exemplo 2 — Perda de um RP2350 em voo

```text
RP2350 #3 (Missão) bloqueia → supervisor isola, reinicia seletivamente
  → Voo+Navegação+Cálculo intactos; Missão em espera; veículo orbita seguro
  → se o reinício falhar, regresso ou aterragem conforme energia e sensores
```

## Exemplo 3 — Curto + calor na baía central

```text
Curto numa derivação normal → eFuse corta; sobreaquecimento do GCV → Router corta SoC
  → FailSafe na cauda (energia e sensores próprios) avalia e assume mínimo
  → R5 anuncia; R1 regista; missão abortada sem perda de controlo
```

---

# 5. Interfaces

| Interface | Papel na redundância/isolamento |
| --- | --- |
| R1 CAN-Principal | Heartbeats, FAULT, HEALTH_STATUS, inibições, sincronismo |
| R2 Fabric | Deteção intra-cluster, redistribuição, reinício seletivo |
| Via de emergência FailSafe→atuação | Inibição do normal + comando mínimo (por atuador, ver ACT) |
| Derivações de energia independentes | Sobrevivência do FailSafe a falhas do normal (HW-005) |
| RJ45-RS R4/R5 | Anúncio e diagnóstico sem expor redes internas |
| Sensores principais + reservas | Comparação, votação e continuidade (SEN/MAT/SEC) |

---

# 6. Pontos em aberto

| # | Ponto em aberto | Resolução |
| --- | --- | --- |
| 1 | Grandezas com redundância obrigatória por classe de aeronave e limiares de divergência | SEN + SEC + ensaio |
| 2 | Diversidade de fabricantes por sensor crítico e lista de reservas do FailSafe | SEN + compras |
| 3 | Política de redistribuição e de reinício seletivo por classe de falha do cluster | COM + SEC + ensaio de falha |
| 4 | Atuadores abrangidos pela via de emergência e implementação física por atuador | ACT + projeto |
| 5 | Seletividade das proteções e independência energética demonstrada por ensaio de curto | HW-005 + ensaio |
| 6 | Estratégia térmica/EMC e matriz de falhas comuns por modelo | Projeto + HW-003/HW-005 |

---

# 7. Referências

* HW-001 — Arquitetura de Hardware
* HW-002 — Grupos Computacionais
* HW-003 — Distribuição de Hardware
* HW-004 — Interfaces Elétricas
* HW-005 — Alimentação e Distribuição de Energia
* HW-006 — Interfaces de Comunicação
* HW-007 — Interfaces de Periféricos
* HW-009 — Expansibilidade e Configuração de Hardware
* docs/Esquemas/Arquitetura-Computacional.md
