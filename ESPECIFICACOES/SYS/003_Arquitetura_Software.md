# SYS-003 — Arquitetura de Software

| Campo             | Valor                    |
|-------------------|--------------------------|
| **Código**        | SYS-003                  |
| **Título**        | Arquitetura de Software  |
| **Versão**        | 2.0                      |
| **Estado**        | Em Desenvolvimento       |
| **Autor**         | ShegaPT                  |
| **Classificação** | Especificação de Sistema |

---

# 1. Objetivo

O presente documento define a arquitetura lógica do software do sistema **AERUS**. Estabelecem-se os princípios de organização, modularização, comunicação, dependências e responsabilidades dos componentes de software em cada grupo computacional, no Master Geral e no Grupo Computacional de Visão.

Não se descrevem algoritmos específicos nem detalhes de implementação. O presente documento serve como referência arquitetónica para todas as especificações de software (série SW) e para a utilização dos modelos matemáticos (série MAT).

---

# 2. Âmbito

Aplica-se a todo o software embarcado: firmware dos Módulos Menores RP2040, firmware dos Masters de Grupo RP2350, serviços dos 8 núcleos do Master Geral, software do SoC de visão (processadores aplicacionais, tempo real, ISP/GPU/NPU/vídeo) e software do Grupo de Comunicação.

Abrange-se a organização modular, as camadas funcionais, a comunicação entre módulos e entre domínios, as bibliotecas por domínio, a gestão de recursos e a parametrização. Os protocolos de transporte (TLV, CAN, IPC, RS) são detalhados na série COM; as políticas temporais concretas, na série SW.

---

# 3. Descrição Detalhada

## 3.1. Princípios fundamentais

Todo o software respeita os princípios seguintes:

- Modularidade com responsabilidade única e bem delimitada.
- Separação de responsabilidades; nenhum módulo assume funções de outro sem justificação funcional.
- Baixo acoplamento e elevada coesão.
- Escalabilidade e parametrização (adaptação por configuração, não por versões de código).
- Determinismo nas funções críticas (controlo, navegação, segurança).
- Reutilização através de bibliotecas por domínio e de serviços partilhados (Cálculo).
- Independência entre domínios computacionais (cada domínio contém localmente o de que necessita).
- Facilidade de manutenção, teste e evolução independente por interfaces estáveis.

## 3.2. Organização modular e camadas funcionais

O software organiza-se em módulos independentes, agrupados por camadas lógicas (não rígidas):

```text
APLICAÇÃO (missão, planeamento, guiamento, diagnóstico, visão/IA)
   │
SERVIÇOS (navegação, fusão, cálculo, supervisão, comunicação, ficheiros, registo)
   │
ABSTRAÇÃO (sensores normalizados, atuadores lógicos, vídeo lógico, rede lógica)
   │
PLATAFORMA (drivers RP2040/RP2350/i.MX, PIO, PWM, SPI/I2C/UART, CAN, Ethernet, MIPI)
```

Um módulo pode pertencer a mais do que uma camada, desde que com justificação técnica. A interação entre módulos ocorre apenas através de interfaces definidas; o acesso direto a estruturas internas de outro módulo é evitado.

## 3.3. Independência dos domínios e bibliotecas por domínio

Cada grupo computacional possui organização interna própria. Os módulos de um domínio não dependem da implementação de outro domínio. Sempre que um domínio necessite de uma funcionalidade, esta existe localmente.

Cada domínio pode possuir bibliotecas comuns próprias (matemática, geometria, conversões, utilitários, tipos, protocolos, configuração), independentes das de outros domínios. Se um domínio tiver várias unidades físicas, todas utilizam exatamente a mesma versão das bibliotecas.

Exceção coordenada: o Grupo de Cálculo funciona como serviço partilhado do Master Geral para evitar duplicação de código pesado. Os restantes núcleos recorrem a MATH_REQUEST/MATH_RESPONSE via INTERCONNECT FABRIC em vez de replicarem o motor matemático.

## 3.4. Software por grupo

### Grupo Sensorial e Grupo Atuador (RP2040 + Master RP2350)

- **Módulo Menor RP2040**: aquisição/normalização ou geração PWM; filtragem; calibração; validação de gama; TLV; máquina de estado local; monitorização (tensão, temperatura); watchdog.
- **Master RP2350**: agregação; validação cruzada; publicação na CAN-Principal; gestão da CAN-Intra-Grupo; diagnóstico; atualização coordenada dos Menores.

### Master Geral (8 núcleos)

| Núcleo | Software principal |
|--------|--------------------|
| Voo | Leis de controlo, guiamento, envelope, validação de solicitações da Missão |
| Fusão | Filtros, combinação de sensores, integridade |
| Navegação | Estimativa PVT/atitude, geodesia (com apoio do Cálculo) |
| Cálculo | Serviço MATH (álgebra, filtros, otimização), sem estado de missão |
| Missão | Gestão de fases, waypoints, implementos (por solicitação) |
| Planeamento | Lógica de trajetória e replaneamento |
| Supervisão | Heartbeats, watchdogs, latências, integridade IPC, estados de segurança |
| Diagnóstico | Health monitoring, registos, auditoria, telemetria de saúde |

A comunicação entre núcleos processa-se por IPC/RPC (ver SYS-005): SENSOR_DATA, MATH_REQUEST/RESPONSE, NAVIGATION_REQUEST/RESPONSE, MISSION_REQUEST/RESPONSE, HEALTH_STATUS, SYSTEM_STATUS, TIME_SYNC, FAULT, HEARTBEAT. Nenhum núcleo pressupõe transparência de memória de outro; cada chamada é explícita, com REQ_ID, TIMESTAMP e CRC.

### Grupo de Visão (i.MX 8M Plus + Router)

- **SoC**: captura MIPI CSI → ISP → processamento CPU/GPU → inferência NPU (função futura, não obrigatória na v1) → codificação (720p60 interno + 720p30 para solo) → saída para RJ45 privada RS com destino à placa TX 5.8 GHz.
- **Router RP2350**: supervisão (watchdog, temperatura, estado da câmara e do armazenamento), gestão de energia e arranque, recuperação, comunicação com a CAN-Principal (telemetria de saúde e comandos de modo de visão). Sistema operativo, pipeline, codec e formato de transporte a fechar (ver pontos em aberto).

### Grupo de Comunicação

Gestor de mensagens para telecomando (RX 2.4 GHz) e telemetria (TX 868 MHz) via RJ45 privada RS; validação, prioridades, filas, eventos e encaminhamento para a CAN-Principal. Todo o telecomando é tratado como solicitação ao Voo, nunca como ordem direta ao Atuador.

## 3.5. Comunicação entre módulos e gestor de comunicações

A comunicação direta entre módulos é permitida apenas com necessidade funcional identificada; na sua ausência, segue-se o fluxo normal da arquitetura.

A comunicação entre módulos e entre domínios é efetuada através de um gestor de comunicações dedicado, responsável por receção, validação, encaminhamento, prioridades, eventos, filas e entrega. Nenhum módulo implementa mecanismos paralelos à arquitetura.

Cada módulo expõe apenas as interfaces estritamente necessárias, com estabilidade ao longo da evolução. A substituição de algoritmos ou modelos preserva as interfaces públicas.

## 3.6. Processos, recursos e parametrização

- Sempre que a plataforma o permita, cada módulo executa como processo independente (robustez, reinício individual, monitorização).
- Os recursos são geridos de forma dinâmica: módulos desnecessários numa fase podem ser suspensos ou terminados, com libertação imediata. A ativação/desativação é transparente e sem compromisso da estabilidade global.
- O software é parametrizado: a adaptação a aeronaves distintas processa-se por configuração fornecida antes da compilação; o binário resultante contém apenas o necessário à plataforma alvo.
- Cada módulo evolui de forma independente; alterações internas não obrigam à modificação de outros módulos.

## 3.7. Gestão temporal do software

A arquitetura suporta execução periódica (funções com frequência definida) e execução orientada a eventos (resposta a condições). A utilização de eventos nunca compromete a estabilidade das funções periódicas críticas. Periodicidades, deadlines, timeouts e recuperação constam da série SW e de SYS-008; o presente documento fixa apenas o modelo.

---

# 4. Exemplos

## Exemplo 1 — Pedido de cálculo como RPC

```text
[Missão] necessita distância geodésica:
  1. constrói MATH_REQUEST {REQ_ID=101, TIPO=GEODESIC, PAYLOAD=lat/lon}
  2. envia via INTERCONNECT FABRIC ao Núcleo de Cálculo
  3. aguarda MATH_RESPONSE {REQ_ID=101, RESULTADO, CRC}
  4. em caso de timeout → regista FAULT, aplica estratégia degradada
```

## Exemplo 2 — Publicação sensorial em TLV

```text
[Master Sensorial] publica na CAN-Principal:
  T=0x10 (pressão normalizada)  L=4  V=<float32>
  T=0x11 (temperatura)           L=2  V=<int16 deci-graus>
Consumidores: Fusão, Navegação, Supervisão — cada qual com cópia independente.
```

## Exemplo 3 — Pipeline de visão

```text
CÂMARA ─MIPI CSI─► ISP (debayer, AE/AWB) ─► CPU/GPU (processamento)
  ├─► 720p60 interno (deteção futura por NPU)
  └─► codificador ─► 720p30 ─► RJ45-RS ─► TX 5.8 GHz ─► Estação terrestre
Router RP2350 observa saúde e reporta HEALTH_STATUS na CAN-Principal.
```

## Exemplo 4 — Módulos por camada (extrato)

| Módulo | Camada | Domínio |
|--------|--------|---------|
| driver_pitot_rp2040 | Plataforma/Abstração | Sensorial |
| pub_tlv_sensores | Serviços | Sensorial |
| lei_voo_longitudinal | Aplicação | Voo (MG) |
| servico_geodesia | Serviços | Cálculo (MG) |
| supervisor_cluster | Serviços | Supervisão (MG) |
| pipeline_video_720p | Aplicação/Serviços | Visão |

---

# 5. Interfaces Com Outros Documentos

| Documento | Relação |
|-----------|---------|
| SYS-002 Computacional | Grupos e núcleos cujos softwares aqui se organizam |
| SYS-004 Hardware | Plataformas (RP2040/RP2350/i.MX) que condicionam o software |
| SYS-005 Informação | Redes e mensagens utilizadas pelos módulos |
| SYS-008 Gestão Temporal | Modelo temporal concretizado por políticas SW |
| SW (série) | Políticas por módulo: prioridades, deadlines, timeouts |
| MAT (série) | Algoritmos servidos pelo Grupo de Cálculo |
| COM (série) | Gestor de mensagens, TLV, CAN, IPC, integridade |
| SEC | Requisitos de isolamento e autoridade observados pelo software |

---

# 6. Estado / Pontos Em Aberto

- **Estado**: Em Desenvolvimento.
- **Pontos em aberto**:
  - Definição fina dos processos por núcleo (o que é processo autónomo face a tarefa).
  - Formato IPC definitivo e política de timeouts/repetições por tipo.
  - Sistema operativo do GCV e mapa de processos (captura, ISP, codec, NPU, supervisão).
  - Codec e encapsulamento do 720p30 sobre ligação série RS.
  - Catálogo de interfaces públicas por módulo e versionamento.
  - Estratégia de atualização de firmware por grupo (bootloader, redundância A/B).

