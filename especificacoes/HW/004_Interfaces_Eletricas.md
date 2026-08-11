# HW-004 — Interfaces_Eletricas

| Campo             | Valor                     |
| ----------------- | ------------------------- |
| **Código**        | HW-004                    |
| **Título**        | Interfaces Elétricas      |
| **Versão**        | 1.0                       |
| **Estado**        | Em Desenvolvimento        |
| **Autor**         | ShegaPT                   |
| **Classificação** | Especificação de Hardware |

---

# 1. Objetivo

O presente documento define os princípios e requisitos gerais aplicáveis às interfaces elétricas utilizadas pelo Aerus.

O objetivo é estabelecer uma arquitetura elétrica coerente entre grupos computacionais, sensores, atuadores, periféricos e sistemas de alimentação, sem definir prematuramente componentes, pinouts ou valores elétricos específicos.

---

# 2. Princípio Geral

Cada interface elétrica deverá ser definida de acordo com a função que desempenha e com as características do equipamento que interliga.

A interface deverá garantir, conforme aplicável:

* compatibilidade elétrica;
* integridade do sinal;
* proteção dos equipamentos;
* isolamento quando necessário;
* capacidade de operação dentro dos limites definidos;
* deteção de condições anormais quando aplicável;
* manutenção e substituição adequadas.

---

# 3. Domínios Elétricos

A arquitetura deverá distinguir entre:

```text
Alimentação
     │
     ├── Grupos Computacionais
     ├── Sensores
     ├── Atuadores
     └── Outros Periféricos
```

A existência de uma ligação elétrica entre dois equipamentos não implica que estes pertençam ao mesmo domínio funcional ou possuam o mesmo nível de autoridade.

As interfaces deverão ser definidas de modo a preservar essa separação.

---

# 4. Tipos de Interface

O Aerus poderá utilizar diferentes tipos de interfaces elétricas de acordo com o periférico ou grupo computacional.

Entre os tipos possíveis encontram-se:

* sinais digitais;
* sinais analógicos;
* GPIO;
* ADC;
* PWM;
* sinais de estado;
* sinais de *feedback*;
* interfaces de comunicação;
* interfaces de alimentação;
* interfaces de controlo.

O tipo concreto utilizado deverá ser definido para cada periférico.

---

# 5. Interfaces Digitais

As interfaces digitais deverão ser utilizadas quando a informação necessária puder ser representada através de estados discretos.

Poderão ser utilizadas para:

* estados;
* sinais de ativação;
* sinais de confirmação;
* deteção de condições;
* comandos simples;
* entradas ou saídas de periféricos.

Os níveis lógicos concretos deverão ser definidos de acordo com os equipamentos utilizados.

---

# 6. Interfaces Analógicas

As interfaces analógicas poderão ser utilizadas para aquisição de grandezas físicas ou estados representados através de valores contínuos.

Quando uma interface analógica for utilizada, deverão ser considerados:

* intervalo de tensão;
* resolução;
* precisão;
* ruído;
* referência;
* impedância;
* frequência de aquisição;
* proteção da entrada.

Os valores concretos serão definidos nas especificações dos respetivos periféricos.

---

# 7. ADC

Os conversores analógico-digital utilizados pelo Aerus deverão possuir características compatíveis com os sensores associados.

A utilização de ADC deverá considerar:

* resolução;
* frequência de aquisição;
* intervalo de entrada;
* referência;
* erro de conversão;
* ruído;
* estabilidade.

O processamento posterior dos valores convertidos pertence ao domínio do Grupo Computacional responsável pela aquisição.

---

# 8. GPIO

Os GPIO poderão ser utilizados para interfaces digitais simples.

Cada utilização deverá definir explicitamente:

* direção;
* estado inicial;
* nível ativo;
* comportamento em erro;
* comportamento durante arranque;
* comportamento durante encerramento.

Um GPIO não deverá permanecer indefinido quando o seu estado possa afetar a segurança ou o funcionamento da aeronave.

---

# 9. PWM

PWM poderá ser utilizado para controlo de determinados atuadores e periféricos.

A utilização de PWM deverá considerar:

* frequência;
* resolução;
* ciclo de trabalho;
* estado de inicialização;
* estado de falha;
* limites mínimo e máximo;
* comportamento quando o módulo responsável deixa de executar.

Os parâmetros concretos deverão ser definidos em função do atuador.

---

# 10. Interfaces de Feedback

Os atuadores deverão, sempre que disponibilizem essa capacidade, fornecer informação que permita determinar o seu estado ou resposta.

O *feedback* poderá ser obtido através de:

* posição;
* rotação;
* estado elétrico;
* carga;
* sinal de retorno;
* informação disponibilizada pelo controlador do atuador;
* outro método adequado.

A ausência de um encoder físico não implica necessariamente ausência de *feedback*.

A forma de aquisição dependerá das características do atuador e da respetiva eletrónica.

---

# 11. Interfaces dos Sensores

Na arquitetura atual, os sensores são ligados diretamente ao Grupo Computacional ESP32-S.

A interface de cada sensor deverá ser compatível com o elemento ESP32-S ao qual estiver associado.

Poderão existir diferentes tipos de interface dentro do mesmo grupo.

A especificação detalhada de cada sensor será definida em `SEN/`.

---

# 12. Interfaces dos Atuadores

Os atuadores utilizados durante a operação normal são controlados através do Grupo Computacional ESP32-A.

As interfaces poderão variar de acordo com o tipo de atuador.

O ESP32-A deverá gerar os sinais necessários à operação do atuador e, quando disponível, adquirir o respetivo *feedback*.

A especificação detalhada dos atuadores será definida em `ACT/`.

---

# 13. Interface de Emergência

O domínio ESP32-FS_A deverá possuir interfaces capazes de controlar o conjunto mínimo de atuadores definido para situações de FailSafe/FailSecure.

Estas interfaces deverão permanecer suficientemente independentes das interfaces utilizadas pelo ESP32-A para permitir a execução da resposta de emergência.

A arquitetura não determina ainda a implementação física concreta dessa independência.

A solução poderá depender do tipo de atuador e da arquitetura elétrica final da aeronave.

---

# 14. Isolamento Elétrico

Quando necessário, deverão ser utilizados mecanismos de isolamento elétrico entre domínios.

O isolamento poderá ser considerado para:

* prevenção de propagação de falhas;
* redução de interferências;
* proteção de equipamentos;
* separação de domínios de segurança;
* proteção contra diferenças de potencial;
* interfaces com equipamentos externos.

A necessidade e o método de isolamento deverão ser definidos individualmente para cada interface.

---

# 15. Proteção das Interfaces

As interfaces deverão ser protegidas contra condições elétricas que possam exceder os limites dos equipamentos.

Conforme aplicável, deverão ser considerados:

* sobretensão;
* sobrecorrente;
* curto-circuito;
* descargas;
* inversão de polaridade;
* transientes;
* ruído;
* interferência eletromagnética.

Os mecanismos concretos de proteção serão definidos durante o projeto detalhado do hardware.

---

# 16. Estado Seguro

Cada interface cujo estado possa afetar a operação da aeronave deverá possuir um comportamento definido para condições anormais.

Deverão ser considerados pelo menos:

* arranque;
* encerramento;
* perda de comunicação;
* falha do elemento controlador;
* entrada em FailSafe/FailSecure;
* reinicialização;
* ausência de *feedback*.

O estado seguro concreto dependerá da função da interface.

---

# 17. Arranque

Durante o arranque, as interfaces deverão assumir estados previamente definidos antes de qualquer módulo iniciar o controlo normal dos periféricos.

O objetivo é evitar:

* comandos espúrios;
* ativação involuntária de atuadores;
* estados indefinidos;
* alterações inesperadas nos periféricos.

A sequência temporal completa de arranque é definida em `SYS-009`.

---

# 18. Encerramento

Durante o encerramento, os sinais deverão ser colocados em estados apropriados antes da remoção da alimentação.

Particular atenção deverá ser dada às interfaces associadas a:

* motores;
* superfícies de controlo;
* atuadores;
* sistemas de segurança;
* periféricos externos.

A sequência completa de encerramento será definida em `SYS-009`.

---

# 19. Compatibilidade

Nenhum periférico deverá ser diretamente ligado a uma interface do Aerus sem confirmação de compatibilidade elétrica.

Deverão ser verificadas, conforme aplicável:

* tensão;
* corrente;
* níveis lógicos;
* tipo de sinal;
* frequência;
* polaridade;
* impedância;
* capacidade de entrada ou saída;
* requisitos de isolamento.

Quando as características não forem diretamente compatíveis deverá existir uma interface de adaptação apropriada.

---

# 20. Separação entre Sinal e Alimentação

Sempre que adequado, deverá ser distinguida a função de alimentação da função de sinal.

Uma ligação de sinal não deverá ser utilizada para alimentar um periférico quando tal utilização não estiver explicitamente prevista.

Da mesma forma, uma linha de alimentação não deverá ser considerada uma interface de comunicação ou controlo.

---

# 21. Interferência

A arquitetura elétrica deverá minimizar interferências entre:

* sistemas computacionais;
* sensores;
* atuadores;
* motores;
* sistemas de potência;
* linhas de comunicação.

A distribuição física dos elementos e a organização da cablagem deverão ser consideradas conjuntamente com as interfaces elétricas.

---

# 22. Identificação das Interfaces

Cada interface física deverá possuir uma identificação inequívoca.

A identificação deverá permitir determinar, conforme aplicável:

* origem;
* destino;
* função;
* tipo de sinal;
* alimentação associada;
* grupo computacional;
* periférico associado.

A nomenclatura concreta das interfaces será definida na documentação de hardware detalhada.

---

# 23. Modularidade

As interfaces deverão favorecer a substituição e expansão dos componentes.

Sempre que possível, um periférico deverá poder ser substituído sem exigir alterações não relacionadas nos restantes sistemas.

A modularidade deverá ser especialmente considerada para:

* sensores;
* atuadores;
* elementos ESP32-S;
* elementos ESP32-A;
* periféricos opcionais;
* implementos externos.

---

# 24. Implementos

Os implementos externos deverão possuir interfaces próprias adequadas à sua integração com o Aerus.

A interface elétrica de um implemento deverá permitir a sua integração sem transformar o implemento num componente interno do Aerus.

A arquitetura deverá permitir que diferentes implementos sejam instalados ou removidos de acordo com a configuração da aeronave.

Os requisitos específicos de comunicação e integração dos implementos serão definidos posteriormente em `IMP/`.

---

# 25. Configuração por Aeronave

As interfaces elétricas efetivamente utilizadas poderão variar de acordo com o modelo da aeronave.

A configuração deverá determinar:

* interfaces existentes;
* periféricos associados;
* tipos de sinal;
* parâmetros elétricos;
* elementos computacionais envolvidos;
* interfaces opcionais.

O código e o hardware deverão utilizar apenas as interfaces previstas na configuração selecionada.

---

# 26. Limites do Documento

Este documento não define:

* valores definitivos de tensão;
* correntes máximas;
* pinouts;
* modelos específicos de microcontroladores;
* modelos de sensores;
* modelos de atuadores;
* conectores específicos;
* esquemas elétricos finais;
* distribuição de alimentação;
* topologia UART;
* protocolo TLV.

Esses elementos serão definidos nas respetivas especificações.

---

# 27. Referências

- HW-001 — Arquitetura_de_Hardware
- HW-002 — Grupos_Computacionais
- HW-003 — Distribuicao_de_Hardware
- HW-005 — Alimentacao_e_Distribuicao_de_Energia
- HW-006 — Interfaces_de_Comunicacao
- HW-007 — Interfaces_de_Perifericos
- HW-008 — Redundancia_e_Isolamento_de_Hardware
- HW-009 — Expansibilidade_e_Configuracao_de_Hardware
- SEN — Especificações de Sensores
- ACT — Especificações de Atuadores
- COM — Especificações de Comunicações
- SEC — Especificações de Segurança
- IMP — Especificações de Implementos
