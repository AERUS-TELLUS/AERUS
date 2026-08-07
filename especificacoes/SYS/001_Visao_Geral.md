# SYS-001 — Visão Geral do Sistema

| Campo             | Valor                    |
|-------------------|--------------------------|
| **Código**        | SYS-001                  |
| **Título**        | Visão Geral do Sistema   |
| **Versão**        | 1.0                      |
| **Estado**        | Em Desenvolvimento       |
| **Autor**         | ShegaPT                  |
| **Classificação** | Especificação de Sistema |

---

# 1. Objetivo

O presente documento estabelece a visão geral do sistema **Aerus**, definindo a sua finalidade, filosofia de desenvolvimento, domínio de aplicação, princípios fundamentais e enquadramento na arquitetura global do projeto.

Este documento constitui a referência conceptual de todo o sistema, servindo de base para as restantes especificações técnicas.

Não são descritos neste documento aspetos específicos relativos à arquitetura computacional, hardware, software, modelos matemáticos ou protocolos de comunicação, os quais são desenvolvidos nas respetivas especificações.

---

# 2. Âmbito

O Aerus é um sistema autónomo de controlo de voo distribuído destinado a aeronaves não tripuladas (UAV) de asa fixa.

O sistema foi concebido para proporcionar elevados níveis de precisão, segurança, modularidade e configurabilidade, permitindo a sua adaptação a diferentes aeronaves de asa fixa e aos respetivos domínios de aplicação, sem comprometer a arquitetura fundamental do sistema.

Embora o domínio principal de aplicação seja a agricultura de precisão, a arquitetura do Aerus foi concebida de forma suficientemente genérica para permitir a sua adaptação a outros contextos operacionais compatíveis, nomeadamente inspeção técnica, monitorização ambiental, vigilância, proteção civil ou outras missões especializadas.

---

# 3. Definição do Sistema

O Aerus é um Sistema Autónomo de Controlo de Voo Distribuído para aeronaves não tripuladas de asa fixa, concebido para proporcionar elevados níveis de precisão, segurança, modularidade e configurabilidade, permitindo a sua adaptação a diferentes aeronaves e aos respetivos domínios de aplicação sem alterar a arquitetura fundamental do sistema.

O sistema é responsável pela execução autónoma de todas as funções relacionadas com o voo da aeronave, incluindo a aquisição de dados, estimativa do estado, navegação, guiamento, controlo, monitorização e gestão de segurança operacional.

O Aerus não constitui um sistema dedicado a uma missão específica, mas sim uma plataforma de voo autónoma capaz de suportar diferentes perfis operacionais através da parametrização do sistema e da integração de implementos externos compatíveis.

---

# 4. Filosofia de Desenvolvimento

O desenvolvimento do Aerus baseia-se nos seguintes princípios fundamentais:

- Segurança como prioridade absoluta.
- Arquitetura computacional distribuída.
- Elevada precisão na estimativa do estado da aeronave.
- Modularidade funcional.
- Elevada configurabilidade.
- Escalabilidade entre diferentes plataformas.
- Separação entre sistema de voo e sistemas de missão.
- Desenvolvimento orientado para rastreabilidade e certificação.

Todas as decisões de arquitetura deverão respeitar estes princípios.

Sempre que exista conflito entre desempenho, funcionalidade e segurança, deverá prevalecer a solução que maximize a segurança operacional.

---

# 5. Objetivos do Projeto

O projeto Aerus possui como objetivo principal o desenvolvimento de um sistema autónomo de voo capaz de controlar aeronaves de asa fixa de forma segura, precisa e fiável.

Os principais objetivos incluem:

- controlo autónomo da aeronave;
- execução automática de missões;
- elevada precisão de navegação;
- arquitetura modular e distribuída;
- integração transparente com implementos externos;
- facilidade de adaptação a diferentes aeronaves;
- redução da necessidade de alterações ao núcleo do sistema;
- suporte à certificação pelas entidades competentes.

---

# 6. Domínio de Aplicação

O Aerus foi concebido prioritariamente para aeronaves agrícolas de asa fixa destinadas à execução de missões de agricultura de precisão.

Entre as aplicações previstas incluem-se, entre outras:

- pulverização líquida;
- pulverização sólida;
- monitorização agrícola;
- inspeção de culturas;
- recolha de dados ambientais.

A arquitetura permite igualmente a adaptação do sistema para outros domínios de utilização compatíveis com aeronaves de asa fixa, mediante a parametrização adequada e, quando necessário, através da integração de implementos específicos.

---

# 7. Implementos Externos

O Aerus foi concebido para funcionar de forma totalmente autónoma e independente da existência de qualquer implemento externo.

A instalação de implementos não constitui um requisito para o funcionamento normal do sistema.

Os implementos representam sistemas independentes, dotados de hardware e software próprios, responsáveis pela execução das respetivas funções específicas.

A comunicação entre o Aerus e qualquer implemento deverá ocorrer exclusivamente através de interfaces normalizadas definidas pelo sistema.

Sempre que um implemento seja instalado, o Aerus deverá identificar automaticamente as capacidades disponibilizadas, bem como as variáveis relevantes para a execução segura da missão.

O Aerus não assume o controlo interno do implemento, limitando-se à utilização da informação necessária ao correto controlo da aeronave e à execução da missão.

As especificações relativas aos implementos encontram-se descritas na série de documentos **IMP**.

---

# 8. Características Gerais

O Aerus caracteriza-se por:

- arquitetura computacional distribuída;
- separação entre aquisição, processamento, controlo e segurança;
- elevada redundância funcional;
- elevada capacidade de configuração;
- independência relativamente aos implementos;
- arquitetura preparada para expansão futura;
- utilização intensiva de modelos matemáticos;
- suporte para múltiplas configurações de aeronaves de asa fixa.

---

# 9. Estrutura das Especificações

A documentação técnica do Aerus encontra-se organizada em diferentes domínios de especificação, agrupando os vários aspetos do sistema segundo a respetiva área funcional.

Cada domínio possui documentação própria e independente, permitindo uma evolução modular da arquitetura sem comprometer a coerência global do projeto.

---

# 10. Referências

As referências específicas serão indicadas em cada documento da respetiva área técnica.

O presente documento deverá ser considerado a referência conceptual para todas as restantes especificações do sistema.
