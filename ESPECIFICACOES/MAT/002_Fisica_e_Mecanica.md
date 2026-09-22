# MAT-002 — Física e Mecânica

| Campo         | Valor                   |
| ------------- | ----------------------- |
| Código        | MAT-002                 |
| Título        | Física e Mecânica       |
| Versão        | 2.0                     |
| Estado        | Em Desenvolvimento      |
| Autor         | ShegaPT                 |
| Classificação | Especificação Matemática|

> **Nota de arquitectura (v2.0):** fórmulas preservadas integralmente. Corrige-se apenas a plataforma: o cálculo de referência passa a residir no **Grupo Computacional de Cálculo (Math Core RP2350#2-C1)** como serviço **MATH_REQUEST / MATH_RESPONSE**, com **implementação local redundante onde determinístico**. Não existem entidades activas fora dos Grupos Computacionais formais (Sensorial, Atuador, FailSafe, Visão GCV, Comunicação, Master Geral, Cálculo).

---

# 1. Objectivo

O presente documento estabelece os fundamentos de Física e Mecânica utilizados pelo sistema Aerus, definindo os princípios físicos e mecânicos que suportam os modelos matemáticos e funcionais relacionados com o comportamento físico da aeronave.

Vamos pensar por camadas: a Física dá-nos as leis universais (gravidade, energia, quantidade de movimento). A Mecânica diz-nos como essas leis se aplicam a corpos com massa. Só depois vêm os modelos de voo, que aplicam estas leis à nossa aeronave concreta. Este documento fixa a primeira camada, sem a contaminar com parâmetros da aeronave.

Este documento estabelece a organização e o âmbito das fórmulas de Física e Mecânica existentes no catálogo matemático do Aerus.

A definição detalhada de cada fórmula, incluindo expressão matemática, entradas, saídas, dependências, unidade de processamento, frequência de execução, precisão numérica, criticidade, redundância e estado de implementação, permanece definida no CATALOGO_MATEMATICA.md.

---

# 2. Âmbito

O domínio de Física e Mecânica compreende os fundamentos físicos necessários para representar forças, movimento, energia, gravidade, quantidade de movimento e comportamento mecânico da aeronave.

O domínio constitui uma camada de base para modelos de nível superior, não devendo absorver fórmulas que já pertençam especificamente a domínios como Aerodinâmica, Navegação, Desempenho da Aeronave, Representação de Atitude ou Segurança de Voo.

A classificação das fórmulas é determinada pelo catálogo e pelo índice matemático existentes.

---

# 3. Modelo de execução — Math Core como serviço

## 3.1 Lógica geral

Todo o cálculo de referência deste domínio vive no **Grupo Computacional de Cálculo (Math Core RP2350#2-C1)**:

```text
Núcleo / Grupo requerente
   │ MATH_REQUEST (FABRIC intra-agrupamento ou CAN-Principal inter-grupos)
   ▼
Math Core RP2350#2-C1 — executa, com precisão double onde indicado
   │ MATH_RESPONSE (REQUEST_ID + TIMESTAMP + CRC)
   ▼
requerente (valida e aplica ao seu modelo)
```

Exemplo: o Núcleo de Navegação precisa da gravitação para um cálculo de apoio em simulação → envia `MATH_REQUEST(MAT-0011)` via FABRIC → recebe `MATH_RESPONSE` → prossegue. O ciclo de voo nunca bloqueia: se o pedido for de apoio/simulação, é assíncrono e sob pedido.

## 3.2 Quando há cópia local?

Apenas quando a operação é **fechada, sem estado, de custo muito baixo e determinística** — por exemplo, `Ep = m·g·h` para estimativa rápida de energia potencial em emergência. Nesse caso, o consumidor (por exemplo, o Grupo FailSafe ou o Núcleo de Missão) detém uma cópia local inline em `float`, validada contra a referência do Math Core. Tudo o resto vai ao serviço central.

Isto garante duas coisas: determinismo no ciclo crítico e unicidade da referência numérica.

## 3.3 Grupos formais envolvidos

* **Master Geral** (núcleos de Voo, Navegação, Missão, Segurança, Diagnóstico, Fusão) — principais clientes.
* **Grupo Sensorial / Atuador** — consumidores locais de energia/movimento para validação.
* **Grupo FailSafe** — detém cópias locais das fórmulas de energia potencial necessárias à lógica de descida de emergência.
* **Grupo Visão GCV e Grupo Comunicação** — consumidores residuais (estatística, supervisão).
* **Grupo de Cálculo** — prestador de referência.

## 3.4 Energia

Alimentação das PCBs a partir de **3,3 V / 5 V / 12 V**, com rails internas geradas por **reguladores / PMIC** locais. A exactidão física das fórmulas é independente da tensão; a validação numérica deve cobrir a gama completa.

---

# 4. Princípios do Domínio

O domínio de Física e Mecânica segue os seguintes princípios:

- representação matemática de fenómenos físicos relevantes para o Aerus;
- separação entre fundamentos físicos e modelos funcionais específicos;
- reutilização dos fundamentos por diferentes modelos;
- preservação das unidades físicas definidas no catálogo;
- utilização da precisão numérica adequada a cada aplicação;
- separação entre cálculo operacional, simulação e investigação;
- manutenção apenas das fórmulas que possuam aplicação definida no sistema;
- referência única no Math Core + local apenas se determinístico.

---

# 5. Fórmulas Abrangidas

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

# 6. Gravitação

## 6.1 Universal Gravitation — MAT-0011

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

| Variável | Descrição           | Unidade |
| -------- | ------------------- | ------- |
| F      | Força Gravitacional | N       |

**Alocação v2.0 (corrige plataforma):** prestador de referência — **Grupo Computacional de Cálculo (Math Core RP2350#2-C1)**, via `MATH_REQUEST` / `MATH_RESPONSE`.

A execução é definida como sob pedido, com recurso a precisão double.

A fórmula é classificada como:

- criticidade operacional: Apoio;
- classificação de software: Opcional;
- consequência de falha: Nenhuma;
- necessária durante: Simulação;
- cálculo redundante: Não (não se exige cópia local; por ser de apoio, o pedido assíncrono ao Math Core é suficiente);
- validação necessária: Não;
- manter: Sim.

O catálogo indica ainda que, nos cálculos de voo em tempo real, esta formulação é normalmente substituída pela constante g. Essa substituição, quando usada no ciclo rápido (ex. `F = m·g`), constitui a implementação local redundante onde determinístico, inline no Núcleo de Voo / FailSafe, sem necessidade de pedido à rede.

---

# 7. Mecânica do Movimento

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

Estas fórmulas encontram-se classificadas no catálogo em domínios funcionais específicos, principalmente Dinâmica de Voo, e deverão ser especificadas nos documentos correspondentes (MAT-007, MAT-008).

A sua inclusão nesta secção serve apenas para estabelecer a relação entre os fundamentos físicos e os domínios que os utilizam. Quando especificadas, seguirão a mesma regra: referência no Math Core + local se determinístico no ciclo do consumidor.

---

# 8. Dinâmica de Corpo Rígido

A dinâmica de corpo rígido constitui outro domínio específico do Aerus e utiliza fundamentos da mecânica para representar o movimento rotacional da aeronave.

O catálogo identifica:

- MAT-0061 — Torque;
- MAT-0062 — Rotational Dynamics;
- MAT-0063 — Moment of Inertia.

Estas fórmulas não são redefinidas neste documento, uma vez que pertencem explicitamente à categoria Dinâmica de Corpo Rígido (MAT-008).

A relação com este documento é exclusivamente de fundamento físico e mecânico.

---

# 9. Energia e Quantidade de Movimento

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

**Alocação v2.0 (corrige plataforma):** referência no **Grupo Computacional de Cálculo (Math Core RP2350#2-C1)** como serviço, com execução a 10–50 Hz quando servida centralmente (precisão `float`), **mais** implementação local redundante e determinística no **Grupo FailSafe** e no **Núcleo de Missão / Núcleo de Segurança** do Master Geral — porque `m·g·h` é fechada e tem de estar disponível mesmo sem rede, para decisão de emergência.

Apesar da sua natureza física, a fórmula permanece associada ao domínio funcional definido pelo catálogo; aqui fixa-se apenas o modelo de execução.

---

# 10. Relação Física → Modelos de Voo

Os princípios da mecânica são utilizados pelos modelos de voo para representar o comportamento translacional e rotacional da aeronave.

A relação entre estes níveis pode ser representada por:

```text
Fundamentos de Física e Mecânica (Math Core como referência)
              │
              ├── Força
              ├── Massa
              ├── Movimento
              ├── Energia
              ├── Quantidade de Movimento
              └── Gravidade
                       │
                       ▼
              Modelos Funcionais (nos seus núcleos)
                       │
        ┌──────────────┼──────────────┐
        ▼              ▼              ▼
 Dinâmica de Voo   Corpo Rígido   Desempenho
        │              │              │
        └──────────────┼──────────────┘
                       ▼
                Controlo / Voo
                       │
                       ▼
              Grupo Atuador (via CAN-Principal, após validação do Núcleo de Voo)
```

Regra de comando (nunca directo): o Núcleo de Missão solicita, o Núcleo de Voo valida e ordena, o Grupo Atuador executa. Ver detalhe em MAT-018.

Os modelos funcionais deverão utilizar os fundamentos necessários sem duplicar definições matemáticas desnecessariamente: ou pedem ao Math Core, ou usam a cópia local quando determinística.

---

# 11. Relação com Outros Domínios

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

# 12. Distribuição Computacional (v2.0)

A distribuição computacional das fórmulas não é definida globalmente por este documento.

Cada fórmula respeita a regra:

1. **Referência no Math Core (RP2350#2-C1)** servida via `MATH_REQUEST` / `MATH_RESPONSE` (FABRIC intra-agrupamento; CAN-Principal inter-grupos).
2. **Cópia local** apenas onde a operação é determinística e necessária no ciclo crítico (ex. `g` constante, `Ep = m·g·h` em emergência).
3. **Sem biblioteca central partilhada como binário único:** cada Grupo compila a sua cópia a partir da mesma referência matemática.

A distribuição não deverá resultar numa biblioteca física central partilhada entre todos os Grupos Computacionais como dependência de execução.

Cada domínio computacional deverá possuir as implementações necessárias (ou o acesso ao serviço) para executar os modelos que lhe sejam atribuídos.

---

# 13. Precisão e Frequência de Execução

A precisão numérica e a frequência de execução são definidas individualmente para cada fórmula.

Poderão existir fórmulas:

- executadas sob pedido (via Math Core);
- executadas em frequência fixa (cópia local, ex. 10–50 Hz para energia);
- utilizadas apenas durante inicialização;
- utilizadas durante simulação;
- utilizadas durante voo;
- utilizadas apenas em investigação.

A escolha da precisão deverá respeitar a especificação individual da fórmula (`double` no serviço central de apoio; `float` nas cópias locais determinísticas).

---

# 14. Redundância e Validação

A necessidade de redundância e validação é determinada individualmente.

O facto de uma fórmula possuir elevada importância física não implica automaticamente a necessidade de cálculo redundante.

Quando a documentação da fórmula determinar cálculo redundante, a redundância concretiza-se em: referência no Math Core + cópia(s) local(is) nos Grupos/Núcleos indicados, com comparação periódica fora do ciclo crítico.

Quando a validação for necessária, esta deverá ser realizada através dos mecanismos definidos pela arquitectura do Aerus (limites físicos, detecção de NaN/inf, votação).

---

# 15. Fórmulas Não Operacionais

Algumas fórmulas de Física existentes no catálogo não fazem parte do sistema operacional de voo.

## 15.1 Wave Equation — MAT-0012

A MAT-0012 — Wave Equation descreve a propagação de ondas num meio contínuo.

A fórmula encontra-se classificada como experimental, possui custo computacional muito alto, não possui unidade de processamento e está classificada como desnecessária.

Não é, portanto, utilizada pelo sistema operacional de voo. Não lhe é atribuído serviço no Math Core operacional; permanece apenas como documentação para investigação.

## 15.2 Mass-Energy Equivalence — MAT-0019

A MAT-0019 — Mass-Energy Equivalence é definida por:

$$
E = mc^2
$$

A fórmula encontra-se classificada como experimental e desnecessária.

Não possui unidade de processamento nem aplicação prática definida no software de voo autónomo.

Consequentemente, não é mantida como componente operacional.

## 15.3 Collision Analysis — MAT-0055

A MAT-0055 — Collision Analysis modela a conservação do momento linear durante colisões:

$$
m_1u_1 + m_2u_2 = m_1v_1 + m_2v_2
$$

A fórmula pode ser utilizada em:

- Simulação;
- Análise de Impacto na Aterragem;
- Análise Estrutural.

Contudo, encontra-se classificada como opcional e com Manter: Não.

O catálogo indica que é útil para simulação e validação, mas não é necessária para a operação autónoma de voo. Quando usada em simulação em solo, pode ser servida pelo Math Core em modo não operacional, sem cópia embarcada obrigatória.

---

# 16. Critério de Separação entre Física e Outros Domínios

Uma fórmula deverá permanecer no domínio funcional definido pelo catálogo quando representar directamente um modelo específico do Aerus.

Assim:

- uma fórmula de força utilizada directamente no modelo de voo pertence à respectiva área de Dinâmica de Voo;
- uma fórmula de torque pertence à Dinâmica de Corpo Rígido;
- uma fórmula de energia específica da aeronave permanece no domínio funcional correspondente;
- uma fórmula de gravidade fundamental permanece em Física;
- uma fórmula de mecânica dos fluidos permanece em Mecânica dos Fluidos;
- uma fórmula de aerodinâmica permanece em Aerodinâmica.

O objectivo deste documento não é duplicar o catálogo, mas estabelecer a base física sobre a qual os restantes modelos são construídos — com execução centralizada no Math Core e cópias locais apenas onde o determinismo o exige.

---

# 17. Evolução do Domínio

O domínio de Física e Mecânica poderá ser expandido caso novas necessidades físicas fundamentais sejam identificadas.

Qualquer nova fórmula deverá ser integrada no sistema documental através da respectiva actualização do:

- CATALOGO_MATEMATICA.md;
- CLASSIFICACAO_MATEMATICA.md;
- INDICE_MATEMATICA.md;
- ALOCACAO_MATEMATICA.md;
- ARQUITETURA.md.

A inclusão de uma fórmula neste domínio deverá ser determinada pela sua função física fundamental e não apenas pela utilização de conceitos físicos na sua expressão matemática. Desde a origem, cada nova fórmula segue a regra Math Core + local se determinístico.

---

# 18. Limites do Documento

Este documento não define:

- o código-fonte das fórmulas;
- a implementação dos modelos de Dinâmica de Voo;
- a implementação dos modelos de Dinâmica de Corpo Rígido;
- a implementação dos modelos Aerodinâmicos;
- os parâmetros específicos da aeronave;
- a alocação definitiva de processamento além da regra Math Core + local;
- os mecanismos específicos de controlo;
- os testes matemáticos individuais.

Esses aspectos são definidos nos respectivos documentos matemáticos, de arquitectura e de implementação.

---

# 19. Referências

- AERUS/math/docs
             ├──ARQUITETURA.md
             ├──CATALOGO_MATEMATICA.md
             ├──CLASSIFICACAO_MATEMATICA.md
             ├──INDICE_MATEMATICA.md
             └──ALOCACAO_MATEMATICA.md
- MAT-001 — Fundamentos Matemáticos (operações de base)
- MAT-003 — Mecânica dos Fluidos
- MAT-007 — Dinâmica de Voo / MAT-008 — Corpo Rígido (modelos consumidores)
- MAT-018 — Matemática de Comunicações (redes FABRIC e CAN-Principal para MATH_REQUEST/RESPONSE)
