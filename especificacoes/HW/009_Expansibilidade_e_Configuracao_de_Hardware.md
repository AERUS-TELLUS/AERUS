# HW-009 — Expansibilidade_e_Configuracao_de_Hardware

| Campo             | Valor                                      |
| ----------------- | ------------------------------------------ |
| **Código**        | HW-009                                     |
| **Título**        | Expansibilidade e Configuração de Hardware |
| **Versão**        | 1.0                                        |
| **Estado**        | Em Desenvolvimento                         |
| **Autor**         | ShegaPT                                    |
| **Classificação** | Especificação de Hardware                  |

---

# 1. Objetivo

O presente documento define os princípios utilizados pelo Aerus para permitir diferentes configurações de hardware sem alterar a arquitetura fundamental do sistema.

O Aerus deverá ser concebido como uma plataforma configurável capaz de equipar diferentes aeronaves de asa fixa, com diferentes dimensões, sensores, atuadores, sistemas de propulsão e implementos.

A configuração específica de cada aeronave deverá determinar os elementos físicos efetivamente utilizados.

---

# 2. Princípio de Configurabilidade

O Aerus não deverá ser desenvolvido como um conjunto de versões de software específicas para cada aeronave.

A mesma base de software deverá poder ser configurada para diferentes plataformas através de parâmetros e configurações específicas.

O objetivo é evitar a criação de código independente para cada aeronave quando a diferença entre elas puder ser representada através de configuração.

---

# 3. Configuração Antes da Compilação

Antes da compilação do Aerus deverão ser introduzidas as características específicas da aeronave que irá utilizar o sistema.

Essas informações poderão definir, entre outros elementos:

* sensores existentes;
* atuadores existentes;
* quantidade de elementos computacionais;
* distribuição dos sensores;
* distribuição dos atuadores;
* parâmetros físicos;
* características aerodinâmicas;
* características da propulsão;
* limites operacionais;
* frequências;
* configurações de comunicação;
* parâmetros matemáticos;
* funcionalidades disponíveis.

O resultado será um sistema compilado especificamente para a configuração da aeronave.

---

# 4. Código Paramétrico

Sempre que duas aeronaves diferirem apenas através de parâmetros, o Aerus deverá utilizar código paramétrico em vez de manter implementações independentes.

Exemplo conceptual:

```text
                Aerus
                  │
          ┌───────┴───────┐
          │ Código comum  │
          └───────┬───────┘
                  │
        Configuração da aeronave
           ┌──────┼──────┐
           ▼      ▼      ▼
        Modelo A Modelo B Modelo C
```

A mesma implementação poderá assim operar diferentes configurações físicas.

---

# 5. Grupos Computacionais Variáveis

Os Grupos Computacionais constituem conceitos arquiteturais e não devem ser interpretados como uma quantidade fixa de componentes físicos.

Por exemplo, o Grupo Computacional ESP32-S poderá ser constituído por:

* um ESP32;
* vários ESP32;
* diferentes distribuições de sensores entre os ESP32.

O mesmo princípio aplica-se aos restantes Grupos Computacionais.

---

# 6. Quantidade de Elementos

A quantidade de elementos físicos pertencentes a cada Grupo Computacional deverá ser determinada pela configuração da aeronave.

Exemplo:

```text
Aeronave A

ESP32-S
 └── ESP32-S_01


Aeronave B

ESP32-S
 ├── ESP32-S_01
 ├── ESP32-S_02
 └── ESP32-S_03
```

Ambas continuam a possuir o mesmo Grupo Computacional ESP32-S.

---

# 7. Distribuição de Sensores

A distribuição dos sensores entre os elementos ESP32-S deverá poder variar de acordo com a aeronave.

A configuração deverá permitir determinar qual elemento é responsável por cada sensor.

Exemplo:

```text
              ESP32-S
                 │
       ┌─────────┴─────────┐
       ▼                   ▼
 ESP32-S_01           ESP32-S_02
       │                   │
 ┌─────┼─────┐       ┌─────┼─────┐
 ▼     ▼     ▼       ▼     ▼     ▼
IMU   GPS   BARO    MAG   TEMP   AirData
```

A distribuição deverá procurar reduzir cablagem, interferências e carga individual dos elementos.

---

# 8. Distribuição de Atuadores

Os atuadores deverão igualmente poder ser distribuídos entre diferentes elementos ESP32-A.

A configuração deverá determinar qual elemento controla cada atuador.

Não deverá ser necessário que todos os atuadores sejam controlados por um único microcontrolador.

---

# 9. Expansão do Número de Elementos

A arquitetura deverá permitir adicionar elementos dentro de um Grupo Computacional quando a capacidade de um único elemento deixar de ser suficiente.

A expansão poderá ser necessária devido a:

* aumento do número de sensores;
* aumento do número de atuadores;
* aumento da frequência de aquisição;
* limitações de processamento;
* limitações de entradas/saídas;
* distribuição física da aeronave;
* requisitos de redundância.

---

# 10. Novos Grupos Computacionais

Os cinco Grupos Computacionais atualmente considerados como base inicial constituem o mínimo inicial da arquitetura.

A arquitetura não deverá impedir a criação futura de novos Grupos Computacionais obrigatórios.

A introdução de um novo Grupo deverá ocorrer quando existir uma necessidade funcional, de segurança, processamento, comunicação ou outro requisito que justifique a sua existência.

---

# 11. Evolução da Plataforma

A arquitetura deverá permitir que o hardware utilizado num Grupo Computacional seja alterado ao longo da evolução do projeto.

Por exemplo, um Grupo Computacional atualmente implementado com RaspberryPi poderá futuramente utilizar outro hardware com capacidade equivalente ou superior.

A identidade arquitetural do Grupo não deverá depender do fabricante ou modelo específico do hardware.

Assim, **Grupo Computacional RaspberryPi** representa uma entidade arquitetural, independentemente de qual hardware físico venha futuramente a implementar essa função.

---

# 12. Hardware de Processamento

A substituição do hardware de processamento deverá ser possível desde que o novo hardware cumpra os requisitos funcionais e de desempenho definidos para o respetivo Grupo Computacional.

Exemplos de evolução possíveis incluem:

* alteração de modelo de RaspberryPi;
* utilização de vários RaspberryPi;
* utilização de um sistema computacional equivalente;
* utilização de hardware de maior capacidade;
* utilização de uma arquitetura computacional distribuída.

A decisão concreta deverá ser definida durante o desenvolvimento da plataforma.

---

# 13. Cluster Computacional

Um Grupo Computacional poderá, quando necessário, ser implementado através de vários computadores trabalhando conjuntamente.

Isto não altera necessariamente a identidade do Grupo Computacional.

Por exemplo:

```text
       Grupo Computacional RaspberryPi
                    │
          ┌─────────┼─────────┐
          ▼         ▼         ▼
      Computador  Computador  Computador
          01         02         03
```

A distribuição interna poderá ser utilizada para aumentar capacidade, disponibilidade ou isolamento de funções.

---

# 14. Expansão sem Alteração Conceptual

A adição de elementos dentro de um Grupo Computacional deverá, sempre que possível, ocorrer sem alteração do conceito arquitetural externo.

Os restantes grupos deverão continuar a comunicar com o Grupo Computacional de acordo com as interfaces definidas.

A complexidade interna do grupo deverá permanecer isolada sempre que possível.

---

# 15. Configuração de Periféricos

A configuração da aeronave deverá indicar os periféricos presentes.

Para cada periférico poderão ser definidos parâmetros como:

* identificação;
* tipo;
* interface;
* elemento responsável;
* frequência de aquisição;
* frequência de comunicação;
* limites;
* calibração;
* redundância;
* dependências;
* estado inicial.

---

# 16. Configuração de Sensores

A configuração deverá permitir determinar quais os sensores instalados na aeronave.

Um modelo poderá possuir, por exemplo:

```text
IMU_A
IMU_B
GPS_A
GPS_B
BARO_A
BARO_B
TEMP_A
TEMP_B
```

Enquanto outro modelo poderá possuir uma quantidade diferente.

A ausência ou presença de determinado sensor deverá ser tratada como uma característica de configuração e não como uma versão completamente diferente do Aerus.

---

# 17. Configuração de Atuadores

O mesmo princípio deverá ser aplicado aos atuadores.

Uma aeronave poderá possuir diferentes:

* superfícies de controlo;
* servos;
* motores;
* ESC;
* mecanismos auxiliares;
* atuadores específicos.

A configuração deverá determinar quais os elementos existentes e como são controlados.

---

# 18. Configuração Aerodinâmica

Os parâmetros físicos e aerodinâmicos da aeronave deverão poder ser configurados.

Dependendo do modelo, poderão existir parâmetros relacionados com:

* massa;
* distribuição de massa;
* centro de gravidade;
* dimensões;
* superfícies de controlo;
* características aerodinâmicas;
* propulsão;
* limites de voo;
* outras características necessárias aos cálculos.

Esses parâmetros serão utilizados pelos módulos que necessitem deles.

---

# 19. Configuração da Propulsão

A plataforma deverá permitir diferentes configurações de propulsão.

A configuração deverá poder definir os parâmetros necessários para o controlo e monitorização do sistema de propulsão.

O Aerus não deverá assumir que todas as aeronaves utilizam exatamente o mesmo motor, ESC ou configuração propulsiva.

---

# 20. Configuração de Redundância

A redundância deverá igualmente ser configurável.

Uma determinada aeronave poderá possuir:

* dois sensores equivalentes;
* três sensores equivalentes;
* diferentes elementos ESP32-S;
* diferentes combinações de sensores principais e de segurança.

A configuração deverá informar o sistema sobre a arquitetura física efetivamente instalada.

---

# 21. Configuração do Domínio de Segurança

A existência e configuração dos elementos do domínio de segurança deverão ser definidas explicitamente.

O ESP32-FS constitui uma componente fundamental da arquitetura.

Os sensores diretamente ligados ao ESP32-FS deverão ser definidos de acordo com a configuração da aeronave.

Outros elementos de segurança poderão ser adicionados quando necessário.

---

# 22. Configuração de Comunicação

A configuração deverá permitir determinar as ligações físicas existentes entre os diferentes elementos.

Poderão ser definidos:

* origem;
* destino;
* interface;
* velocidade;
* parâmetros de comunicação;
* prioridade;
* frequência;
* mecanismos de recuperação.

A especificação detalhada do protocolo pertence a `COM/`.

---

# 23. Configuração de Frequências

As frequências deverão poder ser configuradas de forma independente para diferentes periféricos e funções.

Uma configuração poderá determinar:

```text
Sensor A → 100 Hz
Sensor B → 50 Hz
Sensor C → 20 Hz

ESP32-S → comunicação geral → frequência definida
```

A frequência de um periférico não deverá obrigatoriamente determinar a frequência global do Grupo Computacional.

---

# 24. Configuração de Módulos

Nem todos os módulos de software necessitam de estar permanentemente ativos.

A configuração deverá permitir identificar módulos necessários para determinada aeronave ou função.

Durante a operação, o sistema poderá ainda ativar ou desativar módulos de acordo com o modo e estado atual.

---

# 25. Otimização de Recursos

A configuração deverá procurar evitar a utilização de recursos que não sejam necessários.

Um módulo destinado exclusivamente a determinadas fases da operação poderá permanecer inativo durante as restantes fases.

Isto permitirá utilizar a capacidade computacional disponível para os módulos atualmente relevantes.

Esta estratégia será especialmente importante em elementos com recursos limitados.

---

# 26. Configuração e Compilação

A configuração da aeronave deverá ser conhecida antes da compilação.

O processo conceptual será:

```text
Características da aeronave
          │
          ▼
Configuração Aerus
          │
          ▼
Validação da configuração
          │
          ▼
Compilação
          │
          ▼
Aerus configurado
          │
          ▼
Integração na aeronave
```

A configuração não deverá ser utilizada para alterar arbitrariamente as regras fundamentais do sistema.

---

# 27. Validação da Configuração

Antes da utilização da configuração deverá ser verificado se:

* todos os sensores necessários estão definidos;
* todos os atuadores necessários estão definidos;
* os elementos computacionais necessários existem;
* as ligações necessárias existem;
* os parâmetros são válidos;
* as frequências são compatíveis;
* não existem conflitos de recursos;
* a configuração é coerente com a arquitetura.

Uma configuração inválida não deverá resultar numa compilação considerada válida.

---

# 28. Configuração e Código

A configuração deverá determinar o comportamento parametrizado do Aerus sem permitir alterar arbitrariamente a lógica fundamental do sistema.

Deverá existir uma separação entre:

**Código**

```text
Lógica permanente do Aerus
```

e:

**Configuração**

```text
Características específicas da aeronave
```

---

# 29. Configuração e Implementos

Os implementos deverão ser tratados como sistemas externos ao Aerus.

A configuração da aeronave poderá indicar os tipos de interfaces necessárias para comunicação com implementos.

A lógica específica do implemento deverá permanecer no próprio implemento.

O Aerus deverá receber apenas a informação necessária para executar corretamente as funções relacionadas com o voo.

---

# 30. Evolução de Implementos

A arquitetura deverá permitir a introdução de novos implementos sem exigir uma reconstrução completa do sistema de voo.

A comunicação entre Aerus e implemento deverá permitir que o Aerus determine as informações necessárias para adaptar o voo às características da missão.

A especificação detalhada pertence a `IMP/`.

---

# 31. Compatibilidade

Alterações internas de hardware não deverão quebrar automaticamente as interfaces arquiteturais existentes.

Sempre que possível, a compatibilidade deverá ser preservada através de:

* interfaces estáveis;
* abstração de hardware;
* configuração;
* parametrização;
* versões controladas de interfaces.

---

# 32. Expansão Futura

A arquitetura deverá permanecer aberta à introdução de novos:

* sensores;
* atuadores;
* elementos computacionais;
* Grupos Computacionais;
* interfaces;
* sistemas de segurança;
* implementos;
* funções.

A introdução de qualquer nova função deverá, contudo, ser avaliada quanto ao impacto sobre os restantes componentes.

---

# 33. Alterações de Hardware

A substituição de um componente físico não deverá ser considerada automaticamente uma alteração da arquitetura do Aerus.

Deverá distinguir-se entre:

### Alteração de implementação

Substituição do hardware por outro equivalente sem alteração da responsabilidade arquitetural.

### Alteração arquitetural

Introdução ou remoção de responsabilidades, interfaces ou Grupos Computacionais.

A segunda situação deverá exigir revisão das especificações relevantes.

---

# 34. Escalabilidade

O Aerus deverá suportar crescimento controlado da plataforma.

Esse crescimento poderá ocorrer:

* horizontalmente, através da adição de elementos dentro de um Grupo Computacional;
* verticalmente, através da introdução de novos Grupos Computacionais;
* funcionalmente, através de novos módulos;
* fisicamente, através de novas configurações de aeronave.

---

# 35. Princípio de Compatibilidade Arquitetural

Uma nova configuração de hardware deverá manter os princípios fundamentais da arquitetura Aerus.

A alteração de hardware não deverá eliminar:

* a separação entre domínios;
* a autoridade do ESP32-FS;
* a independência necessária do domínio de segurança;
* as interfaces estabelecidas;
* os mecanismos de comunicação;
* os princípios de redundância;
* os limites definidos para os diferentes Grupos Computacionais.

---

# 36. Limites do Documento

Este documento não define:

* modelos específicos de hardware;
* fabricantes;
* pinouts;
* esquemas elétricos;
* parâmetros aerodinâmicos concretos;
* configuração de uma aeronave específica;
* estrutura detalhada do ficheiro de configuração;
* protocolo TLV;
* algoritmos de controlo;
* algoritmos de navegação;
* regras de segurança;
* implementação dos implementos.

Esses elementos pertencem às respetivas especificações.

---

# 37. Referências

- HW-001 — Arquitetura_de_Hardware
- HW-002 — Grupos_Computacionais
- HW-003 — Distribuicao_de_Hardware
- HW-004 — Interfaces_Eletricas
- HW-005 — Alimentacao_e_Distribuicao_de_Energia
- HW-006 — Interfaces_de_Comunicacao
- HW-007 — Interfaces_de_Perifericos
- HW-008 — Redundancia_e_Isolamento_de_Hardware
- SYS-002 — Arquitetura_Computacional
- SYS-003 — Arquitetura_de_Software
- SYS-004 — Arquitetura_de_Hardware
- SYS-007 — Modos_de_Funcionamento
- SEN — Especificações de Sensores
- ACT — Especificações de Atuadores
- COM — Especificações de Comunicações
- IMP — Especificações de Implementos
- MAT — Especificações Matemáticas
