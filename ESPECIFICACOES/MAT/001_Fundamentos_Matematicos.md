# MAT-001 — Fundamentos Matemáticos

| Campo             | Valor                         |
| ----------------- | ----------------------------- |
| **Código**        | MAT-001                       |
| **Título**        | Fundamentos Matemáticos       |
| **Versão**        | 2.0                           |
| **Estado**        | Em Desenvolvimento            |
| **Autor**         | ShegaPT                       |
| **Classificação** | Especificação Matemática      |

> **Nota de arquitetura (v2.0):** a alocação de processamento passou a utilizar exclusivamente a nomenclatura formal por Grupos Computacionais. O cálculo central é prestado pelo **Grupo Computacional de Cálculo (Math Core RP2350#2-C1)** sob a forma de serviço **MATH_REQUEST / MATH_RESPONSE**. Onde a operação é fechada, sem estado e determinística, mantém-se **implementação local redundante** em cada consumidor. Não existem entidades computacionais activas fora desta nomenclatura.

---

# 1. Objectivo

O presente documento estabelece os fundamentos matemáticos utilizados pelo sistema **Aerus**, definindo as operações e modelos matemáticos fundamentais que servem de base aos restantes domínios matemáticos do sistema.

Vamos explicar isto por partes, com calma, como se estivéssemos a construir uma casa: estes fundamentos são os tijolos. Tudo o resto — Navegação, Controlo, Fusão, Aerodinâmica — são as paredes que se levantam por cima. Se os tijolos forem ambíguos, as paredes ficam tortas. Por isso este documento fixa o significado matemático, as dependências e o modelo de execução, sem misturar lógica de voo.

Este documento define o âmbito dos fundamentos matemáticos do Aerus e a relação destes com os restantes domínios matemáticos.

A definição detalhada de cada fórmula, incluindo expressão matemática, entradas, saídas, dependências, unidade de processamento, frequência de execução, precisão numérica, custo computacional, criticidade, redundância e estado de implementação, permanece definida no `CATALOGO_MATEMATICA.md`.

**O que mudou na v2.0:** mantêm-se integralmente as fórmulas MAT-xxxx já existentes. Corrige-se apenas a plataforma: onde antes se indicava uma placa genérica, passa a indicar-se o Grupo Computacional formal e o serviço do Math Core.

---

# 2. Âmbito

O domínio de Fundamentos Matemáticos compreende as operações matemáticas de carácter geral que podem ser utilizadas como base por outros modelos matemáticos do Aerus.

Este domínio não representa todas as fórmulas existentes no sistema.

O catálogo matemático contém actualmente 163 fórmulas, distribuídas por diferentes domínios funcionais, incluindo Aerodinâmica, Dinâmica de Voo, Navegação, Sistemas de Controlo, Propulsão, Processamento de Sinal, Fusão de Sensores, Segurança de Voo e outros.

O presente documento contém apenas as fórmulas que foram classificadas na documentação existente como pertencentes ao domínio matemático fundamental.

Fora de âmbito: lógica de missão, leis de controlo, estimadores completos, modelos aerodinâmicos. Esses vivem nos seus MAT próprios e apenas *utilizam* estes fundamentos.

---

# 3. Modelo de execução — Grupo Computacional de Cálculo

## 3.1 Quem calcula?

O cálculo matemático central do Aerus é prestado pelo **Grupo Computacional de Cálculo**, concretizado no **Math Core RP2350#2-C1** — isto é, o segundo microcontrolador do agrupamento principal, núcleo 1, dedicado a cálculo.

Pensemos nele como uma «calculadora central» do veículo:

```text
Núcleo Voo (RP2350#1-C0)
Núcleo Fusão (RP2350#1-C1)
Núcleo Navegação (RP2350#2-C0)
Núcleo Missão (RP2350#3-C0/C1)
Núcleo Segurança (RP2350#4-C0)
Grupo Sensorial / Atuador / Comunicação / Visão GCV / FailSafe
        │  MATH_REQUEST (FABRIC ou CAN-Principal)
        ▼
Grupo Computacional de Cálculo (Math Core RP2350#2-C1)
        │  MATH_RESPONSE (mesmo REQUEST_ID + TIMESTAMP + CRC)
        ▼
    requerente
```

O pedido segue o formato IPC interno: origem, destino, tipo `MATH_REQUEST`, `REQUEST_ID`, `TIMESTAMP`, comprimento, carga útil e CRC. A resposta repete o `REQUEST_ID` para permitir correlação e detecção de perda.

Dentro do agrupamento principal (4×RP2350), o transporte é a **FABRIC** interna — ligação ponto-a-ponto determinística de baixa latência (< 50 µs típico). Entre grupos físicos distintos, o transporte é o **CAN-Principal** ou o **CAN-Intra**, conforme a topologia descrita em MAT-018.

## 3.2 Serviço central versus implementação local redundante

A regra é simples e didáctica:

* **Serviço MATH_REQUEST / MATH_RESPONSE:** obrigatório para operações com estado, de custo médio/alto, em precisão `double`, executadas sob pedido, ou partilhadas por vários consumidores (logaritmos, cálculo diferencial genérico, números complexos, integral gaussiana). O Math Core detém a implementação de referência, testada e versionada uma única vez.
* **Implementação local redundante onde determinístico:** obrigatória para operações fechadas, sem estado, de custo muito baixo/baixo, em `float`, executadas a alta frequência e com necessidade de determinismo mesmo se o serviço central estiver indisponível (Pitágoras, magnitude, produto escalar, produto vectorial). Cada consumidor detém uma cópia local idêntica, inline, sem alocação dinâmica, para que o Núcleo de Voo a 200 Hz nunca fique bloqueado à espera da rede.

Porquê os dois? Porque um sistema de voo não pode parar o controlo para ir «perguntar à calculadora» quanto é a norma de um vector. Mas também não deve duplicar em dez sítios diferentes uma rotina numérica delicada em `double`. Separamos, pois, o *rápido e crítico* (local) do *pesado e partilhado* (central).

## 3.3 Grupos Computacionais formais referenciados neste documento

* **Grupo Computacional Sensorial** — aquisição, filtragem e normalização; consome magnitude e produtos para validação primária.
* **Grupo Computacional Atuador** — conversão de comandos lógicos em sinais físicos; consome geometria para verificação de envelope.
* **Grupo Computacional FailSafe** — supervisão de segurança, autoridade máxima; detém cópias locais das operações críticas.
* **Grupo Computacional Visão GCV** — processamento de imagem a bordo; consome fundamentos para geometria projectiva (via supervisor).
* **Grupo Computacional Comunicação** — gestão das cinco redes e do protocolo TLV; consome fundamentos apenas para estatística de ligação.
* **Grupo Computacional Master Geral** — agrupamento principal de 4×RP2350 com os núcleos de Voo, Fusão, Navegação, Missão, Segurança e Diagnóstico; principal cliente do Math Core.
* **Grupo Computacional de Cálculo (Math Core RP2350#2-C1)** — prestador do serviço central.

## 3.4 Energia

As placas que executam estes fundamentos são alimentadas a partir dos barramentos de **3,3 V / 5 V / 12 V** da aeronave. As tensões internas específicas de cada núcleo (por exemplo, regulações para o agrupamento principal) são geradas localmente por **reguladores / PMIC** em cada PCB, com sequenciamento próprio. Nenhuma fórmula altera o seu resultado em função da tensão; a menção serve apenas para garantir que a repetibilidade numérica é validada na gama completa de alimentação.

---

# 4. Princípios do Domínio

Os fundamentos matemáticos possuem as seguintes características:

- constituem operações matemáticas de utilização geral;
- podem servir de dependência para modelos de outros domínios;
- devem permanecer independentes dos modelos que os utilizam;
- não devem incorporar lógica específica de voo;
- não devem depender de módulos funcionais do Aerus;
- devem poder ser reutilizados por diferentes módulos e Grupos Computacionais;
- devem respeitar a alocação definida para cada fórmula (Math Core como referência + local onde determinístico).

Uma fórmula fundamental não deverá incorporar conhecimento específico de Navegação, Aerodinâmica, Controlo, Propulsão ou qualquer outro domínio funcional.

---

# 5. Fórmulas Abrangidas

O cruzamento entre o catálogo, índice, alocação e arquitectura matemática identifica actualmente oito fórmulas operacionais directamente associadas ao domínio de fundamentos matemáticos.

| Código       | Nome                    | Categoria  | Manter |
| ------------ | ----------------------- | ---------- | ------ |
| **MAT-0008** | Pythagorean Theorem     | Geometria  | Sim    |
| **MAT-0009** | Logarithms              | Matemática | Sim    |
| **MAT-0010** | Differential Calculus   | Matemática | Sim    |
| **MAT-0013** | Complex Numbers         | Matemática | Sim    |
| **MAT-0035** | Gaussian Integral       | Matemática | Sim    |
| **MAT-0111** | Vector Magnitude        | Matemática | Sim    |
| **MAT-0112** | Vector Dot Product      | Matemática | Sim    |
| **MAT-0113** | Vector Cross Product    | Matemática | Sim    |

Estas oito fórmulas constituem o conjunto actualmente definido para este domínio. As expressões matemáticas são preservadas integralmente da v1.0.

---

# 6. Geometria Fundamental

## 6.1 Pythagorean Theorem — MAT-0008

A fórmula de Pitágoras estabelece a relação entre os lados de um triângulo rectângulo:

$$
a^2+b^2=c^2
$$

No Aerus, esta fórmula é utilizada para cálculos de distância e magnitude de componentes ortogonais.

É utilizada, entre outros, por:

- Navegação;
- Fusão de Sensores;
- Geometria;
- Dinâmica de Voo;
- Guiamento.

**Alocação v2.0 (correcção de plataforma):**

- Prestador de referência: **Grupo Computacional de Cálculo (Math Core RP2350#2-C1)**, via `MATH_REQUEST` / `MATH_RESPONSE`, para usos sob pedido e para validação cruzada.
- Implementação local redundante, determinística e obrigatória em: Núcleo de Voo, Núcleo de Fusão, Núcleo de Navegação, Grupo Sensorial, Grupo Atuador e Grupo FailSafe — porque a operação é fechada, em `float`, de custo muito baixo e necessária a alta frequência.

A sua taxa de execução é definida como **conforme necessário** quando servida pelo Math Core, e **à frequência do consumidor** (até 200 Hz nos núcleos de voo/fusão) quando executada localmente, com precisão `float`.

A fórmula possui cálculo redundante e é classificada como obrigatória. A redundância obtém-se por comparação entre o resultado local e o resultado do Math Core sempre que ambos estejam disponíveis (votação / tolerância).

---

# 7. Matemática Fundamental

## 7.1 Logarithms — MAT-0009

Os logaritmos fornecem operações matemáticas fundamentais utilizadas por algoritmos matemáticos de nível superior.

A identidade definida no catálogo é:

$$
\log(xy)=\log(x)+\log(y)
$$

A fórmula encontra-se associada a operações de nível superior que necessitem de funções logarítmicas.

**Alocação v2.0:** implementação de referência no **Grupo Computacional de Cálculo (Math Core RP2350#2-C1)**, servida sob pedido via `MATH_REQUEST` / `MATH_RESPONSE`. Não se exige cópia local redundante, por se tratar de operação em geral não crítica no ciclo rápido. Se um núcleo necessitar de logaritmo no ciclo determinístico, deverá pré-calcular tabela ou solicitar ao Math Core fora do ciclo crítico.

---

## 7.2 Differential Calculus — MAT-0010

O cálculo diferencial permite determinar a taxa de variação de uma grandeza relativamente a outra:

$$
\frac{df}{dt}
=
\lim_{h\rightarrow0}
\frac{f(t+h)-f(t)}{h}
$$

Na prática embarcada, implementa-se por diferenças finitas com passo `h` configurado e anti-ruído (filtragem a montante), nunca pelo limite teórico.

Constitui um fundamento matemático para modelos que necessitem de derivadas ou taxas de variação.

**Alocação v2.0:** implementação de referência no **Grupo Computacional de Cálculo (Math Core RP2350#2-C1)**. Os consumidores (Voo, Fusão, Navegação) enviam janela de amostras e recebem derivada estimada. Derivadas triviais de ciclo rápido (ex. derivada de erro no PID) permanecem inline no consumidor como implementação local redundante onde determinístico, devidamente documentada no MAT-015.

---

## 7.3 Complex Numbers — MAT-0013

Os números complexos constituem uma extensão do sistema numérico real utilizada por determinados modelos matemáticos.

A definição fundamental é:

$$
i^2=-1
$$

**Alocação v2.0:** implementação de referência no **Grupo Computacional de Cálculo (Math Core RP2350#2-C1)**. A sua utilização deverá permanecer limitada aos modelos que efectivamente necessitem de representação ou operações com números complexos (ex. análise espectral, transformadas). Não há cópia local obrigatória.

---

# 8. Fundamentos de Probabilidade

## 8.1 Gaussian Integral — MAT-0035

A integral gaussiana constitui um fundamento matemático associado à teoria das probabilidades e às distribuições gaussianas.

A expressão definida no catálogo é:

$$
\int e^{-x^2}dx=\sqrt{\pi}
$$

(na forma definida de −∞ a +∞, com resultado √π; a forma indefinida pressupõe função erro).

A fórmula é utilizada por:

- Estatística;
- Filtro de Kalman;
- Teoria das Probabilidades.

**Alocação v2.0:** implementação de referência no **Grupo Computacional de Cálculo (Math Core RP2350#2-C1)**.

A precisão numérica definida é `double` e a execução ocorre sob pedido via `MATH_REQUEST` / `MATH_RESPONSE`.

---

# 9. Álgebra Vectorial Fundamental

A álgebra vectorial constitui uma base matemática para o tratamento de grandezas vectoriais utilizadas por diferentes domínios do Aerus.

As operações vectoriais deste domínio são independentes dos modelos que posteriormente as utilizam.

---

## 9.1 Vector Magnitude — MAT-0111

A magnitude de um vector tridimensional é determinada por:

$$
|V|=\sqrt{V_x^2+V_y^2+V_z^2}
$$

A fórmula depende do `MAT-0008 — Pythagorean Theorem`.

É utilizada por:

- Navegação;
- Fusão de Sensores;
- Dinâmica de Voo;
- Estimação de Atitude.

**Alocação v2.0:**

- Prestador de referência: **Grupo Computacional de Cálculo (Math Core RP2350#2-C1)**.
- Implementação local redundante obrigatória em: Núcleo de Voo, Núcleo de Fusão, Núcleo de Navegação e Grupo Sensorial, a **200 Hz**, precisão `float`, por ser operação do ciclo crítico.

A fórmula é classificada como crítica para a segurança, obrigatória, redundante e com validação necessária. A validação faz-se por comparação local versus Math Core quando disponível, e por limites físicos (ex. norma não negativa, não NaN/inf) em cada ciclo.

---

## 9.2 Vector Dot Product — MAT-0112

O produto escalar entre dois vectores é definido por:

$$
A\cdot B=|A||B|\cos\theta
$$

(forma computacional equivalente: `Ax·Bx + Ay·By + Az·Bz`).

A fórmula depende de `Vector Magnitude`.

É utilizada por:

- Navegação;
- Guiamento;
- Controlo de Atitude.

**Alocação v2.0:**

- Prestador de referência: **Grupo Computacional de Cálculo (Math Core RP2350#2-C1)**.
- Implementação local redundante obrigatória nos consumidores de ciclo rápido (Voo, Fusão, Navegação), a **200 Hz**, precisão `float`.

A fórmula é classificada como crítica para a segurança, obrigatória, redundante e com validação necessária.

---

## 9.3 Vector Cross Product — MAT-0113

O produto vectorial entre dois vectores é definido por:

$$
A\times B=
[
A_yB_z-A_zB_y,\,
A_zB_x-A_xB_z,\,
A_xB_y-A_yB_x
]
$$

A fórmula é utilizada por:

- cálculo de torque;
- matemática de rotações;
- Dinâmica de Voo.

**Alocação v2.0:**

- Prestador de referência: **Grupo Computacional de Cálculo (Math Core RP2350#2-C1)**.
- Implementação local redundante obrigatória nos consumidores de ciclo rápido, a **200 Hz**, precisão `float`.

A fórmula é classificada como crítica para a segurança e obrigatória.

---

# 10. Dependências entre Fundamentos

As fórmulas deste domínio podem depender de outras fórmulas igualmente pertencentes ao domínio de fundamentos matemáticos.

As dependências actualmente identificadas incluem:

```text
MAT-0008 — Pythagorean Theorem
              │
              ▼
MAT-0111 — Vector Magnitude
              │
              ▼
MAT-0112 — Vector Dot Product
```

As dependências individuais de cada fórmula são definidas no CATALOGO_MATEMATICA.md.

Uma fórmula poderá utilizar outras fórmulas deste domínio sem que seja necessário duplicar a definição matemática da fórmula utilizada. Quando ambas existirem em versão local e central, a versão local deve chamar a primitiva local (não deve fazer `MATH_REQUEST` recursivo no ciclo rápido).

---

# 11. Relação com Outros Domínios

Os fundamentos matemáticos constituem uma base para fórmulas pertencentes a outros domínios do Aerus.

A utilização de uma fórmula fundamental por outro domínio não altera a classificação dessa fórmula.

Por exemplo, uma fórmula de Navegação poderá utilizar operações de magnitude ou produto vectorial sem que essas operações passem a pertencer ao domínio de Navegação.

Da mesma forma, modelos de Dinâmica de Voo, Controlo, Estimação de Atitude ou Fusão de Sensores poderão utilizar fundamentos matemáticos definidos neste documento.

A separação entre os fundamentos matemáticos e os modelos específicos deverá ser mantida. Em termos de execução, isto significa: o modelo vive no seu núcleo (Voo, Fusão, Navegação…), o fundamento vive no Math Core como serviço, com cópia local apenas quando determinístico.

---

# 12. Distribuição Computacional (v2.0 — corrige plataforma)

As fórmulas deste domínio não são obrigatoriamente executadas por um único Grupo Computacional.

A distribuição é determinada individualmente para cada fórmula, segundo a regra:

1. **Referência única no Math Core.** Toda a fórmula deste documento possui implementação de referência no **Grupo Computacional de Cálculo (Math Core RP2350#2-C1)**, versionada, testada e servida via `MATH_REQUEST` / `MATH_RESPONSE` através da FABRIC (intra-agrupamento) ou do CAN-Principal (inter-grupos).
2. **Cópia local onde determinístico.** As fórmulas fechadas de ciclo rápido (MAT-0008, MAT-0111, MAT-0112, MAT-0113) possuem adicionalmente implementação local redundante em cada Grupo/Núcleo consumidor, sem dependência de rede no ciclo crítico.
3. **Sem biblioteca física central partilhada.** A existência de implementações equivalentes não implica um único binário partilhado. Cada Grupo detém a sua compilação, adequada ao seu compilador e às suas restrições temporais, mas matematicamente idêntica e validada contra a referência do Math Core.

Quando um Grupo Computacional for constituído por múltiplos elementos de processamento, cada elemento que necessite de determinada fórmula deverá possuir a respectiva implementação (ou acesso ao serviço, se fora do ciclo crítico).

**Tabela-resumo da alocação:**

| Fórmula | Referência Math Core | Local redundante | Transporte do pedido |
| ------- | -------------------- | ---------------- | -------------------- |
| MAT-0008 | Sim | Voo, Fusão, Navegação, Sensorial, Atuador, FailSafe | FABRIC / CAN-Principal |
| MAT-0009 | Sim | Não exigida | FABRIC / CAN-Principal, sob pedido |
| MAT-0010 | Sim | Apenas derivadas triviais de ciclo (documentar em MAT-015) | FABRIC, sob pedido |
| MAT-0013 | Sim | Não exigida | FABRIC, sob pedido |
| MAT-0035 | Sim (`double`) | Não exigida | FABRIC, sob pedido |
| MAT-0111 | Sim | Voo, Fusão, Navegação, Sensorial (200 Hz) | FABRIC / CAN-Principal |
| MAT-0112 | Sim | Voo, Fusão, Navegação (200 Hz) | FABRIC |
| MAT-0113 | Sim | Voo, Fusão, Navegação (200 Hz) | FABRIC |

---

# 13. Precisão Numérica e Execução

A precisão numérica não é definida globalmente para o domínio de Fundamentos Matemáticos.

Cada fórmula deverá utilizar a precisão definida na respectiva especificação.

Da mesma forma, a frequência de execução deverá ser determinada individualmente de acordo com a utilização da fórmula.

Entre os parâmetros definidos individualmente poderão encontrar-se:

- precisão numérica;
- frequência de execução;
- custo computacional;
- criticidade operacional;
- classificação de software;
- necessidade de cálculo redundante;
- necessidade de validação.

Estes parâmetros deverão permanecer definidos no CATALOGO_MATEMATICA.md e nos documentos de alocação correspondentes.

Regra prática: `float` no ciclo rápido local (determinismo, 200 Hz); `double` no Math Core sob pedido (exactidão).

---

# 14. Redundância e Validação

A necessidade de redundância e validação é determinada individualmente para cada fórmula.

Uma fórmula não deverá ser considerada redundante apenas por pertencer ao domínio de Fundamentos Matemáticos.

Quando o catálogo determinar a necessidade de cálculo redundante, deverão existir implementações independentes: a de referência no Math Core e as locais nos Grupos/Núcleos definidos para essa fórmula. A comparação periódica (fora do ciclo crítico) entre ambas constitui o mecanismo de validação.

Quando estiver definida a necessidade de validação, o resultado deverá ser sujeito ao mecanismo de validação correspondente à arquitectura do sistema (verificação de NaN/inf, limites físicos, votação).

A redundância matemática deverá ser aplicada apenas quando existir uma necessidade funcional, operacional ou de segurança identificada.

---

# 15. Fórmulas Excluídas

Nem todas as fórmulas classificadas como Matemática ou Geometria no catálogo pertencem ao conjunto operacional de Fundamentos Matemáticos.

A classificação temática de uma fórmula não é, por si só, suficiente para determinar a sua inclusão neste documento.

A inclusão deverá respeitar simultaneamente a classificação, finalidade, estado de implementação, utilização e restantes propriedades definidas na documentação matemática.

## 15.1 Euler's Formula for Polyhedra — MAT-0014

A fórmula MAT-0014 — Euler's Formula for Polyhedra encontra-se associada à área de Geometria.

Contudo, a documentação existente classifica esta fórmula como experimental e indica que não deverá ser mantida como componente operacional.

Consequentemente, não é incluída no conjunto de fórmulas operacionais deste documento.

---

# 16. Critério de Inclusão

Uma fórmula poderá integrar o domínio de Fundamentos Matemáticos quando representar uma operação ou modelo matemático de carácter geral que sirva de base a outros modelos do Aerus.

A inclusão deverá ser determinada através da documentação matemática existente e não apenas através do nome ou da numeração da fórmula.

Uma fórmula que represente directamente um modelo específico de:

- Aerodinâmica;
- Dinâmica de Voo;
- Navegação;
- Controlo;
- Propulsão;
- Energia;
- Segurança;
- Sensores;
- Processamento de Sinal;
- Fusão de Sensores;
- Deverá permanecer no respectivo domínio funcional, mesmo quando utilize operações matemáticas fundamentais.

---

# 17. Critério de Exclusão

Uma fórmula não deverá integrar este domínio quando:

- representar directamente um modelo funcional específico;
- possuir dependência conceptual de um domínio operacional específico;
- estiver classificada como experimental sem necessidade operacional;
- estiver classificada como desnecessária;
- não possuir utilização prevista no Aerus;
- estiver explicitamente atribuída a outro domínio matemático.

A existência de uma operação matemática dentro de uma fórmula pertencente a outro domínio não constitui motivo para transferir essa fórmula para Fundamentos Matemáticos.

---

# 18. Evolução do Domínio

O domínio de Fundamentos Matemáticos poderá ser expandido durante o desenvolvimento do Aerus.

Sempre que uma nova necessidade matemática fundamental seja identificada, deverá ser efectuada a respectiva classificação e integração na documentação matemática.

A introdução de uma nova fórmula deverá ser reflectida, quando aplicável, nos seguintes documentos:

- CATALOGO_MATEMATICA.md;
- CLASSIFICACAO_MATEMATICA.md;
- INDICE_MATEMATICA.md;
- ALOCACAO_MATEMATICA.md;
- ARQUITETURA.md.

Este documento deverá ser actualizado sempre que uma nova fórmula seja oficialmente integrada neste domínio. Qualquer nova fórmula segue desde a origem a regra v2.0 (referência no Math Core + local apenas se determinística).

---

# 19. Limites do Documento

Este documento não define:

- o código-fonte das implementações matemáticas;
- a implementação específica de cada fórmula;
- os parâmetros individuais de execução;
- a alocação definitiva de processamento além da regra Math Core + local;
- os mecanismos específicos de redundância além da comparação referência/local;
- os mecanismos específicos de validação além dos indicados;
- os testes matemáticos;
- a utilização operacional detalhada de cada fórmula.

Esses aspectos são definidos nos respectivos documentos matemáticos, de arquitectura e de implementação.

---

# 20. Referências

- AERUS/math/docs
             ├──ARQUITETURA.md
             ├──CATALOGO_MATEMATICA.md
             ├──CLASSIFICACAO_MATEMATICA.md
             ├──INDICE_MATEMATICA.md
             └──ALOCACAO_MATEMATICA.md
- MAT-018 — Matemática de Comunicações (modelo das 5 redes e orçamentos de latência)
- Grupo Computacional de Cálculo (Math Core RP2350#2-C1) — serviço MATH_REQUEST / MATH_RESPONSE via FABRIC e CAN-Principal
