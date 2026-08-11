# HW-003 — Distribuicao_de_Hardware

| Campo             | Valor                     |
| ----------------- | ------------------------- |
| **Código**        | HW-003                    |
| **Título**        | Distribuição de Hardware  |
| **Versão**        | 1.0                       |
| **Estado**        | Em Desenvolvimento        |
| **Autor**         | ShegaPT                   |
| **Classificação** | Especificação de Hardware |

---

# 1. Objetivo

O presente documento define os princípios para a distribuição física dos elementos computacionais e periféricos que constituem o sistema Aerus.

A distribuição física deverá permitir que cada Grupo Computacional execute as suas responsabilidades de forma eficiente, mantendo a separação funcional e física necessária entre os diferentes domínios.

A distribuição concreta dependerá da configuração de cada aeronave.

---

# 2. Princípio de Distribuição

A arquitetura do Aerus não exige que todos os elementos pertencentes a um mesmo Grupo Computacional estejam fisicamente concentrados num único local.

Um grupo poderá ser distribuído pela aeronave sempre que essa distribuição ofereça vantagens funcionais, elétricas, temporais ou de integração.

A distribuição deverá procurar reduzir ligações desnecessariamente longas e evitar a concentração excessiva de funções num único elemento físico.

---

# 3. Distribuição por Proximidade dos Periféricos

Sempre que tecnicamente adequado, os elementos computacionais deverão ser instalados próximos dos periféricos que lhes estão associados.

Esta abordagem é especialmente relevante para o Grupo Computacional ESP32-S.

Exemplo:

```text
             [Sensor]
                 │
                 │ ligação curta
                 ▼
            [ESP32-S]
                 │
                 │ comunicação do domínio
                 ▼
              Aerus
```

A proximidade poderá reduzir:

* comprimento de cablagem;
* perdas e interferências;
* quantidade de sinais analógicos transportados;
* complexidade da instalação;
* quantidade de cablagem necessária.

---

# 4. Distribuição do ESP32-S

O Grupo Computacional ESP32-S poderá ser constituído por vários elementos distribuídos pela aeronave.

A quantidade de elementos dependerá principalmente da:

* quantidade de sensores;
* localização dos sensores;
* frequência de aquisição;
* capacidade de processamento necessária;
* necessidade de separar grupos de sensores;
* configuração específica da aeronave.

Exemplo conceptual:

```text
                  FRENTE
                    ▲
                    │

             [ESP32-S_01]
              Sensores dianteiros

                    │

        ┌───────────┴───────────┐

 [ESP32-S_02]             [ESP32-S_03]
 Sensores esquerdo         Sensores direito

        └───────────┬───────────┘

             [ESP32-S_04]
              Sensores traseiros

                    │
                    ▼
                   CAUDA
```

A distribuição acima é apenas conceptual e não representa uma configuração obrigatória.

---

# 5. Distribuição do ESP32-A

O Grupo Computacional ESP32-A poderá igualmente ser constituído por vários elementos.

A distribuição deverá considerar principalmente:

* localização dos atuadores;
* quantidade de atuadores;
* requisitos de resposta;
* quantidade de sinais;
* necessidade de *feedback*;
* características elétricas das interfaces.

A proximidade dos elementos ESP32-A aos atuadores poderá reduzir o comprimento das ligações de controlo.

---

# 6. Distribuição do ESP32-FS

O Grupo Computacional ESP32-FS deverá possuir uma distribuição física que preserve a sua independência relativamente aos restantes domínios.

A localização dos elementos deverá considerar:

* proteção física;
* alimentação;
* disponibilidade dos dados necessários;
* resistência a falhas locais;
* acessibilidade para manutenção;
* isolamento relativamente a potenciais fontes de falha.

Quando o grupo possuir vários elementos, a distribuição deverá ser definida de forma a não criar uma dependência desnecessária de um único ponto físico.

---

# 7. Distribuição do ESP32-FS_A

O Grupo Computacional ESP32-FS_A deverá ser instalado de forma a permitir o acesso físico aos atuadores que possam ser utilizados durante uma situação de emergência.

A sua localização deverá minimizar o caminho entre:

```text
ESP32-FS_A
     │
     ├── Ailerons / Elevons
     ├── Leme
     ├── Motor(es)
     └── Outros atuadores de emergência
```

A seleção definitiva dos atuadores sob responsabilidade do ESP32-FS_A ainda não está concluída.

Consequentemente, a distribuição física definitiva deste grupo deverá permanecer configurável.

---

# 8. Distribuição do RaspberryPi

O Grupo Computacional RaspberryPi deverá ser instalado numa posição que permita:

* acesso aos restantes domínios;
* adequada alimentação;
* proteção contra vibração;
* proteção térmica;
* manutenção;
* acesso físico para configuração;
* integração com os restantes sistemas da aeronave.

A arquitetura não pressupõe que exista apenas um elemento físico RaspberryPi.

Quando existirem vários elementos, a sua distribuição deverá ser determinada de acordo com a arquitetura computacional da aeronave.

---

# 9. Separação Física dos Domínios

A distribuição física deverá procurar preservar a separação entre os diferentes domínios computacionais.

A separação não implica necessariamente distância física elevada.

O objetivo é evitar que uma falha física localizada afete simultaneamente vários domínios que deveriam permanecer funcionalmente independentes.

Deverão ser considerados, conforme aplicável:

* alimentação;
* cablagem;
* proteção mecânica;
* temperatura;
* vibração;
* humidade;
* interferência eletromagnética;
* acessibilidade;
* manutenção.

---

# 10. Separação do Domínio de Segurança

O ESP32-FS e os elementos associados ao domínio de segurança deverão possuir condições físicas adequadas à preservação da sua função mesmo perante falhas nos sistemas de operação normal.

A distribuição deverá evitar que uma única falha física previsível inutilize simultaneamente:

* ESP32-FS;
* RaspberryPi;
* ESP32-A;
* ESP32-S.

Os mecanismos específicos de isolamento e redundância serão definidos em `HW-008`.

---

# 11. Distribuição de Sensores

Na configuração atual, os sensores são ligados diretamente ao Grupo Computacional ESP32-S.

A distribuição dos elementos ESP32-S deverá, portanto, acompanhar a distribuição dos sensores sempre que isso apresentar vantagens técnicas.

Poderão existir elementos ESP32-S em diferentes regiões da aeronave.

A arquitetura deverá permitir que diferentes elementos executem aquisições com frequências diferentes, de acordo com os requisitos dos sensores associados.

---

# 12. Distribuição de Atuadores

Os atuadores da operação normal são associados ao Grupo Computacional ESP32-A.

A distribuição física dos elementos ESP32-A poderá acompanhar a distribuição dos atuadores.

O objetivo é evitar que um único elemento tenha obrigatoriamente de controlar todos os atuadores da aeronave quando uma distribuição física diferente for mais adequada.

O *feedback* dos atuadores deverá igualmente ser considerado na distribuição.

---

# 13. Cablagem

A distribuição dos elementos deverá procurar minimizar cablagens desnecessariamente longas.

Deverá ser dada preferência, sempre que tecnicamente adequada, à aproximação entre:

```text
Sensor ───── ESP32-S
Atuador ──── ESP32-A
```

em vez de concentrar todos os elementos num único ponto.

A definição dos tipos de cablagem, conectores, níveis elétricos e características das interfaces pertence a `HW-004` e `HW-006`.

---

# 14. Comunicação entre Elementos Distribuídos

A distribuição física dos elementos deverá considerar a necessidade de comunicação entre diferentes grupos e elementos.

A comunicação entre hardware será realizada através das interfaces definidas na arquitetura de comunicação.

A topologia concreta das ligações entre:

* ESP32-S;
* ESP32-A;
* ESP32-FS;
* ESP32-FS_A;
* RaspberryPi;

não é estabelecida neste documento.

A topologia deverá ser definida posteriormente de acordo com os requisitos de comunicação, segurança e isolamento.

---

# 15. Distribuição em Função da Aeronave

A distribuição física não deverá ser fixa para todas as aeronaves.

Uma aeronave poderá utilizar:

```text
ESP32-S → 1 elemento
ESP32-A → 1 elemento
```

enquanto outra poderá utilizar:

```text
ESP32-S → vários elementos
ESP32-A → vários elementos
```

sem alterar a definição lógica dos respetivos grupos computacionais.

---

# 16. Configuração Específica

A configuração física de uma aeronave deverá definir, pelo menos:

* quantidade de elementos de cada grupo;
* localização aproximada;
* periféricos associados;
* interfaces utilizadas;
* alimentação;
* ligações físicas;
* elementos opcionais;
* requisitos particulares da instalação.

A configuração deverá ser específica para cada modelo de aeronave.

---

# 17. Modularidade

A distribuição física deverá favorecer uma arquitetura modular.

A substituição de um elemento deverá ser possível sem exigir alterações desnecessárias nos restantes elementos.

Sempre que possível, sensores, atuadores e elementos computacionais deverão poder ser substituídos ou reposicionados através de interfaces previamente definidas.

---

# 18. Manutenção

A instalação deverá permitir manutenção, inspeção e substituição dos elementos.

Deverão ser considerados:

* acesso físico;
* identificação dos elementos;
* identificação das ligações;
* possibilidade de desconexão;
* proteção contra ligação incorreta;
* inspeção visual;
* substituição de componentes.

Os procedimentos de manutenção propriamente ditos serão definidos na documentação operacional e de manutenção aplicável.

---

# 19. Expansão

A distribuição física deverá permitir futuras alterações da arquitetura.

Deverá ser possível, quando previsto no projeto da aeronave, adicionar:

* elementos ESP32-S;
* elementos ESP32-A;
* novos periféricos;
* novos grupos computacionais;
* redundâncias adicionais.

A expansão não deverá exigir a reconstrução completa da arquitetura física.

---

# 20. Restrições

A distribuição física não deverá:

* obrigar à concentração de todos os elementos num único local;
* assumir que um Grupo Computacional possui apenas um elemento;
* definir uma topologia de comunicação ainda não aprovada;
* transformar uma ligação física numa relação de autoridade;
* introduzir dependências funcionais desnecessárias;
* comprometer a independência do domínio ESP32-FS.

---

# 21. Limites do Documento

Este documento define os princípios de distribuição física.

Não define detalhadamente:

* pinout;
* conectores;
* tensões;
* correntes;
* proteção elétrica;
* alimentação;
* protocolo de comunicação;
* sensores específicos;
* atuadores específicos;
* algoritmos;
* regras de segurança;
* requisitos estruturais da aeronave.

Esses elementos pertencem às respetivas especificações.

---

# 22. Referências

- HW-001 — Arquitetura_de_Hardware
- HW-002 — Grupos_Computacionais
- HW-004 — Interfaces_Eletricas
- HW-005 — Alimentacao_e_Distribuicao_de_Energia
- HW-006 — Interfaces_de_Comunicacao
- HW-007 — Interfaces_de_Perifericos
- HW-008 — Redundancia_e_Isolamento_de_Hardware
- HW-009 — Expansibilidade_e_Configuracao_de_Hardware
- SEN — Especificações de Sensores
- ACT — Especificações de Atuadores
- SEC — Especificações de Segurança
