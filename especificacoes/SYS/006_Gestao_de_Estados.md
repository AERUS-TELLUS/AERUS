# SYS-006 — Gestao_de_Estados

| Campo             | Valor                    |
|-------------------|--------------------------|
| **Código**        | SYS-006                  |
| **Título**        | Gestão de Estados        |
| **Versão**        | 1.0                      |
| **Estado**        | Em Desenvolvimento       |
| **Autor**         | ShegaPT                  |
| **Classificação** | Especificação de Sistema |

---

# 1. Objetivo

O presente documento define a arquitetura geral de gestão de estados do sistema Aerus.

São estabelecidos os princípios relativos à criação, alteração, propagação e utilização dos estados internos dos diferentes grupos computacionais, garantindo coerência, previsibilidade e segurança durante todo o funcionamento do sistema.

Este documento não define os estados específicos de cada domínio funcional, os quais são descritos nas respetivas especificações técnicas.

---

# 2. Princípios Gerais

A gestão de estados do Aerus baseia-se nos seguintes princípios:

- propriedade dos estados;
- consistência global;
- previsibilidade;
- rastreabilidade;
- isolamento entre domínios;
- validação antes da transição;
- sincronização entre grupos computacionais;
- prioridade da segurança.

Os estados representam a condição operacional de um determinado elemento do sistema num dado instante.

---

# 3. Propriedade dos Estados

Cada grupo computacional é proprietário dos seus próprios estados internos.

Apenas o próprio grupo computacional pode criar, modificar ou eliminar os seus estados internos.

Nenhum outro grupo computacional poderá alterar diretamente esses estados.

Esta regra garante a integridade funcional e evita inconsistências provocadas por alterações externas.

---

# 4. Categorias de Estados

A arquitetura distingue três categorias fundamentais de estados.

## Estados Internos

Representam a condição interna de funcionamento de cada grupo computacional.

São utilizados exclusivamente pelo respetivo grupo durante o processamento local.

Apenas o proprietário pode alterá-los.

---

## Estados Operacionais

Representam a condição operacional observável por outros grupos computacionais.

Estes estados podem ser utilizados para indicar, entre outros:

- disponibilidade;
- indisponibilidade;
- perda de comunicação;
- funcionamento normal;
- funcionamento degradado.

Os critérios para determinação destes estados são definidos pela arquitetura do sistema.

---

## Estados de Segurança

Representam estados relacionados com mecanismos de proteção da aeronave.

Incluem estados associados a:

- FailSafe;
- FailSecure;
- inibição;
- recuperação;
- procedimentos de emergência.

A gestão destes estados encontra-se associada ao Grupo Computacional ESP32-FS.

---

# 5. Alteração de Estados

Qualquer alteração de estado deverá respeitar as regras definidas para esse elemento.

Uma transição de estado deverá ocorrer apenas quando:

- existam condições válidas;
- tenham sido verificadas as respetivas regras;
- seja garantida a coerência da transição.

Não deverão existir alterações arbitrárias de estados.

---

# 6. Estados dos Grupos Computacionais

Cada grupo computacional mantém autonomamente o seu estado interno.

Esta responsabilidade encontra-se distribuída da seguinte forma:

- ESP32-S gere exclusivamente os seus estados internos;
- ESP32-A gere exclusivamente os seus estados internos;
- RaspberryPi gere exclusivamente os seus estados internos;
- ESP32-FS gere exclusivamente os seus estados internos;
- ESP32-FS_A gere exclusivamente os seus estados internos.

---

# 7. Supervisão Externa

Embora cada grupo seja responsável pelos seus estados internos, determinados grupos computacionais podem declarar estados operacionais relativos a outros grupos, desde que tal seja permitido pelas regras da arquitetura.

Estas declarações não alteram os estados internos do grupo observado.

Constituem apenas uma avaliação externa do seu estado operacional.

---

# 8. Supervisão do RaspberryPi

O Grupo Computacional RaspberryPi monitoriza continuamente os Grupos Computacionais ESP32-S e ESP32-A.

Na ausência de comunicação durante o intervalo temporal definido para cada grupo, o RaspberryPi poderá declarar estados operacionais previamente definidos, como por exemplo:

- ON;
- OFF;
- outros estados previstos pela arquitetura.

Esta declaração não altera o estado interno do grupo computacional monitorizado.

---

# 9. Supervisão do ESP32-FS

O Grupo Computacional ESP32-FS monitoriza continuamente:

- RaspberryPi;
- ESP32-S;
- ESP32-A;
- ESP32-FS_A.

Sempre que as regras de segurança assim o determinem, poderá declarar estados operacionais ou estados de segurança relativos aos restantes grupos computacionais.

O Grupo Computacional ESP32-FS possui igualmente autoridade para determinar a ativação dos mecanismos de FailSafe e FailSecure.

---

# 10. Transições de Estado

Todas as transições de estado deverão ser determinísticas.

Uma transição deverá possuir:

- estado de origem;
- condição de transição;
- estado de destino.

Sempre que necessário, poderão existir estados intermédios destinados a garantir uma evolução controlada entre diferentes condições operacionais.

---

# 11. Sincronização

Os diferentes grupos computacionais deverão manter informação consistente relativamente aos estados operacionais do sistema.

A sincronização de estados deverá ocorrer através dos mecanismos de comunicação definidos pela arquitetura.

Sempre que existam divergências entre estados observados por diferentes grupos computacionais, estas deverão ser resolvidas de acordo com as regras estabelecidas nas especificações da área COM e SEC.

---

# 12. Persistência

Os estados representam exclusivamente a condição atual do sistema.

Sempre que necessário, poderão existir mecanismos de registo histórico para efeitos de diagnóstico, auditoria ou análise posterior.

A persistência destes registos é independente da gestão dos estados propriamente dita.

---

# 13. Escalabilidade

A arquitetura de gestão de estados deverá permitir a introdução futura de:

- novos grupos computacionais;
- novos estados;
- novas categorias de estados;
- novas regras de transição.

Estas evoluções não deverão comprometer os princípios definidos na presente especificação.

---

# 14. Referências

- SYS-002 — Arquitetura Computacional
- SYS-003 — Arquitetura Software
- SYS-005 — Fluxo Global de Informação
- SYS-007 — Modos de Funcionamento
- COM — Especificações de Comunicações
- SEC — Especificações de Segurança
- SW — Especificações de Software