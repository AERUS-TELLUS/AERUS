# MAT-002 — Física e Mecânica

| Campo         | Valor                   |
| ------------- | ----------------------- |
| Código        | MAT-002                 |
| Título        | Física e Mecânica       |
| Versão        | 1.0                     |
| Estado        | Em Desenvolvimento      |
| Autor         | ShegaPT                 |
| Classificação | Especificação Matemática|

---

# 1. Objetivo

O presente documento estabelece os fundamentos de Física e Mecânica utilizados pelo sistema Aerus, definindo os princípios físicos e mecânicos que suportam os modelos matemáticos e funcionais relacionados com o comportamento físico da aeronave.

Este documento estabelece a organização e o âmbito das fórmulas de Física e Mecânica existentes no catálogo matemático do Aerus.

A definição detalhada de cada fórmula, incluindo expressão matemática, entradas, saídas, dependências, unidade de processamento, frequência de execução, precisão numérica, criticidade, redundância e estado de implementação, permanece definida no CATALOGO_MATEMATICA.md.

---

# 2. Âmbito

O domínio de Física e Mecânica compreende os fundamentos físicos necessários para representar forças, movimento, energia, gravidade, quantidade de movimento e comportamento mecânico da aeronave.

O domínio constitui uma camada de base para modelos de nível superior, não devendo absorver fórmulas que já pertençam especificamente a domínios como Aerodinâmica, Navegação, Desempenho da Aeronave, Representação de Atitude ou Segurança de Voo.

A classificação das fórmulas é determinada pelo catálogo e pelo índice matemático existentes.

---

# 3. Princípios do Domínio

O domínio de Física e Mecânica segue os seguintes princípios:

- representação matemática de fenómenos físicos relevantes para o Aerus;
- separação entre fundamentos físicos e modelos funcionais específicos;
- reutilização dos fundamentos por diferentes modelos;
- preservação das unidades físicas definidas no catálogo;
- utilização da precisão numérica adequada a cada aplicação;
- separação entre cálculo operacional, simulação e investigação;
- manutenção apenas das fórmulas que possuam aplicação definida no sistema.

---

# 4. Fórmulas Abrangidas

O catálogo matemático identifica várias fórmulas relacionadas com Física e Mecânica.

A classificação não deverá ser determinada apenas pelo facto de uma fórmula representar um fenómeno físico. Fórmulas pertencentes especificamente à Dinâmica de Voo, Dinâmica de Corpo Rígido, Mecânica dos Fluidos, Navegação ou outros domínios permanecem nos respetivos documentos.

As fórmulas fundamentais diretamente classificadas como Física incluem:

| Código   | Nome                    | Categoria | Estado de Utilização |
| -------- | ----------------------- | --------- | -------------------- |
| MAT-0011 | Universal Gravitation   | Física    | Mantida              |
| MAT-0012 | Wave Equation           | Física    | Não operacional      |
| MAT-0019 | Mass-Energy Equivalence | Física    | Não mantida          |
| MAT-0055 | Collision Analysis      | Física    | Não mantida          |

A MAT-0012 encontra-se classificada como experimental, sem unidade de processamento e sem aplicação operacional definida.

A MAT-0019 encontra-se classificada como experimental, sem unidade de processamento e como desnecessária para o software de voo autónomo.

A MAT-0055 é útil para simulação e validação, mas está explicitamente classificada como não necessária para a operação autónoma de voo.

Consequentemente, a única fórmula desta categoria atualmente mantida para utilização no sistema é MAT-0011.

---

# 5. Gravitação

## 5.1 Universal Gravitation — MAT-0011

A Lei da Gravitação Universal determina a força de atração gravitacional entre duas massas:

$$
F = G\frac{m_1m_2}{r^2}
$$

As entradas definidas no catálogo são:

| Variável | Descrição               | Unidade  |
| -------- | ----------------------- | -------- |
| G        | Constante Gravitacional | N·m²/kg² |
| m₁       | Massa                   | kg       |
| m₂       | Massa                   | kg       |
|r         | Distância               | m        |

A saída é:

Variável | Descrição           | Unidade |
| ------ | ------------------- | ------- |
| F      | Força Gravitacional | N       |

A fórmula é utilizada por modelos físicos e encontra-se alocada ao Grupo Computacional Raspberry Pi.

A execução é definida como sob pedido, utilizando precisão double.

A fórmula é classificada como:

- criticidade operacional: Apoio;
- classificação de software: Opcional;
- consequência de falha: Nenhuma;
- necessária durante: Simulação;
- cálculo redundante: Não;
- validação necessária: Não;
- manter: Sim.

O catálogo indica ainda que, nos cálculos de voo em tempo real, esta formulação é normalmente substituída pela constante g.

---

# 6. Mecânica do Movimento

A mecânica do movimento constitui a base física para a representação das forças, acelerações, velocidades e movimento da aeronave.

As fórmulas específicas de Dinâmica de Voo que utilizam estes princípios permanecem nos respetivos documentos, não sendo duplicadas neste domínio.

Entre as fórmulas catalogadas encontram-se:

- MAT-0045 — Linear Velocity;
- MAT-0046 — Linear Acceleration;
- MAT-0047 — Angular Velocity;
- MAT-0048 — Angular Acceleration;
- MAT-0049 — Free Falling Body;
- MAT-0050 — Centrifugal Force;
- MAT-0051 — Impulse and Momentum;
- MAT-0052 — Work and Energy;
- MAT-0053 — Kinetic Energy;
- MAT-0054 — Potential Energy;
- MAT-0060 — Newton's Second Law.

Estas fórmulas encontram-se classificadas no catálogo em domínios funcionais específicos, principalmente Dinâmica de Voo, e deverão ser especificadas nos documentos correspondentes.

A sua inclusão nesta secção serve apenas para estabelecer a relação entre os fundamentos físicos e os domínios que os utilizam.

---

# 7. Dinâmica de Corpo Rígido

A dinâmica de corpo rígido constitui outro domínio específico do Aerus e utiliza fundamentos da mecânica para representar o movimento rotacional da aeronave.

O catálogo identifica:

- MAT-0061 — Torque;
- MAT-0062 — Rotational Dynamics;
- MAT-0063 — Moment of Inertia.

Estas fórmulas não são redefinidas neste documento, uma vez que pertencem explicitamente à categoria Dinâmica de Corpo Rígido.

A relação com este documento é exclusivamente de fundamento físico e mecânico.

---

# 8. Energia e Quantidade de Movimento

Os princípios de energia e quantidade de movimento são utilizados por diferentes modelos do Aerus.

O catálogo identifica, entre outras, as seguintes fórmulas:

- MAT-0038 — Conservation of Momentum;
- MAT-0039 — Conservation of Energy;
- MAT-0051 — Impulse and Momentum;
- MAT-0052 — Work and Energy;
- MAT-0053 — Kinetic Energy;
- MAT-0054 — Potential Energy.

Estas fórmulas encontram-se distribuídas entre Dinâmica de Voo e outros domínios específicos.

A fórmula MAT-0054 — Potential Energy, por exemplo, é definida por:

$$
E_p = mgh
$$

e é utilizada por Gestão de Energia, Planeamento de Missão, Previsão de Planeio e Lógica de Descida de Emergência.

A implementação encontra-se alocada ao Grupo Computacional Raspberry Pi e ao ESP32-FS, com execução de 10–50 Hz e precisão float.

Apesar da sua natureza física, a fórmula permanece associada ao domínio funcional definido pelo catálogo.

---

# 9. Mecânica e Modelos de Voo

Os princípios da mecânica são utilizados pelos modelos de voo para representar o comportamento translacional e rotacional da aeronave.

A relação entre estes níveis pode ser representada por:

Fundamentos de Física e Mecânica
              │
              ├── Força
              ├── Massa
              ├── Movimento
              ├── Energia
              ├── Quantidade de Movimento
              └── Gravidade
                       │
                       ▼
              Modelos Funcionais
                       │
        ┌──────────────┼──────────────┐
        ▼              ▼              ▼
 Dinâmica de Voo   Corpo Rígido   Desempenho
        │              │              │
        └──────────────┼──────────────┘
                       ▼
                Controlo / Voo

Os modelos funcionais deverão utilizar os fundamentos necessários sem duplicar definições matemáticas desnecessariamente.

---

# 10. Relação com Outros Domínios

As fórmulas de Física e Mecânica podem ser utilizadas por diversos domínios do Aerus.

Entre os domínios relacionados encontram-se:

- Dinâmica de Voo;
- Dinâmica de Corpo Rígido;
- Desempenho da Aeronave;
- Gestão de Energia;
- Modelo Atmosférico;
- Aerodinâmica;
- Segurança de Voo;
- Simulação.

A utilização de uma fórmula física por outro domínio não altera a classificação dessa fórmula.

Cada fórmula deverá permanecer no domínio definido pela documentação matemática.

---

# 11. Distribuição Computacional

A distribuição computacional das fórmulas não é definida globalmente por este documento.

Cada fórmula deverá respeitar a unidade de processamento definida no catálogo e na documentação de alocação.

Quando uma fórmula possuir implementação em mais de um Grupo Computacional, cada implementação deverá respeitar as características do respetivo domínio computacional.

A distribuição não deverá resultar numa biblioteca física central partilhada entre todos os Grupos Computacionais.

Cada domínio computacional deverá possuir as implementações necessárias para executar os modelos que lhe sejam atribuídos.

---

# 12. Precisão e Frequência de Execução

A precisão numérica e a frequência de execução são definidas individualmente para cada fórmula.

Poderão existir fórmulas:

- executadas sob pedido;
- executadas em frequência fixa;
- utilizadas apenas durante inicialização;
- utilizadas durante simulação;
- utilizadas durante voo;
- utilizadas apenas em investigação.

A escolha da precisão deverá respeitar a especificação individual da fórmula.

---

# 13. Redundância e Validação

A necessidade de redundância e validação é determinada individualmente.

O facto de uma fórmula possuir elevada importância física não implica automaticamente a necessidade de cálculo redundante.

Quando a documentação da fórmula determinar cálculo redundante, a redundância deverá ser implementada nos Grupos Computacionais indicados.

Quando a validação for necessária, esta deverá ser realizada através dos mecanismos definidos pela arquitetura do Aerus.

---

# 14. Fórmulas Não Operacionais

Algumas fórmulas de Física existentes no catálogo não fazem parte do sistema operacional de voo.

## 14.1 Wave Equation — MAT-0012

A MAT-0012 — Wave Equation descreve a propagação de ondas num meio contínuo.

A fórmula encontra-se classificada como experimental, possui custo computacional muito alto, não possui unidade de processamento e está classificada como desnecessária.

Não é, portanto, utilizada pelo sistema operacional de voo.

## 14.2 Mass-Energy Equivalence — MAT-0019

A MAT-0019 — Mass-Energy Equivalence é definida por:

$$
E = mc^2
$$

A fórmula encontra-se classificada como experimental e desnecessária.

Não possui unidade de processamento nem aplicação prática definida no software de voo autónomo.

Consequentemente, não é mantida como componente operacional.

## 14.3 Collision Analysis — MAT-0055

A MAT-0055 — Collision Analysis modela a conservação do momento linear durante colisões:

$$
m_1u_1 + m_2u_2 = m_1v_1 + m_2v_2
$$

A fórmula pode ser utilizada em:

- Simulação;
- Análise de Impacto na Aterragem;
- Análise Estrutural.

Contudo, encontra-se classificada como opcional e com Manter: Não.

O catálogo indica que é útil para simulação e validação, mas não é necessária para a operação autónoma de voo.

---

# 15. Critério de Separação entre Física e Outros Domínios

Uma fórmula deverá permanecer no domínio funcional definido pelo catálogo quando representar diretamente um modelo específico do Aerus.

Assim:

- uma fórmula de força utilizada diretamente no modelo de voo pertence à respetiva área de Dinâmica de Voo;
- uma fórmula de torque pertence à Dinâmica de Corpo Rígido;
- uma fórmula de energia específica da aeronave permanece no domínio funcional correspondente;
- uma fórmula de gravidade fundamental permanece em Física;
- uma fórmula de mecânica dos fluidos permanece em Mecânica dos Fluidos;
- uma fórmula de aerodinâmica permanece em Aerodinâmica.

O objetivo deste documento não é duplicar o catálogo, mas estabelecer a base física sobre a qual os restantes modelos são construídos.

---

# 16. Evolução do Domínio

O domínio de Física e Mecânica poderá ser expandido caso novas necessidades físicas fundamentais sejam identificadas.

Qualquer nova fórmula deverá ser integrada no sistema documental através da respetiva atualização do:

- CATALOGO_MATEMATICA.md;
- CLASSIFICACAO_MATEMATICA.md;
- INDICE_MATEMATICA.md;
- ALOCACAO_MATEMATICA.md;
- ARQUITETURA.md.

A inclusão de uma fórmula neste domínio deverá ser determinada pela sua função física fundamental e não apenas pela utilização de conceitos físicos na sua expressão matemática.

---

# 17. Limites do Documento

Este documento não define:

- o código-fonte das fórmulas;
- a implementação dos modelos de Dinâmica de Voo;
- a implementação dos modelos de Dinâmica de Corpo Rígido;
- a implementação dos modelos Aerodinâmicos;
- os parâmetros específicos da aeronave;
- a alocação definitiva de processamento;
- os mecanismos específicos de controlo;
- os testes matemáticos individuais.

Esses aspetos são definidos nos respetivos documentos matemáticos, de arquitetura e de implementação.

---

# 18. Referências

- AERUS/math/docs
             ├──ARQUITETURA.md
             ├──CATALOGO_MATEMATICA.md
             ├──CLASSIFICACAO_MATEMATICA.md
             ├──INDICE_MATEMATICA.md
             └──ALOCACAO_MATEMATICA.md
