# SYS-006 — Gestão de Estados

| Campo             | Valor                    |
|-------------------|--------------------------|
| **Código**        | SYS-006                  |
| **Título**        | Gestão de Estados        |
| **Versão**        | 2.0                      |
| **Estado**        | Em Desenvolvimento       |
| **Autor**         | ShegaPT                  |
| **Classificação** | Especificação de Sistema |

---

# 1. Objetivo

O presente documento define a arquitetura geral de gestão de estados do sistema AERUS. Estabelecem-se os princípios relativos à criação, alteração, propagação e utilização dos estados internos dos grupos computacionais, do Master Geral e do Grupo de Visão, com garantia de coerência, previsibilidade e segurança.

Não se definem os estados específicos de cada domínio funcional; tais estados constam das respetivas especificações técnicas (SW, SEC, OPS, SEN, ACT, NAV, CTL).

---

# 2. Âmbito

Aplica-se a todos os proprietários de estado: Módulos Menores RP2040, Masters RP2350, os 8 núcleos do Master Geral, o Router do GCV e o Grupo de Comunicação, bem como às redes que transportam estados (CAN-Intra, CAN-Principal, CAN-FailSafe, FABRIC).

---

# 3. Descrição Detalhada

## 3.1. Princípios gerais

- **Propriedade**: cada grupo/núcleo é proprietário exclusivo dos seus estados internos; só o proprietário cria, modifica ou elimina.
- Consistência global e previsibilidade: transições determinísticas (origem, condição, destino), sem alterações arbitrárias.
- Rastreabilidade: toda a transição relevante é registada com timestamp para diagnóstico e auditoria.
- Isolamento: declarações externas sobre outro grupo não alteram o seu estado interno.
- Validação antes da transição e sincronização entre grupos via redes normativas.
- Prioridade da segurança: estados de segurança prevalecem sobre estados operacionais.

## 3.2. Categorias de estados

- **Estados Internos**: condição interna de funcionamento (ex.: modo do driver, fase de filtro, estado do codificador). Utilização exclusiva do proprietário.
- **Estados Operacionais**: condição observável por outros (disponibilidade, indisponibilidade, perda de comunicação, normal, degradado). Critérios definidos pela arquitetura.
- **Estados de Segurança**: proteção (FailSafe, FailSecure, inibição, recuperação, emergência). Gestão associada ao FailSafe/Supervisão e transporte prioritário na CAN-FailSafe.

## 3.3. Propriedade por grupo (normativa)

| Proprietário | Estados próprios |
|--------------|------------------|
| Grupo Sensorial (Master + Menores) | Aquisição, validade por sensor, saúde de barramento intra |
| Grupo Atuador | Validação de comando, envelope, saúde por atuador |
| Núcleos Voo/Fusão/Navegação/Cálculo/Missão/Planeamento | Estado de cada serviço no cluster |
| Supervisão/Diagnóstico (MG) | Saúde do cluster, heartbeats, latências, integridade IPC |
| GCV (SoC + Router) | Captura, ISP, codec, temperatura, armazenamento, ligação RF |
| Comunicação | Ligação RF, filas, integridade de telecomando/telemetria |
| FailSafe | Estados de segurança globais e inibições |

Exemplo de regra: o Router do GCV é proprietário do estado `VISAO_SAUDE`; o Master Geral apenas o subscreve e declara, quando aplicável, `VISAO_OPERACIONAL=DEGRADADO` como avaliação externa, sem alteração do estado interno do GCV.

## 3.4. Supervisão externa (avaliação, não alteração)

Determinados grupos podem declarar estados operacionais relativos a outros, quando as regras o permitam. Tais declarações constituem avaliação externa e nunca alteram o estado interno do observado.

- **Master Geral (função Missão/Voo)**: monitoriza Sensorial e Atuador via CAN-Principal; em ausência de comunicação no intervalo definido, declara estados como `SEM_COMUNICACAO` ou `INDISPONIVEL`.
- **Supervisão do cluster**: monitoriza os 8 núcleos via HEARTBEAT/HALTH na FABRIC (latência, erros, bloqueio, CRC). Pode declarar perda de nó e impor degradação.
- **FailSafe**: monitoriza todos (Masters, MG, GCV via Router, Comunicação). Pode declarar estados operacionais e de segurança e determinar FailSafe/FailSecure. As ordens críticas circulam na CAN-FailSafe.

## 3.5. Transições, sincronização e persistência

Toda a transição possui origem, condição e destino; sempre que necessário, utilizam-se estados intermédios para evolução controlada.

A sincronização processa-se pelos mecanismos COM/SEC (HEALTH_STATUS, SYSTEM_STATUS, TIME_SYNC, FAULT). Perante divergência entre observadores, aplica-se a regra COM/SEC (prevalência do FailSafe em matéria de segurança; prevalência do proprietário em matéria interna; marcação temporal como desempate técnico).

Os estados representam a condição atual; o histórico é objeto de registo (log) independente para diagnóstico, auditoria e análise, sem confusão com a gestão propriamente dita.

## 3.6. Deteção de falha de 1x RP2350 (regra explícita)

Perante falta de HEARTBEAT, watchdog expirado, latência excessiva, CRC inválido ou dados incoerentes num RP2350 do cluster, a Supervisão: identifica o nó, determina serviços perdidos (ex.: Missão+Planeamento), impõe estado predefinido (ex.: `MISSÃO_INDISPONIVEL`, `MODO_SEGURO`), mantém funções críticas possíveis, regista FAULT com timestamp e informa restantes grupos via CAN-Principal e, se crítico, via CAN-FailSafe. A recuperação automática depende da classe de falha (ver SEC).

## 3.7. Escalabilidade

Admite-se adição futura de grupos, estados, categorias e regras, sem compromisso dos princípios. Novos estados são documentados com proprietário, categoria, condições e rede de publicação.

---

# 4. Exemplos

## Exemplo 1 — Propriedade respeitada

```text
Master Sensorial: ESTADO_INTERNO=AMOSTRAGEM_OK (proprietário: Sensorial)
MG declara: SENSORIAL_OPERACIONAL=NORMAL (avaliação externa)
→ o registo interno do Sensorial permanece inalterado.
```

## Exemplo 2 — Perda de comunicação

```text
Sem quadros do Atuador na CAN-Principal durante T_limite:
  MG declara ATUADOR_OPERACIONAL=SEM_COMUNICACAO;
  FailSafe avalia e, se crítico, declara ATUADOR_SEGURANCA=INIBIDO
  via CAN-FailSafe + SYSTEM_STATUS.
```

## Exemplo 3 — Falha no cluster

```text
RP2350 #3 sem HEARTBEAT há 3 janelas:
  Supervisão declara NO cluster: RP2350_3=EM_FALHA,
  MISSÃO=INDISPONIVEL, VOO=MANTIDO, modo global=SEGURO;
  Diagnóstico regista FAULT {nó, serviços, t, contadores}.
```

## Exemplo 4 — Tabela de estados (extrato)

| Estado | Categoria | Proprietário | Rede de publicação |
|--------|-----------|--------------|--------------------|
| AMOSTRAGEM_OK | Interno | Sensorial | Intra + resumo na Principal |
| ATUADOR=NORMAL | Operacional | Atuador | Principal |
| FAILSAFE_ATIVO | Segurança | FailSafe | FailSafe + Principal (resumo) |
| VISAO_SAUDE=OK | Interno/Oper. | Router GCV | Principal |

---

# 5. Interfaces Com Outros Documentos

| Documento | Relação |
|-----------|---------|
| SYS-002 | Grupos e autoridade que sustentam a propriedade |
| SYS-005 | Redes que transportam estados |
| SYS-007/008 | Modos e tempos que condicionam transições |
| COM / SEC / SW | Mecanismos, políticas de falha e políticas por módulo |
| SEN/ACT/NAV/CTL | Estados específicos de cada domínio |

---

# 6. Estado / Pontos Em Aberto

- **Estado**: Em Desenvolvimento.
- **Pontos em aberto**: catálogo de estados por grupo; intervalos de declaração de perda; formato SYSTEM_STATUS/HEALTH_STATUS/FAULT; política de desempate em divergência; retenção de logs e relação com certificação.

