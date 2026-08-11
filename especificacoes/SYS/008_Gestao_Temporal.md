# SYS-008 — Gestao_Temporal

| Campo             | Valor                    |
| ----------------- | ------------------------ |
| **Código**        | SYS-008                  |
| **Título**        | Gestão Temporal          |
| **Versão**        | 1.0                      |
| **Estado**        | Em Desenvolvimento       |
| **Autor**         | ShegaPT                  |
| **Classificação** | Especificação de Sistema |

---

# 1. Objetivo

O presente documento define os princípios e a arquitetura temporal global do sistema Aerus.

São estabelecidos os mecanismos gerais de sincronização temporal, referência temporal, contagem de tempo, aquisição periódica, comunicação periódica e coordenação temporal entre os diferentes grupos computacionais.

As políticas temporais específicas dos módulos de software, incluindo prioridades, *deadlines*, *timeouts*, recuperação e tratamento de atrasos, são definidas nas especificações da área SW.

---

# 2. Princípios Gerais

A arquitetura temporal do Aerus baseia-se nos seguintes princípios:

* sincronização distribuída;
* referência temporal comum;
* utilização de múltiplas referências temporais;
* periodicidade configurável;
* independência temporal dos periféricos;
* separação entre aquisição e comunicação;
* estabilidade temporal;
* deteção de atrasos;
* tolerância controlada a variações temporais;
* prioridade da segurança.

O sistema deverá manter uma referência temporal suficientemente consistente entre os diferentes grupos computacionais para permitir a correlação dos dados, execução dos cálculos e análise posterior dos acontecimentos.

---

# 3. Referência Temporal

O Aerus utiliza uma arquitetura temporal sincronizada entre os diferentes grupos computacionais.

O Grupo Computacional RaspberryPi e o Grupo Computacional ESP32-FS estabelecem inicialmente uma referência temporal comum.

Após esta sincronização inicial:

1. ESP32-S sincroniza com a referência estabelecida por RaspberryPi e ESP32-FS;
2. ESP32-A sincroniza com a referência estabelecida por RaspberryPi e ESP32-FS;
3. ESP32-FS_A sincroniza com ESP32-FS.

Desta forma, os diferentes grupos computacionais mantêm uma referência temporal coerente, permitindo a correlação dos acontecimentos provenientes de diferentes domínios.

---

# 4. Sincronização Inicial

A sincronização temporal entre RaspberryPi e ESP32-FS deverá ocorrer durante a inicialização do sistema.

Esta sincronização estabelece a referência temporal comum utilizada pelos dois grupos computacionais durante a operação.

Os restantes grupos computacionais apenas deverão considerar a sua referência temporal válida após concluírem o respetivo processo de sincronização.

Os mecanismos técnicos utilizados para a sincronização são definidos na especificação COM.

---

# 5. Redundância Temporal

A arquitetura temporal não depende exclusivamente de um único grupo computacional após a sincronização inicial.

RaspberryPi e ESP32-FS mantêm referências temporais sincronizadas e utilizam-nas independentemente nas respetivas funções.

Esta característica permite que o ESP32-FS continue a efetuar as suas funções de segurança sem depender da execução contínua do RaspberryPi.

---

# 6. Domínios Temporais

O Aerus utiliza diferentes referências temporais para diferentes finalidades.

Entre estas encontram-se:

* tempo UTC;
* tempo desde a inicialização;
* tempo desde o arranque;
* tempo de missão;
* tempo de voo;
* tempo desde entrada num modo;
* tempo desde alteração de estado;
* tempo desde comunicação;
* tempo desde aquisição de dados;
* tempo desde ocorrência de eventos.

Cada referência temporal deverá possuir uma finalidade claramente definida.

---

# 7. Tempo UTC

O tempo UTC deverá estar disponível no sistema sempre que exista uma referência válida.

O timestamp UTC deverá ser associado aos dados cuja rastreabilidade temporal seja necessária, incluindo, quando aplicável:

* dados de sensores;
* eventos;
* estados;
* alertas;
* alarmes;
* comandos;
* alterações de modo;
* registos de missão;
* dados destinados a auditoria;
* telemetria disponibilizada à GroundStation.

A disponibilidade de UTC não deverá constituir uma dependência obrigatória para o funcionamento das funções de controlo de voo.

---

# 8. Tempo Monotónico

O sistema deverá utilizar referências temporais monotónicas para cálculos dependentes de intervalos de tempo.

Estas referências deverão ser independentes de alterações do relógio UTC.

São exemplos de aplicações:

* medição de períodos;
* determinação de *timeouts*;
* cálculo de *deadlines*;
* medição de latências;
* controlo de frequências;
* deteção de perda de comunicação;
* cálculo de duração de estados;
* cálculo de duração de modos.

---

# 9. Tempo Operacional

O Aerus deverá disponibilizar referências temporais relativas ao funcionamento da aeronave.

Entre estas encontram-se:

### Tempo desde inicialização

Tempo decorrido desde o início do processo de inicialização do sistema.

### Tempo desde arranque

Tempo decorrido desde o arranque operacional da aeronave.

### Tempo de missão

Tempo decorrido desde o início da missão.

### Tempo de voo

Tempo correspondente ao período de voo da aeronave.

### Tempo no modo atual

Tempo decorrido desde a entrada no modo operacional atual.

### Tempo no estado atual

Tempo decorrido desde a última alteração do estado relevante.

Estas referências deverão estar disponíveis para utilização interna e, quando aplicável, para apresentação na GroundStation.

---

# 10. Frequência dos Periféricos

Cada sensor e atuador poderá possuir uma frequência operacional própria.

A frequência deverá ser definida individualmente para cada periférico de acordo com as suas características e necessidades funcionais.

O grupo computacional responsável deverá garantir o cumprimento da frequência definida para cada periférico.

A frequência de aquisição de um periférico não deverá ser confundida com a frequência de comunicação entre grupos computacionais.

---

# 11. Frequência de Aquisição

O Grupo Computacional ESP32-S deverá executar a aquisição dos diferentes sensores de acordo com as frequências individuais definidas para cada sensor.

Diferentes sensores poderão, portanto, ser adquiridos a frequências diferentes e independentemente uns dos outros.

Os dados adquiridos poderão ser temporariamente acumulados e processados internamente pelo ESP32-S antes da sua transmissão.

---

# 12. Frequência de Comunicação

A comunicação entre grupos computacionais possui uma frequência própria, independente das frequências individuais dos periféricos.

O Grupo Computacional ESP32-S poderá, por exemplo, adquirir dados de um determinado sensor a uma frequência superior à frequência utilizada para comunicação com os restantes grupos computacionais.

Nesse caso, os dados adquiridos são acumulados, processados e organizados internamente, sendo posteriormente transmitidos de acordo com a frequência de comunicação definida.

Esta separação permite reduzir tráfego desnecessário sem diminuir a frequência de aquisição necessária ao processamento local.

---

# 13. Frequência dos Módulos

Os módulos de software poderão possuir frequências de execução diferentes.

A frequência de execução de um módulo poderá depender de:

* modo operacional;
* estado do sistema;
* criticidade da função;
* disponibilidade de recursos;
* necessidade operacional.

A alteração da frequência de execução não deverá comprometer a estabilidade temporal dos restantes módulos.

As frequências e políticas específicas de cada módulo são definidas nas especificações da área SW.

---

# 14. Modelo Temporal de Execução

O Aerus deverá utilizar um modelo temporal estável capaz de manter o funcionamento previsível perante pequenas variações na ocorrência de eventos.

O sistema deverá, simultaneamente, permanecer preparado para alterações de:

* modo;
* estado;
* carga computacional;
* eventos;
* condições operacionais.

As alterações relevantes poderão desencadear procedimentos temporais diferentes dos utilizados durante a operação estável.

---

# 15. Execução Periódica e Orientada a Eventos

A arquitetura temporal suporta simultaneamente execução periódica e mecanismos orientados a eventos.

A execução periódica é utilizada quando uma função necessita de uma frequência temporal definida.

A execução orientada a eventos é utilizada quando uma função deverá responder à ocorrência de uma condição ou acontecimento específico.

A utilização de eventos não deverá comprometer a estabilidade temporal das funções periódicas críticas.

---

# 16. Atrasos Temporais

O sistema deverá detetar situações em que uma operação não seja concluída dentro da sua janela temporal prevista.

Um atraso deverá ser registado e avaliado de acordo com a criticidade da função afetada.

A existência de um atraso não deverá, por si só, determinar uma ação universal para todos os módulos.

A ação a executar dependerá da política temporal definida para a função correspondente.

---

# 17. Recuperação Temporal

Quando uma execução ultrapassar a janela temporal definida, poderão ser aplicados mecanismos de recuperação.

Dependendo da criticidade da função, estes poderão incluir:

* permitir a conclusão da execução;
* repetir a operação;
* registar o atraso;
* abandonar a execução atual;
* avançar para o ciclo seguinte;
* executar uma estratégia degradada;
* desencadear mecanismos de segurança.

As regras concretas são definidas pelas políticas temporais de cada módulo.

---

# 18. Segurança Temporal

A gestão temporal deverá considerar a possibilidade de atrasos, perda de sincronização ou comportamento temporal anómalo como potenciais indicadores de falha.

As funções de segurança deverão poder utilizar informação temporal proveniente dos diferentes grupos computacionais para determinar:

* perda de comunicação;
* ausência de resposta;
* execução atrasada;
* falha de sincronização;
* comportamento temporal anómalo.

A resposta a estas condições é definida nas especificações da área SEC.

---

# 19. Alterações de Modo e Estado

A alteração do modo operacional ou de estados relevantes poderá alterar as necessidades temporais dos módulos.

Quando ocorrer uma alteração deste tipo, os módulos afetados deverão aplicar as políticas temporais correspondentes ao novo contexto operacional.

Esta alteração deverá ocorrer de forma controlada, evitando transições temporais instáveis.

---

# 20. Registo Temporal

As informações temporais relevantes deverão poder ser registadas juntamente com os dados a que correspondem.

O registo deverá permitir, quando aplicável:

* reconstrução cronológica da operação;
* correlação entre sensores;
* correlação entre grupos computacionais;
* análise de eventos;
* análise de falhas;
* auditoria;
* diagnóstico.

---

# 21. GroundStation

As referências temporais relevantes poderão ser disponibilizadas à GroundStation.

Entre os valores que poderão ser apresentados encontram-se:

* UTC;
* tempo desde inicialização;
* tempo desde arranque;
* tempo de missão;
* tempo de voo;
* tempo no modo atual;
* duração de estados;
* informação temporal relevante para diagnóstico.

---

# 22. Evolução

A arquitetura temporal deverá permitir a introdução futura de novos grupos computacionais, periféricos, módulos e mecanismos de sincronização sem alterar os princípios fundamentais definidos nesta especificação.

---

# 23. Referências

- SYS-002 — Arquitetura_Computacional
- SYS-005 — Fluxo_Global_de_Informacao
- SYS-006 — Gestao_de_Estados
- SYS-007 — Modos_de_Funcionamento
- SYS-009 — Arranque_e_Encerramento
- SW — Especificações de Software
- COM — Especificações de Comunicações
- SEN — Especificações de Sensores
- ACT — Especificações de Atuadores
- SEC — Especificações de Segurança
