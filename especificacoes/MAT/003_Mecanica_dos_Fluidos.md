# MAT-003 — Mecânica dos Fluidos

| Campo         | Valor                   |
| ------------- | ----------------------- |
| Código        | MAT-003                 |
| Título        | Mecânica dos Fluidos    |
| Versão        | 2.0                     |
| Estado        | Em Desenvolvimento      |
| Autor         | ShegaPT                 |
| Classificação | Especificação Matemática|

> **Nota de arquitectura (v2.0):** fórmulas MAT-xxxx preservadas integralmente. Corrige-se apenas a plataforma: toda a execução de referência passa para o **Grupo Computacional de Cálculo (Math Core RP2350#2-C1)** como serviço **MATH_REQUEST / MATH_RESPONSE** (sob pedido / offline), com **implementação local redundante apenas onde a operação for fechada e determinística**. Não existem entidades activas fora dos Grupos formais.

# 1. Objectivo

O presente documento estabelece o domínio matemático de Mecânica dos Fluidos utilizado pelo sistema Aerus, reunindo as formulações destinadas à representação e análise do comportamento de fluidos.

Vamos explicar a ideia central: o ar que envolve a aeronave comporta-se como um fluido. Para prever sustentação, arrasto, escoamento em entradas de ar e desempenho do motor, precisamos de leis de conservação (massa, momento, energia) aplicadas ao ar. Este documento fixa essas leis, sem as misturar com o modelo aerodinâmico completo da aeronave — que vive em MAT-005.

Este domínio suporta principalmente modelos relacionados com escoamento de ar, conservação de massa, escoamento viscoso, escoamento compressível e análise de regimes de escoamento.

A definição individual de cada fórmula permanece no CATALOGO_MATEMATICA.md.

# 2. Âmbito

O domínio de Mecânica dos Fluidos abrange as fórmulas classificadas explicitamente como Mecânica dos Fluidos no catálogo matemático.

As fórmulas deste domínio são utilizadas principalmente em:

- modelação aerodinâmica;
- análise de escoamento;
- modelos de entrada de ar;
- propulsão;
- simulação de fluidos;
- análise de desempenho;
- validação CFD;
- análise de escoamento compressível.

Fórmulas relacionadas com fluidos que estejam classificadas no catálogo como pertencentes a outros domínios permanecem nesses respetivos domínios.

## 2.1 Modelo de execução (v2.0)

Todo este domínio é de **apoio / simulação / análise**, não de ciclo rápido de voo. Por isso a regra é:

* **Referência única no Math Core RP2350#2-C1**, servida via `MATH_REQUEST` / `MATH_RESPONSE` através da FABRIC (se o requerente for um núcleo do agrupamento principal) ou do CAN-Principal (se for outro grupo). Precisão `double` (ou `float/double` onde indicado), execução **Sob Pedido / Offline**.
* **Sem cópia local obrigatória no ciclo de voo**, excepto Reynolds/continuidade simplificada se um dia forem chamadas a 10–50 Hz num monitor — nesse caso, documentar como implementação local redundante onde determinístico, validada contra o Math Core.
* **Navier-Stokes completo (MAT-0006)** permanece não embarcado: custo extremamente alto, sem serviço operacional, apenas documentação para CFD em solo.

## 2.2 Grupos e energia

* Clientes típicos: Núcleo de Voo, Núcleo de Missão, Núcleo de Navegação (via Master Geral), Grupo Comunicação (para correcções Pitot via ar).
* Prestador: Grupo de Cálculo.
* Alimentação das PCBs: **3,3 V / 5 V / 12 V** com rails internas por **reguladores / PMIC**. A validade numérica é independente da tensão.

# 3. Fórmulas Abrangidas

O catálogo matemático identifica actualmente as seguintes fórmulas como pertencentes ao domínio de Mecânica dos Fluidos:

| Código | Nome | Estado |
| ------ | ---- | ------ |
| MAT-0005 | Continuity Equation | Mantida |
| MAT-0006 | Navier-Stokes Equation | Não Mantida (apenas análise/CFD) |
| MAT-0037 | Conservation of Mass | Mantida |
| MAT-0040 | Isentropic Flow | Mantida |
| MAT-0041 | Isentropic Momentum Equation | Mantida |
| MAT-0056 | Viscous Force | Mantida |
| MAT-0083 | Reynolds Number | Mantida |

O conjunto acima corresponde às fórmulas que o catálogo classifica explicitamente como Mecânica dos Fluidos. As expressões são preservadas da v1.0; altera-se apenas a unidade de processamento.

# 4. Conservation of Mass — MAT-0037

A MAT-0037 — Conservation of Mass representa a conservação de massa num sistema fechado.

**Expressão Matemática**

$$\frac{dm}{dt}=0$$

**Entradas**

| Variável | Descrição | Unidade |
| -------- | --------- | ------- |
| m | Massa | kg |
| t | Tempo | s |

**Saída**

| Variável | Descrição | Unidade |
| -------- | --------- | ------- |
| dm/dt | Taxa de variação da massa | kg/s |

**Utilização**

A fórmula é utilizada por:

- Aerodinâmica;
- Propulsão;
- Simulação de Fluidos.

**Execução (v2.0 — corrige plataforma)**

| Parâmetro | Valor |
| --------- | ----- |
| Unidade de Processamento | Grupo Computacional de Cálculo (Math Core RP2350#2-C1), via MATH_REQUEST / MATH_RESPONSE |
| Taxa de Execução | Sob Pedido |
| Precisão Numérica | double |
| Custo Computacional | Muito Baixo |
| Criticidade Operacional | Apoio |
| Classificação de Software | Obrigatório |
| Cálculo Redundante | Não (serviço central suficiente; cópia local apenas se o consumidor demonstrar necessidade determinística) |
| Validação Necessária | Não |
| Manter | Sim |

A consequência de uma falha é a redução da precisão do modelo.

A fórmula é necessária durante Simulação e Análise de Desempenho.

# 5. Continuity Equation — MAT-0005

A MAT-0005 — Continuity Equation representa a conservação de massa aplicada ao escoamento de um fluido.

**Expressão Matemática**

$$\rho_1A_1V_1=\rho_2A_2V_2$$

**Forma Alternativa**

$$\rho AV=\text{Constant}$$

**Entradas**

| Variável | Descrição | Unidade |
| -------- | --------- | ------- |
| ρ | Densidade | kg/m³ |
| A | Área | m² |
| V | Velocidade | m/s |

**Saída**

| Variável | Descrição | Unidade |
| -------- | --------- | ------- |
| Flow Conservation | Conservação do escoamento | - |

**Dependências**

- Propriedades do Fluido;
- Conservation of Mass (MAT-0037).

**Utilização**

A fórmula é utilizada por:

- Modelos Aerodinâmicos;
- Modelos de Entrada de Ar;
- Propulsão.

**Execução (v2.0)**

| Parâmetro | Valor |
| --------- | ----- |
| Unidade de Processamento | Grupo Computacional de Cálculo (Math Core RP2350#2-C1) |
| Taxa de Execução | Sob Pedido |
| Precisão Numérica | float / double |
| Custo Computacional | Baixo |
| Criticidade Operacional | Apoio |
| Classificação de Software | Importante |
| Cálculo Redundante | Não |
| Validação Necessária | Não |
| Manter | Sim |

A consequência de uma falha é a redução da precisão do modelo. Necessária durante Simulação e Análise de Desempenho. Transporte do pedido: FABRIC se requerido por núcleo do Master Geral; CAN-Principal se requerido por Grupo Sensorial/Comunicação.

# 6. Isentropic Flow — MAT-0040

A MAT-0040 — Isentropic Flow descreve o escoamento adiabático compressível com entropia constante.

**Expressão Matemática**

$$\frac{P}{\rho^\gamma}=\text{Constant}$$

**Entradas:** Pressão P; Densidade ρ; Razão de calores específicos γ.

**Saída:** a constante isentrópica $$\frac{P}{\rho^\gamma}$$.

**Dependências:** Ideal Gas Law.

**Utilização:** Análise Pitot; Modelos de Escoamento de Ar; Propulsão.

**Execução (v2.0)**

| Parâmetro | Valor |
| --------- | ----- |
| Unidade de Processamento | Grupo Computacional de Cálculo (Math Core RP2350#2-C1) |
| Taxa de Execução | Sob Pedido |
| Precisão Numérica | double |
| Custo Computacional | Médio |
| Criticidade Operacional | Apoio |
| Classificação de Software | Importante |
| Cálculo Redundante | Não |
| Validação Necessária | Não |
| Manter | Sim |

A consequência de uma falha é a redução da precisão do modelo. Necessária sob pedido.

# 7. Isentropic Momentum Equation — MAT-0041

A MAT-0041 — Isentropic Momentum Equation representa a equação do momento aplicada a escoamento isentrópico compressível.

**Expressão Matemática**

$$\rho V(dV)+dP=0$$

**Entradas:** Densidade ρ; Velocidade V; Pressão P.

**Saída:** Variação de pressão dP.

**Dependências:** Isentropic Flow (MAT-0040).

**Utilização:** Propulsão; Análise de Escoamento Compressível.

**Execução (v2.0)**

| Parâmetro | Valor |
| --------- | ----- |
| Unidade de Processamento | Grupo Computacional de Cálculo (Math Core RP2350#2-C1) |
| Taxa de Execução | Sob Pedido |
| Precisão Numérica | double |
| Custo Computacional | Médio |
| Criticidade Operacional | Apoio |
| Classificação de Software | Importante |
| Cálculo Redundante | Não |
| Validação Necessária | Não |
| Manter | Sim |

A consequência de uma falha é a redução da precisão do modelo. Necessária sob pedido.

# 8. Viscous Force — MAT-0056

A MAT-0056 — Viscous Force calcula a força de corte gerada pela viscosidade do fluido.

**Expressão Matemática**

$$F_v=\mu A\frac{dv}{dy}$$

**Forma Alternativa**

$$F=\mu A\frac{dv}{dy}$$

**Entradas**

| Variável | Descrição | Unidade |
| -------- | --------- | ------- |
| μ | Viscosidade Dinâmica | Pa·s |
| A | Área de Superfície | m² |
| dv/dy | Gradiente de Velocidade | 1/s |

**Saídas**

| Variável | Descrição | Unidade |
| -------- | --------- | ------- |
| Fᵥ | Força Viscosa | N |
| F | Força Viscosa | N |

**Dependências:** Propriedades do Fluido; Gradiente de Velocidade.

**Utilização:** Modelação Aerodinâmica; CFD; Análise de Arrasto; Análise Aerodinâmica; Validação CFD; Simulação de Desempenho.

**Execução (v2.0)**

| Parâmetro | Valor |
| --------- | ----- |
| Unidade de Processamento | Grupo Computacional de Cálculo (Math Core RP2350#2-C1); em modo Apenas Simulação/Offline quando aplicável |
| Taxa de Execução | Sob Pedido / Offline |
| Precisão Numérica | double |
| Custo Computacional | Médio |
| Criticidade Operacional | Apoio |
| Classificação de Software | Útil |
| Cálculo Redundante | Não |
| Validação Necessária | Não |
| Manter | Sim |

A consequência de uma falha é a redução da precisão do modelo. Necessária durante Simulação.

# 9. Reynolds Number — MAT-0083

A MAT-0083 — Reynolds Number determina o regime de escoamento através da relação entre forças inerciais e viscosas.

**Expressão Matemática**

$$Re=\frac{\rho VL}{\mu}$$

**Entradas**

| Variável | Descrição | Unidade |
| -------- | --------- | ------- |
| ρ | Densidade | kg/m³ |
| V | Velocidade | m/s |
| L | Comprimento Característico | m |
| μ | Viscosidade Dinâmica | Pa·s |

**Saída**

| Variável | Descrição | Unidade |
| -------- | --------- | ------- |
| Re | Número de Reynolds | - |

**Dependências:** Dynamic Pressure; Viscous Force (MAT-0056).

**Utilização:** Modelação Aerodinâmica; Análise de Estol; Validação CFD.

**Execução (v2.0)**

| Parâmetro | Valor |
| --------- | ----- |
| Unidade de Processamento | Grupo Computacional de Cálculo (Math Core RP2350#2-C1) |
| Taxa de Execução | Sob Pedido |
| Precisão Numérica | double |
| Custo Computacional | Baixo |
| Criticidade Operacional | Apoio |
| Classificação de Software | Importante |
| Cálculo Redundante | Não (admitir cópia local redundante onde determinístico se um monitor de estol a 10–50 Hz vier a necessitar; a validar em MAT-005/MAT-012) |
| Validação Necessária | Não |
| Manter | Sim |

A consequência de uma falha é a redução da precisão do modelo. Necessária durante Simulação e Análise de Desempenho.

# 10. Navier-Stokes Equation — MAT-0006

A MAT-0006 — Navier-Stokes Equation representa as equações gerais que regem o escoamento de um fluido viscoso.

**Expressão Matemática**

$$\rho\left(\frac{\partial v}{\partial t}+(v\cdot\nabla)v\right)=-\nabla p+f$$

**Entradas**

| Variável | Descrição | Unidade |
| -------- | --------- | ------- |
| ρ | Densidade | kg/m³ |
| v | Campo de Velocidades | m/s |
| p | Pressão | Pa |
| f | Forças de Corpo | N/m³ |

**Saída:** A solução da dinâmica do fluido, com múltiplas grandezas físicas dependentes da resolução.

**Dependências:** Resolvedor CFD (externo, em solo).

**Utilização:** Simulação CFD (em solo).

**Execução**

| Parâmetro | Valor |
| --------- | ----- |
| Unidade de Processamento | Nenhum a bordo (não servida pelo Math Core operacional) |
| Taxa de Execução | N/A |
| Precisão Numérica | double |
| Custo Computacional | Extremamente Alto |
| Criticidade Operacional | Experimental |
| Classificação de Software | Desnecessário a bordo |
| Cálculo Redundante | Não |
| Validação Necessária | Não |
| Manter | Não (como componente operacional; manter como documentação) |

A fórmula não possui utilização operacional a bordo. O catálogo classifica esta formulação como adequada para CFD e projecto aerodinâmico, mas inadequada para execução em tempo real a bordo. Permanece documentada para efeitos de análise, CFD e projecto.

# 11. Relação entre as Fórmulas

```text
Conservation of Mass (MAT-0037)
        │
        ▼
Continuity Equation (MAT-0005)
        │
        ├──────────────► Modelos Aerodinâmicos
        │
        └──────────────► Modelos de Entrada de Ar

Propriedades do Fluido
        │
        ├──────────────► Continuity Equation
        │
        └──────────────► Viscous Force (MAT-0056)
                              │
                              ▼
                       Reynolds Number (MAT-0083)

Ideal Gas Law
        │
        ▼
Isentropic Flow (MAT-0040)
        │
        ▼
Isentropic Momentum Equation (MAT-0041)
```

A Navier-Stokes Equation (MAT-0006) permanece separada da cadeia operacional por depender de um resolvedor CFD e possuir custo computacional incompatível com a execução operacional a bordo. Todas as setas «utiliza» concretizam-se em execução como `MATH_REQUEST` ao Math Core, salvo Navier-Stokes.

# 12. Distribuição Computacional (v2.0)

Todas as fórmulas mantidas deste domínio são servidas principalmente pelo **Grupo Computacional de Cálculo (Math Core RP2350#2-C1)**.

Nenhuma das fórmulas classificadas explicitamente como Mecânica dos Fluidos possui, no catálogo actual, execução operacional de ciclo rápido atribuída a grupos de aquisição ou actuação. Quando um dia for necessária (ex. Reynolds em monitor), a atribuição far-se-á como implementação local redundante onde determinístico, devidamente validada contra a referência do Math Core.

A distribuição computacional de cada fórmula permanece conforme a tabela de execução das secções 4–9 e o documento de alocação matemática. Transporte: FABRIC para pedidos intra-agrupamento; CAN-Principal para pedidos inter-grupos; nunca CAN-FailSafe (reservado a segurança) nem RJ45-RS (reservado a RF).

# 13. Frequência e Custo Computacional

As fórmulas deste domínio apresentam diferentes requisitos computacionais. As fórmulas destinadas a modelos operacionais ou de análise simplificada possuem custos reduzidos ou moderados.

A MAT-0006 constitui excepção, com custo extremamente alto e sem unidade de processamento a bordo.

A utilização de uma fórmula de Mecânica dos Fluidos não implica, por si só, execução contínua. A maioria encontra-se definida como Sob Pedido ou Sob Pedido / Offline — isto é, o requerente envia `MATH_REQUEST` apenas quando precisa (ex. recalcular polar de arrasto, validar entrada de ar), recebe `MATH_RESPONSE` e prossegue.

# 14. Redundância e Validação

As fórmulas deste domínio não possuem actualmente cálculo redundante obrigatório, por serem de apoio.

Se futuramente uma delas for chamada no ciclo crítico, aplicar-se-á a regra geral: referência no Math Core + cópia local determinística + comparação periódica.

As fórmulas actualmente classificadas como Mecânica dos Fluidos não possuem validação matemática adicional definida no catálogo. A validação de modelos que utilizem estas fórmulas poderá ocorrer através dos mecanismos específicos dos respectivos domínios funcionais, incluindo validação CFD e comparação com modelos experimentais quando aplicável.

# 15. Fórmulas Não Operacionais

A única fórmula deste domínio actualmente marcada como não mantida operacionalmente é MAT-0006 — Navier-Stokes Equation. A sua exclusão da execução operacional não implica a eliminação da formulação da documentação. Permanece relevante para CFD, projecto aerodinâmico, análise de escoamento e validação de modelos — em solo.

# 16. Relação com Outros Domínios

As fórmulas de Mecânica dos Fluidos são utilizadas por: Aerodinâmica; Propulsão; Modelos de Entrada de Ar; Análise de Desempenho; Simulação de Fluidos; Análise de Estol; Modelos de Escoamento Compressível.

A utilização por outro domínio não altera a classificação. As fórmulas permanecem centralizadas documentalmente neste domínio como serviço do Math Core, enquanto os modelos consumidores permanecem nos documentos funcionais.

# 17. Evolução do Domínio

A introdução de novas fórmulas deverá ser acompanhada pela actualização de: CATALOGO_MATEMATICA.md; CLASSIFICACAO_MATEMATICA.md; INDICE_MATEMATICA.md; ALOCACAO_MATEMATICA.md; ARQUITETURA.md.

Uma fórmula deverá ser integrada neste domínio apenas quando a sua classificação determinar explicitamente a pertença à categoria Mecânica dos Fluidos, já com alocação v2.0 (Math Core + local se determinístico).

# 18. Limites do Documento

Este documento não define: implementação de CFD; código-fonte; modelos aerodinâmicos completos; modelos de propulsão; parâmetros da aeronave; implementação de entrada de ar; sistemas de controlo; alocação definitiva de software além da regra Math Core; protocolos de comunicação (ver MAT-018); mecanismos de validação específicos de cada domínio funcional.

# 19. Referências

- AERUS/math/docs
             ├──ARQUITETURA.md
             ├──CATALOGO_MATEMATICA.md
             ├──CLASSIFICACAO_MATEMATICA.md
             ├──INDICE_MATEMATICA.md
             └──ALOCACAO_MATEMATICA.md
- MAT-001 — Fundamentos (base matemática)
- MAT-005 — Aerodinâmica (principal consumidora)
- MAT-018 — Matemática de Comunicações (transporte MATH_REQUEST/RESPONSE)
