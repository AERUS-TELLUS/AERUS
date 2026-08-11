# HW-002 — Grupos_Computacionais

| Campo             | Valor                     |
| ----------------- | ------------------------- |
| **Código**        | HW-002                    |
| **Título**        | Grupos Computacionais     |
| **Versão**        | 1.0                       |
| **Estado**        | Em Desenvolvimento        |
| **Autor**         | ShegaPT                   |
| **Classificação** | Especificação de Hardware |

---

# 1. Objetivo

O presente documento define o conceito de Grupo Computacional utilizado na arquitetura de hardware do Aerus e estabelece as responsabilidades e características dos grupos computacionais que constituem a arquitetura inicial do sistema.

O conceito de Grupo Computacional permite separar uma responsabilidade lógica do hardware físico que a executa.

Um grupo poderá ser constituído por um ou vários elementos computacionais, dependendo das necessidades da aeronave e da distribuição dos respetivos periféricos.

---

# 2. Conceito de Grupo Computacional

Um Grupo Computacional é uma unidade lógica e funcional da arquitetura do Aerus constituída por um ou mais elementos computacionais que partilham uma responsabilidade arquitetónica comum.

O Grupo Computacional não corresponde obrigatoriamente a:

* um processador;
* um microcontrolador;
* uma placa;
* um computador;
* uma localização física única.

A quantidade de elementos físicos pertencentes a um grupo depende da configuração concreta da aeronave.

---

# 3. Elementos de um Grupo

Um grupo poderá possuir um único elemento ou vários elementos.

Exemplo:

```text
ESP32-S
│
├── Elemento 01
├── Elemento 02
├── Elemento 03
└── Elemento 04
```

Todos os elementos pertencem ao mesmo domínio funcional, mas poderão possuir diferentes periféricos associados.

A distribuição deverá ser determinada de acordo com:

* quantidade de periféricos;
* localização física;
* requisitos temporais;
* capacidade de processamento;
* necessidades de comunicação;
* requisitos de redundância;
* características da aeronave.

---

# 4. Grupos Computacionais Obrigatórios

A arquitetura inicial do Aerus define cinco grupos computacionais obrigatórios:

```text
RaspberryPi
ESP32-S
ESP32-A
ESP32-FS
ESP32-FS_A
```

Estes grupos representam as responsabilidades mínimas atualmente definidas para o sistema.

A arquitetura não impede a introdução futura de novos grupos computacionais.

---

# 5. Grupo Computacional RaspberryPi

## 5.1 Função

O Grupo Computacional RaspberryPi constitui o principal domínio computacional de operação normal do Aerus.

É responsável pela coordenação geral do sistema durante a operação normal e executa os módulos necessários à gestão da missão, processamento e controlo.

---

## 5.2 Responsabilidades

Entre as suas responsabilidades encontram-se:

* orquestração do sistema;
* gestão da missão;
* processamento de informação;
* execução dos cálculos atribuídos ao domínio;
* gestão dos comandos de voo;
* gestão dos módulos;
* gestão dos modos dentro das suas competências;
* comunicação com os restantes grupos;
* disponibilização de informação à GroundStation;
* coordenação das funções de operação normal.

---

## 5.3 Natureza do Hardware

A designação `RaspberryPi` identifica o Grupo Computacional e não estabelece que o sistema tenha obrigatoriamente de utilizar um Raspberry Pi específico.

O grupo poderá ser constituído por:

* um único computador;
* vários computadores;
* uma arquitetura distribuída;
* um cluster;
* outro hardware computacional com capacidade adequada.

A alteração do hardware físico não deverá alterar a responsabilidade lógica atribuída ao grupo.

---

# 6. Grupo Computacional ESP32-S

## 6.1 Função

O Grupo Computacional ESP32-S é responsável pela aquisição dos dados dos sensores e pelo processamento primário desses dados.

---

## 6.2 Estrutura

O ESP32-S poderá ser constituído por um ou vários microcontroladores.

Exemplo:

```text
ESP32-S
│
├── ESP32-S_01
│   ├── Sensores
│   └── Aquisição
│
├── ESP32-S_02
│   ├── Sensores
│   └── Aquisição
│
└── ESP32-S_03
    ├── Sensores
    └── Aquisição
```

A quantidade de elementos não é fixa.

---

## 6.3 Responsabilidades

O grupo é responsável por:

* aquisição de sensores;
* conversão de sinais;
* processamento primário;
* aplicação dos cálculos necessários ao domínio;
* validação preliminar;
* organização dos dados;
* preparação dos dados para transmissão.

Cada elemento deverá cumprir as necessidades temporais dos periféricos que lhe estejam atribuídos.

---

## 6.4 Distribuição Física

A utilização de vários elementos permite colocar capacidade de aquisição próxima dos sensores.

Esta distribuição poderá reduzir:

* comprimento das ligações;
* quantidade de cablagem;
* transporte de sinais analógicos a longa distância;
* interferências;
* carga sobre um único microcontrolador.

---

# 7. Grupo Computacional ESP32-A

## 7.1 Função

O Grupo Computacional ESP32-A é responsável pela conversão final dos comandos de voo e pelo controlo físico dos atuadores durante a operação normal.

---

## 7.2 Estrutura

O grupo poderá ser constituído por um ou vários microcontroladores.

A distribuição dependerá da quantidade, localização e características dos atuadores da aeronave.

---

## 7.3 Responsabilidades

O ESP32-A é responsável por:

* receber comandos de controlo do RaspberryPi;
* processar os comandos recebidos;
* aplicar as conversões necessárias;
* controlar os atuadores;
* obter *feedback* dos atuadores quando disponível;
* disponibilizar informação sobre o estado dos atuadores.

---

## 7.4 Comandos Provenientes do ESP32-FS

O ESP32-A não recebe comandos normais de controlo de voo provenientes do ESP32-FS.

O ESP32-FS apenas poderá enviar ao ESP32-A a ordem necessária para inibir o seu controlo durante uma situação de emergência.

O controlo de emergência dos atuadores é realizado através do Grupo Computacional ESP32-FS_A.

---

# 8. Grupo Computacional ESP32-FS

## 8.1 Função

O Grupo Computacional ESP32-FS constitui o domínio computacional de segurança do Aerus.

Possui a maior autoridade hierárquica do sistema.

---

## 8.2 Independência

O ESP32-FS executa as suas próprias avaliações de segurança independentemente do RaspberryPi.

Não depende da decisão do RaspberryPi para determinar se uma condição representa uma ameaça à segurança.

---

## 8.3 Dados Recebidos

O ESP32-FS poderá receber informação proveniente dos restantes grupos necessária à sua avaliação.

Entre esta informação encontram-se:

* valores dos sensores;
* resultados preliminares dos cálculos do ESP32-S;
* *feedback* de posição;
* *feedback* de rotação;
* *feedback* dos atuadores;
* estados relevantes;
* informação proveniente do RaspberryPi.

A informação recebida deverá ser suficiente para permitir ao ESP32-FS efetuar a sua própria avaliação da condição da aeronave.

---

## 8.4 Relação com RaspberryPi

RaspberryPi e ESP32-FS funcionam de forma independente relativamente à avaliação de segurança.

O RaspberryPi poderá solicitar a entrada em condições de FailSafe/FailSecure.

O ESP32-FS deverá avaliar autonomamente a solicitação antes de a aceitar.

Uma solicitação do RaspberryPi não constitui automaticamente uma ordem obrigatória para o ESP32-FS.

O ESP32-FS poderá aceitar ou recusar a solicitação de acordo com os dados disponíveis e as regras de segurança.

---

# 9. Grupo Computacional ESP32-FS_A

## 9.1 Função

O Grupo Computacional ESP32-FS_A constitui o domínio físico de atuação associado ao ESP32-FS.

A sua função é permitir ao ESP32-FS controlar o conjunto mínimo de atuadores necessário para uma resposta de emergência.

---

## 9.2 Operação

O ESP32-FS_A apenas deverá operar no contexto de FailSafe/FailSecure.

Durante a operação normal, o controlo dos atuadores permanece sob responsabilidade do ESP32-A.

---

## 9.3 Comandos

O ESP32-FS_A recebe ordens diretamente do ESP32-FS.

Não executa os cálculos de navegação, controlo ou segurança necessários para determinar a resposta de emergência.

A sua função é executar fisicamente os comandos básicos recebidos.

---

## 9.4 Conversão

O ESP32-FS_A poderá converter comandos básicos em sinais físicos apropriados aos atuadores.

Exemplos incluem:

* PWM;
* sinais digitais;
* outras interfaces de atuação aplicáveis.

A interface concreta de cada atuador é definida nas especificações correspondentes.

---

# 10. Separação Funcional

Os cinco grupos possuem responsabilidades distintas:

| Grupo       | Responsabilidade principal                          |
| ----------- | --------------------------------------------------- |
| RaspberryPi | Orquestração e operação normal                      |
| ESP32-S     | Aquisição e processamento primário                  |
| ESP32-A     | Processamento final e controlo normal dos atuadores |
| ESP32-FS    | Segurança e decisão de emergência                   |
| ESP32-FS_A  | Atuação mínima de emergência                        |

Esta separação não significa que os grupos funcionem isoladamente.

Todos contribuem para o funcionamento global do Aerus.

---

# 11. Independência Funcional

Cada grupo deverá possuir autonomia suficiente para executar as funções que lhe são atribuídas sem depender desnecessariamente de outros grupos.

A comunicação entre grupos deverá existir quando necessária à execução das respetivas responsabilidades.

A independência funcional não impede a partilha de informação necessária.

---

# 12. Comunicação Interna ao Grupo

Quando um grupo possuir vários elementos físicos, estes deverão funcionar como partes do mesmo domínio funcional.

A distribuição interna deverá permitir:

* partilha dos dados necessários;
* sincronização;
* distribuição de tarefas;
* coordenação;
* monitorização.

Os mecanismos concretos de comunicação interna serão definidos nas especificações de comunicação e hardware correspondentes.

---

# 13. Biblioteca Matemática

Cada domínio computacional que necessite de cálculos matemáticos deverá possuir a sua própria implementação da biblioteca matemática aplicável.

Quando um grupo for constituído por vários elementos computacionais, cada elemento poderá possuir uma cópia da biblioteca correspondente ao domínio.

Exemplo:

```text
ESP32-S
│
├── ESP32-S_01 → Biblioteca MAT-ESP32-S
├── ESP32-S_02 → Biblioteca MAT-ESP32-S
└── ESP32-S_03 → Biblioteca MAT-ESP32-S
```

O objetivo é permitir que cada elemento tenha acesso direto às funções necessárias sem depender de uma biblioteca matemática centralizada.

A definição das fórmulas e da arquitetura matemática é realizada em `MAT/`.

---

# 14. Gestão de Recursos

Cada elemento computacional deverá utilizar os recursos disponíveis de acordo com as necessidades do seu grupo.

Os módulos que não sejam necessários durante determinado modo ou estado poderão ser suspensos ou desativados, permitindo utilizar os recursos computacionais disponíveis para funções prioritárias.

Esta gestão deverá respeitar as políticas definidas para cada módulo.

---

# 15. Independência de Modelo

Os grupos computacionais deverão ser configuráveis para diferentes modelos de aeronave.

A quantidade de elementos pertencentes a cada grupo poderá variar entre configurações.

Exemplo:

```text
Aeronave A

ESP32-S → 2 elementos
ESP32-A → 2 elementos
RaspberryPi → 1 elemento


Aeronave B

ESP32-S → 5 elementos
ESP32-A → 3 elementos
RaspberryPi → 2 elementos
```

A estrutura lógica dos grupos permanece a mesma.

---

# 16. Configuração Pré-Compilação

A configuração específica de uma aeronave deverá ser determinada antes da compilação do Aerus.

A configuração poderá definir:

* quantidade de elementos;
* distribuição de funções;
* periféricos existentes;
* parâmetros;
* recursos utilizados;
* características específicas da aeronave.

O objetivo é manter o código parametrizado, evitando a criação de uma implementação completamente independente para cada aeronave.

---

# 17. Expansão da Arquitetura

A arquitetura deverá permitir a introdução de novos grupos computacionais quando novas necessidades forem identificadas.

A introdução de um novo grupo deverá definir explicitamente:

* responsabilidade;
* autoridade;
* interfaces;
* dependências;
* requisitos temporais;
* requisitos de segurança;
* relação com os grupos existentes.

A existência futura de novos grupos não invalida os cinco grupos obrigatórios atualmente definidos.

---

# 18. Relação com a Arquitetura de Autoridade

A existência de um grupo computacional não determina, por si só, autoridade sobre os restantes grupos.

A autoridade deverá ser determinada pelas regras do sistema.

A arquitetura atual estabelece:

```text
                    ESP32-FS
                       │
              ┌────────┴────────┐
              │                 │
         RaspberryPi        ESP32-FS_A
              │
         ┌────┴────┐
         │         │
     ESP32-S     ESP32-A
```

Este esquema representa apenas a hierarquia geral de autoridade.

Não representa a topologia de comunicação, fluxo de dados ou ligações físicas.

---

# 19. Limites do Documento

Este documento não define:

* componentes físicos específicos;
* modelos de microcontroladores;
* modelos de computadores;
* pinouts;
* alimentação;
* topologia UART;
* protocolo TLV;
* sensores específicos;
* atuadores específicos;
* fórmulas matemáticas;
* algoritmos de controlo;
* regras de segurança detalhadas.

Esses elementos serão definidos nas respetivas especificações.

---

# 20. Referências

- HW-001 — Arquitetura_de_Hardware
- HW-003 — Distribuicao_de_Hardware
- HW-004 — Interfaces_Eletricas
- HW-005 — Alimentacao_e_Distribuicao_de_Energia
- HW-006 — Interfaces_de_Comunicacao
- HW-007 — Interfaces_de_Perifericos
- HW-008 — Redundancia_e_Isolamento_de_Hardware
- HW-009 — Expansibilidade_e_Configuracao_de_Hardware
- SYS-002 — Arquitetura_Computacional
- SYS-005 — Fluxo_Global_de_Informacao
- SYS-006 — Gestao_de_Estados
- SYS-007 — Modos_de_Funcionamento
- MAT — Especificações Matemáticas
- COM — Especificações de Comunicações
- SEC — Especificações de Segurança
