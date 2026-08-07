# Arquitetura do Repositório

**Documento:** ARQUITETURA_DO_REPOSITORIO.md

**Projeto:** Aerus

**Versão:** 1.0

**Estado:** Em desenvolvimento

---

# 1. Objetivo

O presente documento define a organização estrutural do repositório do projeto **Aerus**, estabelecendo as regras para a distribuição do código-fonte, documentação, especificações técnicas, recursos partilhados e restantes artefactos de desenvolvimento.

Esta organização tem como principal objetivo garantir:

* Separação clara de responsabilidades;
* Facilidade de manutenção;
* Escalabilidade do projeto;
* Rastreabilidade entre documentação e implementação;
* Independência entre os diferentes computadores que constituem o sistema Aerus;
* Facilidade de auditoria.

A estrutura do repositório deve refletir a arquitetura física e lógica do sistema, evitando a mistura de componentes pertencentes a unidades computacionais distintas.

---

# 2. Filosofia de Organização

Ao contrário de um projeto de software convencional, o **Aerus** não é composto por uma única aplicação.

O sistema é constituído por várias unidades computacionais independentes, cada uma com responsabilidades próprias, ciclo de desenvolvimento próprio e requisitos específicos.

Por este motivo, o repositório encontra-se organizado por hardware, permitindo que cada unidade possua o seu próprio código, documentação, testes, ferramentas e configurações.

Cada computador do sistema é tratado como um subprojeto autónomo.

Esta organização reduz o acoplamento entre componentes, facilita a manutenção e representa diretamente a arquitetura física do sistema.

---

# 3. Estrutura Geral

A estrutura de topo do repositório deverá seguir o seguinte modelo:

```text
Aerus/
|
├── RaspberryPi/        # Computador da missão
├── ESP32-S/            # Computador de aquisição
├── ESP32-A/            # Computador de controlo
├── ESP32-FS/           # Computador de segurança
├── ESP32-FS_A/         # Controlador de emergência
├── especificacoes/     # Especificações técnicas do sistema
├── docs/               # Documentação geral e guias rápidos
├── shared/             # Protocolos, definições TLV, CRC, HMAC, estruturas comuns, modelos de dados
├── hardware/           # Esquemas elétricos, PCB, CAD, pinouts
├── simulacao/          # Modelos, cenários e ferramentas de simulação
└── README.md
```

---

# 4. Computadores do Sistema

Cada pasta correspondente a um hardware e representa um subprojeto independente.

Cada subprojeto deverá possuir toda a informação necessária ao seu desenvolvimento, incluindo código, documentação, testes, ferramentas e configurações.

Exemplo:

```text
ESP32-S/

├── src/
├── include/
├── configs/
├── docs/
├── tests/
├── scripts/
├── README.md
└── CHANGELOG.md
```

Cada computador poderá utilizar linguagens, compiladores, ferramentas e bibliotecas diferentes, sem afetar a organização global do projeto.

---

# 5. Pasta "docs"

A pasta **docs** destina-se exclusivamente à documentação geral do projeto.

Nesta pasta deverão existir apenas documentos de leitura rápida, destinados a fornecer uma visão global do sistema.

Exemplos:

* Introdução ao Aerus;
* Guia de Instalação;
* Guia de Desenvolvimento;
* Guia de Compilação;
* Convenções de Código;
* Arquitetura Geral.

A pasta **docs** não deverá conter documentação técnica detalhada.

Essa documentação pertence à pasta **especificacoes**.

---

# 6. Pasta "especificacoes"

A pasta **especificacoes** contém toda a documentação técnica oficial do sistema.

Cada domínio funcional deverá possuir a sua própria especificação independente.

```text
SYS/    # Sistema
    001_Visao_Geral.md                  # O que é o Aerus.
    002_Arquitetura_Computacional.md    # Organização dos domínios computacionais.
    003_Arquitetura_Software.md         # Organização lógica do software.
    004_Arquitetura_Hardware.md         # Organização física do hardware.
    005_Fluxo_Global_de_Informacao.md   # Como a informação percorre todo o sistema.
    006_Gestao_de_Estados.md            # Estados globais e transições.
    007_Modos_de_Funcionamento.md       # Modos operacionais do sistema.
    008_Gestao_Temporal.md              # Sincronização e requisitos temporais.
    009_Arranque_e_Encerramento.md      # Sequência completa de boot e shutdown.
HW/     # Hardware
SW/     # Software
MAT/    # Matemática
SEN/    # Sensores
ACT/    # Atuadores
NAV/    # Navegação
GUI/    # Guiamento
CTL/    # Controlo
COM/    # Comunicações
SEC/    # Segurança
ENE/    # Energia
TST/    # Testes
VAL/    # Validação
CER/    # Certificação
OPS/    # Operações
IMP/    # Implementos
```

Cada especificação deverá possuir:

* introdução;
* arquitetura;
* requisitos;
* implementação;
* diagramas;
* referências.

O significado de cada uma:

* SYS/ — Sistema
    Documentação de arquitetura geral, filosofia, organização, modos de funcionamento, gestão de estados e funcionamento global do Aerus.

* HW/ — Hardware
    Arquitetura física, Raspberry Pi, ESP32-S, ESP32-A, ESP32-FS, ESP32-FS_A, barramentos, alimentação, sincronização e interligações.

* SW/ — Software
    Arquitetura do software, módulos, bibliotecas, APIs internas, organização do código e responsabilidades.

* MAT/ — Matemática
    Todos os modelos matemáticos, algoritmos, filtros, estimadores, controladores, transformações, fusão sensorial e respetiva fundamentação.

* SEN/ — Sensores
    Todos os sensores suportados pelo Aerus, respetivas características, calibração, interfaces, frequência de aquisição e variáveis produzidas.

* ACT/ — Atuadores
    Motores, ESC, servos, trem de aterragem, atuadores auxiliares e respetivos métodos de controlo.

* NAV/ — Navegação
    Posicionamento, planeamento e seguimento de trajetórias, gestão de waypoints, navegação autónoma e regressos automáticos.

* GUI/ — Guiamento
    Determinação da trajetória desejada e geração das referências de voo a partir da missão definida.

* CTL/ — Controlo
    Conversão das referências de guiamento em comandos para os atuadores, estabilidade, controlo longitudinal, lateral e direcional.

* COM/ — Comunicações
    Protocolos internos e externos, barramentos, rádio, telemetria, vídeo e interfaces de comunicação.

* SEC/ — Segurança
    Arquitetura de segurança, ESP32-FS, FailSafe, FailSecure, monitorização, redundância e recuperação de falhas.

* ENE/ — Energia
    Gestão energética, monitorização das baterias, consumo, autonomia e estratégias de otimização.

* TST/ — Testes
    Procedimentos de teste, SIL, HIL, testes unitários, integração, solo, voo e aceitação.

* VAL/ — Validação
    Métodos de validação, critérios de conformidade, análise de resultados e verificação dos requisitos.

* CER/ — Certificação
    Documentação, rastreabilidade e evidências destinadas aos processos de certificação e conformidade regulamentar.

* OPS/ — Operações
    Procedimentos operacionais, modos de utilização, preparação, execução e encerramento das missões.

* IMP/ — Implementos
    Especificação da interface entre o Aerus e sistemas externos (implementos), incluindo protocolos de deteção, identificação, capacidades, troca de dados e requisitos de compatibilidade. Não documenta os implementos em si, apenas a forma como estes interagem com o Aerus.

Sempre que possível, cada capítulo deverá existir como um ficheiro Markdown independente.

Posteriormente, todos os ficheiros poderão ser agregados automaticamente para gerar documentação em formato PDF ou outro formato equivalente.

*Princípio da Hierarquia das Especificações*

Cada conjunto de especificações deverá descrever apenas os conceitos pertencentes ao seu nível de abstração.

As especificações SYS definem a arquitetura e os princípios gerais do sistema.
As especificações de domínio (COM, MAT, SEN, ACT, SEC, etc.) definem detalhadamente cada área funcional.
As especificações SW e HW definem a organização e implementação técnica.
O código constitui a implementação final das especificações e não deverá substituir a documentação técnica.

---

# 7. Pasta "shared"

A pasta **shared** destina-se exclusivamente a elementos comuns a todo o sistema.

Poderão existir nesta pasta:

* definições de protocolos;
* estruturas de mensagens;
* identificadores;
* códigos de erro;
* constantes físicas;
* modelos de dados;
* documentação comum;
* bibliotecas verdadeiramente independentes do hardware.

Não deverá existir nesta pasta qualquer código específico de um determinado computador.

---

# 8. Pasta "hardware"

A pasta **hardware** contém toda a documentação relativa ao desenvolvimento físico do sistema.

Exemplos:

* esquemáticos;
* PCB;
* modelos CAD;
* pinagens;
* conectores;
* diagramas elétricos;
* listas de materiais;
* documentação de montagem.

Esta pasta não deverá conter código-fonte.

---

# 9. Pasta "simulacao"

A pasta **simulacao** contém todos os recursos destinados à simulação do sistema.

Exemplos:

* modelos de aeronaves;
* modelos atmosféricos;
* cenários;
* perfis de missão;
* dados de ensaio;
* ferramentas de validação;
* scripts de simulação.

---

# 10. Organização Interna

Todos os subprojetos deverão seguir, sempre que possível, uma organização semelhante.

Exemplo:

```text
src/
include/
configs/
docs/
tests/
scripts/
assets/
README.md
CHANGELOG.md
```

Esta uniformização facilita a navegação no repositório e reduz a curva de aprendizagem de novos colaboradores.

---

# 11. Princípios de Desenvolvimento

A organização do repositório deverá respeitar os seguintes princípios:

* Separação de responsabilidades;
* Baixo acoplamento entre subprojetos;
* Elevada coesão interna;
* Independência entre unidades computacionais;
* Modularidade;
* Escalabilidade;
* Rastreabilidade documental;
* Reprodutibilidade.

---

# 12. Evolução da Estrutura

Durante as fases iniciais de desenvolvimento, a identificação dos subprojetos será realizada através do hardware utilizado.

Exemplos:

* RaspberryPi
* ESP32-S
* ESP32-A
* ESP32-FS
* ESP32-FS_A

Esta abordagem facilita o desenvolvimento e a localização imediata dos diferentes componentes.

Numa fase posterior do projeto, caso a arquitetura evolua para novos computadores ou diferentes plataformas de processamento, esta organização poderá ser revista para refletir as funções desempenhadas por cada unidade computacional.

Esta eventual alteração não deverá afetar a arquitetura interna do código nem a organização das especificações técnicas.

---

# 13. Considerações Finais

O repositório do Aerus representa a arquitetura do próprio sistema.

A sua organização não pretende apenas facilitar o desenvolvimento do software, mas também documentar a estrutura física, lógica e funcional da plataforma.

Cada diretoria de topo corresponde a um domínio claramente definido, permitindo que a evolução do projeto ocorra de forma organizada, modular e sustentável ao longo de todo o seu ciclo de vida.

A manutenção desta estrutura constitui um requisito fundamental para garantir a qualidade do desenvolvimento, a consistência da documentação e a preparação do sistema para futuras atividades de validação, auditoria e certificação.
