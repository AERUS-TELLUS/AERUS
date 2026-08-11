# HW-005 — Alimentacao_e_Distribuicao_de_Energia

| Campo             | Valor                                 |
| ----------------- | ------------------------------------- |
| **Código**        | HW-005                                |
| **Título**        | Alimentação e Distribuição de Energia |
| **Versão**        | 1.0                                   |
| **Estado**        | Em Desenvolvimento                    |
| **Autor**         | ShegaPT                               |
| **Classificação** | Especificação de Hardware             |

---

# 1. Objetivo

O presente documento define os princípios gerais da arquitetura de alimentação elétrica do Aerus.

A arquitetura de energia deverá fornecer alimentação adequada aos grupos computacionais e periféricos, mantendo a disponibilidade necessária para o funcionamento do sistema e permitindo a separação entre diferentes domínios quando necessário.

A definição dos valores elétricos concretos será realizada durante o desenvolvimento detalhado do hardware.

---

# 2. Princípio Geral

O sistema de alimentação deverá ser considerado como parte integrante da arquitetura de segurança e fiabilidade do Aerus.

A alimentação deverá ser dimensionada de acordo com as necessidades de:

* grupos computacionais;
* sensores;
* atuadores;
* sistemas de comunicação;
* periféricos;
* sistemas auxiliares;
* implementos, quando aplicável.

A perda ou degradação da alimentação de um componente deverá ser considerada uma possível condição de falha do sistema.

---

# 3. Arquitetura de Distribuição

A arquitetura deverá distribuir a energia desde a fonte principal até aos diferentes consumidores.

De forma conceptual:

```text
Fonte de Energia
       │
       ▼
Distribuição Principal
       │
       ├── Grupo Computacional RaspberryPi
       │
       ├── Grupo Computacional ESP32-S
       │
       ├── Grupo Computacional ESP32-A
       │
       ├── Grupo Computacional ESP32-FS
       │
       ├── Grupo Computacional ESP32-FS_A
       │
       └── Periféricos
```

A arquitetura final poderá possuir diferentes níveis de conversão e distribuição.

---

# 4. Fonte Principal

A aeronave deverá possuir uma fonte principal de energia adequada à operação do sistema.

A fonte poderá alimentar diretamente ou através de sistemas de conversão os diferentes domínios da aeronave.

A seleção da fonte dependerá da configuração da aeronave e das necessidades energéticas dos seus sistemas.

Os parâmetros concretos da fonte não são definidos neste documento.

---

# 5. Conversão de Energia

Quando a tensão ou características elétricas da fonte principal não forem diretamente compatíveis com um consumidor, deverá ser utilizado um sistema de conversão apropriado.

Os sistemas de conversão poderão ser utilizados para fornecer:

* tensão adequada;
* corrente adequada;
* estabilidade;
* isolamento;
* proteção;
* distribuição específica por domínio.

Cada conversor deverá ser dimensionado de acordo com a carga associada.

---

# 6. Distribuição por Domínio

Sempre que necessário, a alimentação deverá ser distribuída por diferentes domínios de forma independente.

A arquitetura deverá evitar que uma falha localizada provoque desnecessariamente a perda simultânea de sistemas que não necessitam de partilhar a mesma alimentação.

A necessidade de separação será determinada de acordo com:

* função;
* criticidade;
* consumo;
* segurança;
* características dos equipamentos.

---

# 7. Alimentação do RaspberryPi

O Grupo Computacional RaspberryPi deverá possuir uma alimentação adequada às necessidades do hardware utilizado.

Caso o grupo seja constituído por vários elementos, cada elemento deverá possuir alimentação compatível com as suas características.

A arquitetura deverá permitir que a alimentação do RaspberryPi seja monitorizada sempre que essa informação seja relevante para a operação ou segurança.

---

# 8. Alimentação do ESP32-S

Os elementos pertencentes ao Grupo Computacional ESP32-S deverão possuir alimentação adequada aos microcontroladores e sensores associados.

Quando existirem vários elementos, a distribuição de energia poderá ser feita de forma distribuída.

A arquitetura deverá considerar o consumo adicional dos sensores associados a cada elemento.

A perda de alimentação de um elemento ESP32-S não deverá ser automaticamente considerada equivalente à perda de todos os elementos do grupo.

---

# 9. Alimentação do ESP32-A

Os elementos ESP32-A deverão possuir alimentação adequada ao processamento e às interfaces utilizadas para controlo dos atuadores.

A alimentação dos próprios elementos computacionais deverá ser distinguida, quando necessário, da alimentação de potência dos atuadores.

A arquitetura não deverá assumir que um microcontrolador pode fornecer diretamente a energia necessária a um atuador.

Quando necessário, deverá existir uma etapa de potência apropriada entre o elemento computacional e o atuador.

---

# 10. Alimentação do ESP32-FS

A alimentação do Grupo Computacional ESP32-FS deverá ser projetada de modo a preservar a sua capacidade de executar as funções de segurança.

A arquitetura deverá considerar a possibilidade de falhas ou perturbações na alimentação dos sistemas de operação normal.

Sempre que tecnicamente necessário, o domínio de segurança deverá possuir condições de alimentação que reduzam a probabilidade de uma falha comum afetar simultaneamente o domínio normal e o domínio de segurança.

---

# 11. Alimentação do ESP32-FS_A

O Grupo Computacional ESP32-FS_A deverá possuir alimentação suficiente para executar as funções mínimas de atuação necessárias durante uma situação de emergência.

A disponibilidade energética do ESP32-FS_A deverá ser considerada conjuntamente com a disponibilidade do ESP32-FS.

A arquitetura deverá evitar uma dependência energética desnecessária que impeça o domínio de segurança de executar uma resposta quando esta for necessária.

---

# 12. Alimentação dos Atuadores

Os atuadores poderão possuir necessidades energéticas significativamente superiores às dos elementos computacionais.

A alimentação dos atuadores deverá, portanto, ser dimensionada independentemente das necessidades elétricas dos microcontroladores.

Deverão ser considerados:

* corrente nominal;
* corrente de arranque;
* picos de consumo;
* carga mecânica;
* duração da operação;
* número de atuadores ativos simultaneamente.

Os valores concretos serão definidos em `ACT/` e na especificação elétrica detalhada.

---

# 13. Alimentação dos Sensores

Os sensores deverão receber alimentação compatível com as suas especificações.

A alimentação dos sensores deverá considerar:

* tensão;
* corrente;
* estabilidade;
* ruído;
* tempo de inicialização;
* comportamento durante perda de alimentação.

Quando vários sensores partilharem uma alimentação, deverá ser avaliado o impacto que uma falha nessa alimentação poderá provocar.

---

# 14. Monitorização Energética

Sempre que tecnicamente necessário, o Aerus deverá possuir capacidade de monitorizar parâmetros relevantes da alimentação.

Poderão ser monitorizados, conforme aplicável:

* tensão;
* corrente;
* potência;
* consumo acumulado;
* estado da fonte;
* estado dos conversores;
* temperatura;
* outras grandezas relevantes.

Os valores medidos poderão ser utilizados pelo sistema de controlo e pelo domínio de segurança.

---

# 15. Energia e Massa da Aeronave

A arquitetura energética deverá considerar que a fonte de energia constitui parte da massa total da aeronave.

O consumo energético durante a missão poderá alterar a massa da aeronave dependendo do tipo de fonte e da forma como a energia é consumida.

Os cálculos relativos à massa, energia, autonomia e comportamento da aeronave pertencem às especificações matemáticas e energéticas correspondentes.

---

# 16. Gestão de Consumo

Os módulos do Aerus poderão ser ativados, suspensos ou desativados de acordo com o modo e estado atual do sistema.

A redução do consumo deverá ser considerada quando um módulo ou periférico não for necessário.

Esta gestão poderá contribuir simultaneamente para:

* redução do consumo energético;
* redução da carga computacional;
* aumento da autonomia;
* redução térmica.

A desativação de um sistema nunca deverá ocorrer quando a sua ausência comprometer uma função necessária ao estado atual da aeronave.

---

# 17. Cargas Variáveis

A arquitetura deverá considerar que o consumo elétrico do sistema não é constante.

O consumo poderá variar devido a:

* alteração do modo de funcionamento;
* ativação ou desativação de módulos;
* quantidade de sensores ativos;
* quantidade de atuadores ativos;
* alterações de carga dos atuadores;
* utilização de periféricos;
* utilização de implementos.

A distribuição deverá ser dimensionada considerando condições normais e condições de maior consumo previsíveis.

---

# 18. Picos de Consumo

O dimensionamento não deverá considerar apenas o consumo médio.

Deverão ser considerados picos de consumo provocados por:

* arranque de motores;
* movimento simultâneo de atuadores;
* ativação de periféricos;
* inicialização de sistemas;
* alterações rápidas de carga;
* outros eventos transitórios.

Os sistemas de alimentação deverão suportar os picos previstos sem provocar instabilidade nos sistemas computacionais.

---

# 19. Separação entre Potência e Eletrónica

Sempre que necessário, os circuitos de potência deverão ser separados dos circuitos de processamento e comunicação.

Esta separação tem como objetivos:

* reduzir interferências;
* proteger os elementos computacionais;
* evitar quedas de tensão provocadas por cargas elevadas;
* limitar a propagação de falhas;
* melhorar a estabilidade das interfaces.

---

# 20. Proteção

Os sistemas de alimentação deverão possuir mecanismos de proteção adequados aos equipamentos envolvidos.

Poderão ser considerados:

* proteção contra sobrecorrente;
* proteção contra sobretensão;
* proteção contra subtensão;
* proteção contra curto-circuito;
* proteção térmica;
* proteção contra inversão de polaridade;
* proteção contra transientes.

A implementação concreta dependerá da arquitetura elétrica final.

---

# 21. Falha de Alimentação

A perda de alimentação de um elemento deverá ser tratada como uma possível condição de falha.

A reação do sistema dependerá da função do elemento afetado.

Uma falha poderá provocar:

* perda de um sensor;
* perda de um atuador;
* perda de um elemento computacional;
* degradação de uma função;
* alteração de um modo;
* entrada em FailSafe/FailSecure.

A determinação da resposta pertence às especificações de segurança e de gestão de estados.

---

# 22. Falhas Comuns

Deverão ser considerados cenários em que uma única falha de alimentação possa afetar vários sistemas simultaneamente.

Sempre que uma falha comum puder comprometer uma função crítica, deverá ser avaliada a necessidade de:

* separação de alimentação;
* redundância;
* proteção independente;
* fontes alternativas;
* isolamento.

A implementação dependerá da análise de segurança da aeronave.

---

# 23. Arranque

A alimentação dos diferentes sistemas deverá ser disponibilizada de forma compatível com a sequência de arranque do Aerus.

Os elementos deverão atingir estados elétricos estáveis antes de serem considerados disponíveis para operação.

A sequência de arranque e inicialização dos grupos é definida em `SYS-009`.

---

# 24. Encerramento

O encerramento deverá garantir que os sistemas são colocados em condições apropriadas antes da remoção da alimentação.

Deverão ser considerados especialmente:

* atuadores;
* motores;
* sistemas de potência;
* armazenamento de dados;
* sistemas de segurança;
* periféricos externos.

A sequência funcional de encerramento é definida em `SYS-009`.

---

# 25. Implementos

Os implementos poderão possuir requisitos energéticos próprios.

A integração de um implemento deverá considerar:

* fonte de alimentação;
* consumo;
* picos;
* proteção;
* isolamento;
* impacto na autonomia;
* impacto na distribuição de energia da aeronave.

Um implemento não deverá comprometer a alimentação dos sistemas essenciais do Aerus.

A arquitetura específica de integração pertence a `IMP/`.

---

# 26. Configuração por Aeronave

A arquitetura energética deverá ser configurável de acordo com a aeronave.

Poderão variar:

* fonte principal;
* capacidade energética;
* número de conversores;
* distribuição;
* potência disponível;
* quantidade de elementos computacionais;
* quantidade de sensores;
* quantidade de atuadores;
* implementos disponíveis.

A configuração deverá garantir que os sistemas instalados recebem a energia necessária para a sua operação.

---

# 27. Reserva Energética

A capacidade energética disponível deverá ser considerada durante o planeamento e execução da missão.

O sistema deverá possuir mecanismos para determinar a energia disponível e estimar o impacto dessa disponibilidade na operação quando aplicável.

A gestão de energia deverá considerar não apenas a conclusão da missão, mas também a necessidade de manter energia suficiente para executar as funções necessárias até à aterragem e encerramento seguro.

---

# 28. Relação com a Segurança

A arquitetura energética deverá ser considerada parte integrante da estratégia de segurança do Aerus.

A indisponibilidade de energia de um sistema crítico poderá impedir a execução de uma função de segurança.

Por esse motivo, a análise energética deverá identificar os sistemas cuja alimentação é necessária para:

* controlo normal;
* aquisição de sensores;
* segurança;
* atuação de emergência;
* comunicação essencial;
* aterragem segura.

Os mecanismos de resposta a falhas serão definidos em `SEC/`.

---

# 29. Limites do Documento

Este documento não define:

* modelo de bateria;
* química da bateria;
* tensão nominal;
* capacidade nominal;
* corrente máxima;
* modelos de conversores;
* fusíveis específicos;
* conectores;
* bitolas de cablagem;
* esquemas elétricos;
* valores de proteção;
* requisitos específicos de cada sensor;
* requisitos específicos de cada atuador.

Esses elementos deverão ser definidos durante o projeto detalhado.

---

# 30. Referências

- HW-001 — Arquitetura_de_Hardware
- HW-002 — Grupos_Computacionais
- HW-003 — Distribuicao_de_Hardware
- HW-004 — Interfaces_Eletricas
- HW-006 — Interfaces_de_Comunicacao
- HW-007 — Interfaces_de_Perifericos
- HW-008 — Redundancia_e_Isolamento_de_Hardware
- HW-009 — Expansibilidade_e_Configuracao_de_Hardware
- SYS-006 — Gestao_de_Estados
- SYS-007 — Modos_de_Funcionamento
- SYS-009 — Arranque_e_Encerramento
- MAT — Especificações Matemáticas
- SEC — Especificações de Segurança
- ENE — Especificações de Energia
- ACT — Especificações de Atuadores
- SEN — Especificações de Sensores
- IMP — Especificações de Implementos
