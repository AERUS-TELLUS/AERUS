# MAT-003 — Mecânica dos Fluidos

| Campo         | Valor                   |
| ------------- | ----------------------- |
| Código        | MAT-003                 |
| Título        | Mecânica dos Fluidos    |
| Versão        | 1.0                     |
| Estado        | Em Desenvolvimento      |
| Autor         | ShegaPT                 |
| Classificação | Especificação Matemática|

# 1. Objetivo

O presente documento estabelece o domínio matemático de Mecânica dos Fluidos utilizado pelo sistema Aerus, reunindo as formulações destinadas à representação e análise do comportamento de fluidos.

Este domínio suporta principalmente modelos relacionados com escoamento de ar, conservação de massa, escoamento viscoso, escoamento compressível e análise de regimes de escoamento.

A definição individual de cada fórmula permanece no CATALOGO_MATEMATICA.md.

# 2. Âmbito

O domínio de Mecânica dos Fluidos abrange as fórmulas classificadas explicitamente como Mecânica dos Fluidos no catálogo matemático.

As fórmulas deste domínio são utilizadas principalmente em:

modelação aerodinâmica;
análise de escoamento;
modelos de entrada de ar;
propulsão;
simulação de fluidos;
análise de desempenho;
validação CFD;
análise de escoamento compressível.

Fórmulas relacionadas com fluidos que estejam classificadas no catálogo como pertencentes a outros domínios permanecem nesses respetivos domínios.

3. Fórmulas Abrangidas

O catálogo matemático identifica atualmente as seguintes fórmulas como pertencentes ao domínio de Mecânica dos Fluidos:

Código

Nome

Estado

MAT-0005

Continuity Equation

Mantida

MAT-0006

Navier-Stokes Equation

Não Mantida

MAT-0037

Conservation of Mass

Mantida

MAT-0040

Isentropic Flow

Mantida

MAT-0041

Isentropic Momentum Equation

Mantida

MAT-0056

Viscous Force

Mantida

MAT-0083

Reynolds Number

Mantida

O conjunto acima corresponde às fórmulas que o catálogo classifica explicitamente como Mecânica dos Fluidos.

4. Conservation of Mass — MAT-0037

A MAT-0037 — Conservation of Mass representa a conservação de massa num sistema fechado.

Expressão Matemática

$$\frac{dm}{dt}=0$$

Entradas

Variável

Descrição

Unidade

m

Massa

kg

t

Tempo

s

Saída

Variável

Descrição

Unidade

dm/dt

Taxa de variação da massa

kg/s

Utilização

A fórmula é utilizada por:

Aerodinâmica;

Propulsão;

Simulação de Fluidos.

Execução

Parâmetro

Valor

Unidade de Processamento

Raspberry Pi

Taxa de Execução

Sob Pedido

Precisão Numérica

double

Custo Computacional

Muito Baixo

Criticidade Operacional

Apoio

Classificação de Software

Obrigatório

Cálculo Redundante

Não

Validação Necessária

Não

Manter

Sim

A consequência de uma falha é a redução da precisão do modelo.

A fórmula é necessária durante:

Simulação;

Análise de Desempenho.

5. Continuity Equation — MAT-0005

A MAT-0005 — Continuity Equation representa a conservação de massa aplicada ao escoamento de um fluido.

Expressão Matemática

$$\rho_1A_1V_1=\rho_2A_2V_2$$

Forma Alternativa

$$\rho AV=\text{Constant}$$

Entradas

Variável

Descrição

Unidade

ρ

Densidade

kg/m³

A

Área

m²

V

Velocidade

m/s

Saída

Variável

Descrição

Unidade

Flow Conservation

Conservação do escoamento

-

Dependências

Propriedades do Fluido;

Conservation of Mass.

Utilização

A fórmula é utilizada por:

Modelos Aerodinâmicos;

Modelos de Entrada de Ar;

Propulsão.

Execução

Parâmetro

Valor

Unidade de Processamento

Raspberry Pi

Taxa de Execução

Sob Pedido

Precisão Numérica

float / double

Custo Computacional

Baixo

Criticidade Operacional

Apoio

Classificação de Software

Importante

Cálculo Redundante

Não

Validação Necessária

Não

Manter

Sim

A consequência de uma falha é a redução da precisão do modelo.

A fórmula é necessária durante:

Simulação;

Análise de Desempenho.

6. Isentropic Flow — MAT-0040

A MAT-0040 — Isentropic Flow descreve o escoamento adiabático compressível com entropia constante.

Expressão Matemática

$$\frac{P}{\rho^\gamma}=\text{Constant}$$

Entradas

Pressão P;

Densidade ρ;

Razão de calores específicos γ.

Saída

A constante isentrópica:

$$\frac{P}{\rho^\gamma}$$

Dependências

Ideal Gas Law.

Utilização

A fórmula é utilizada por:

Análise Pitot;

Modelos de Escoamento de Ar;

Propulsão.

Execução

Parâmetro

Valor

Unidade de Processamento

Raspberry Pi

Taxa de Execução

Sob Pedido

Precisão Numérica

double

Custo Computacional

Médio

Criticidade Operacional

Apoio

Classificação de Software

Importante

Cálculo Redundante

Não

Validação Necessária

Não

Manter

Sim

A consequência de uma falha é a redução da precisão do modelo.

A fórmula é necessária sob pedido.

7. Isentropic Momentum Equation — MAT-0041

A MAT-0041 — Isentropic Momentum Equation representa a equação do momento aplicada a escoamento isentrópico compressível.

Expressão Matemática

$$\rho V(dV)+dP=0$$

Entradas

Densidade ρ;

Velocidade V;

Pressão P.

Saída

Variação de pressão dP.

Dependências

Isentropic Flow.

Utilização

A fórmula é utilizada por:

Propulsão;

Análise de Escoamento Compressível.

Execução

Parâmetro

Valor

Unidade de Processamento

Raspberry Pi

Taxa de Execução

Sob Pedido

Precisão Numérica

double

Custo Computacional

Médio

Criticidade Operacional

Apoio

Classificação de Software

Importante

Cálculo Redundante

Não

Validação Necessária

Não

Manter

Sim

A consequência de uma falha é a redução da precisão do modelo.

A fórmula é necessária sob pedido.

8. Viscous Force — MAT-0056

A MAT-0056 — Viscous Force calcula a força de corte gerada pela viscosidade do fluido.

Expressão Matemática

$$F_v=\mu A\frac{dv}{dy}$$

Forma Alternativa

$$F=\mu A\frac{dv}{dy}$$

Entradas

Variável

Descrição

Unidade

μ

Viscosidade Dinâmica

Pa·s

A

Área de Superfície

m²

dv/dy

Gradiente de Velocidade

1/s

Saídas

Variável

Descrição

Unidade

Fᵥ

Força Viscosa

N

F

Força Viscosa

N

Dependências

Propriedades do Fluido;

Gradiente de Velocidade.

Utilização

A fórmula é utilizada por:

Modelação Aerodinâmica;

CFD;

Análise de Arrasto;

Análise Aerodinâmica;

Validação CFD;

Simulação de Desempenho.

Execução

Parâmetro

Valor

Unidade de Processamento

Raspberry Pi; Raspberry Pi (Apenas Simulação)

Taxa de Execução

Sob Pedido / Offline

Precisão Numérica

double

Custo Computacional

Médio

Criticidade Operacional

Apoio

Classificação de Software

Útil

Cálculo Redundante

Não

Validação Necessária

Não

Manter

Sim

A consequência de uma falha é a redução da precisão do modelo.

A fórmula é necessária durante Simulação.

9. Reynolds Number — MAT-0083

A MAT-0083 — Reynolds Number determina o regime de escoamento através da relação entre forças inerciais e viscosas.

Expressão Matemática

$$Re=\frac{\rho VL}{\mu}$$

Entradas

Variável

Descrição

Unidade

ρ

Densidade

kg/m³

V

Velocidade

m/s

L

Comprimento Característico

m

μ

Viscosidade Dinâmica

Pa·s

Saída

Variável

Descrição

Unidade

Re

Número de Reynolds

-

Dependências

Dynamic Pressure;

Viscous Force.

Utilização

A fórmula é utilizada por:

Modelação Aerodinâmica;

Análise de Estol;

Validação CFD.

Execução

Parâmetro

Valor

Unidade de Processamento

Raspberry Pi

Taxa de Execução

Sob Pedido

Precisão Numérica

double

Custo Computacional

Baixo

Criticidade Operacional

Apoio

Classificação de Software

Importante

Cálculo Redundante

Não

Validação Necessária

Não

Manter

Sim

A consequência de uma falha é a redução da precisão do modelo.

A fórmula é necessária durante:

Simulação;

Análise de Desempenho.

10. Navier-Stokes Equation — MAT-0006

A MAT-0006 — Navier-Stokes Equation representa as equações gerais que regem o escoamento de um fluido viscoso.

Expressão Matemática

$$\rho\left(\frac{\partial v}{\partial t}+(v\cdot\nabla)v\right)=-\nabla p+f$$

Entradas

Variável

Descrição

Unidade

ρ

Densidade

kg/m³

v

Campo de Velocidades

m/s

p

Pressão

Pa

f

Forças de Corpo

N/m³

Saída

A solução da dinâmica do fluido, com múltiplas grandezas físicas dependentes da resolução.

Dependências

Resolvedor CFD.

Utilização

Simulação CFD.

Execução

Parâmetro

Valor

Unidade de Processamento

Nenhum

Taxa de Execução

N/A

Precisão Numérica

double

Custo Computacional

Extremamente Alto

Criticidade Operacional

Experimental

Classificação de Software

Desnecessário

Cálculo Redundante

Não

Validação Necessária

Não

Manter

Não

A fórmula não possui utilização operacional a bordo.

O catálogo classifica esta formulação como adequada para CFD e projeto aerodinâmico, mas inadequada para execução em tempo real a bordo.

Consequentemente, permanece documentada neste domínio para efeitos de análise, CFD e projeto, mas não integra a execução operacional do Aerus.

11. Relação entre as Fórmulas

As fórmulas do domínio apresentam relações de dependência que podem ser representadas de forma simplificada:

Conservation of Mass
        │
        ▼
Continuity Equation
        │
        ├──────────────► Modelos Aerodinâmicos
        │
        └──────────────► Modelos de Entrada de Ar


Propriedades do Fluido
        │
        ├──────────────► Continuity Equation
        │
        └──────────────► Viscous Force
                              │
                              ▼
                       Reynolds Number


Ideal Gas Law
        │
        ▼
Isentropic Flow
        │
        ▼
Isentropic Momentum Equation

A Navier-Stokes Equation permanece separada da cadeia operacional por depender de um resolvedor CFD e possuir custo computacional incompatível com a execução operacional a bordo.

12. Distribuição Computacional

As fórmulas deste domínio são executadas principalmente no Grupo Computacional Raspberry Pi.

Nenhuma das fórmulas classificadas explicitamente como Mecânica dos Fluidos possui, no catálogo atual, execução operacional atribuída diretamente ao ESP32-S, ESP32-A ou ESP32-FS.

A distribuição computacional de cada fórmula deverá permanecer conforme definida no catálogo matemático e no documento de alocação matemática.

13. Frequência e Custo Computacional

As fórmulas deste domínio apresentam diferentes requisitos computacionais.

As fórmulas destinadas a modelos operacionais ou de análise simplificada possuem custos reduzidos ou moderados.

A MAT-0006 — Navier-Stokes Equation constitui uma exceção, sendo classificada com custo computacional extremamente alto e sem unidade de processamento atribuída.

A utilização de uma fórmula de Mecânica dos Fluidos não implica, por si só, execução contínua. A maioria das fórmulas deste domínio encontra-se definida como Sob Pedido ou Sob Pedido / Offline.

14. Redundância e Validação

As fórmulas deste domínio não possuem atualmente cálculo redundante definido.

A necessidade de redundância deverá ser determinada individualmente conforme a criticidade e utilização da fórmula.

As fórmulas atualmente classificadas como Mecânica dos Fluidos não possuem validação matemática adicional definida no catálogo.

A validação de modelos que utilizem estas fórmulas poderá ocorrer através dos mecanismos específicos dos respetivos domínios funcionais, incluindo validação CFD e comparação com modelos experimentais quando aplicável.

15. Fórmulas Não Operacionais

A única fórmula deste domínio atualmente marcada como não mantida é:

MAT-0006 — Navier-Stokes Equation.

A sua exclusão da execução operacional não implica a eliminação da formulação da documentação matemática do Aerus.

A fórmula permanece relevante para:

CFD;

projeto aerodinâmico;

análise de escoamento;

validação de modelos.

16. Relação com Outros Domínios

As fórmulas de Mecânica dos Fluidos são utilizadas por diferentes domínios funcionais do Aerus, nomeadamente:

Aerodinâmica;

Propulsão;

Modelos de Entrada de Ar;

Análise de Desempenho;

Simulação de Fluidos;

Análise de Estol;

Modelos de Escoamento Compressível.

A utilização de uma fórmula deste domínio por outro domínio não altera a sua classificação.

As fórmulas permanecem centralizadas documentalmente neste domínio, enquanto os modelos que as utilizam permanecem definidos nos respetivos documentos funcionais.

17. Evolução do Domínio

A introdução de novas fórmulas de Mecânica dos Fluidos deverá ser acompanhada pela atualização dos documentos matemáticos de referência.

Quando aplicável, deverão ser atualizados:

CATALOGO_MATEMATICA.md;

CLASSIFICACAO_MATEMATICA.md;

INDICE_MATEMATICA.md;

ALOCACAO_MATEMATICA.md;

ARQUITETURA.md.

Uma fórmula deverá ser integrada neste domínio apenas quando a sua classificação matemática determinar explicitamente a sua pertença à categoria Mecânica dos Fluidos.

18. Limites do Documento

Este documento não define:

implementação de CFD;

código-fonte das fórmulas;

modelos aerodinâmicos completos;

modelos de propulsão;

parâmetros específicos da aeronave;

implementação de modelos de entrada de ar;

implementação dos sistemas de controlo;

alocação definitiva de software;

protocolos de comunicação;

mecanismos de validação específicos de cada domínio funcional.

Esses aspetos são definidos nos respetivos documentos técnicos e matemáticos.

19. Referências

- AERUS/math/docs
             ├──ARQUITETURA.md
             ├──CATALOGO_MATEMATICA.md
             ├──CLASSIFICACAO_MATEMATICA.md
             ├──INDICE_MATEMATICA.md
             └──ALOCACAO_MATEMATICA.md
