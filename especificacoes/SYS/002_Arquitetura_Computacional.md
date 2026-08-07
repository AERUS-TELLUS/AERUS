# SYS-002 — Arquitetura Computacional

| Campo             | Valor                     |
|-------------------|---------------------------|
| **Código**        | SYS-002                   |
| **Título**        | Arquitetura Computacional |
| **Versão**        | 1.0                       |
| **Estado**        | Em Desenvolvimento        |
| **Autor**         | ShegaPT                   |
| **Classificação** | Especificação de Sistema  |

---

# 1. Objetivo

O presente documento define a arquitetura computacional do sistema **Aerus**, estabelecendo a organização lógica dos seus domínios computacionais, as respetivas responsabilidades, os níveis de autoridade, os fluxos de informação e os princípios fundamentais de funcionamento.

Este documento constitui a referência principal para todas as especificações relacionadas com hardware, software, comunicações, segurança, navegação e matemática.

---

# 2. Princípios Arquitetónicos

A arquitetura computacional do Aerus baseia-se nos seguintes princípios fundamentais:

- distribuição funcional;
- separação de responsabilidades;
- isolamento entre funções críticas;
- elevada modularidade;
- elevada escalabilidade;
- processamento paralelo;
- supervisão permanente;
- independência entre domínios computacionais;
- segurança por autoridade hierárquica;
- preparação para certificação.

Todas as decisões de arquitetura deverão respeitar estes princípios.

---

# 3. Domínios Computacionais

O Aerus encontra-se organizado em domínios computacionais independentes.

Cada domínio representa uma responsabilidade funcional do sistema, não correspondendo obrigatoriamente a uma única unidade computacional física.

Um domínio computacional poderá ser constituído por um ou mais computadores, microcontroladores ou unidades de processamento, conforme a configuração da aeronave.

A arquitetura define responsabilidades funcionais e não quantidades fixas de hardware.

Na versão atual do sistema encontram-se definidos os seguintes domínios computacionais:

- Grupo Computacional RaspberryPi;
- Grupo Computacional ESP32-S;
- Grupo Computacional ESP32-A;
- Grupo Computacional ESP32-FS;
- Grupo Computacional ESP32-FS_A.

Versões futuras do Aerus poderão introduzir novos domínios computacionais sempre que tal se revele necessário.

---

# 4. Grupo Computacional RaspberryPi

O Grupo Computacional RaspberryPi constitui a unidade principal de processamento do sistema em condições normais de operação.

É responsável por:

- orquestração global do sistema;
- gestão da missão;
- navegação;
- guiamento;
- execução dos modelos matemáticos de elevado custo computacional;
- gestão de comunicações externas;
- parametrização da aeronave;
- coordenação dos restantes domínios computacionais.

O Grupo RaspberryPi não possui autoridade máxima sobre o sistema.

Todas as decisões relacionadas com segurança permanecem subordinadas ao Grupo Computacional ESP32-FS.

---

# 5. Grupo Computacional ESP32-S

O Grupo Computacional ESP32-S é responsável pela aquisição e processamento primário da informação proveniente dos sensores da aeronave.

As suas responsabilidades incluem:

- aquisição de dados;
- sincronização temporal;
- conversão de sinais;
- validação primária;
- filtragem inicial;
- cálculos preliminares;
- distribuição dos dados para os restantes domínios computacionais.

O número de unidades pertencentes a este grupo depende da quantidade, localização e distribuição dos sensores existentes na aeronave.

---

# 6. Grupo Computacional ESP32-A

O Grupo Computacional ESP32-A é responsável pelo controlo normal dos atuadores.

Recebe do Grupo RaspberryPi comandos de alto nível independentes da tecnologia utilizada pelos diferentes atuadores.

Compete ao Grupo ESP32-A:

- validar os comandos recebidos;
- verificar a conformidade com o envelope operacional;
- converter comandos lógicos para protocolos físicos;
- controlar motores;
- controlar servomecanismos;
- controlar restantes atuadores instalados.

O Grupo RaspberryPi nunca deverá gerar diretamente sinais específicos dos atuadores.

Toda a abstração entre lógica de voo e hardware físico deverá ser realizada pelo Grupo ESP32-A.

---

# 7. Grupo Computacional ESP32-FS

O Grupo Computacional ESP32-FS constitui o domínio computacional responsável pela segurança do sistema.

Este grupo permanece permanentemente ativo durante toda a operação da aeronave.

As suas responsabilidades incluem:

- monitorização contínua dos sensores;
- receção permanente dos estados do sistema;
- execução independente dos modelos matemáticos necessários à avaliação da segurança;
- validação permanente do estado da aeronave;
- deteção de condições anómalas;
- decisão sobre ativação de modos FailSafe;
- decisão sobre ativação de modos FailSecure;
- supervisão da integridade global do sistema.

O Grupo ESP32-FS possui a mais elevada autoridade computacional do Aerus.

Nenhum outro domínio computacional poderá sobrepor-se às decisões relacionadas com segurança.

---

# 8. Grupo Computacional ESP32-FS_A

O Grupo Computacional ESP32-FS_A constitui o domínio responsável pelo controlo físico dos atuadores durante situações de emergência.

A sua arquitetura funcional é equivalente ao Grupo ESP32-A.

A diferença reside exclusivamente na origem dos comandos recebidos.

Durante operação normal o Grupo ESP32-FS_A permanece inativo.

Quando ativado pelo Grupo ESP32-FS passa a assumir o controlo exclusivo dos atuadores críticos necessários à preservação da segurança da aeronave.

---

# 9. Hierarquia de Autoridade

A arquitetura do Aerus define uma hierarquia de autoridade independente do fluxo de dados existente entre os diferentes domínios computacionais.

Na versão atual encontra-se estabelecida a seguinte hierarquia:

Nível 0

- Grupo Computacional ESP32-FS

Nível 1

- Grupo Computacional RaspberryPi
- Grupo Computacional ESP32-FS_A

Nível 2

- Grupo Computacional ESP32-S
- Grupo Computacional ESP32-A

A autoridade representa exclusivamente a capacidade de tomada de decisão.

Não representa prioridades de comunicação nem dependências computacionais.

---

# 10. Fluxo de Informação

O fluxo de informação entre domínios computacionais é independente da respetiva autoridade hierárquica.

Cada domínio comunica apenas a informação necessária ao desempenho das responsabilidades definidas.

O detalhe dos protocolos de comunicação encontra-se especificado na série COM.

---

# 11. Fluxo de Decisão

O Aerus distingue explicitamente informação, comandos e decisões.

Os diferentes domínios computacionais poderão:

- produzir dados;
- emitir comandos;
- efetuar solicitações;
- tomar decisões.

As decisões relacionadas com segurança pertencem exclusivamente ao Grupo ESP32-FS.

Qualquer outro domínio computacional apenas poderá solicitar a ativação de procedimentos de emergência.

A decisão final pertence sempre ao Grupo ESP32-FS.

---

# 12. Solicitações de Emergência

Qualquer domínio computacional poderá solicitar ao Grupo ESP32-FS a ativação de procedimentos FailSafe ou FailSecure.

Uma solicitação não constitui uma ordem.

Após receção da solicitação, o Grupo ESP32-FS deverá:

- validar o estado global da aeronave;
- confirmar ou rejeitar a solicitação;
- comunicar a decisão tomada;
- manter registo do evento.

Solicitações sucessivas deverão respeitar um *intervalo mínimo de reavaliação*, evitando degradação do desempenho computacional do domínio responsável pela segurança.

---

# 13. Escalabilidade

A arquitetura do Aerus não estabelece um número fixo de unidades computacionais.

Cada domínio poderá ser composto por uma ou mais unidades físicas, mantendo sempre as responsabilidades definidas neste documento.

Esta abordagem permite adaptar o sistema a aeronaves de diferentes dimensões e complexidade sem alterar a arquitetura fundamental.

---

# 14. Referências

SYS-001 — Visão Geral do Sistema

HW — Especificações de Hardware

SW — Especificações de Software

COM — Especificações de Comunicações

SEC — Especificações de Segurança