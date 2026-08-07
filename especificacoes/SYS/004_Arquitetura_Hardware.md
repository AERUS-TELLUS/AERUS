# SYS-004 — Arquitetura Hardware

| Campo             | Valor                    |
|-------------------|--------------------------|
| **Código**        | SYS-004                  |
| **Título**        | Arquitetura Hardware     |
| **Versão**        | 1.0                      |
| **Estado**        | Em Desenvolvimento       |
| **Autor**         | ShegaPT                  |
| **Classificação** | Especificação de Sistema |

---

# 1. Objetivo

O presente documento define a arquitetura física do sistema Aerus, estabelecendo a organização dos grupos computacionais, a distribuição das responsabilidades de hardware e os princípios que regem a sua interação.

Este documento não especifica componentes eletrónicos, modelos de sensores, protocolos de comunicação ou esquemas elétricos, limitando-se à arquitetura física do sistema.

---

# 2. Filosofia da Arquitetura

A arquitetura hardware do Aerus baseia-se numa filosofia de processamento distribuído.

Em vez de concentrar todas as responsabilidades numa única unidade computacional, estas são distribuídas por diferentes grupos computacionais especializados, permitindo:

- reduzir a carga computacional individual;
- aumentar a robustez do sistema;
- simplificar a manutenção;
- facilitar a escalabilidade;
- aumentar a tolerância a falhas;
- permitir evolução independente de cada domínio computacional.

Cada grupo computacional possui responsabilidades claramente definidas, evitando sobreposição desnecessária de funções.

---

# 3. Grupos Computacionais

A arquitetura base do Aerus é constituída pelos seguintes grupos computacionais:

- Grupo Computacional RaspberryPi;
- Grupo Computacional ESP32-S;
- Grupo Computacional ESP32-A;
- Grupo Computacional ESP32-FS;
- Grupo Computacional ESP32-FS_A.

Cada grupo representa um domínio funcional do sistema e não um equipamento físico específico.

O hardware utilizado para implementar cada grupo poderá evoluir ao longo do desenvolvimento do projeto sem alterar a arquitetura global do sistema.

---

# 4. Escalabilidade

Cada grupo computacional poderá ser constituído por uma ou mais unidades computacionais.

A quantidade de unidades pertencentes a cada grupo dependerá das necessidades da aeronave, da carga computacional prevista e da distribuição física dos diferentes dispositivos.

A arquitetura do Aerus não estabelece limites quanto ao número de unidades existentes em cada grupo computacional.

---

# 5. Distribuição Funcional

Cada grupo computacional executa exclusivamente as funções pertencentes ao seu domínio de responsabilidade.

A distribuição das responsabilidades visa minimizar dependências entre diferentes grupos computacionais e otimizar a utilização dos recursos disponíveis.

Sempre que possível, cada grupo deverá efetuar localmente o processamento pertencente ao seu domínio antes de disponibilizar informação aos restantes grupos.

---

# 6. Aquisição de Dados

Todos os sensores da aeronave deverão ligar-se diretamente ao Grupo Computacional ESP32-S.

Este grupo é responsável pela:

- aquisição dos sinais;
- conversão dos dados;
- validação primária;
- processamento inicial;
- disponibilização da informação aos restantes grupos computacionais.

A arquitetura admite a introdução futura de sensores dedicados a outros grupos computacionais, caso tal se revele necessário, sem alterar os princípios gerais definidos nesta especificação.

---

# 7. Controlo dos Atuadores

O controlo dos atuadores é efetuado pelo Grupo Computacional ESP32-A.

Este grupo recebe os comandos provenientes do Grupo Computacional RaspberryPi, verifica a sua conformidade com os limites operacionais definidos para a aeronave e converte-os para os sinais físicos necessários ao acionamento dos respetivos atuadores.

O Grupo Computacional ESP32-A é igualmente responsável pela monitorização contínua do estado dos atuadores.

---

# 8. Realimentação dos Atuadores

Todos os atuadores deverão fornecer mecanismos de realimentação do seu estado.

A informação devolvida poderá incluir, entre outros:

- posição;
- velocidade;
- rotação;
- corrente elétrica;
- tensão;
- estado interno;
- telemetria disponível.

O método utilizado para obtenção desta informação depende das características do respetivo atuador.

---

# 9. Processamento Principal

O Grupo Computacional RaspberryPi constitui a unidade responsável pelo processamento principal do sistema durante o funcionamento normal.

Entre as suas responsabilidades incluem-se:

- coordenação global do sistema;
- execução da missão;
- navegação;
- guiamento;
- controlo superior;
- gestão dos restantes grupos computacionais.

O exercício destas responsabilidades ocorre sempre dentro dos limites impostos pela arquitetura de segurança do Aerus.

---

# 10. Arquitetura de Segurança

A segurança do sistema é assegurada pelo Grupo Computacional ESP32-FS.

Este grupo executa continuamente funções próprias de monitorização e avaliação da segurança da aeronave.

Sempre que considere existir risco suficiente para comprometer a segurança da operação, poderá assumir a autoridade prevista pela arquitetura do sistema.

As responsabilidades específicas deste grupo encontram-se definidas nas especificações da área SEC.

---

# 11. Controlo de Emergência

O Grupo Computacional ESP32-FS_A constitui a unidade responsável pela execução dos comandos de emergência durante situações de FailSafe ou FailSecure.

Este grupo permanece preparado para assumir o controlo dos atuadores críticos sempre que ativado pelo Grupo Computacional ESP32-FS.

Durante o funcionamento normal, o Grupo Computacional ESP32-FS_A permanece inativo relativamente ao controlo da aeronave.

---

# 12. Independência Física

Cada grupo computacional deverá possuir o maior grau possível de independência relativamente aos restantes.

Sempre que possível, falhas internas de um determinado grupo não deverão impedir o funcionamento dos restantes grupos computacionais.

Esta independência constitui um dos princípios fundamentais da arquitetura hardware do Aerus.

---

# 13. Interfaces Físicas

A comunicação entre grupos computacionais é efetuada através de interfaces físicas apropriadas às necessidades do sistema.

A arquitetura não impõe nesta especificação qualquer tecnologia específica de comunicação, sendo a sua definição efetuada nas respetivas especificações de hardware e comunicações.

---

# 14. Evolução da Arquitetura

A arquitetura hardware do Aerus foi concebida para permitir a evolução dos diferentes grupos computacionais de forma independente.

Alterações ao hardware utilizado por um grupo computacional não deverão obrigar à reformulação da arquitetura global do sistema, desde que sejam mantidas as respetivas responsabilidades funcionais e interfaces definidas.

---

# 15. Referências

SYS-001 — Visão Geral do Sistema
SYS-002 — Arquitetura Computacional
SYS-003 — Arquitetura Software
SYS-005 — Fluxo Global de Informação
HW — Especificações de Hardware
COM — Especificações de Comunicações
SEC — Especificações de Segurança
ACT — Especificações de Atuadores
SEN — Especificações de Sensores