# MAT-001 — Fundamentos Matemáticos

| Campo             | Valor                         |
| ----------------- | ----------------------------- |
| **Código**        | MAT-001                       |
| **Título**        | Fundamentos Matemáticos       |
| **Versão**        | 1.0                           |
| **Estado**        | Em Desenvolvimento            |
| **Autor**         | ShegaPT                       |
| **Classificação** | Especificação Matemática      |

---

# 1. Objetivo

O presente documento estabelece os fundamentos matemáticos utilizados pelo sistema **Aerus**, definindo as operações e modelos matemáticos fundamentais que servem de base aos restantes domínios matemáticos do sistema.

Este documento define o âmbito dos fundamentos matemáticos do Aerus e a relação destes com os restantes domínios matemáticos.

A definição detalhada de cada fórmula, incluindo expressão matemática, entradas, saídas, dependências, unidade de processamento, frequência de execução, precisão numérica, custo computacional, criticidade, redundância e estado de implementação, permanece definida no `CATALOGO_MATEMATICA.md`.

---

# 2. Âmbito

O domínio de Fundamentos Matemáticos compreende as operações matemáticas de carácter geral que podem ser utilizadas como base por outros modelos matemáticos do Aerus.

Este domínio não representa todas as fórmulas existentes no sistema.

O catálogo matemático contém atualmente 163 fórmulas, distribuídas por diferentes domínios funcionais, incluindo Aerodinâmica, Dinâmica de Voo, Navegação, Sistemas de Controlo, Propulsão, Processamento de Sinal, Fusão de Sensores, Segurança de Voo e outros.

O presente documento contém apenas as fórmulas que foram classificadas na documentação existente como pertencentes ao domínio matemático fundamental.

---

# 3. Princípios do Domínio

Os fundamentos matemáticos possuem as seguintes características:

- constituem operações matemáticas de utilização geral;
- podem servir de dependência para modelos de outros domínios;
- devem permanecer independentes dos modelos que os utilizam;
- não devem incorporar lógica específica de voo;
- não devem depender de módulos funcionais do Aerus;
- devem poder ser reutilizados por diferentes módulos e Grupos Computacionais;
- devem respeitar a alocação definida para cada fórmula.

Uma fórmula fundamental não deverá incorporar conhecimento específico de Navegação, Aerodinâmica, Controlo, Propulsão ou qualquer outro domínio funcional.

---

# 4. Fórmulas Abrangidas

O cruzamento entre o catálogo, índice, alocação e arquitetura matemática identifica atualmente oito fórmulas operacionais diretamente associadas ao domínio de fundamentos matemáticos.

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

Estas oito fórmulas constituem o conjunto atualmente definido para este domínio.

---

# 5. Geometria Fundamental

## 5.1 Pythagorean Theorem — MAT-0008

A fórmula de Pitágoras estabelece a relação entre os lados de um triângulo retângulo:

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

A fórmula está alocada a:

- Grupo Computacional RaspberryPi;
- Grupo Computacional ESP32-FS;
- Grupo Computacional ESP32-S;
- Grupo Computacional ESP32-A.

A sua taxa de execução é definida como **conforme necessário**, com precisão `float`.

A fórmula possui cálculo redundante e é classificada como obrigatória.

---

# 6. Matemática Fundamental

## 6.1 Logarithms — MAT-0009

Os logaritmos fornecem operações matemáticas fundamentais utilizadas por algoritmos matemáticos de nível superior.

A identidade definida no catálogo é:

$$
\log(xy)=\log(x)+\log(y)
$$

A fórmula encontra-se associada a operações de nível superior que necessitem de funções logarítmicas.

A implementação está atualmente alocada ao Grupo Computacional RaspberryPi.

---

## 6.2 Differential Calculus — MAT-0010

O cálculo diferencial permite determinar a taxa de variação de uma grandeza relativamente a outra:

$$
\frac{df}{dt}
=
\lim_{h\rightarrow0}
\frac{f(t+h)-f(t)}{h}
$$

Constitui um fundamento matemático para modelos que necessitem de derivadas ou taxas de variação.

A implementação está atualmente alocada ao Grupo Computacional RaspberryPi.

---

## 6.3 Complex Numbers — MAT-0013

Os números complexos constituem uma extensão do sistema numérico real utilizada por determinados modelos matemáticos.

A definição fundamental é:

$$
i^2=-1
$$

A fórmula encontra-se atualmente alocada ao Grupo Computacional RaspberryPi.

A sua utilização deverá permanecer limitada aos modelos que efetivamente necessitem de representação ou operações com números complexos.

---

# 7. Fundamentos de Probabilidade

## 7.1 Gaussian Integral — MAT-0035

A integral gaussiana constitui um fundamento matemático associado à teoria das probabilidades e às distribuições gaussianas.

A expressão definida no catálogo é:

$$
\int e^{-x^2}dx=\sqrt{\pi}
$$

A fórmula é utilizada por:

- Estatística;
- Filtro de Kalman;
- Teoria das Probabilidades.

A implementação está atualmente alocada ao Grupo Computacional RaspberryPi.

A precisão numérica definida é `double` e a execução ocorre sob pedido.

---

# 8. Álgebra Vetorial Fundamental

A álgebra vetorial constitui uma base matemática para o tratamento de grandezas vetoriais utilizadas por diferentes domínios do Aerus.

As operações vetoriais deste domínio são independentes dos modelos que posteriormente as utilizam.

---

## 8.1 Vector Magnitude — MAT-0111

A magnitude de um vetor tridimensional é determinada por:

$$
|V|=\sqrt{V_x^2+V_y^2+V_z^2}
$$

A fórmula depende do `MAT-0008 — Pythagorean Theorem`.

É utilizada por:

- Navegação;
- Fusão de Sensores;
- Dinâmica de Voo;
- Estimação de Atitude.

A implementação está atualmente alocada ao:

- Grupo Computacional RaspberryPi;
- Grupo Computacional ESP32-S.

A taxa de execução definida é `200 Hz`, com precisão `float`.

A fórmula é classificada como crítica para a segurança, obrigatória, redundante e com validação necessária.

---

## 8.2 Vector Dot Product — MAT-0112

O produto escalar entre dois vetores é definido por:

$$
A\cdot B=|A||B|\cos\theta
$$

A fórmula depende de `Vector Magnitude`.

É utilizada por:

- Navegação;
- Guiamento;
- Controlo de Atitude.

A implementação está atualmente alocada ao Grupo Computacional RaspberryPi.

A taxa de execução definida é `200 Hz`, com precisão `float`.

A fórmula é classificada como crítica para a segurança, obrigatória, redundante e com validação necessária.

---

## 8.3 Vector Cross Product — MAT-0113

O produto vetorial entre dois vetores é definido por:

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

A implementação está atualmente alocada ao Grupo Computacional RaspberryPi.

A taxa de execução definida é `200 Hz`, com precisão `float`.

A fórmula é classificada como crítica para a segurança e obrigatória.

---

# 9. Dependências entre Fundamentos

As fórmulas deste domínio podem depender de outras fórmulas igualmente pertencentes ao domínio de fundamentos matemáticos.

As dependências atualmente identificadas incluem:

MAT-0008 — Pythagorean Theorem
              │
              ▼
MAT-0111 — Vector Magnitude
              │
              ▼
MAT-0112 — Vector Dot Product

As dependências individuais de cada fórmula são definidas no CATALOGO_MATEMATICA.md.

Uma fórmula poderá utilizar outras fórmulas deste domínio sem que seja necessário duplicar a definição matemática da fórmula utilizada.

---

# 10. Relação com Outros Domínios

Os fundamentos matemáticos constituem uma base para fórmulas pertencentes a outros domínios do Aerus.

A utilização de uma fórmula fundamental por outro domínio não altera a classificação dessa fórmula.

Por exemplo, uma fórmula de Navegação poderá utilizar operações de magnitude ou produto vetorial sem que essas operações passem a pertencer ao domínio de Navegação.

Da mesma forma, modelos de Dinâmica de Voo, Controlo, Estimação de Atitude ou Fusão de Sensores poderão utilizar fundamentos matemáticos definidos neste documento.

A separação entre os fundamentos matemáticos e os modelos específicos deverá ser mantida.

---

# 11. Distribuição Computacional

As fórmulas deste domínio não são obrigatoriamente executadas por um único Grupo Computacional.

A sua distribuição é determinada individualmente para cada fórmula através da documentação de alocação matemática.

Quando uma fórmula seja necessária em diferentes Grupos Computacionais, cada Grupo deverá possuir a implementação necessária para a sua própria execução.

A existência de implementações equivalentes em diferentes Grupos Computacionais não implica a existência de uma biblioteca matemática central partilhada entre os mesmos.

Cada Grupo Computacional deverá possuir as suas próprias implementações matemáticas, de acordo com as necessidades do respetivo domínio.

Quando um Grupo Computacional for constituído por múltiplos elementos de processamento, cada elemento que necessite de determinada fórmula deverá possuir a respetiva implementação.

---

# 12. Precisão Numérica e Execução

A precisão numérica não é definida globalmente para o domínio de Fundamentos Matemáticos.

Cada fórmula deverá utilizar a precisão definida na respetiva especificação.

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

---

# 13. Redundância e Validação

A necessidade de redundância e validação é determinada individualmente para cada fórmula.

Uma fórmula não deverá ser considerada redundante apenas por pertencer ao domínio de Fundamentos Matemáticos.

Quando o catálogo determinar a necessidade de cálculo redundante, deverão existir implementações independentes nos Grupos Computacionais definidos para essa fórmula.

Quando estiver definida a necessidade de validação, o resultado deverá ser sujeito ao mecanismo de validação correspondente à arquitetura do sistema.

A redundância matemática deverá ser aplicada apenas quando existir uma necessidade funcional, operacional ou de segurança identificada.

---

# 14. Fórmulas Excluídas

Nem todas as fórmulas classificadas como Matemática ou Geometria no catálogo pertencem ao conjunto operacional de Fundamentos Matemáticos.

A classificação temática de uma fórmula não é, por si só, suficiente para determinar a sua inclusão neste documento.

A inclusão deverá respeitar simultaneamente a classificação, finalidade, estado de implementação, utilização e restantes propriedades definidas na documentação matemática.

## 14.1 Euler's Formula for Polyhedra — MAT-0014

A fórmula MAT-0014 — Euler's Formula for Polyhedra encontra-se associada à área de Geometria.

Contudo, a documentação existente classifica esta fórmula como experimental e indica que não deverá ser mantida como componente operacional.

Consequentemente, não é incluída no conjunto de fórmulas operacionais deste documento.

---

# 15. Critério de Inclusão

Uma fórmula poderá integrar o domínio de Fundamentos Matemáticos quando representar uma operação ou modelo matemático de carácter geral que sirva de base a outros modelos do Aerus.

A inclusão deverá ser determinada através da documentação matemática existente e não apenas através do nome ou da numeração da fórmula.

Uma fórmula que represente diretamente um modelo específico de:

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
- Deverá permanecer no respetivo domínio funcional, mesmo quando utilize operações matemáticas fundamentais.

---

# 16. Critério de Exclusão

Uma fórmula não deverá integrar este domínio quando:

- representar diretamente um modelo funcional específico;
- possuir dependência conceptual de um domínio operacional específico;
- estiver classificada como experimental sem necessidade operacional;
- estiver classificada como desnecessária;
- não possuir utilização prevista no Aerus;
- estiver explicitamente atribuída a outro domínio matemático.

A existência de uma operação matemática dentro de uma fórmula pertencente a outro domínio não constitui motivo para transferir essa fórmula para Fundamentos Matemáticos.

---

# 17. Evolução do Domínio

O domínio de Fundamentos Matemáticos poderá ser expandido durante o desenvolvimento do Aerus.

Sempre que uma nova necessidade matemática fundamental seja identificada, deverá ser efetuada a respetiva classificação e integração na documentação matemática.

A introdução de uma nova fórmula deverá ser refletida, quando aplicável, nos seguintes documentos:

- CATALOGO_MATEMATICA.md;
- CLASSIFICACAO_MATEMATICA.md;
- INDICE_MATEMATICA.md;
- ALOCACAO_MATEMATICA.md;
- ARQUITETURA.md.

Este documento deverá ser atualizado sempre que uma nova fórmula seja oficialmente integrada neste domínio.

---

# 18. Limites do Documento

Este documento não define:

- o código-fonte das implementações matemáticas;
- a implementação específica de cada fórmula;
- os parâmetros individuais de execução;
- a alocação definitiva de processamento;
- os mecanismos específicos de redundância;
- os mecanismos específicos de validação;
- os testes matemáticos;
- a utilização operacional detalhada de cada fórmula.

Esses aspetos são definidos nos respetivos documentos matemáticos, de arquitetura e de implementação.

---

# 19. Referências

- AERUS/math/docs
             ├──ARQUITETURA.md
             ├──CATALOGO_MATEMATICA.md
             ├──CLASSIFICACAO_MATEMATICA.md
             ├──INDICE_MATEMATICA.md
             └──ALOCACAO_MATEMATICA.md
