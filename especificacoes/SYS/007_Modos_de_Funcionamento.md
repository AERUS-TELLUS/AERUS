# SYS-007 — Modos de Funcionamento

| Campo             | Valor                    |
|-------------------|--------------------------|
| **Código**        | SYS-007                  |
| **Título**        | Modos de Funcionamento   |
| **Versão**        | 2.0                      |
| **Estado**        | Em Desenvolvimento       |
| **Autor**         | ShegaPT                  |
| **Classificação** | Especificação de Sistema |

---

# 1. Objetivo

O presente documento define a arquitetura geral dos modos de funcionamento do sistema AERUS. Os modos representam a condição operacional global da aeronave desde o período anterior ao arranque até ao encerramento completo.

Definem-se apenas princípios gerais; os critérios individuais de entrada, saída e validação de cada modo, bem como as checklists, constam de OPS e das especificações de cada domínio.

---

# 2. Âmbito

Aplica-se à sequência operacional global, à gestão do modo ativo, à sincronização entre grupos (incluindo Master Geral e GCV), à gestão de módulos por modo e à articulação com procedimentos de emergência (SEC), sem os quais nenhum modo se considera completo.

---

# 3. Descrição Detalhada

## 3.1. Filosofia e exclusividade

O AERUS opera sempre num único modo global. O modo representa a fase operacional atual e determina as regras gerais aplicadas pelo sistema nesse período. Todos os grupos trabalham de forma coordenada para suportar o modo ativo.

Em qualquer instante existe apenas um modo ativo. Não é permitida coexistência de modos. Cada transição substitui integralmente o modo anterior, após validação das condições do modo seguinte. Não existem transições arbitrárias.

## 3.2. Sequência operacional de referência

```text
Before_Start → After_Start → Taxi (opcional) → Line_Up → Before_Takeoff
→ After_Takeoff → Climb → In_Flight → Descent → Approach → Before_Landing
→ Landing → After_Landing → Parking (opcional) → Securing_Aircraft → Shutdown
```

Consoante a missão, etapas podem ser omitidas ou substituídas por equivalentes, com observância das regras da arquitetura. `Taxi` e `Parking` são opcionais, dependentes da capacidade de deslocação em solo. A granularidade (Climb/Descent/Approach/Before_Landing) é mantida por compatibilidade operacional e pode ser agregada por parametrização quando a aeronave o justifique.

## 3.3. Transições, checklists e tolerâncias

Cada modo associa-se a uma checklist (condições de transição). As checklists operacionais são especificadas em OPS. Admitem-se tolerâncias destinadas exclusivamente a compensar incertezas de medição, oscilações de sensores e atrasos naturais; nunca com compromisso da segurança.

## 3.4. Gestão dos módulos por modo

Cada modo pode exigir regimes distintos por módulo: ativo, em espera, suspenso, reativado. O objetivo é a otimização de recursos sem compromisso do voo. Exemplos normativos:

| Modo | Comportamento típico |
|------|----------------------|
| After_Start | Todos os grupos em autoteste; GCV em arranque sequenciado; Comunicação em escuta |
| In_Flight | Todos os serviços críticos ativos; NPU de visão como função futura, não obrigatória |
| Approach/Landing | Módulos não necessários em espera controlada; sensores de proximidade com prioridade elevada |
| After_Landing/Parking | Desativação progressiva com observância de dependências |

As regras concretas constam de SW; a supervisão de conformidade cabe ao Diagnóstico e ao FailSafe.

## 3.5. Gestão do modo e modos de emergência

Em funcionamento normal, a gestão do modo é efetuada pelo Grupo de Missão (Master Geral), sob validação permanente do Controlo de Voo. O FailSafe pode impedir ou alterar a evolução dos modos sempre que a segurança o exija.

Os procedimentos de emergência (FailSafe/FailSecure) não constituem modos independentes. Quando ocorre emergência, mantém-se o modo da fase em curso, com ativação em paralelo das regras de segurança (SEC). Deste modo, preserva-se o contexto operacional e impõe-se a proteção.

## 3.6. Sincronização e comportamento por grupo

Todos os grupos tomam conhecimento do modo ativo através das redes normativas (CAN-Principal para operação; CAN-FailSafe para segurança; FABRIC para coordenação interna do cluster; Router para o GCV). Perante degradação (ex.: falha de 1x RP2350 com perda de Missão), o Voo mantém controlo seguro e o FailSafe impõe o regime compatível com o modo em curso (ex.: órbita de espera em In_Flight, abortagem em Approach, conforme SEC/OPS).

## 3.7. Escalabilidade

Admite-se adição, remoção ou alteração de modos sem compromisso da estrutura. Cada novo modo define condições, checklist, regime de módulos e comportamento em falha.

---

# 4. Exemplos

## Exemplo 1 — Transição validada

```text
Estado: Line_Up. Checklist Before_Takeoff: sensores OK, atuadores OK,
  vento dentro de limites, missão carregada, FailSafe ARMADO.
  → Missão solicita, Voo valida, modo passa a Before_Takeoff.
  Em falha de validação → permanência em Line_Up + motivo registado.
```

## Exemplo 2 — Emergência sem mudança de modo

```text
Modo: In_Flight. Falha de Missão (RP2350 #3).
  → modo permanece In_Flight; FailSafe impõe regime SEGURO (órbita),
  Voo mantém controlo, Comunicação informa o solo, Diagnóstico regista.
```

## Exemplo 3 — Regime de módulos

```text
Approach: sensores de proximidade a cadência máxima;
  codificador do GCV mantém 720p30 para o solo;
  planeamento de longo curso em espera;
  tudo por decisão coordenada Missão→Voo, supervisionada pelo FailSafe.
```

---

# 5. Interfaces Com Outros Documentos

| Documento | Relação |
|-----------|---------|
| SYS-006 Estados | Estados que suportam a avaliação de cada modo |
| SYS-008 Temporal | Janelas e cadências por modo |
| SYS-009 Arranque/Encerramento | Concretização dos modos iniciais e finais |
| OPS | Checklists e procedimentos por modo |
| SW/SEC/COM | Regimes, emergência e propagação do modo |

---

# 6. Estado / Pontos Em Aberto

- **Estado**: Em Desenvolvimento.
- **Pontos em aberto**: critérios de entrada/saída por modo; agregação de Climb/Descent/Approach por parametrização; regimes de módulos por modo e aeronave; comportamento degradado por modo em falha de cluster; ensaios de transição.

