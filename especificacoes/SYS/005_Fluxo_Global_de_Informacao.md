# SYS-005 — Fluxo Global de Informação

| Campo             | Valor                      |
|-------------------|----------------------------|
| **Código**        | SYS-005                    |
| **Título**        | Fluxo Global de Informação |
| **Versão**        | 1.0                        |
| **Estado**        | Em Desenvolvimento         |
| **Autor**         | ShegaPT                    |
| **Classificação** | Especificação de Sistema   |

---

# 1. Objetivo

O presente documento define a forma como a informação circula entre os diferentes grupos computacionais do sistema Aerus.

São estabelecidos os princípios gerais do fluxo de informação, a distribuição dos dados entre os diferentes domínios computacionais e a separação entre fluxos de informação, fluxos de controlo e fluxos de autoridade.

Os detalhes relativos aos protocolos de comunicação, formatos de mensagens e mecanismos de transporte (CAN FD, TLV) encontram-se definidos nas respetivas especificações da área COM.

---

# 2. Princípios Gerais

O fluxo de informação do Aerus foi concebido segundo os seguintes princípios:

- processamento distribuído;
- minimização da latência;
- redução de redundâncias desnecessárias;
- paralelização do processamento;
- independência entre domínios computacionais;
- previsibilidade do fluxo dos dados;
- elevada robustez perante falhas.

Sempre que possível, a informação deverá ser processada no grupo computacional onde é inicialmente adquirida, sendo transmitidos apenas os resultados necessários aos restantes grupos.

---

# 3. Tipos de Fluxo

A arquitetura distingue três tipos fundamentais de fluxo.

## Fluxo de Informação

Corresponde à circulação de dados entre grupos computacionais.

Inclui, entre outros:

- dados de sensores;
- resultados de cálculos;
- estados internos;
- feedback dos atuadores;
- dados de navegação;
- dados de missão.

---

## Fluxo de Controlo

Corresponde aos comandos utilizados para controlar o funcionamento normal da aeronave.

Inclui:

- comandos de voo;
- comandos dos atuadores;
- comandos operacionais;
- comandos de missão.

---

## Fluxo de Autoridade

Corresponde às decisões relacionadas com a segurança da aeronave.

Inclui:

- pedidos de entrada em FailSafe;
- pedidos de entrada em FailSecure;
- aceitação ou rejeição desses pedidos;
- ativação do controlo de emergência;
- inibição de grupos computacionais.

O fluxo de autoridade é independente dos restantes fluxos.

---

# 4. Fluxo de Aquisição

Todos os sensores da aeronave comunicam diretamente com o Grupo Computacional ESP32-S.

Este grupo é responsável por:

- aquisição;
- validação;
- conversão;
- normalização;
- cálculos primários;
- preparação da informação.

Após processamento inicial, a informação é distribuída para os restantes grupos computacionais que dela necessitem.

---

# 5. Fluxo de Informação dos Sensores

Após aquisição e processamento primário, o Grupo Computacional ESP32-S distribui a informação simultaneamente para:

- Grupo Computacional RaspberryPi;
- Grupo Computacional ESP32-FS.

Cada um destes grupos utiliza os dados recebidos de forma independente, efetuando os seus próprios cálculos e tomando decisões de acordo com as respetivas responsabilidades.

Não existe dependência entre os cálculos efetuados por estes dois grupos computacionais.

---

# 6. Fluxo de Processamento Principal

Durante o funcionamento normal da aeronave, o Grupo Computacional RaspberryPi constitui o principal consumidor da informação proveniente dos sensores.

Com base nessa informação são executadas, entre outras, funções relacionadas com:

- navegação;
- guiamento;
- gestão da missão;
- controlo superior;
- planeamento;
- coordenação do sistema.

Os comandos gerados são enviados diretamente ao Grupo Computacional ESP32-A.

---

# 7. Fluxo de Controlo dos Atuadores

O Grupo Computacional ESP32-A recebe os comandos provenientes do Grupo Computacional RaspberryPi.

Antes da execução dos comandos, este grupo deverá:

- validar os comandos recebidos;
- verificar os limites operacionais;
- efetuar as conversões necessárias;
- gerar os sinais físicos adequados aos diferentes atuadores.

Após execução dos comandos, o Grupo Computacional ESP32-A obtém continuamente informação relativa ao estado dos respetivos atuadores.

---

# 8. Fluxo de Realimentação

A informação obtida através da realimentação dos atuadores é distribuída simultaneamente para:

- Grupo Computacional RaspberryPi;
- Grupo Computacional ESP32-FS.

Esta informação permite:

- confirmar a correta execução dos comandos;
- monitorizar o estado dos atuadores;
- detetar anomalias;
- apoiar os cálculos efetuados pelos diferentes grupos computacionais.

---

# 9. Fluxo de Segurança

O Grupo Computacional ESP32-FS executa permanentemente os seus próprios cálculos utilizando:

- dados provenientes do Grupo Computacional ESP32-S;
- informação de realimentação dos atuadores;
- estados recebidos do Grupo Computacional RaspberryPi.

Os cálculos efetuados pelo Grupo Computacional ESP32-FS são independentes dos realizados pelo Grupo Computacional RaspberryPi.

---

# 10. Fluxo de Estados

O Grupo Computacional RaspberryPi e o Grupo Computacional ESP32-FS trocam continuamente informação relativa ao estado global do sistema.

Esta informação inclui, entre outros:

- estado operacional;
- estado da missão;
- estado dos diferentes grupos computacionais;
- alertas;
- notificações.

A troca de estados não implica qualquer alteração automática da autoridade de cada grupo computacional.

---

# 11. Fluxo de Autoridade

Durante o funcionamento normal, o Grupo Computacional RaspberryPi possui autoridade sobre o controlo operacional da missão.

Sempre que considere existir uma situação potencialmente perigosa, poderá solicitar ao Grupo Computacional ESP32-FS a ativação dos mecanismos de FailSafe ou FailSecure.

O Grupo Computacional ESP32-FS analisa autonomamente essa solicitação.

A decisão final pertence exclusivamente ao Grupo Computacional ESP32-FS.

Da mesma forma, o Grupo Computacional ESP32-FS poderá iniciar autonomamente um procedimento de emergência sempre que os seus próprios cálculos assim o justifiquem.

---

# 12. Fluxo de Emergência

Quando é ativado um procedimento de FailSafe ou FailSecure, o Grupo Computacional ESP32-FS assume a autoridade prevista pela arquitetura de segurança.

Durante este processo poderão ocorrer, entre outras, as seguintes ações:

- inibição do Grupo Computacional ESP32-A;
- ativação do Grupo Computacional ESP32-FS_A;
- transferência do controlo dos atuadores críticos;
- execução das manobras de emergência.

A seleção das ações depende da situação operacional e das regras definidas nas especificações da área SEC.

---

# 13. Paralelismo

Os diferentes grupos computacionais executam os respetivos cálculos em paralelo.

Sempre que possível, o processamento é efetuado localmente em cada domínio computacional.

Esta abordagem permite:

- reduzir tempos de resposta;
- minimizar atrasos de comunicação;
- aumentar a robustez do sistema;
- reduzir dependências entre grupos computacionais.

---

# 14. Escalabilidade

O fluxo global de informação foi concebido para permitir a introdução futura de:

- novos sensores;
- novos atuadores;
- novos grupos computacionais;
- novos módulos de software;
- novos tipos de missão.

Estas evoluções não deverão alterar significativamente os princípios gerais definidos nesta especificação.

---

# 15. Referências

- SYS-002 — Arquitetura Computacional
- SYS-003 — Arquitetura Software
- SYS-004 — Arquitetura Hardware
- SYS-006 — Gestão de Estados
- COM — Especificações de Comunicações
- SEC — Especificações de Segurança
- SEN — Especificações de Sensores
- ACT — Especificações de Atuadores
- MAT — Especificações Matemáticas