# HW-007 — Interfaces_de_Perifericos

| Campo             | Valor                     |
| ----------------- | ------------------------- |
| **Código**        | HW-007                    |
| **Título**        | Interfaces de Periféricos |
| **Versão**        | 1.0                       |
| **Estado**        | Em Desenvolvimento        |
| **Autor**         | ShegaPT                   |
| **Classificação** | Especificação de Hardware |

---

# 1. Objetivo

O presente documento define os princípios de integração física e funcional entre os Grupos Computacionais do Aerus e os periféricos externos.

São considerados periféricos, entre outros:

* sensores;
* atuadores;
* controladores eletrónicos;
* sistemas auxiliares;
* interfaces externas;
* implementos.

A especificação individual de cada periférico deverá permanecer nas respetivas especificações.

---

# 2. Princípio Geral

Cada periférico deverá ser associado ao Grupo Computacional responsável pela sua aquisição, controlo ou supervisão.

A ligação física de um periférico não determina, por si só, a autoridade funcional sobre o sistema.

A arquitetura deverá manter separadas:

* aquisição de informação;
* processamento;
* controlo;
* atuação;
* segurança.

---

# 3. Sensores

Na arquitetura atualmente definida, os sensores são ligados diretamente ao Grupo Computacional ESP32-S.

```text id="v8y2cp"
              ┌─────────────┐
Sensor 1 ────►│             │
Sensor 2 ────►│   ESP32-S   │
Sensor 3 ────►│             │
Sensor N ────►│             │
              └─────────────┘
```

O ESP32-S é responsável pela aquisição e tratamento inicial dos dados dos sensores associados.

---

# 4. Distribuição dos Sensores

Um Grupo Computacional ESP32-S poderá possuir vários elementos físicos.

Consequentemente, os sensores poderão ser distribuídos entre diferentes elementos ESP32-S de acordo com a configuração da aeronave.

A distribuição deverá considerar:

* localização física;
* frequência de aquisição;
* quantidade de sensores;
* capacidade de processamento;
* requisitos temporais;
* necessidades elétricas.

---

# 5. Frequência de Aquisição

Cada sensor poderá possuir uma frequência de aquisição própria.

O elemento ESP32-S responsável deverá cumprir a frequência definida para cada periférico individualmente.

Assim:

```text id="p6f5dn"
Sensor A ──► 100 Hz
Sensor B ──► 50 Hz
Sensor C ──► 20 Hz
Sensor D ──► 10 Hz
```

As diferentes aquisições poderão ser posteriormente agregadas para transmissão ao restante sistema.

---

# 6. Agregação de Dados

O ESP32-S deverá poder acumular os dados provenientes dos sensores associados e construir mensagens ou pacotes destinados aos restantes Grupos Computacionais.

A frequência de aquisição individual dos sensores não deverá ser confundida com a frequência de comunicação entre hardwares.

```text id="h0v6x2"
Sensor A ─┐
Sensor B ─┤
Sensor C ─┼──► ESP32-S ───► Pacote ───► Sistema
Sensor D ─┘
```

A definição da estrutura das mensagens pertence a `COM/`.

---

# 7. Estado dos Sensores

O sistema deverá ser capaz de determinar o estado dos sensores quando essa informação estiver disponível.

Poderão ser considerados:

* ativo;
* inativo;
* inicializando;
* válido;
* inválido;
* degradado;
* sem resposta;
* com dados inconsistentes.

Os estados concretos dependem do tipo de sensor.

---

# 8. Qualidade dos Dados

A aquisição de um valor não implica automaticamente que esse valor seja válido.

Sempre que aplicável, o ESP32-S deverá ser capaz de identificar condições como:

* ausência de dados;
* dados fora dos limites;
* dados inconsistentes;
* falha de comunicação com o periférico;
* frequência de atualização insuficiente;
* comportamento anormal.

A informação relativa à qualidade dos dados deverá acompanhar os dados quando necessária.

---

# 9. Sensores Redundantes

A arquitetura deverá permitir a utilização de múltiplos sensores para medir a mesma grandeza.

A utilização de sensores redundantes poderá permitir:

* comparação;
* validação;
* deteção de divergências;
* aumento da disponibilidade;
* deteção de falhas.

A estratégia matemática e lógica para combinar ou validar esses dados será definida em `MAT/`, `SEN/` e `SEC/`, conforme aplicável.

---

# 10. Atuadores

Os atuadores utilizados na operação normal são controlados pelo Grupo Computacional ESP32-A.

```text id="f7z9qc"
              ┌─────────────┐
              │   ESP32-A   │
              └──────┬──────┘
                     │
          ┌──────────┼──────────┐
          ▼          ▼          ▼
       Atuador    Atuador    Atuador
          1          2          N
```

O ESP32-A recebe comandos provenientes do RaspberryPi e converte esses comandos para os sinais necessários ao controlo dos atuadores.

---

# 11. Comandos de Atuadores

O RaspberryPi deverá enviar ao ESP32-A comandos de controlo em representação adequada ao sistema.

O ESP32-A deverá:

1. receber o comando;
2. verificar se o comando é válido;
3. verificar os limites aplicáveis;
4. converter o comando para a interface do atuador;
5. executar o comando;
6. obter *feedback* quando disponível;
7. disponibilizar o estado resultante ao sistema.

O ESP32-A não deverá executar diretamente um comando que esteja fora dos limites definidos para o respetivo atuador.

---

# 12. Feedback dos Atuadores

Sempre que possível, os atuadores deverão fornecer informação de retorno.

O *feedback* poderá ser obtido através de:

* posição;
* velocidade;
* rotação;
* carga;
* corrente;
* estado interno;
* informação disponibilizada pelo controlador;
* outro mecanismo apropriado.

A arquitetura não exige a utilização de um encoder específico.

O método de obtenção do *feedback* dependerá do atuador.

---

# 13. Estado Final do Atuador

Quando um atuador disponibilizar informação suficiente para determinar a sua posição ou estado final, essa informação deverá ser utilizada pelo ESP32-A.

O sistema poderá manter, quando aplicável, a última posição ou condição conhecida do atuador.

Esta informação poderá ser relevante após:

* paragem;
* perda de comando;
* alteração de estado;
* reinicialização;
* entrada em condição de segurança.

---

# 14. Atuadores com Controladores Próprios

Alguns atuadores poderão possuir eletrónica própria de controlo.

Nesse caso, o ESP32-A deverá comunicar com essa eletrónica através da interface adequada.

Exemplo conceptual:

```text id="x6h8rf"
RaspberryPi
     │
     ▼
 ESP32-A
     │
     ▼
Controlador
do Atuador
     │
     ▼
 Atuador
```

O controlador do atuador poderá disponibilizar informação adicional utilizada pelo ESP32-A.

---

# 15. Motores e ESC

Quando um motor for controlado através de um ESC, o ESC constitui uma interface entre o ESP32-A e o sistema de propulsão.

O ESP32-A deverá enviar ao ESC o comando adequado e, quando disponível, receber informação de retorno.

O *feedback* disponibilizado pelo ESC poderá incluir, conforme o equipamento:

* rotação;
* estado;
* corrente;
* tensão;
* temperatura;
* outras informações.

Os detalhes concretos serão definidos em `ACT/`.

---

# 16. Limites dos Atuadores

Cada atuador deverá possuir limites operacionais definidos.

Esses limites poderão incluir:

* posição mínima;
* posição máxima;
* velocidade;
* aceleração;
* rotação;
* potência;
* corrente;
* outros parâmetros relevantes.

O ESP32-A deverá impedir que comandos normais ultrapassem os limites aplicáveis.

---

# 17. Interface de Segurança

O domínio de segurança possui interfaces próprias para atuar sobre os elementos necessários em condições de FailSafe/FailSecure.

O ESP32-FS poderá enviar ao ESP32-A uma ordem de **inibição**.

Essa ordem não constitui um comando normal de voo.

```text id="5qg5za"
ESP32-FS
    │
    │ Inibição
    ▼
ESP32-A
```

O ESP32-FS_A constitui uma via adicional de atuação de segurança e recebe comandos diretamente do ESP32-FS.

---

# 18. Independência da Atuação de Segurança

A arquitetura deverá evitar que a função de segurança dependa exclusivamente do caminho normal de comando.

O domínio normal utiliza:

```text id="xv5k6r"
RaspberryPi → ESP32-A → Atuador
```

Enquanto o domínio de segurança poderá utilizar:

```text id="2o5v3r"
ESP32-FS → ESP32-A
ESP32-FS → ESP32-FS_A
```

A implementação física concreta destas interfaces será definida de acordo com cada atuador.

---

# 19. Periféricos Externos

O Aerus poderá integrar periféricos externos que não sejam diretamente necessários ao controlo básico da aeronave.

Esses periféricos poderão incluir:

* sistemas auxiliares;
* equipamentos de missão;
* sistemas de monitorização;
* implementos;
* outros equipamentos específicos da aeronave.

A integração deverá manter a separação entre o sistema de voo e a função específica do periférico.

---

# 20. Implementos

Os implementos constituem sistemas externos ao Aerus.

Um implemento poderá possuir:

* sensores próprios;
* atuadores próprios;
* controlador próprio;
* sistema de comunicação;
* sistema de alimentação;
* lógica específica da missão.

O Aerus deverá ser capaz de comunicar com o implemento e receber a informação necessária para o funcionamento seguro da aeronave.

---

# 21. Informação Proveniente de Implementos

Um implemento poderá disponibilizar ao Aerus informação relevante para o voo.

Por exemplo, no caso de um sistema de pulverização, o Aerus poderá necessitar de conhecer parâmetros como:

* massa;
* caudal;
* quantidade de carga restante;
* estado do implemento;
* outros parâmetros relevantes.

Esta informação poderá ser utilizada pelo Aerus para cálculos relacionados com o comportamento da aeronave.

O Aerus não necessita, contudo, de executar diretamente a função específica do implemento.

---

# 22. Interfaces Configuráveis

A arquitetura deverá permitir que a mesma plataforma Aerus utilize diferentes periféricos.

A configuração da aeronave deverá determinar:

* quais os sensores presentes;
* quais os atuadores presentes;
* quais as interfaces utilizadas;
* quais os parâmetros de cada periférico;
* quais os módulos necessários;
* quais os periféricos opcionais.

O código deverá ser parametrizado sempre que possível em vez de existir uma implementação completamente diferente para cada aeronave.

---

# 23. Substituição de Periféricos

A substituição de um periférico deverá ser possível quando o novo periférico cumprir a interface e os requisitos definidos.

A substituição poderá exigir alteração da configuração da aeronave, mas não deverá obrigatoriamente exigir alteração estrutural do software.

---

# 24. Inicialização

Cada periférico deverá possuir uma sequência de inicialização adequada.

Durante a inicialização deverão ser verificadas, quando aplicável:

* presença;
* comunicação;
* alimentação;
* estado inicial;
* configuração;
* validade dos dados;
* capacidade de operação.

Um periférico que não passe os testes necessários não deverá ser considerado operacional.

---

# 25. Perda de Periférico

A perda de um periférico deverá ser identificável quando a sua função exigir monitorização.

A reação dependerá da importância do periférico.

Poderá resultar em:

* registo;
* degradação funcional;
* desativação de um módulo;
* alteração de estado;
* alteração de modo;
* procedimento de segurança.

A resposta concreta será definida nas especificações correspondentes.

---

# 26. Periféricos Não Necessários

Um periférico ou módulo associado poderá ser temporariamente desativado quando não for necessário para o estado ou modo atual da aeronave.

A desativação poderá ter como objetivo:

* reduzir consumo;
* libertar processamento;
* reduzir tráfego de comunicação;
* reduzir interferências;
* reduzir carga do sistema.

A desativação deverá ser reversível quando o periférico voltar a ser necessário.

---

# 27. Ativação Condicional

A ativação de periféricos poderá depender do modo de funcionamento da aeronave.

Exemplo conceptual:

```text id="a0j6vb"
                 Modo Aerus
                     │
          ┌──────────┼──────────┐
          ▼          ▼          ▼
       Periférico  Periférico  Periférico
        ativo       inativo     ativo
```

O sistema deverá evitar consumir recursos de periféricos que não sejam necessários para a função atual.

---

# 28. Identificação

Cada periférico integrado deverá possuir uma identificação que permita ao sistema determinar, quando aplicável:

* tipo;
* identidade;
* estado;
* capacidades;
* parâmetros;
* interface;
* configuração.

A identificação concreta e os mecanismos utilizados serão definidos nas respetivas especificações.

---

# 29. Configuração Física

A configuração física deverá estabelecer explicitamente as ligações entre periféricos e elementos computacionais.

Exemplo:

```text id="j4j2r1"
Sensor A ─────► ESP32-S_01
Sensor B ─────► ESP32-S_01
Sensor C ─────► ESP32-S_02

Atuador A ────► ESP32-A_01
Atuador B ────► ESP32-A_02
```

Esta configuração poderá variar entre aeronaves.

---

# 30. Manutenção

As interfaces deverão permitir inspeção, manutenção e substituição dos periféricos.

Deverão ser considerados:

* identificação;
* acessibilidade;
* conectores;
* proteção contra ligação incorreta;
* integridade das ligações;
* facilidade de substituição.

Os procedimentos de manutenção pertencem à documentação operacional e de manutenção aplicável.

---

# 31. Limites do Documento

Este documento não define:

* sensores específicos;
* atuadores específicos;
* pinouts;
* conectores concretos;
* tensões;
* correntes;
* frequências concretas de cada sensor;
* parâmetros concretos de cada atuador;
* estrutura do protocolo TLV;
* implementação dos drivers;
* algoritmos de fusão de sensores;
* regras completas de segurança.

Esses elementos pertencem às respetivas especificações.

---

# 32. Referências

- HW-001 — Arquitetura_de_Hardware
- HW-002 — Grupos_Computacionais
- HW-003 — Distribuicao_de_Hardware
- HW-004 — Interfaces_Eletricas
- HW-005 — Alimentacao_e_Distribuicao_de_Energia
- HW-006 — Interfaces_de_Comunicacao
- HW-008 — Redundancia_e_Isolamento_de_Hardware
- HW-009 — Expansibilidade_e_Configuracao_de_Hardware
- SYS-006 — Gestao_de_Estados
- SYS-007 — Modos_de_Funcionamento
- SYS-008 — Gestao_Temporal
- SEN — Especificações de Sensores
- ACT — Especificações de Atuadores
- SEC — Especificações de Segurança
- COM — Especificações de Comunicações
- IMP — Especificações de Implementos
