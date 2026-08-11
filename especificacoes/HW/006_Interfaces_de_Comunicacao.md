# HW-006 — Interfaces_de_Comunicacao

| Campo             | Valor                     |
| ----------------- | ------------------------- |
| **Código**        | HW-006                    |
| **Título**        | Interfaces de Comunicação |
| **Versão**        | 1.0                       |
| **Estado**        | Em Desenvolvimento        |
| **Autor**         | ShegaPT                   |
| **Classificação** | Especificação de Hardware |

---

# 1. Objetivo

O presente documento define a arquitetura das interfaces utilizadas para comunicação entre os diferentes Grupos Computacionais que constituem o Aerus.

O objetivo é estabelecer quais os meios físicos de comunicação utilizados, os princípios gerais de ligação entre os diferentes domínios e as condições gerais para troca de informação entre elementos computacionais.

A definição detalhada do protocolo de comunicação pertence à especificação `COM/`.

---

# 2. Princípio Geral

A comunicação entre diferentes elementos de hardware do Aerus deverá utilizar interfaces físicas adequadas à função e à arquitetura do sistema.

Na arquitetura atualmente definida, a comunicação entre diferentes hardwares será realizada através de **UART**.

Isto aplica-se tanto a:

* comunicação entre ESP32 e RaspberryPi;
* comunicação entre diferentes RaspberryPi;
* comunicação entre diferentes elementos de outros Grupos Computacionais quando aplicável.

---

# 3. UART

A UART constitui a interface física de comunicação entre diferentes domínios computacionais do Aerus.

A utilização de UART deverá permitir comunicação:

* entre microcontroladores;
* entre microcontroladores e RaspberryPi;
* entre diferentes elementos RaspberryPi;
* entre elementos pertencentes ao mesmo Grupo Computacional quando necessário.

Os parâmetros elétricos e de configuração concretos de cada ligação serão definidos na configuração específica da aeronave.

---

# 4. Separação entre Interface e Protocolo

A UART define o meio físico de transporte.

O conteúdo transportado pela UART será organizado segundo o protocolo de comunicação do Aerus.

De forma simplificada:

```text
┌───────────────────────────────┐
│          Aerus COM            │
│                               │
│   TLV + Prioridade + Eventos  │
│   Filas + Gestão de Mensagens │
└───────────────┬───────────────┘
                │
                ▼
              UART
                │
                ▼
┌───────────────────────────────┐
│      Outro Grupo Computacional│
└───────────────────────────────┘
```

A especificação detalhada desta camada pertence a `COM/`.

---

# 5. Comunicação entre Grupos Computacionais

Os diferentes Grupos Computacionais poderão comunicar entre si sempre que exista uma necessidade funcional válida.

A existência de uma ligação física entre dois grupos não significa que todos os dados devam ser diretamente partilhados entre eles.

Cada comunicação deverá possuir uma finalidade lógica dentro da arquitetura.

Quando uma informação puder seguir o fluxo normal do sistema, deverá preferencialmente utilizar esse fluxo em vez de criar uma comunicação direta desnecessária.

---

# 6. Ligações Atualmente Definidas

A arquitetura atualmente estabelecida contempla as seguintes comunicações:

```text
                 ┌──────────────┐
                 │   ESP32-FS   │
                 └──────┬───────┘
                        │
          ┌─────────────┼─────────────┐
          │             │             │
          ▼             ▼             ▼
     ESP32-S       RaspberryPi     ESP32-FS_A
          │             │
          │             │
          └──────┬──────┘
                 │
                 ▼
              ESP32-A
```

Esta representação demonstra apenas as relações atualmente estabelecidas e não constitui ainda o esquema definitivo da topologia física.

---

# 7. ESP32-S

O Grupo Computacional ESP32-S deverá comunicar diretamente com:

* RaspberryPi;
* ESP32-FS.

A comunicação com RaspberryPi permite disponibilizar os dados de sensores ao sistema de operação normal.

A comunicação com ESP32-FS permite que o domínio de segurança tenha acesso aos dados necessários para executar as suas próprias avaliações.

O ESP32-S não deverá depender exclusivamente do RaspberryPi para disponibilizar informação ao ESP32-FS.

---

# 8. RaspberryPi

O Grupo Computacional RaspberryPi deverá comunicar diretamente com:

* ESP32-S;
* ESP32-A;
* ESP32-FS;
* outros elementos RaspberryPi quando existirem.

A comunicação com ESP32-A permite ao RaspberryPi enviar os comandos de controlo resultantes do processamento de voo.

A comunicação com ESP32-FS permite ao RaspberryPi solicitar ações relacionadas com segurança e receber informação proveniente desse domínio.

O RaspberryPi não comunica diretamente com ESP32-FS_A.

---

# 9. ESP32-A

O Grupo Computacional ESP32-A deverá receber os comandos normais de controlo de voo diretamente do RaspberryPi.

O ESP32-A poderá ainda receber do ESP32-FS uma ordem específica de **inibição**.

Essa ordem não constitui um comando de voo.

Consequentemente:

```text
RaspberryPi ──────► ESP32-A
   comandos de voo

ESP32-FS ─────────► ESP32-A
   inibição
```

O ESP32-FS não deverá enviar comandos normais de controlo de voo ao ESP32-A.

---

# 10. ESP32-FS

O Grupo Computacional ESP32-FS possui a posição hierárquica superior no domínio de segurança.

Deverá possuir comunicação com os restantes Grupos Computacionais necessários à execução das suas responsabilidades.

Entre as comunicações atualmente definidas encontram-se:

* ESP32-S;
* RaspberryPi;
* ESP32-A;
* ESP32-FS_A.

A comunicação do ESP32-FS com os restantes grupos não significa que este assuma automaticamente todas as funções desses grupos.

A comunicação deverá servir exclusivamente as responsabilidades atribuídas ao domínio de segurança.

---

# 11. ESP32-FS_A

O Grupo Computacional ESP32-FS_A recebe ordens diretamente do ESP32-FS.

Não deverá receber comandos normais de voo provenientes do RaspberryPi.

A comunicação existente entre ESP32-FS e ESP32-FS_A deverá permitir ao domínio de segurança executar as funções atribuídas ao ESP32-FS_A durante condições de FailSafe/FailSecure.

---

# 12. Comunicação Normal e Comunicação de Segurança

A arquitetura deverá distinguir logicamente entre:

**Comunicação operacional normal**

```text
RaspberryPi
    │
    ▼
ESP32-A
```

e:

**Comunicação de segurança**

```text
ESP32-FS
    │
    ├──► ESP32-A
    │       inibição
    │
    └──► ESP32-FS_A
            comandos de segurança
```

A existência de ambas as vias deverá permitir que o domínio de segurança mantenha a capacidade de intervir quando necessário sem assumir o controlo normal do sistema de voo.

---

# 13. Comunicação Direta

Uma comunicação direta entre dois módulos poderá ser utilizada quando existir uma razão lógica para tal.

A comunicação direta deverá ser preferida quando:

* a informação for necessária diretamente pelo destinatário;
* o fluxo normal provocar atraso desnecessário;
* existir uma necessidade de segurança;
* existir uma necessidade temporal;
* o acesso direto reduzir processamento ou complexidade.

A comunicação direta não deverá ser utilizada simplesmente porque existe uma ligação física disponível.

---

# 14. Fluxo Normal de Informação

Quando não existir necessidade de comunicação direta, a informação deverá seguir o fluxo normal definido pela arquitetura de software.

Exemplo conceptual:

```text
Sensor
  │
  ▼
ESP32-S
  │
  ▼
RaspberryPi
  │
  ▼
Módulo de Controlo
```

Um módulo não deverá contornar deliberadamente este fluxo sem motivo funcional válido.

---

# 15. Protocolo TLV

As mensagens transmitidas entre diferentes elementos computacionais serão estruturadas através de um protocolo baseado em **TLV — Type, Length, Value**.

O TLV permitirá estruturar as mensagens de forma modular e extensível.

A estrutura detalhada dos campos, tipos, comprimentos, valores e regras de validação pertence a `COM/`.

---

# 16. Prioridade das Mensagens

As mensagens poderão possuir diferentes níveis de prioridade.

A prioridade será utilizada para determinar a ordem de tratamento das mensagens quando existirem várias mensagens pendentes.

De forma conceptual:

```text
Mensagem recebida
       │
       ▼
Avaliação da prioridade
       │
       ▼
Gestão da mensagem
```

Os níveis de prioridade e as respetivas regras serão definidos em `COM/`.

---

# 17. Comunicação Orientada a Eventos

O protocolo suportará comunicação orientada a eventos.

Os eventos constituem uma parte fundamental do mecanismo de aquisição e transmissão de informação do Aerus.

Os eventos associados à aquisição e aos sensores serão definidos em `SEN/`.

Eventos relacionados com segurança, alertas e alarmes serão definidos em `SEC/`.

Este documento apenas estabelece que a infraestrutura física deverá suportar esse modelo de comunicação.

---

# 18. Filas de Mensagens

Cada elemento que necessite de processar mensagens deverá possuir mecanismos de fila adequados.

A utilização de filas deverá impedir que a chegada simultânea de várias mensagens provoque *overflow* ou perda descontrolada de informação.

A fila deverá respeitar as regras de prioridade definidas pelo protocolo.

De forma conceptual:

```text
Mensagens
   │
   ▼
┌─────────────────┐
│ Fila de Entrada │
└────────┬────────┘
         │
         ▼
   Prioridade
         │
         ▼
     Processamento
```

---

# 19. Ordem de Processamento

A gestão das mensagens deverá considerar, pela ordem definida para o sistema:

1. prioridade;
2. eventos;
3. processamento através da fila correspondente.

A implementação concreta desta lógica pertence ao protocolo `COM/`.

---

# 20. Comunicação e Temporização

A comunicação entre grupos deverá respeitar os requisitos temporais definidos pelo Aerus.

Nem todas as mensagens terão necessariamente a mesma periodicidade.

A frequência de comunicação poderá depender de:

* tipo de informação;
* módulo;
* modo de funcionamento;
* estado do sistema;
* prioridade;
* criticidade;
* evento ocorrido.

Os requisitos temporais detalhados serão definidos em `COM/` e `SYS-008`.

---

# 21. Frequência de Comunicação

Cada Grupo Computacional poderá possuir uma frequência geral de comunicação com os restantes elementos.

Esta frequência é independente da frequência individual de aquisição de cada sensor.

Por exemplo:

```text
Sensor A ── aquisição ──►
Sensor B ── aquisição ──► ESP32-S
Sensor C ── aquisição ──►
                           │
                           │ acumulação
                           ▼
                    Pacote de dados
                           │
                           │ frequência de comunicação
                           ▼
                     UART / TLV
```

Assim, um ESP32-S poderá adquirir diferentes sensores em frequências distintas e posteriormente transmitir os dados segundo a frequência de comunicação definida.

---

# 22. Comunicação Assíncrona

A arquitetura deverá permitir que mensagens sejam recebidas e processadas independentemente da periodicidade de outros módulos.

Uma alteração de estado, evento ou condição de segurança poderá gerar uma mensagem fora do ciclo periódico normal.

A infraestrutura de comunicação deverá ser capaz de acomodar essas mensagens sem depender exclusivamente da transmissão periódica.

---

# 23. Overflow

Nenhum elemento deverá assumir que a taxa de chegada de mensagens será sempre inferior à sua capacidade instantânea de processamento.

A implementação deverá possuir mecanismos para:

* armazenamento temporário;
* priorização;
* controlo da fila;
* deteção de saturação;
* tratamento de mensagens atrasadas;
* descarte controlado quando permitido.

As regras de descarte serão definidas pelo protocolo e dependerão da prioridade da mensagem.

---

# 24. Integridade da Comunicação

As mensagens deverão possuir mecanismos que permitam determinar se os dados recebidos são válidos.

A implementação concreta dos mecanismos de:

* integridade;
* identificação;
* validação;
* autenticação;
* proteção;

será definida nas especificações de `COM/` e `SEC/`.

---

# 25. Falha de Comunicação

A perda de comunicação entre dois elementos deverá ser detetável quando a ligação for necessária à operação.

A resposta dependerá da importância da ligação.

Poderá resultar em:

* registo da falha;
* atraso;
* repetição;
* alteração do estado;
* pedido de recuperação;
* entrada em procedimento de segurança;
* continuação normal quando a ligação não for crítica.

As regras concretas pertencem a `COM/` e `SEC/`.

---

# 26. Recuperação

Quando uma comunicação falhar, o sistema deverá possuir mecanismos adequados de recuperação quando aplicável.

Uma tentativa de recuperação poderá aguardar um intervalo superior ao intervalo normal esperado para a resposta.

Após tentativas consecutivas sem resposta satisfatória, o sistema poderá:

* reiniciar o ciclo;
* avançar para o próximo ciclo;
* executar outro procedimento definido para a condição.

A decisão dependerá da criticidade da comunicação e do impacto que a espera possa causar na segurança.

---

# 27. Cooldown

Determinadas operações de comunicação, especialmente pedidos repetidos entre domínios, poderão possuir um intervalo mínimo entre tentativas.

Este mecanismo deverá impedir que um módulo sobrecarregue outro através de pedidos sucessivos.

O valor do *cooldown* será determinado de acordo com a função e criticidade da comunicação.

---

# 28. Comunicação entre Elementos do Mesmo Grupo

Quando um Grupo Computacional possuir vários elementos físicos, esses elementos poderão comunicar entre si através das interfaces previstas para o grupo.

A existência de vários elementos não altera a identidade lógica do Grupo Computacional.

Por exemplo:

```text
       ESP32-S
          │
    ┌─────┼─────┐
    ▼     ▼     ▼
 ESP32-S ESP32-S ESP32-S
    01      02      03
```

Os elementos continuam a constituir o mesmo Grupo Computacional ESP32-S.

---

# 29. Escalabilidade

A arquitetura de comunicação deverá permitir que um Grupo Computacional seja constituído por mais elementos no futuro.

A adição de elementos não deverá exigir a alteração do princípio fundamental do protocolo.

A topologia física deverá ser definida de acordo com a quantidade real de elementos presentes em cada configuração de aeronave.

---

# 30. Expansão Futura

A arquitetura deverá permitir a introdução futura de:

* novos Grupos Computacionais;
* novos elementos dentro de grupos existentes;
* novos tipos de mensagens;
* novos eventos;
* novas prioridades;
* novos periféricos;
* novos implementos.

A introdução de novos elementos deverá procurar manter compatibilidade com a arquitetura existente.

---

# 31. Relação com a Arquitetura de Software

A interface de comunicação física não deverá determinar diretamente a organização interna dos módulos de software.

Os módulos comunicam através das interfaces definidas pelo sistema, enquanto a implementação interna permanece independente.

Esta separação permite atualizar um módulo sem alterar necessariamente os restantes.

---

# 32. Limites do Documento

Este documento não define detalhadamente:

* estrutura completa das mensagens TLV;
* tabela de tipos;
* tabela de prioridades;
* checksum;
* CRC;
* HMAC;
* autenticação;
* cifragem;
* regras completas de retransmissão;
* tempos concretos;
* *timeouts* concretos;
* *cooldowns* concretos;
* gestão detalhada das filas;
* estados de erro;
* implementação de drivers UART.

Esses elementos deverão ser definidos em `COM/` e `SEC/`, conforme a respetiva função.

---

# 33. Referências

- HW-001 — Arquitetura_de_Hardware
- HW-002 — Grupos_Computacionais
- HW-003 — Distribuicao_de_Hardware
- HW-004 — Interfaces_Eletricas
- HW-005 — Alimentacao_e_Distribuicao_de_Energia
- HW-007 — Interfaces_de_Perifericos
- HW-008 — Redundancia_e_Isolamento_de_Hardware
- HW-009 — Expansibilidade_e_Configuracao_de_Hardware
- SYS-005 — Fluxo_Global_de_Informacao
- SYS-006 — Gestao_de_Estados
- SYS-008 — Gestao_Temporal
- SEN — Especificações de Sensores
- SEC — Especificações de Segurança
- COM — Especificações de Comunicações
- IMP — Especificações de Implementos
