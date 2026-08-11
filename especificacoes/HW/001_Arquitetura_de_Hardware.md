# HW-001 — Arquitetura_de_Hardware

| Campo             | Valor                     |
| ----------------- | ------------------------- |
| **Código**        | HW-001                    |
| **Título**        | Arquitetura de Hardware   |
| **Versão**        | 1.0                       |
| **Estado**        | Em Desenvolvimento        |
| **Autor**         | ShegaPT                   |
| **Classificação** | Especificação de Hardware |

---

# 1. Objetivo

O presente documento define a arquitetura física geral do sistema Aerus.

A arquitetura de hardware do Aerus foi concebida como uma arquitetura computacional distribuída, constituída por vários grupos computacionais independentes, com responsabilidades distintas e complementares.

O objetivo desta distribuição é permitir que aquisição de dados, processamento, controlo e segurança sejam realizados em domínios computacionais separados, reduzindo a dependência de um único elemento físico e permitindo que cada domínio seja dimensionado de acordo com as suas necessidades.

---

# 2. Princípio de Arquitetura Distribuída

O Aerus não deverá depender de um único computador responsável por todas as funções.

As funções do sistema são distribuídas por diferentes grupos computacionais, permitindo separar:

* processamento geral;
* aquisição de sensores;
* controlo de atuadores;
* segurança;
* controlo mínimo de emergência.

Esta separação permite que uma falha num determinado domínio não implique automaticamente a perda de todas as capacidades da aeronave.

---

# 3. Grupos Computacionais

A arquitetura inicial do Aerus é constituída pelos seguintes grupos computacionais:

```text
RaspberryPi
ESP32-S
ESP32-A
ESP32-FS
ESP32-FS_A
```

Estes grupos constituem o conjunto mínimo inicial da arquitetura.

A existência destes grupos é obrigatória na arquitetura atual, mas não limita a possibilidade de serem adicionados novos grupos computacionais em versões futuras.

---

# 4. Natureza dos Grupos Computacionais

Um grupo computacional não deverá ser interpretado como necessariamente correspondente a um único dispositivo físico.

Um grupo poderá ser constituído por um ou vários elementos computacionais.

Por exemplo:

```text
ESP32-S
│
├── ESP32-S_01
├── ESP32-S_02
├── ESP32-S_03
└── ...
```

A quantidade e distribuição dos elementos dependerá principalmente da configuração da aeronave, da quantidade de sensores, da distribuição física dos equipamentos e das necessidades de processamento.

O mesmo princípio aplica-se aos restantes grupos quando tecnicamente aplicável.

---

# 5. Grupo Computacional RaspberryPi

O Grupo Computacional RaspberryPi constitui o principal domínio de processamento e orquestração do Aerus durante a operação normal.

A sua função geral inclui:

* coordenação dos diferentes módulos;
* gestão da missão;
* processamento de informação;
* execução dos cálculos necessários ao seu domínio;
* gestão dos comandos de voo;
* comunicação com os restantes grupos;
* gestão dos modos e estados dentro das suas competências;
* disponibilização de informação à GroundStation;
* gestão geral da operação normal.

A designação `RaspberryPi` identifica o grupo computacional e não constitui uma obrigação permanente relativamente ao hardware físico utilizado.

A implementação poderá futuramente utilizar outro hardware computacional com capacidade equivalente ou superior sem alterar o conceito arquitetónico do grupo.

---

# 6. Grupo Computacional ESP32-S

O Grupo Computacional ESP32-S é responsável pela aquisição e processamento primário dos dados provenientes dos sensores.

As suas funções incluem:

* aquisição de dados;
* conversão dos sinais provenientes dos sensores;
* processamento primário;
* aplicação dos cálculos necessários ao domínio;
* validação preliminar dos dados;
* organização dos dados;
* preparação das mensagens destinadas aos restantes grupos.

Um grupo ESP32-S poderá possuir vários microcontroladores, permitindo distribuir fisicamente os sensores pela aeronave.

Cada elemento do grupo deverá possuir os recursos necessários para cumprir as frequências de aquisição dos periféricos que lhe estejam associados.

---

# 7. Grupo Computacional ESP32-A

O Grupo Computacional ESP32-A é responsável pelo processamento final associado ao controlo dos atuadores.

As suas funções incluem:

* receção dos comandos de controlo;
* conversão e processamento final dos comandos;
* aplicação das transformações necessárias;
* controlo dos atuadores;
* aquisição de *feedback* dos atuadores;
* disponibilização do estado dos atuadores;
* execução das funções necessárias à interface física com os atuadores.

O RaspberryPi fornece os comandos de voo ao ESP32-A durante a operação normal.

O ESP32-A não recebe comandos normais de controlo de voo provenientes do ESP32-FS.

O ESP32-FS apenas poderá enviar ao ESP32-A a ordem necessária para o inibir durante uma situação de emergência.

---

# 8. Grupo Computacional ESP32-FS

O Grupo Computacional ESP32-FS constitui o domínio de segurança do Aerus e possui a maior autoridade hierárquica do sistema.

A sua função é monitorizar continuamente a condição da aeronave e avaliar autonomamente situações que possam comprometer a segurança.

O ESP32-FS recebe informação proveniente dos restantes domínios necessários à sua avaliação, incluindo:

* dados dos sensores e resultados preliminares provenientes do ESP32-S;
* *feedback* de posição, rotação e outros dados provenientes do ESP32-A;
* estados relevantes do RaspberryPi.

O ESP32-FS executa os seus próprios cálculos independentemente do RaspberryPi.

A sua decisão não depende obrigatoriamente da decisão tomada pelo RaspberryPi.

---

# 9. Grupo Computacional ESP32-FS_A

O Grupo Computacional ESP32-FS_A constitui o domínio físico de atuação associado ao ESP32-FS.

Este grupo possui capacidade mínima necessária para permitir ao ESP32-FS controlar diretamente os atuadores indispensáveis à execução de uma resposta de emergência.

O ESP32-FS_A não constitui um segundo sistema de controlo de voo completo.

A sua função principal é converter as ordens básicas provenientes do ESP32-FS em sinais físicos apropriados aos atuadores.

Entre os atuadores potencialmente abrangidos encontram-se:

* ailerons;
* elevons;
* leme;
* motores;
* outros atuadores considerados necessários para uma aterragem segura.

A definição final dos atuadores sob controlo de emergência deverá ser estabelecida em documentação específica posterior.

---

# 10. Separação de Responsabilidades

Os grupos computacionais deverão possuir responsabilidades distintas.

A distribuição geral é:

```text
RaspberryPi
    │
    ├── Orquestração
    ├── Processamento geral
    ├── Missão
    └── Controlo normal

ESP32-S
    │
    ├── Aquisição
    ├── Conversão
    └── Processamento primário

ESP32-A
    │
    ├── Processamento final
    ├── Controlo
    └── Atuadores

ESP32-FS
    │
    ├── Segurança
    ├── Monitorização independente
    └── Decisão de emergência

ESP32-FS_A
    │
    └── Atuação mínima de emergência
```

Esta separação deverá ser preservada mesmo quando um determinado grupo seja constituído por vários elementos físicos.

---

# 11. Independência entre Domínios

Cada grupo deverá possuir o menor grau de dependência possível relativamente aos restantes.

A existência de comunicação entre dois grupos deverá ter uma finalidade funcional definida.

Nenhum grupo deverá aceder deliberadamente a informação pertencente a outro domínio sem uma razão operacional válida.

Quando a informação necessária já esteja disponível através do fluxo normal do sistema, deverá ser utilizado esse fluxo em vez de criar uma dependência direta adicional.

---

# 12. Redundância Funcional

A arquitetura permite que diferentes grupos executem cálculos relacionados com a mesma condição da aeronave.

Esta característica é particularmente relevante para o ESP32-FS.

O ESP32-FS deverá possuir capacidade suficiente para efetuar uma avaliação independente das condições relevantes para a segurança, utilizando os dados disponíveis no seu próprio domínio de processamento.

Desta forma, a decisão de segurança não depende exclusivamente do resultado produzido pelo RaspberryPi.

---

# 13. Autoridade de Hardware

A arquitetura de hardware deve ser distinguida da arquitetura de fluxo de dados.

A existência de uma ligação física entre dois grupos não implica que um grupo possua autoridade sobre o outro.

A autoridade é determinada pelas regras funcionais e de segurança definidas pelo sistema.

De forma geral:

```text
                    ESP32-FS
                       │
          ┌────────────┴────────────┐
          │                         │
     RaspberryPi                ESP32-FS_A
          │
     ┌────┴────┐
     │         │
 ESP32-S     ESP32-A
```

Este esquema representa apenas a relação geral de autoridade e não constitui uma representação das ligações físicas ou do fluxo de dados.

---

# 14. Arquitetura Física Distribuída

A distribuição física dos elementos deverá considerar a localização dos sensores, atuadores e restantes periféricos.

Não é necessário que todos os elementos de um mesmo grupo estejam fisicamente concentrados num único ponto.

Por exemplo, múltiplos elementos ESP32-S poderão ser instalados em diferentes regiões da aeronave para reduzir:

* comprimento das ligações dos sensores;
* interferências;
* complexidade da cablagem;
* quantidade de sinais analógicos transportados por longas distâncias;
* carga sobre um único microcontrolador.

A distribuição concreta será definida em `HW-003`.

---

# 15. Comunicação entre Grupos

Os grupos computacionais comunicam através de interfaces físicas dedicadas.

A arquitetura atual utiliza UART como meio de comunicação entre os diferentes grupos computacionais.

A comunicação lógica é estruturada através de um protocolo baseado em TLV.

O protocolo e as regras completas de comunicação são definidos em `COM/`.

Este documento define apenas a existência da separação física entre os domínios.

---

# 16. Sensores

Na arquitetura atual, os sensores são ligados diretamente ao Grupo Computacional ESP32-S.

O ESP32-S é responsável pela aquisição e processamento primário dos dados.

A arquitetura deverá, contudo, permitir que futuramente determinados sensores possam ser ligados diretamente ao ESP32-FS caso seja determinada a necessidade dessa alteração.

Essa possibilidade não constitui um requisito da implementação atual.

---

# 17. Atuadores

Os atuadores utilizados no funcionamento normal da aeronave são controlados através do Grupo Computacional ESP32-A.

O ESP32-A deverá possuir capacidade de obter *feedback* dos atuadores quando este estiver disponível.

O *feedback* poderá assumir diferentes formas dependendo do atuador.

Exemplos incluem:

* posição;
* rotação;
* estado;
* resposta elétrica;
* carga;
* outros parâmetros disponibilizados pelo próprio atuador ou pelo respetivo controlador.

Durante uma situação de emergência, o ESP32-FS poderá inibir o controlo normal do ESP32-A e assumir, através do ESP32-FS_A, o controlo do conjunto mínimo de atuadores necessário à execução da resposta de segurança.

---

# 18. Segurança Física

O domínio ESP32-FS deverá permanecer suficientemente independente dos restantes grupos para permitir a execução das suas funções de segurança mesmo perante falhas no sistema de controlo normal.

A arquitetura deverá evitar que uma falha exclusivamente no RaspberryPi impeça o ESP32-FS de executar a sua função.

Da mesma forma, uma falha num domínio de aquisição ou controlo deverá ser detetável sempre que os dados necessários à sua deteção estejam disponíveis.

Os mecanismos específicos de segurança são definidos em `SEC/`.

---

# 19. Expansibilidade

A arquitetura deverá permitir a introdução de:

* novos elementos computacionais;
* novos sensores;
* novos atuadores;
* novos periféricos;
* novos grupos computacionais;
* novos mecanismos de redundância.

A introdução de novos elementos não deverá exigir a alteração dos princípios fundamentais da arquitetura distribuída.

---

# 20. Configuração por Aeronave

O Aerus deverá ser configurável para diferentes aeronaves de asa fixa.

A configuração poderá determinar:

* quantidade de elementos de cada grupo;
* distribuição física;
* sensores existentes;
* atuadores existentes;
* interfaces utilizadas;
* recursos computacionais;
* parâmetros específicos da aeronave.

A arquitetura não deverá exigir a existência de hardware não utilizado pela configuração selecionada.

---

# 21. Independência do Modelo de Aeronave

O hardware deverá ser definido através de uma arquitetura parametrizável, permitindo equipar diferentes modelos de aeronaves sem criar uma implementação completamente independente para cada modelo.

As diferenças entre aeronaves deverão ser tratadas principalmente através da configuração específica e da seleção dos componentes aplicáveis.

---

# 22. Limites deste Documento

Este documento define apenas a arquitetura geral de hardware.

Não define detalhadamente:

* características elétricas dos componentes;
* pinout;
* alimentação;
* protocolo TLV;
* sensores específicos;
* atuadores específicos;
* fórmulas matemáticas;
* algoritmos de controlo;
* mecanismos detalhados de segurança;
* requisitos de instalação;
* requisitos estruturais.

Esses elementos são definidos nas respetivas especificações.

---

# 23. Referências

- SYS-002 — Arquitetura_Computacional
- SYS-004 — Arquitetura_Hardware
- SYS-005 — Fluxo_Global_de_Informacao
- SYS-006 — Gestao_de_Estados
- SYS-007 — Modos_de_Funcionamento
- SYS-008 — Gestao_Temporal
- HW-002 — Grupos_Computacionais
- HW-003 — Distribuicao_de_Hardware
- HW-004 — Interfaces_Eletricas
- HW-005 — Alimentacao_e_Distribuicao_de_Energia
- HW-006 — Interfaces_de_Comunicacao
- HW-007 — Interfaces_de_Perifericos
- HW-008 — Redundancia_e_Isolamento_de_Hardware
- HW-009 — Expansibilidade_e_Configuracao_de_Hardware
- COM — Especificações de Comunicações
- SEN — Especificações de Sensores
- ACT — Especificações de Atuadores
- SEC — Especificações de Segurança
