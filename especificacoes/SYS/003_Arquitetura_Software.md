# SYS-003 — Arquitetura de Software

| Campo             | Valor                    |
|-------------------|--------------------------|
| **Código**        | SYS-003                  |
| **Título**        | Arquitetura de Software  |
| **Versão**        | 1.0                      |
| **Estado**        | Em Desenvolvimento       |
| **Autor**         | Projeto Aerus            |
| **Classificação** | Especificação de Sistema |

---

# 1. Objetivo

O presente documento define a arquitetura lógica do software do sistema **Aerus**, estabelecendo os princípios de organização, modularização, comunicação, dependências e responsabilidades dos diferentes componentes de software.

Este documento não descreve algoritmos específicos nem detalhes de implementação, servindo como referência arquitetónica para todas as restantes especificações de software.

---

# 2. Princípios Fundamentais

Toda a arquitetura de software do Aerus deverá respeitar os seguintes princípios:

- Modularidade;
- Separação de responsabilidades;
- Baixo acoplamento;
- Elevada coesão;
- Escalabilidade;
- Parametrização;
- Determinismo;
- Reutilização;
- Independência entre domínios computacionais;
- Facilidade de manutenção.

Nenhum módulo deverá assumir responsabilidades pertencentes a outro módulo sem uma justificação funcional devidamente definida.

---

# 3. Organização Modular

O software do Aerus encontra-se dividido em módulos independentes.

Cada módulo possui uma responsabilidade funcional claramente definida e deverá executar exclusivamente as funções pertencentes ao seu domínio.

Sempre que possível, um módulo deverá desconhecer os detalhes internos de implementação dos restantes módulos.

A interação entre módulos deverá ocorrer apenas através das interfaces definidas pela arquitetura do sistema.

---

# 4. Responsabilidade dos Módulos

Cada módulo deverá possuir uma responsabilidade única e bem delimitada.

Sempre que uma determinada funcionalidade possa ser claramente separada das restantes, deverá ser implementada como um módulo autónomo.

A existência de módulos independentes visa:

- reduzir dependências;
- facilitar testes;
- simplificar manutenção;
- permitir evolução independente;
- aumentar a previsibilidade do sistema.

---

# 5. Comunicação Entre Módulos

A comunicação direta entre módulos é permitida.

Contudo, apenas deverá ocorrer quando existir uma necessidade funcional claramente identificada.

Na ausência dessa necessidade, a informação deverá seguir o fluxo normal definido pela arquitetura global do sistema.

O objetivo consiste em minimizar dependências desnecessárias sem limitar a eficiência do sistema.

---

# 6. Camadas Funcionais

O Aerus organiza os seus módulos em camadas funcionais.

As camadas representam agrupamentos lógicos de responsabilidades e não constituem limitações rígidas da arquitetura.

Um mesmo módulo poderá pertencer simultaneamente a mais do que uma camada funcional, desde que tal seja tecnicamente justificado.

As camadas destinam-se exclusivamente a facilitar a organização da arquitetura e a compreensão do sistema.

---

# 7. Independência dos Domínios Computacionais

Cada domínio computacional possui a sua própria organização interna de software.

Os módulos pertencentes a um determinado domínio não dependem da implementação existente noutros domínios.

Sempre que um domínio necessite de determinada funcionalidade, esta deverá existir localmente nesse domínio.

Esta abordagem elimina dependências de execução entre diferentes unidades computacionais.

---

# 8. Bibliotecas Comuns por Domínio

Cada domínio computacional poderá possuir um conjunto próprio de bibliotecas comuns.

Estas bibliotecas poderão incluir, entre outras:

- Matemática;
- Geometria;
- Conversões;
- Utilitários;
- Tipos de dados;
- Protocolos;
- Configuração.

As bibliotecas pertencentes a um domínio computacional são independentes das bibliotecas existentes noutros domínios.

Sempre que um domínio seja constituído por múltiplas unidades computacionais, todas deverão utilizar exatamente a mesma versão das respetivas bibliotecas.

---

# 9. Processos Independentes

Sempre que a plataforma computacional o permita, cada módulo deverá executar como um processo independente.

A separação entre processos visa:

- aumentar a robustez;
- reduzir interferências;
- facilitar reinícios individuais;
- melhorar a monitorização;
- simplificar manutenção.

A arquitetura deverá evitar dependências críticas entre processos.

---

# 10. Gestão Dinâmica de Recursos

O Aerus deverá utilizar os recursos computacionais de forma dinâmica.

Os módulos que não sejam necessários durante uma determinada fase da operação poderão ser suspensos ou terminados.

Os recursos libertados deverão ficar imediatamente disponíveis para os restantes módulos do sistema.

A ativação e desativação dos módulos deverá ocorrer de forma transparente, sem comprometer a estabilidade global do sistema.

---

# 11. Parametrização

O software do Aerus deverá ser parametrizado.

A adaptação a diferentes aeronaves deverá ser efetuada através de parâmetros de configuração e não através da criação de versões específicas do código.

Antes da compilação deverão ser fornecidas todas as configurações necessárias à aeronave que irá utilizar o sistema.

Após compilação, o software resultante deverá conter apenas os componentes e parâmetros necessários à plataforma alvo.

---

# 12. Evolução Modular

Cada módulo deverá poder evoluir independentemente dos restantes.

Sempre que possível, alterações internas a um módulo não deverão obrigar à modificação dos restantes módulos.

A substituição de algoritmos, modelos matemáticos ou implementações deverá ocorrer mantendo as interfaces públicas previamente definidas.

---

# 13. Gestão de Comunicações

A comunicação entre módulos e entre domínios computacionais deverá ser efetuada através de um gestor de comunicações dedicado.

Este gestor é responsável por:

- receção de mensagens;
- validação;
- encaminhamento;
- gestão de prioridades;
- gestão de eventos;
- gestão de filas;
- entrega ao destinatário.

Nenhum módulo deverá implementar mecanismos próprios de comunicação paralelos à arquitetura definida pelo sistema.

---

# 14. Interfaces

Cada módulo deverá expor apenas as interfaces estritamente necessárias ao desempenho das suas funções.

O acesso direto a estruturas internas de outros módulos deverá ser evitado.

Sempre que possível, as interfaces deverão manter-se estáveis ao longo da evolução do sistema.

---

# 15. Escalabilidade

A arquitetura de software do Aerus deverá permitir:

- introdução de novos módulos;
- remoção de módulos existentes;
- substituição de algoritmos;
- atualização de bibliotecas;
- evolução da arquitetura;

sem necessidade de reformular significativamente o restante sistema.

---

# 16. Referências

SYS-001 — Visão Geral do Sistema
SYS-002 — Arquitetura Computacional
SYS-004 — Arquitetura Hardware
SYS-005 — Fluxo Global de Informação
SW — Especificações de Software
MAT — Especificações Matemáticas
COM — Especificações de Comunicações