# CTL-001 — Lógica de Controlo

| Campo             | Valor                     |
| ----------------- | ------------------------- |
| **Código**        | CTL-001                   |
| **Título**        | Lógica de Controlo        |
| **Versão**        | 1.0                       |
| **Estado**        | Em Desenvolvimento        |
| **Autor**         | ShegaPT                   |
| **Classificação** | Especificação de Controlo |

---

# 1. Objetivo

O presente documento define a lógica de controlo do sistema **Aerus**, ou seja, as regras invioláveis que transformam intenções de missão em movimentos físicos da aeronave.

A regra fundamental, sem exceções em voo, é:

```text
MISSÃO solicita → VOO valida → ATUADOR executa
```

Isto significa:

* A **Missão** nunca comanda diretamente um atuador. Apenas pede (solicita) um comportamento: manter rumo, subir, orbitar, seguir trajetória, abortar.
* O **Voo** (núcleo de voo do Master Geral, a 200 Hz) verifica se o pedido cabe no envolvente seguro, se os dados de suporte são válidos e se a manobra é executável. Só depois converte o pedido em comandos de atuadores.
* O **Atuador** (Grupo Computacional de Atuadores) volta a validar limites físicos antes de gerar qualquer sinal elétrico e confirma a execução por realimentação.

Qualquer **bypass direto** (Missão → Atuador sem passar pelo Voo, ou qualquer outro atalho) é proibido por arquitetura, tanto em programa como em cablagem. O documento distribui esta lógica pelos 8 núcleos do Master Geral, define o FailSafe e explica como o sistema se mantém controlável mesmo quando partes falham.

---

# 2. Âmbito

## 2.1 Dentro do âmbito

* Cadeia de autoridade de controlo em operação normal: Missão → Planeamento/Navegação (quando necessário) → Voo → Atuadores.
* Papel de cada um dos 8 núcleos do Master Geral na lógica de controlo (Voo 200 Hz, Fusão 200 Hz, Navegação 50–100 Hz, Cálculo sob pedido, Missão 10–50 Hz, Planeamento esporádico, Supervisão contínua, Diagnóstico lento).
* Validações obrigatórias do Voo e do Grupo de Atuadores (envolvente, coerência temporal, integridade, limites físicos).
* Comportamento FailSafe e FailSecure: contenção, espera, regresso, aterragem de emergência e transferência para atuação de emergência.
* Proibição de bypass direto e mecanismos que a impõem (físicos, protocolares e de programa).

## 2.2 Fora do âmbito

* Leis de controlo concretas (ganhos PID, controlo ótimo, misturas específicas por célula): pertencem a MAT-015 e a documentos CTL posteriores por eixo.
* Modelos aerodinâmicos e de propulsão (MAT-005, MAT-006, MAT-007).
* Detalhe de motores, servos e eletrónica de potência (ACT).
* Decisão de segurança e autoridade máxima (SEC): este documento descreve como o Voo obedece à Segurança, não como a Segurança decide.
* Pipeline sensorial (SEN-001) e serviço de navegação (NAV-001), aqui apenas consumidos.

---

# 3. Descrição

## 3.1 Princípio de autoridade: quem pode o quê

| Entidade | Pode | Não pode |
|----------|------|----------|
| Missão (Master Geral, Núcleo de Missão + Planeamento) | Pedir comportamentos (referências, waypoints, modos). Pedir abortos e esperas. | Gerar PWM, ordenar deflexão de superfície, comandar motor diretamente. Declarar-se autoridade de segurança. |
| Voo (Master Geral, Núcleo de Voo) | Aceitar, limitar ou rejeitar pedidos. Gerar comandos validados para atuadores a 200 Hz. Declarar-se incapaz e pedir contenção. | Ignorar limites de envolvente. Usar dados expirados como se fossem frescos. Contornar o Grupo de Atuadores. Sobrepor-se à Segurança. |
| Atuadores (Grupo Computacional de Atuadores, RP2040/RP2350 periféricos) | Validar pela segunda vez, converter em sinais físicos, executar, medir realimentação. Recusar comando fora de limites físicos. | Aceitar ordens de outra origem que não o Voo em operação normal ou a Atuação de Emergência em FailSafe. Extrapolar comandos em falta sem regra explícita. |
| Segurança (Grupo de Segurança + Atuação de Emergência) | Inibir o Grupo de Atuadores normal, assumir atuadores críticos, ordenar FailSafe/FailSecure. | Pilotar a missão. Gerar trajetória de cruzeiro. Substituir o Voo sem declarar emergência. |
| Supervisão (Master Geral, Núcleo de Supervisão) | Observar prazos, reiniciar núcleos não críticos, pedir contenção, sincronizar tempo. | Gerar comandos de voo. Mascarar falhas repetidas sem as escalar. |

A frase que resume a tabela: **a Missão propõe, o Voo dispõe, o Atuador confirma, a Segurança prevalece**.

## 3.2 A cadeia completa em operação normal

```text
MISSÃO (10–50 Hz)            Deseja: «seguir para ponto B a 25 m/s a 120 m»
  │ MISSION_REQUEST (FABRIC, com prazo e identificador)
  ▼
PLANEAMENTO (esporádico)     Verifica obstáculos, gera trajetória verificável
  │ plano + margem
  ▼
NAVEGAÇÃO (50–100 Hz)        Confirma posição/velocidade atuais, projeta seguimento
  │ NAVIGATION_RESPONSE (posição + erro de seguimento + idade)
  ▼
VOO (200 Hz)                 VALIDA: dados frescos? envolvente OK? manobra executável?
  │ se SIM → comando validado (FABRIC → CAN-Principal, TLV, 200 Hz, CRÍTICA)
  │ se NÃO → rejeita com motivo + mantém referência anterior segura
  ▼
ATUADORES                    VALIDA de novo: limites físicos? taxa plausível? CRC OK?
  │ se SIM → PWM/GPIO + realimentação (CAN-Principal)
  │ se NÃO → mantém última posição segura + reporta RECUSA
  ▼
AERONAVE                     Superfícies + propulsão movem-se; sensores confirmam.
```

Cada seta possui prazo (ver SW-0xx) e cada bloco possui via degradada. Nenhuma seta pode ser saltada.

## 3.3 O que o Voo valida sempre (lista mínima, sem exceções)

Antes de converter qualquer pedido em comando, o Núcleo de Voo verifica, por esta ordem:

1. **Frescura dos dados**: estado de Fusão com idade < 10 ms, solução de Navegação com idade compatível com a fase, resposta de Cálculo dentro do prazo ou marcada como TIMEOUT (nesse caso usa via degradada). Dados obsoletos → pedido suspenso, mantém-se referência anterior.
2. **Validade dos estados**: nenhuma grandeza em estado REJEITADA/CONGELADA/AUSENTE pode sustentar manobra agressiva. Com sensores degradados, o Voo reduz automaticamente a agressividade (limita inclinação, velocidade vertical, aceleração).
3. **Envolvente de voo**: velocidade dentro de [perda + margem, máxima estrutural], altitude dentro de [mínima, máxima], inclinação lateral e longitudinal dentro de limites por modo, taxa de subida/descida limitada, bateria/energia suficiente para a manobra pedida mais regresso.
4. **Continuidade**: o salto entre a referência anterior e a nova é executável em um período de 5 ms sem descontinuidade violenta (limitação de taxa — *slew rate* — e filtragem de referência). Pedidos em degrau excessivo são suavizados ou rejeitados.
5. **Modo e autoridade**: o modo atual permite aquele pedido (ex.: não se aceita «desligar motor» em descolagem por pedido de Missão; apenas a Segurança pode ordenar contenção). Se o Grupo de Segurança declarou FailSafe, o Voo normal cessa e obedece à contenção.
6. **Integridade da mensagem**: CRC, sequência, autenticidade e plausibilidade do pedido. Pedido corrompido ou fora de sequência é descartado e contabilizado, nunca executado parcialmente.

Se qualquer teste falhar, o Voo responde com **REJEIÇÃO MOTIVADA** (código + grandeza violada + valor), mantém a última referência segura e assinala ao Diagnóstico. A Missão, ao receber a rejeição, adapta-se (replaneia, espera ou aborta) em vez de insistir por repetição cega. Insistência sem alteração após rejeição é limitada por intervalo mínimo entre retentativas (anti-sobrecarga).

## 3.4 O que o Atuador valida sempre (segunda barreira)

O Grupo Computacional de Atuadores não é um executor cego. Cada comando recebido passa por:

1. **Origem**: apenas Voo normal ou Atuação de Emergência (conforme estado declarado pela Segurança). Qualquer outra origem → descarte + alerta.
2. **Limites físicos**: curso de servo, largura de impulso, corrente de motor, taxa de variação. Valores fora → saturação segura + RECUSA parcial explícita (informa o que foi saturado).
3. **Prazo**: idade do comando < limite (ex.: < 15 ms para comandos a 200 Hz). Comando antigo → mantém posição segura em vez de executar manobra atrasada.
4. **Coerência**: comandos contraditórios no mesmo ciclo (ex.: subir + descer) → contenção + FAULT.
5. **Realimentação**: após execução, mede posição/corrente/temperatura e publica estado. Divergência entre ordenado e medido além de tolerância → alerta de atuador.

Esta dupla validação (Voo + Atuador) é intencional: protege contra erro de programa no Voo, contra corrupção no barramento e contra avaria no atuador, em camadas independentes.

## 3.5 Papel dos 8 núcleos na lógica de controlo

| Núcleo | Papel no controlo | Interação de controlo |
|--------|-------------------|----------------------|
| Voo (RP2350 #1 Core0, 200 Hz) | Único gerador de comandos validados. Executa leis de estabilização e seguimento, limitação de envolvente e mistura. | Consome Fusão + Navegação + Cálculo; produz comandos; obedece a Supervisão e Segurança. |
| Fusão (RP2350 #1 Core1, 200 Hz) | Fornece atitude/velocidade/aceleração fundidas com idade e estado. Sem fusão válida não há manobra agressiva. | Publica a 200 Hz; em degradação avisa explicitamente. |
| Navegação (RP2350 #2 Core0, 50–100 Hz) | Fornece posição e erro de seguimento; valida exequibilidade geométrica do pedido. | Responde a Voo e Missão; consome Fusão + Cálculo. |
| Cálculo (RP2350 #2 Core1, sob pedido) | Serve transformações, misturas e verificações matemáticas com prazo. | Herda prioridade do requerente; responde ou declara TIMEOUT. |
| Missão (RP2350 #3 Core0, 10–50 Hz) | Gera pedidos, gere waypoints e modos, trata rejeições. | Nunca comanda atuadores; apenas pede ao Voo. |
| Planeamento (RP2350 #3 Core1, esporádico) | Gera trajetórias verificáveis com margens; interrompível. | Serve a Missão; consome Navegação + Cálculo. |
| Supervisão (RP2350 #4 Core0, contínuo) | Vigia prazos, batimentos e integridade; declara contenção; sincroniza tempo. | Pode congelar Missão/Planeamento; nunca gera comandos de voo. |
| Diagnóstico (RP2350 #4 Core1, lento) | Regista rejeições, saturações, divergências e latências para análise. | Não interfere no ciclo; primeira a ser descartada. |

## 3.6 FailSafe e FailSecure: o que acontece quando o normal já não é seguro

FailSafe é o conjunto de comportamentos que preservam a segurança quando o voo normal já não pode ser garantido (perda de dados críticos, falha de comunicação, energia baixa, divergência de atuadores, ordem da Segurança). FailSecure é o conjunto que preserva pessoas e bens mesmo à custa do veículo (corte de propulsão, paraquedas quando existir, aterragem imediata controlada).

Regras de controlo em FailSafe:

1. **Declaração explícita**: apenas o Grupo de Segurança pode declarar FailSafe/FailSecure. O Master Geral pode pedir, nunca declarar. A declaração viaja no barramento de segurança com prioridade SUPER_CRÍTICA.
2. **Inibição do normal**: o Grupo de Atuadores normal é inibido (ignora o Voo) e a Atuação de Emergência assume os atuadores críticos com leis simplificadas e robustas (manter atitude, plainar, orbitar, regressar ou aterrar, conforme configuração).
3. **Congelamento da Missão**: a Missão e o Planeamento são suspensos. O Voo normal, se ainda vivo, passa a contenção (manter voo estável) até transferência completa.
4. **Regresso por camadas**: tenta-se primeiro espera (loiter) segura; se impossível, regresso ao ponto de lançamento; se impossível, aterragem imediata no local menos mau; sempre com aviso à estação terrestre quando houver ligação.
5. **Saída de FailSafe**: apenas por decisão da Segurança após verificação (dados válidos, energia suficiente, comunicação restabelecida, autoteste). Nunca por timeout silencioso nem por insistência da Missão.

O Voo normal e a Atuação de Emergência nunca comandam em simultâneo. A comutação é atómica do ponto de vista dos atuadores (há um instante definido de transferência, anunciado e registado).

## 3.7 Proibição de bypass direto: como é imposta, não apenas declarada

«Nunca bypass direto» não é um conselho: é garantido por três barreiras independentes.

**Barreira 1 — Física.** Não existe ligação elétrica nem caminho de programa que permita à Missão (RP2350 #3) gerar sinais de atuadores. Os periféricos de PWM/GPIO de atuação pertencem ao Grupo de Atuadores, noutra placa, noutro barramento. A Missão não tem pinos para lá chegar.

**Barreira 2 — Protocolar.** O Grupo de Atuadores só aceita mensagens com origem = Voo normal ou Atuação de Emergência, autenticadas e com prioridade adequada. Mensagens com origem = Missão/Planeamento/Navegação/Visão dirigidas a atuadores são descartadas por filtro de origem e geram alerta de violação arquitetónica.

**Barreira 3 — Programa.** O Núcleo de Voo é o único com codificador de comandos de atuadores; a Missão é compilada sem esse codificador. Revisão de código verifica que nenhum caminho de Missão instancia mensagens de atuadores. Testes de integração injetam pedidos diretos e exigem rejeição.

Violar qualquer barreira em ensaio é considerado defeito crítico bloqueante.

---

# 4. Exemplos ASCII

## 4.1 Caso feliz: seguir para waypoint (cadeia completa)

```text
MISSÃO ── MISSION_REQUEST ──► VOO : «ir para WPT 7, 25 m/s, 120 m»
  (id=101, prazo 40 ms, via FABRIC)

VOO ── NAVIGATION_REQUEST ──► NAVEGAÇÃO : «posição atual + erro para WPT 7?»
NAVEGAÇÃO ── MATH_REQUEST ──► CÁLCULO : «distância e rumo»
CÁLCULO ── MATH_RESPONSE ──► NAVEGAÇÃO : «1820 m, rumo 043°»
NAVEGAÇÃO ── NAV_RESPONSE ──► VOO : «posição válida (idade 12 ms), erro 1820 m»
FUSÃO ── (publicação 200 Hz) ──► VOO : «atitude válida (idade 2 ms)»

VOO valida: envolvente OK, continuidade OK, integridade OK
VOO ── COMANDO_VALIDADO (200 Hz, TLV/CAN-Principal) ──► ATUADORES :
        «rolamento +8°, pitch +2°, motor 62%» (limitado e suavizado)

ATUADORES validam: limites OK, idade 3 ms OK
ATUADORES ── PWM/GPIO ──► superfícies + motor
ATUADORES ── FEEDBACK ──► VOO + SEGURANÇA : «executado, posições medidas OK»

MISSÃO recebe: «pedido 101 EM_EXECUÇÃO» → avança máquina de estados.
```

## 4.2 Caso de rejeição: pedido fora do envolvente

```text
MISSÃO ── MISSION_REQUEST ──► VOO : «subir a +8 m/s a 30 m de altura»

VOO valida: taxa de subida máxima nesta configuração = +4 m/s
  → REJEIÇÃO MOTIVADA (id=102, motivo=TAXA_SUBIDA_EXCEDIDA, limite=4 m/s)

VOO mantém referência anterior segura («manter 120 m em espera»)
VOO ── MISSION_RESPONSE(id=102, REJEITADA, limite) ──► MISSÃO
DIAGNÓSTICO regista rejeição + contexto (idade, modo, energia)

MISSÃO adapta: replaneia subida a +3 m/s ou aborta perna.
ATUADORES nunca ficam a saber do pedido inválido (não chega a comando).
```

## 4.3 Caso de degradação sensorial: sem Pitot, sem manobra agressiva

```text
FUSÃO ── ESTADO (DEGRADADA, AR_SUSPEITO, idade 2 ms) ──► VOO (200 Hz)

MISSÃO ── MISSION_REQUEST ──► VOO : «curva apertada a 30 m/s»

VOO valida: com AR degradado, inclinação máxima cai de 35° para 15°,
            velocidade limitada a 22 m/s (margem contra perda)
  → ACEITAÇÃO PARCIAL (executa versão conservadora + informa limite)

ATUADORES executam versão conservadora + FEEDBACK
MISSÃO recebe: «pedido EM_EXECUÇÃO_DEGRADADA (limite=AR)» → ajusta plano.
```

## 4.4 Caso FailSafe: perda de Fusão, transferência para emergência

```text
FUSÃO muda (3 ciclos sem IMU válida)
  → VOO declara INCAPAZ_DE_MANOBRA_AGRESSIVA, passa a contenção (voo reto)
  → SUPERVISÃO deteta (10 ms) → pede avaliação à SEGURANÇA

SEGURANÇA avalia (dados próprios + estados) → declara FAILSAFE
  → BUS DE SEGURANÇA (SUPER_CRÍTICA): INIBE Atuadores normais
  → ATUAÇÃO DE EMERGÊNCIA assume: «plainar + orbitar no local»
  → VOO normal cessa comandos (obedece à inibição)
  → MISSÃO/PLANEAMENTO congelados
  → DIAGNÓSTICO + estação terrestre: «FAILSAFE_ATIVO, motivo=FUSÃO»

Saída: só por ordem da SEGURANÇA após dados válidos + autoteste.
```

## 4.5 Tentativa de bypass (bloqueada nas três barreiras)

```text
MISSÃO (defeituosa) tenta: «ATUADOR: deflete profundor +20°» direta

Barreira protocolar: ATUADORES verificam origem=MISSÃO → DESCARTA + ALERTA
  «VIOLAÇÃO_ARQUITETÓNICA: origem não autorizada para atuadores»

Barreira física: mesmo que o programa tentasse, não há PWM na placa da Missão.
Barreira de programa: auditoria mostra que a Missão nem possui o codificador.

Resultado: aeronave mantém voo seguro; defeito registado como crítico.
```

---

# 5. Interfaces

## 5.1 Mensagens de controlo (lógica, transporte TLV/CAN FD ou IPC/FABRIC)

| Mensagem | Emissor → Recetor | Via | Cadência | Prioridade | Conteúdo essencial |
|----------|-------------------|-----|----------|------------|-------------------|
| MISSION_REQUEST | Missão → Voo (via Planeamento/Navegação quando aplicável) | FABRIC (IPC) | 10–50 Hz + evento | MÉDIA | id, tipo de comportamento, parâmetros, prazo, modo |
| MISSION_RESPONSE | Voo → Missão | FABRIC | Por pedido + 10 Hz resumo | MÉDIA | id, ACEITE/REJEITADA/EM_EXECUÇÃO/DEGRADADA + motivo |
| NAVIGATION_REQUEST/RESPONSE | Voo/Missão ↔ Navegação | FABRIC | 50–100 Hz | ALTA | posição, erro de seguimento, idade, estado |
| MATH_REQUEST/RESPONSE | Qualquer núcleo → Cálculo | FABRIC | Sob pedido | Herdada | operação, operandos, prazo, resultado ou TIMEOUT |
| COMANDO_VALIDADO | Voo → Atuadores | CAN-Principal (operacional) | 200 Hz | CRÍTICA | comandos por eixo/motor + sequência + CRC + idade |
| FEEDBACK_ATUADOR | Atuadores → Voo + Segurança | CAN-Principal | 200 Hz resumido + evento | ALTA | posições medidas, correntes, estados, recusas |
| HEALTH/HEARTBEAT | Todos → Supervisão | FABRIC + CAN-Principal | 100 Hz int. / 10 Hz difusão | SUPER_CRÍTICA/ALTA | batimento, prazos, contadores |
| INIBIÇÃO | Segurança → Atuadores | Bus de segurança | Evento | SUPER_CRÍTICA | inibe normal, transfere autoridade |
| FAILSAFE/FAILSECURE | Segurança → Todos | Ambos os barramentos | Evento + 10 Hz enquanto ativo | SUPER_CRÍTICA | modo de emergência + motivo + configuração |

## 5.2 Limites e tempos (resumo normativo, detalhe em SW-0xx)

* Voo publica comandos a 200 Hz; comandos com idade > 15 ms são ignorados pelos Atuadores.
* Missão retenta pedidos rejeitados apenas após intervalo mínimo (anti-sobrecarga) e com parâmetros alterados.
* Cálculo responde em ≤ 1,5 ms a pedidos de Voo/Fusão, ≤ 4 ms a Navegação, ≤ 50 ms a Missão/Planeamento, ou declara TIMEOUT.
* Supervisão deteta Voo mudo em ≤ 10 ms e difunde FAULT em ≤ 5 ms.
* Qualquer bypass detetado gera alerta de violação e é contabilizado como defeito crítico.

---

# 6. Pontos em Aberto

1. **Leis de controlo por eixo**: longitudinal, lateral-direcional, misturas por configuração (asa fixa convencional, asa voadora, VTOL quando aplicável), ganhos por modo e margens de estabilidade. Pertencem a documentos CTL seguintes.
2. **Envolvente detalhada por célula**: velocidades de perda e estruturais, fatores de carga, centragem, limites de vento e de turbulência para cada manobra.
3. **Comportamento de contenção do Voo**: atitude de espera, velocidade de segurança e gestão de energia quando a Missão está congelada mas ainda sem FailSafe declarado.
4. **Manobras de emergência da Atuação de Emergência**: plainar, orbitar, regressar, aterrar, corte de propulsão; critérios de escolha e parâmetros por cenário.
5. **Transferência atómica normal→emergência**: sequência elétrica e lógica, tempo máximo de interrupção de atuação e verificação de posse.
6. **Limites de taxa e de saturação por atuador**: valores por servo/motor, comportamento anti-saturação (*anti-windup*) e priorização de eixos sob saturação.
7. **Gestão de divergência ordenado contra medido**: tolerâncias, persistência antes de declarar avaria e ação (isolar superfície, redistribuir, abortar).
8. **Ensaios de rejeição de bypass**: matriz de injeção de mensagens inválidas e critérios de aceitação para cada barreira.
9. **Interação com vento e turbulência**: quando a rejeição por envolvente deve ser temporária (rajada) contra persistente (configuração errada).
10. **Registo forense**: conjunto mínimo de sinais a 200 Hz para reconstruir qualquer decisão de validação após voo.

---

# 7. Referências

* SYS-002 — Arquitetura Computacional (autoridade e domínios).
* SYS-005 — Fluxo Global de Informação (fluxos de controlo e autoridade).
* SYS-008 — Gestão Temporal (prazos e sincronização).
* SW-0xx — Políticas Temporais (matriz temporal dos 8 núcleos e GCV).
* SEN-001 — Cadeia Sensorial (dados que o Voo valida).
* NAV-001 — Serviço de Navegação (provedor de posição/seguimento ao Voo).
* COM-001/004/006/008 — Comunicação, prioridades, tempos limite e CAN FD.
* MAT-015 — Sistemas de Controlo (leis de controlo).
* SEC — Segurança (declaração e gestão de FailSafe/FailSecure).
* ACT — Atuadores (limites físicos e realimentação).
* Docs/Esquemas/Arquitetura-Computacional (§ separação Missão→Voo→Atuador).
