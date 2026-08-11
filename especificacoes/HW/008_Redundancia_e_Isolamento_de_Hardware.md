# HW-008 — Redundancia_e_Isolamento_de_Hardware

| Campo             | Valor                                |
| ----------------- | ------------------------------------ |
| **Código**        | HW-008                               |
| **Título**        | Redundância e Isolamento de Hardware |
| **Versão**        | 1.0                                  |
| **Estado**        | Em Desenvolvimento                   |
| **Autor**         | ShegaPT                              |
| **Classificação** | Especificação de Hardware            |

---

# 1. Objetivo

O presente documento define os princípios de redundância e isolamento de hardware aplicáveis ao Aerus.

A arquitetura deverá utilizar redundância sempre que esta contribua de forma significativa para a disponibilidade, deteção de falhas ou segurança do sistema.

A redundância não deverá ser aplicada indiscriminadamente.

O princípio fundamental será utilizar apenas a redundância necessária para reduzir riscos relevantes sem introduzir massa, complexidade, consumo ou novos pontos de falha desnecessários.

---

# 2. Princípio de Redundância

A redundância do Aerus deverá seguir um princípio semelhante ao utilizado em sistemas aeronáuticos de elevada exigência:

> redundância suficiente para manter ou recuperar uma função crítica, mas sem duplicação indiscriminada de todos os componentes.

A quantidade de elementos redundantes dependerá da criticidade da função.

Poderão existir:

* dois ou mais sensores equivalentes;
* múltiplos elementos computacionais dentro de um Grupo Computacional;
* sensores independentes associados ao domínio de segurança;
* vias independentes de atuação;
* mecanismos de recuperação através do ESP32-FS e ESP32-FS_A.

---

# 3. Redundância de Sensores

Sensores cuja falha possa provocar uma decisão incorreta ou uma emergência desnecessária poderão possuir sensores redundantes.

Quando aplicável, poderão existir dois ou mais sensores capazes de medir a mesma grandeza.

```text id="5b4y7c"
             ┌──► Sensor A ──► ESP32-S
Grandeza ────┤
             └──► Sensor B ──► ESP32-S
```

Os sensores redundantes deverão, sempre que possível, ser independentes entre si.

---

# 4. Independência dos Sensores Redundantes

A redundância de sensores deverá evitar, sempre que justificável, a existência de uma única falha comum capaz de inutilizar simultaneamente todos os sensores.

A independência poderá ser obtida através de:

* sensores fisicamente separados;
* elementos computacionais diferentes;
* interfaces diferentes;
* fabricantes diferentes;
* alimentação diferente quando necessário;
* tecnologias diferentes quando justificável.

A necessidade de cada forma de independência deverá ser avaliada de acordo com a criticidade da grandeza medida.

---

# 5. Sensores de Fabricantes Diferentes

Para determinadas grandezas críticas, poderá ser utilizada diversidade de fabricante ou tecnologia.

Esta abordagem tem como objetivo reduzir a probabilidade de uma falha específica de um determinado componente afetar simultaneamente todas as fontes de informação.

A utilização de sensores de fabricantes diferentes será especialmente relevante no domínio de segurança.

---

# 6. Redundância no ESP32-S

O Grupo Computacional ESP32-S poderá possuir múltiplos elementos físicos.

Dois ou mais elementos ESP32-S poderão adquirir sensores equivalentes de forma independente.

Exemplo:

```text id="r5s3wq"
        Sensor A1 ──► ESP32-S_01
Grandeza
        Sensor A2 ──► ESP32-S_02
```

Cada elemento deverá produzir os seus próprios dados.

Os dados não deverão ser automaticamente considerados equivalentes apenas por serem provenientes do mesmo tipo de sensor.

---

# 7. Comparação de Dados

Quando existirem múltiplas fontes para a mesma grandeza, o sistema poderá comparar os respetivos valores.

A comparação poderá permitir:

* deteção de divergências;
* deteção de sensores degradados;
* deteção de falhas;
* validação cruzada;
* manutenção da operação quando uma fonte falhar.

Os algoritmos de comparação e decisão pertencem às especificações `SEN/`, `MAT/` e `SEC/`.

---

# 8. Redundância Computacional

A redundância computacional deverá ser aplicada de forma seletiva.

Não é objetivo do Aerus duplicar integralmente todos os Grupos Computacionais.

A quantidade de elementos computacionais deverá ser determinada de acordo com:

* criticidade;
* capacidade necessária;
* disponibilidade;
* massa;
* consumo;
* complexidade;
* possibilidade de recuperação através de outro domínio.

---

# 9. ESP32-A

Não será adotada, como princípio geral, uma duplicação de elementos ESP32-A para controlar simultaneamente o mesmo atuador.

Cada atuador deverá possuir normalmente um elemento ESP32-A responsável pelo seu controlo.

A duplicação direta de controlo do mesmo atuador poderá introduzir conflitos e complexidade adicional.

---

# 10. Falha de ESP32-A

A falha de um elemento ESP32-A responsável por um atuador deverá ser tratada como uma condição de falha do sistema.

Nessa situação, o Aerus deverá poder recorrer ao domínio de segurança.

O ESP32-FS_A poderá assumir a atuação necessária em condições de FailSafe/FailSecure, de acordo com as regras definidas pelo sistema.

```text id="k2k6p1"
Operação normal:

RaspberryPi
     │
     ▼
 ESP32-A
     │
     ▼
 Atuador


Falha / emergência:

ESP32-FS
     │
     ▼
ESP32-FS_A
     │
     ▼
 Atuador
```

---

# 11. Falha do Atuador

A redundância computacional não deverá ser utilizada para mascarar uma falha física do atuador.

Se o próprio atuador apresentar uma falha, o sistema deverá ser capaz de reconhecer essa condição através do *feedback* disponível ou de outras informações.

A resposta deverá depender da consequência da falha.

Poderá ser possível:

* utilizar outro atuador;
* alterar a configuração de controlo;
* alterar o modo de funcionamento;
* cancelar a missão;
* executar uma aterragem;
* executar outro procedimento de emergência.

O sistema não deverá assumir automaticamente que toda falha conduz a RTL.

---

# 12. Sensores Críticos do ESP32-FS

O ESP32-FS deverá possuir acesso direto a sensores considerados supercríticos.

Entre os sensores atualmente previstos encontram-se:

* GPS;
* IMU;
* barómetro;
* temperatura.

Outros sensores poderão ser adicionados posteriormente quando a análise de segurança determinar essa necessidade.

---

# 13. Independência dos Sensores do ESP32-FS

Os sensores ligados diretamente ao ESP32-FS deverão ser independentes dos sensores principais utilizados pelo domínio normal sempre que tal seja necessário para garantir a função de reserva.

Sempre que aplicável, deverão ser utilizados sensores de fabricantes diferentes dos sensores principais.

O objetivo é evitar que uma falha comum nos sensores principais inutilize simultaneamente a informação necessária ao domínio de segurança.

---

# 14. Função dos Sensores do ESP32-FS

Os sensores ligados ao ESP32-FS possuem duas funções principais.

### 14.1. Beacon

Os dados necessários deverão poder alimentar diretamente o sistema de **Beacon** obrigatório aplicável à operação da aeronave.

### 14.2. Reserva de Emergência

Os mesmos sensores poderão fornecer ao domínio de segurança um conjunto mínimo de informações de voo caso os sensores principais fiquem indisponíveis ou não confiáveis.

---

# 15. Dados de Reserva

Os sensores associados ao ESP32-FS não constituem a fonte primária de dados para o voo normal.

Durante a operação normal, os dados desses sensores deverão permanecer destinados principalmente às funções atribuídas ao domínio de segurança e ao Beacon.

Caso os sensores principais deixem de fornecer informação válida, os sensores de reserva poderão ser utilizados para suportar as funções mínimas necessárias à recuperação da aeronave.

---

# 16. Recuperação em Emergência

A disponibilidade dos sensores de reserva deverá permitir que determinadas falhas não conduzam automaticamente à perda da capacidade de voo.

Por exemplo, uma falha dos sensores principais de:

* posição;
* atitude;
* altitude;

poderá permitir ao ESP32-FS utilizar as fontes de reserva disponíveis para suportar uma operação de emergência.

Quando as condições forem suficientes, poderá ser executado um **RTL — Return to Launch** seguro.

---

# 17. Limitações da Recuperação

A existência de sensores de reserva não garante que qualquer falha possa ser recuperada.

A decisão deverá depender da informação disponível e da capacidade da aeronave continuar a operar de forma segura.

Caso os dados disponíveis não permitam uma recuperação segura através de RTL, o Aerus poderá selecionar outro procedimento de emergência.

A estratégia de decisão pertence a `SEC/`.

---

# 18. Redundância do Domínio de Segurança

O ESP32-FS constitui uma camada independente de supervisão e segurança.

A arquitetura deverá permitir que este domínio continue a executar as suas funções mesmo quando o domínio normal apresentar falhas.

O objetivo não é duplicar completamente o Aerus, mas manter as funções mínimas necessárias para:

* deteção de falhas;
* avaliação de segurança;
* execução de medidas de emergência;
* atuação necessária;
* recuperação da aeronave quando possível.

---

# 19. ESP32-FS_A

O ESP32-FS_A constitui um elemento de atuação associado ao domínio de segurança.

Este grupo não deverá participar no controlo normal da aeronave.

A sua existência permite manter uma capacidade de atuação mesmo perante determinadas falhas do caminho normal.

O ESP32-FS_A recebe comandos diretamente do ESP32-FS.

---

# 20. Isolamento entre Domínios

Os diferentes Grupos Computacionais deverão possuir isolamento suficiente para impedir que uma falha localizada se propague automaticamente para todo o sistema.

O isolamento deverá ser considerado a nível de:

* alimentação;
* comunicação;
* processamento;
* software;
* atuação;
* sensores.

A implementação concreta dependerá da natureza da função.

---

# 21. Isolamento do Domínio de Segurança

O domínio constituído por ESP32-FS e ESP32-FS_A deverá permanecer funcional perante determinadas falhas do domínio operacional.

O RaspberryPi não deverá possuir autoridade para obrigar o ESP32-FS a executar uma ação de segurança.

O RaspberryPi poderá solicitar uma entrada em FailSafe/FailSecure, mas o ESP32-FS deverá avaliar independentemente essa solicitação.

---

# 22. Independência de Decisão

O ESP32-FS deverá possuir capacidade de realizar as suas próprias avaliações utilizando os dados disponíveis.

Assim, uma solicitação proveniente do RaspberryPi não deverá ser considerada automaticamente válida.

Exemplo:

```text id="0b9g2p"
RaspberryPi
     │
     │ Pedido de emergência
     ▼
 ESP32-FS
     │
     ├── Avalia sensores
     ├── Avalia estados
     ├── Avalia feedback
     └── Avalia segurança
              │
       ┌──────┴──────┐
       ▼             ▼
    Aceita          Recusa
       │             │
       ▼             ▼
Procedimento     Operação
de emergência     normal
```

---

# 23. Falhas Comuns

A arquitetura deverá procurar minimizar pontos de falha comuns que possam inutilizar simultaneamente:

* sensores principais e de reserva;
* domínio normal e domínio de segurança;
* alimentação normal e alimentação de segurança;
* comunicação normal e comunicação de segurança;
* múltiplos elementos redundantes.

Quando uma falha comum não puder ser eliminada, deverá ser considerada na análise de segurança.

---

# 24. Redundância de Alimentação

A necessidade de redundância ou separação de alimentação deverá ser determinada pela criticidade dos sistemas.

Não será obrigatório duplicar a alimentação de todos os componentes.

Sistemas cuja perda possa comprometer funções críticas poderão necessitar de maior independência energética.

A arquitetura detalhada pertence a `HW-005`.

---

# 25. Redundância de Comunicação

A existência de múltiplas vias de comunicação não será obrigatória para todos os sistemas.

A necessidade de uma via independente deverá ser determinada pela criticidade da informação.

O domínio de segurança deverá possuir as ligações necessárias para manter as suas funções mesmo perante determinadas falhas do sistema normal.

A arquitetura física detalhada encontra-se em `HW-006`.

---

# 26. Redundância de Atuadores

A redundância de atuadores deverá ser aplicada apenas quando existir uma vantagem operacional ou de segurança justificável.

Quando a falha de um atuador puder ser compensada por outro atuador ou por uma alteração de procedimento, essa possibilidade poderá ser utilizada.

Não deverá ser assumido que todos os atuadores necessitam de duplicação.

---

# 27. Redundância e Massa

Toda redundância deverá ser avaliada tendo em consideração o impacto físico na aeronave.

A duplicação de componentes poderá aumentar:

* massa;
* consumo;
* volume;
* complexidade;
* cablagem;
* pontos de falha;
* manutenção.

Consequentemente, a redundância deverá ser aplicada apenas quando o benefício superar os custos introduzidos.

---

# 28. Redundância e Complexidade

A redundância excessiva poderá introduzir novos riscos.

Sistemas redundantes deverão ser suficientemente independentes para que a redundância tenha valor real.

Não deverá ser considerada redundância útil a simples duplicação de componentes que partilhem o mesmo:

* sensor físico;
* alimentação;
* ligação;
* erro de configuração;
* ponto de falha;
* ambiente de falha comum.

---

# 29. Degradação Controlada

Quando uma parte redundante falhar, o Aerus deverá procurar manter a operação com os recursos restantes sempre que isso for seguro.

A perda de uma fonte de informação não deverá provocar automaticamente uma emergência quando existirem outras fontes suficientemente confiáveis.

A decisão deverá considerar:

* quantidade de fontes disponíveis;
* qualidade dos dados;
* divergência entre fontes;
* criticidade da grandeza;
* estado atual da aeronave.

---

# 30. Isolamento de Falhas

Uma falha deverá ser localizada sempre que possível.

O sistema deverá procurar determinar:

1. qual o componente afetado;
2. qual a função afetada;
3. quais as funções dependentes;
4. se existem fontes redundantes;
5. se a operação pode continuar;
6. se é necessário executar um procedimento de segurança.

---

# 31. Falha de um Elemento dentro de um Grupo

A falha de um elemento físico pertencente a um Grupo Computacional não deverá ser automaticamente interpretada como falha total do Grupo.

Por exemplo, se o ESP32-S possuir vários microcontroladores e apenas um falhar, os restantes poderão continuar a executar as suas funções.

A consequência dependerá da distribuição dos sensores e das funções entre os elementos.

---

# 32. Configuração por Aeronave

A quantidade de redundância poderá variar entre diferentes aeronaves.

Uma aeronave poderá possuir:

* dois sensores para determinada grandeza;
* três ou mais sensores para outra;
* múltiplos ESP32-S;
* diferentes configurações de atuadores;
* diferentes níveis de reserva.

A configuração deverá ser definida antes da compilação e integração do Aerus.

---

# 33. Princípio de Não-Duplicação Desnecessária

O Aerus não deverá duplicar uma função simplesmente porque é tecnicamente possível.

Antes de introduzir redundância deverá ser avaliado:

* qual o risco reduzido;
* qual a falha coberta;
* qual a independência obtida;
* qual o custo físico;
* qual o custo computacional;
* qual a complexidade adicional;
* se existe outro mecanismo de recuperação mais eficiente.

---

# 34. Relação com FailSafe/FailSecure

A redundância e o isolamento deverão permitir que o sistema entre em procedimentos FailSafe/FailSecure de forma controlada.

O domínio de segurança deverá utilizar as fontes de informação disponíveis para determinar a resposta apropriada.

Nem toda falha deverá resultar na mesma ação.

A resposta poderá variar desde a continuação da missão até um procedimento de recuperação ou aterragem de emergência.

---

# 35. Limites do Documento

Este documento não define:

* número final de sensores;
* modelos específicos;
* fabricantes específicos;
* arquitetura elétrica final;
* algoritmos de fusão de sensores;
* lógica de votação;
* regras completas de FailSafe/FailSecure;
* procedimentos de emergência;
* configuração final do ESP32-FS_A;
* quantidade definitiva de elementos ESP32-S;
* redundância específica de cada atuador.

Esses elementos serão definidos nas especificações correspondentes.

---

# 36. Referências

- HW-001 — Arquitetura_de_Hardware
- HW-002 — Grupos_Computacionais
- HW-003 — Distribuicao_de_Hardware
- HW-005 — Alimentacao_e_Distribuicao_de_Energia
- HW-006 — Interfaces_de_Comunicacao
- HW-007 — Interfaces_de_Perifericos
- HW-009 — Expansibilidade_e_Configuracao_de_Hardware
- SYS-002 — Arquitetura_Computacional
- SYS-006 — Gestao_de_Estados
- SYS-007 — Modos_de_Funcionamento
- SEN — Especificações de Sensores
- ACT — Especificações de Atuadores
- SEC — Especificações de Segurança
- ENE — Especificações de Energia
