# SYS-007 — Modos_de_Funcionamento

| Campo             | Valor                    |
|-------------------|--------------------------|
| **Código**        | SYS-007                  |
| **Título**        | Modos de Funcionamento   |
| **Versão**        | 1.0                      |
| **Estado**        | Em Desenvolvimento       |
| **Autor**         | ShegaPT                  |
| **Classificação** | Especificação de Sistema |

---

# 1. Objetivo

O presente documento define a arquitetura geral dos modos de funcionamento do sistema Aerus.

Os modos representam a condição operacional global da aeronave ao longo de toda a operação, desde o momento anterior ao arranque até ao encerramento completo do sistema.

Este documento define apenas os princípios gerais de funcionamento, não especificando os critérios individuais de entrada, saída ou validação de cada modo.

---

# 2. Filosofia

O Aerus opera sempre num único modo global.

O modo de funcionamento representa a fase operacional atual da aeronave e determina as regras gerais que deverão ser aplicadas pelo sistema durante esse período.

Todos os grupos computacionais trabalham de forma coordenada para suportar o modo atualmente ativo.

---

# 3. Exclusividade

Em qualquer instante existe apenas um modo de funcionamento ativo.

Não é permitida a existência simultânea de múltiplos modos operacionais.

Sempre que ocorre uma transição, o novo modo substitui integralmente o anterior.

---

# 4. Sequência Operacional

A arquitetura base do Aerus define a seguinte sequência operacional:

1. Before_Start
2. After_Start
3. Taxi
4. Line_Up
5. Before_Takeoff
6. After_Takeoff
7. Climb
8. In_Flight
9.  Descent
10. Approach
11. Before_Landing
12. Landing
13. After_Landing
14. Parking
15. Securing_Aircraft
16. Shutdown

Esta sequência constitui a operação de referência do sistema.

Dependendo do tipo de missão, determinadas etapas poderão ser ignoradas ou substituídas por outras equivalentes, desde que respeitem as regras definidas pela arquitetura.

---

# 5. Transições

A passagem entre modos apenas poderá ocorrer quando forem satisfeitas as condições definidas para o modo seguinte.

Cada transição deverá ser validada antes da sua execução.

Não são permitidas transições arbitrárias entre modos.

---

# 6. Checklists

Cada modo operacional encontra-se associado a um conjunto de verificações designado por checklist.

A checklist define todas as condições que deverão estar satisfeitas antes da transição para o modo seguinte.

As checklists operacionais são especificadas na documentação da área OPS.

---

# 7. Tolerâncias

A arquitetura admite pequenas tolerâncias durante a validação das condições de transição.

Estas tolerâncias destinam-se exclusivamente a compensar:

- incertezas de medição;
- pequenas oscilações dos sensores;
- atrasos naturais do sistema.

As tolerâncias nunca deverão comprometer a segurança da operação.

---

# 8. Gestão dos Módulos

Cada modo poderá definir diferentes requisitos relativamente aos módulos de software existentes.

Dependendo do modo operacional, determinados módulos poderão:

- permanecer ativos;
- entrar em espera;
- ser suspensos temporariamente;
- ser reativados.

Esta gestão tem como objetivo otimizar os recursos computacionais disponíveis sem comprometer o correto funcionamento da aeronave.

As regras específicas encontram-se definidas nas especificações da área SW.

---

# 9. Alteração do Modo

Durante o funcionamento normal, a gestão do modo operacional é efetuada pelo Grupo Computacional RaspberryPi.

Sempre que necessário, o Grupo Computacional ESP32-FS poderá impedir ou alterar a evolução normal dos modos operacionais caso a segurança da aeronave assim o exija.

---

# 10. Modos de Emergência

Os procedimentos de emergência não constituem modos operacionais independentes.

Quando ocorre uma situação de FailSafe ou FailSecure, o sistema mantém o modo operacional correspondente à fase da missão em curso, sendo ativadas em paralelo as respetivas regras de segurança.

A gestão destes procedimentos encontra-se definida nas especificações da área SEC.

---

# 11. Sincronização

Todos os grupos computacionais deverão possuir conhecimento do modo operacional atualmente ativo.

A alteração do modo deverá ser propagada a todos os grupos computacionais através dos mecanismos definidos pela arquitetura de comunicações.

---

# 12. Escalabilidade

A arquitetura permite a introdução futura de novos modos operacionais.

A adição, remoção ou alteração de modos não deverá comprometer a estrutura geral definida nesta especificação.

---

# 13. Referências

- SYS-006 — Gestao_de_Estados
- SYS-008 — Gestao_Temporal
- OPS — Procedimentos Operacionais
- SW — Especificações de Software
- COM — Especificações de Comunicações
- SEC — Especificações de Segurança