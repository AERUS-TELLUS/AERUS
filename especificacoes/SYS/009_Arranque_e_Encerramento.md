# SYS-009 — Arranque_e_Encerramento

| Campo             | Valor                    |
| ----------------- | ------------------------ |
| **Código**        | SYS-009                  |
| **Título**        | Arranque e Encerramento  |
| **Versão**        | 1.0                      |
| **Estado**        | Em Desenvolvimento       |
| **Autor**         | ShegaPT                  |
| **Classificação** | Especificação de Sistema |

---

# 1. Objetivo

O presente documento define a arquitetura geral dos processos de arranque, preparação operacional, encerramento e desativação do sistema Aerus.

O processo foi concebido segundo princípios de operação aeronáutica, combinando verificações efetuadas pelo operador com verificações executadas pelo próprio sistema.

O Aerus deverá considerar o arranque e o encerramento como processos controlados e verificáveis, não como simples operações de alimentação ou desligamento dos grupos computacionais.

---

# 2. Princípio Geral

A operação do Aerus inicia-se através de uma sequência de verificações.

Estas verificações dividem-se em duas categorias principais:

* verificações efetuadas pelo operador;
* verificações efetuadas pelo sistema.

As verificações do operador podem incluir inspeções físicas, visuais e funcionais da aeronave.

As verificações do sistema podem incluir validações de hardware, sensores, atuadores, comunicações, configuração, sincronização temporal e restantes condições necessárias à operação.

---

# 3. Before_Start

O modo `Before_Start` corresponde à preparação inicial da aeronave antes da ativação do sistema.

Nesta fase o Aerus encontra-se dependente do operador para a execução das verificações externas à capacidade do sistema.

O operador deverá executar o respetivo checklist operacional.

As verificações poderão incluir, entre outras:

* inspeção visual da aeronave;
* inspeção física;
* verificação da integridade estrutural;
* verificação dos componentes instalados;
* verificação dos sistemas necessários à missão;
* verificação das condições externas;
* confirmação da configuração da aeronave;
* confirmação da configuração da missão;
* outras verificações determinadas pelo procedimento operacional.

O checklist completo é definido na documentação `OPS/`.

---

# 4. Ativação do Sistema

A conclusão do checklist `Before_Start` constitui a condição necessária para a ativação do sistema.

A ativação poderá envolver:

* alimentação dos grupos computacionais;
* inicialização dos sistemas eletrónicos;
* inicialização das interfaces;
* inicialização dos mecanismos de comunicação;
* início da sincronização temporal;
* carregamento das configurações aplicáveis.

A aplicação de alimentação não deverá, por si só, significar que a aeronave se encontra pronta para voo.

---

# 5. After_Start

Após a ativação do sistema, o Aerus entra no modo `After_Start`.

Esta fase corresponde principalmente à execução de verificações internas do sistema.

O Aerus deverá validar, de acordo com a configuração da aeronave:

* grupos computacionais;
* comunicações;
* sincronização temporal;
* sensores;
* atuadores;
* configuração;
* módulos necessários;
* estados internos;
* integridade dos dados;
* condições necessárias à operação.

Poderão existir verificações que requerem intervenção ou confirmação do operador.

Um exemplo é a confirmação da resposta dos sistemas de controlo.

---

# 6. Validação Pós-Arranque

O sistema não deverá considerar a inicialização concluída apenas porque os grupos computacionais foram iniciados.

Os sistemas necessários à operação deverão ser verificados individualmente.

A conclusão satisfatória destas verificações permite avançar para a fase operacional seguinte.

Qualquer condição incompatível com a continuação da operação deverá ser tratada de acordo com as regras aplicáveis.

---

# 7. Taxi

O modo `Taxi` é opcional e depende das características físicas e operacionais da aeronave.

Aeronaves que disponham de capacidade de deslocação em solo poderão utilizar este modo.

Aeronaves que não necessitem ou não possuam essa capacidade poderão transitar diretamente para `Line_Up`.

Durante `Taxi`, o Aerus deverá manter as funções necessárias ao controlo seguro da aeronave no solo.

---

# 8. Line_Up

O modo `Line_Up` corresponde à preparação final da aeronave para a descolagem.

Nesta fase a aeronave encontra-se, em princípio, fisicamente posicionada para iniciar a descolagem.

Poderão ser executadas:

* verificações finais;
* validações de configuração;
* ajustes de calibração;
* confirmação de sensores;
* confirmação de parâmetros operacionais;
* confirmação da disponibilidade dos sistemas necessários.

As operações concretas são definidas pelos procedimentos da aeronave e respetivos checklists.

---

# 9. Before_TakeOff

O modo `Before_TakeOff` corresponde à última fase de preparação em solo antes da descolagem.

Nesta fase é executado o checklist final de solo.

O sistema deverá confirmar que as condições necessárias à descolagem estão satisfeitas.

A transição para a fase de descolagem deverá depender da conclusão satisfatória das verificações aplicáveis.

---

# 10. After_TakeOff

Após a aeronave abandonar o solo, o Aerus entra no modo `After_TakeOff`.

Este modo corresponde à verificação imediata pós-descolagem.

O sistema deverá verificar o funcionamento dos sistemas necessários ao voo, incluindo, quando aplicável:

* sensores utilizados no solo;
* sensores utilizados em voo;
* sistemas de controlo;
* sistemas de navegação;
* sistemas de aquisição;
* restantes sistemas necessários à operação.

O objetivo é confirmar que os sistemas apresentam comportamento consistente após a transição efetiva para voo.

---

# 11. In_Flight

Após a conclusão das verificações pós-descolagem, o Aerus entra no modo `In_Flight`.

Este constitui o principal modo operacional durante o voo.

Durante esta fase o sistema executa continuamente as funções necessárias à missão, controlo, navegação, gestão energética, aquisição de dados, comunicações e segurança.

Poderão existir verificações contínuas ou periódicas destinadas a confirmar o funcionamento correto dos sistemas.

Ao contrário das fases de preparação e aterragem, não existe um checklist operacional discreto associado a cada instante do voo.

As verificações necessárias são executadas continuamente pelos respetivos módulos.

---

# 12. Before_Landing

A aproximação à fase de aterragem inicia a transição para `Before_Landing`.

Este modo corresponde à preparação e verificação da aeronave antes do início efetivo da sequência de aterragem.

O Aerus deverá verificar as condições necessárias para executar a aterragem de forma segura.

Poderão ser verificadas, entre outras:

* disponibilidade dos sensores necessários;
* disponibilidade dos sistemas de controlo;
* condições de navegação;
* estado da aeronave;
* configuração de aterragem;
* condições da missão;
* condições externas relevantes.

---

# 13. Descent

Após a preparação para aterragem, o Aerus entra no modo `Descent`.

Nesta fase é executada a gestão da descida e dos periféricos necessários à preparação da aeronave para aterragem.

Dependendo da configuração da aeronave, poderão ser geridos sistemas como:

* iluminação;
* trem de aterragem;
* superfícies ou dispositivos específicos;
* outros periféricos externos.

A utilização destes sistemas depende da configuração específica da aeronave.

O Aerus deverá utilizar apenas os recursos aplicáveis à configuração instalada.

---

# 14. Approach

O modo `Approach` corresponde à aproximação final.

Nesta fase o Aerus deverá preparar progressivamente a aeronave para o contacto com o solo.

Módulos que já não sejam necessários poderão ser colocados em estado de espera ou desativados, desde que tal seja permitido pelas regras aplicáveis e não comprometa a segurança.

A redução de atividade computacional deverá ser efetuada de forma controlada.

---

# 15. Deteção do Solo

Durante `Approach`, os sensores destinados à deteção da proximidade do solo poderão começar a produzir medições relevantes para a aterragem.

Exemplos incluem:

* sensores ultrassónicos;
* sensores óticos;
* outros sensores de distância ou proximidade.

A entrada no modo `Landing` deverá depender da obtenção de medições consistentes e das restantes condições definidas para a aterragem.

A simples obtenção de uma medição isolada não deverá ser considerada suficiente quando forem necessárias medições consistentes.

---

# 16. Landing

O modo `Landing` corresponde à fase final da aterragem.

Nesta fase o Aerus deverá executar as funções necessárias para controlar a aeronave até ao estabelecimento de uma condição de solo segura.

Os sistemas necessários para a aterragem deverão permanecer ativos até deixarem de ser necessários.

Após a confirmação das condições de solo aplicáveis, o Aerus deverá avançar para `After_Landing`.

---

# 17. After_Landing

Após a aterragem, o Aerus entra no modo `After_Landing`.

Nesta fase são executadas as ações necessárias para estabilizar a aeronave após o contacto com o solo.

Módulos e periféricos que já não sejam necessários poderão ser progressivamente colocados em espera ou desativados.

A desativação deverá respeitar as dependências existentes entre módulos e sistemas.

---

# 18. Parking

O modo `Parking` é opcional e aplica-se às aeronaves que utilizem procedimentos de deslocação em solo após a aterragem.

Quando aplicável, a aeronave poderá deslocar-se para a posição definida antes de iniciar o procedimento de segurança da aeronave.

Aeronaves que não utilizem `Parking` poderão transitar diretamente de `After_Landing` para `Securing_Aircraft`.

---

# 19. Securing_Aircraft

O modo `Securing_Aircraft` corresponde à colocação da aeronave numa condição segura após a conclusão da operação de voo.

Nesta fase deverão ser executados os procedimentos necessários para impedir ações não intencionais dos sistemas da aeronave.

Poderão ser incluídas ações como:

* bloqueio dos motores;
* inibição de determinados atuadores;
* desativação de funções de controlo;
* colocação de sistemas em condição segura;
* confirmação de que não existem comandos de voo ativos.

As ações concretas dependem da configuração da aeronave e dos respetivos procedimentos.

---

# 20. Shutdown

O modo `Shutdown` corresponde à fase final da operação.

Esta fase volta a envolver o operador de forma direta.

O operador deverá executar o checklist de encerramento aplicável.

Este checklist deverá garantir, entre outros aspetos:

* integridade da aeronave;
* condição segura dos atuadores;
* condição segura dos motores;
* condição dos sistemas eletrónicos;
* condição dos sistemas de energia;
* preservação dos equipamentos;
* conclusão da missão;
* preparação para desligamento.

Apenas após a conclusão das verificações aplicáveis deverá ser efetuado o desligamento físico do sistema.

---

# 21. Desligamento Físico

O encerramento lógico do Aerus deverá preceder o desligamento físico da alimentação.

Quando todos os procedimentos aplicáveis estiverem concluídos, o operador poderá:

* desligar a alimentação;
* desconectar baterias;
* executar procedimentos de armazenamento;
* executar procedimentos adicionais definidos para a aeronave.

A ordem exata destas operações deverá ser definida em `OPS/`.

---

# 22. Interrupção Anormal

Uma falha durante qualquer fase de arranque ou encerramento poderá impedir a progressão normal da sequência.

Nestes casos, o Aerus deverá aplicar as regras correspondentes à condição detetada.

A deteção e tratamento de situações de segurança são definidos na especificação `SEC/`.

A sequência normal de arranque ou encerramento nunca deverá ter prioridade sobre uma condição de segurança que exija intervenção.

---

# 23. Relação com os Modos de Funcionamento

Os procedimentos definidos neste documento correspondem aos modos operacionais estabelecidos em `SYS-007`.

A sequência geral é:

```text
Before_Start
      ↓
After_Start
      ↓
Taxi  ──────────────┐
      ↓             │
Line_Up ←───────────┘
      ↓
Before_TakeOff
      ↓
After_TakeOff
      ↓
In_Flight
      ↓
Before_Landing
      ↓
Descent
      ↓
Approach
      ↓
Landing
      ↓
After_Landing
      ↓
Parking ───────────┐
      ↓            │
Securing_Aircraft ←┘
      ↓
Shutdown
```

`Taxi` e `Parking` são etapas opcionais dependentes da configuração da aeronave.

---

# 24. Princípio de Configuração

O processo de arranque e encerramento deverá ser adaptável à configuração específica da aeronave.

Aerus deverá conseguir determinar quais os procedimentos aplicáveis à configuração instalada sem assumir a existência de sistemas que não façam parte da aeronave.

Por exemplo, uma aeronave sem trem de aterragem não deverá possuir requisitos operacionais relacionados com esse periférico.

---

# 25. Separação entre Sistema e Operador

O processo de operação combina duas fontes de validação:

### Operador

Responsável pelas verificações que exigem intervenção física, visual ou decisão operacional.

### Aerus

Responsável pelas verificações que podem ser executadas automaticamente pelos sistemas computacionais.

Nenhuma destas fontes deverá ser considerada substituta absoluta da outra.

A separação exata das responsabilidades é definida pelos procedimentos operacionais.

---

# 26. Referências

SYS-006 — Gestao_de_Estados
SYS-007 — Modos_de_Funcionamento
SYS-008 — Gestao_Temporal
OPS — Especificações Operacionais
SEN — Especificações de Sensores
ACT — Especificações de Atuadores
NAV — Especificações de Navegação
CTL — Especificações de Controlo
SEC — Especificações de Segurança
ENE — Especificações Energéticas
