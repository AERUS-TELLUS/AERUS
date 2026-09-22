# SYS-008 — Gestão Temporal

| Campo             | Valor                    |
|-------------------|--------------------------|
| **Código**        | SYS-008                  |
| **Título**        | Gestão Temporal          |
| **Versão**        | 2.0                      |
| **Estado**        | Em Desenvolvimento       |
| **Autor**         | ShegaPT                  |
| **Classificação** | Especificação de Sistema |

---

# 1. Objetivo

O presente documento define os princípios e a arquitetura temporal global do sistema AERUS. Estabelecem-se os mecanismos gerais de sincronização, referência temporal, contagem de tempo, aquisição e comunicação periódicas e coordenação temporal entre grupos, Master Geral e GCV.

As políticas temporais específicas por módulo (prioridades, deadlines, timeouts, recuperação, atrasos) constam da série SW e da política temporal dedicada; o presente documento fixa o modelo global.

---

# 2. Âmbito

Aplica-se a todas as referências temporais, à sincronização entre CAN-Intra, CAN-Principal, CAN-FailSafe, FABRIC e RJ45-RS, às cadências de periféricos e módulos e à apresentação temporal na estação terrestre.

---

# 3. Descrição Detalhada

## 3.1. Princípios gerais

- Sincronização distribuída com referência comum.
- Utilização de múltiplas referências, cada qual com finalidade definida.
- Periodicidade configurável por periférico, por rede e por módulo.
- Independência temporal dos periféricos face à comunicação entre grupos.
- Separação entre aquisição e comunicação.
- Estabilidade temporal com tolerância controlada a variações.
- Deteção de atrasos como indicador de falha.
- Prioridade da segurança em qualquer conflito temporal.

O sistema mantém referência suficientemente consistente para correlação de dados, execução de cálculos e análise posterior.

## 3.2. Referência temporal e sincronização inicial

O Master Geral e o FailSafe estabelecem a referência comum no arranque (via CAN-Principal/FailSafe e TIME_SYNC na FABRIC). Após a referência base:

1. Grupo Sensorial sincroniza-se com a referência do Master Geral/FailSafe.
2. Grupo Atuador sincroniza-se do mesmo modo.
3. Funções de emergência sincronizam-se diretamente com o FailSafe.
4. Router do GCV e Comunicação sincronizam-se como nós da CAN-Principal (com disciplina própria de vídeo/RF, ver 3.6).

Apenas após conclusão do processo considera-se válida a referência de cada grupo. Os mecanismos técnicos constam de COM. Após sincronização, o FailSafe mantém referência independente, de modo a prosseguir funções de segurança sem dependência de execução contínua da Missão.

## 3.3. Domínios temporais

Utilizam-se, entre outras, as referências: UTC; tempo desde inicialização; tempo desde arranque; tempo de missão; tempo de voo; tempo no modo; tempo no estado; tempo desde comunicação/aquisição/evento.

- **UTC**: associado, quando disponível, a sensores, eventos, estados, alertas, comandos, mudanças de modo, registos e telemetria para a estação terrestre. A disponibilidade de UTC nunca constitui dependência obrigatória do controlo de voo.
- **Tempo monotónico**: base de intervalos (períodos, timeouts, deadlines, latências, perda de comunicação, duração de estados/modos), independente de ajustes do relógio UTC.
- **Tempo operacional**: inicialização, arranque, missão, voo, modo e estado, para utilização interna e apresentação no solo.

## 3.4. Frequências: periféricos, aquisição, comunicação e módulos

- **Periféricos**: cada sensor/atuador possui frequência própria, garantida pelo grupo responsável (Módulo Menor RP2040 + Master RP2350).
- **Aquisição**: o Grupo Sensorial adquire cada sensor à respetiva cadência, de forma independente; os dados podem ser acumulados e processados localmente antes da transmissão.
- **Comunicação**: cada rede possui cadência própria. Exemplo: aquisição de pitot a alta cadência com publicação agregada à cadência da CAN-Principal. A separação reduz tráfego sem perda de resolução local.
- **Módulos**: cada módulo pode ter frequência própria, consoante modo, estado, criticidade, recursos e necessidade. A alteração de frequência não compromete a estabilidade dos restantes. O detalhe consta de SW.

## 3.5. Modelo de execução, atrasos e recuperação

Suportam-se execução periódica (funções com frequência definida) e execução orientada a eventos (resposta a condições). Os eventos nunca comprometem funções periódicas críticas.

O sistema deteta conclusões fora da janela prevista; cada atraso é registado e avaliado pela criticidade. A ação depende da política da função: permitir conclusão, repetir, registar, abandonar e avançar, estratégia degradada ou mecanismos de segurança. Mudanças de modo/estado aplicam políticas do novo contexto, de forma controlada.

A gestão temporal serve a segurança: atrasos, perda de sincronização ou comportamento anómalo são indicadores de falha (perda de comunicação, ausência de resposta, sincronização perdida). A resposta consta de SEC.

## 3.6. Tempo no cluster e no GCV

- **Cluster (FABRIC)**: TIME_SYNC e HEARTBEAT periódicos com TIMESTAMP e CRC; supervisão de latência por nó/núcleo; deteção de nó mudo e de deriva. Orçamentos de latência por tipo (ex.: MATH_RESPONSE mais restrito que HEALTH_STATUS) a fechar na matriz de latências.
- **GCV**: disciplina de vídeo a 720p60 interno (captura→ISP→processamento) com derivação a 720p30 para o solo; timestamps de captura para correlação com navegação; jitter de codificação isolado da disciplina de voo (o atraso de vídeo nunca bloqueia o controlo). O Router reporta saúde temporal (perda de frame, deriva) na CAN-Principal.

## 3.7. Registo e estação terrestre

As informações temporais relevantes são registadas com os dados (reconstrução cronológica, correlação entre sensores e grupos, análise de eventos/falhas, auditoria, diagnóstico). Para o solo, disponibilizam-se UTC, tempos de inicialização/arranque/missão/voo/modo, durações e diagnóstico temporal.

## 3.8. Evolução

Admite-se adição de grupos, periféricos, módulos e mecanismos sem alteração dos princípios.

---

# 4. Exemplos

## Exemplo 1 — Separação aquisição/comunicação

```text
Pitot: aquisição a 200 Hz no RP2040 (filtragem local).
Master Sensorial: agrega e publica a 50 Hz na CAN-Principal (TLV).
Fusão consome a 50 Hz; deteção de rajada preservada pelo pré-processamento local.
```

## Exemplo 2 — Timeout IPC

```text
NAV envia MATH_REQUEST (REQ_ID=77, t0).
Se MATH_RESPONSE não chega até t0+limite → NAV aplica última válida
+ contador; Supervisão regista atraso; após N falhas → FAULT.
```

## Exemplo 3 — Sincronização

```text
Arranque: MG ↔ FailSafe acordam base (TIME_SYNC).
Sensorial/Atuador alinham-se; o Router do GCV alinha o relógio de saúde/telemetria; o relógio de frame
mantém disciplina própria com timestamp de captura correlacionável.
```

## Exemplo 4 — Tabela de cadências (valores ilustrativos, a fechar)

| Função | Cadência alvo | Rede | Relógio |
|--------|---------------|------|---------|
| Aquisição inercial | Alta (por sensor) | Intra | Monotónico local |
| Publicação sensorial | Média | Principal | Comum sincronizado |
| HEARTBEAT cluster | Alta/periódica | FABRIC | Monotónico + TIMESTAMP |
| Vídeo interno | 60 fps | Interna GCV | Relógio de vídeo |
| Vídeo para solo | 30 fps | RJ45-RS→RF | Relógio de vídeo |

---

# 5. Interfaces Com Outros Documentos

| Documento | Relação |
|-----------|---------|
| SYS-002/005 | Grupos e redes cuja disciplina aqui se define |
| SYS-006/007/009 | Estados, modos e arranque que condicionam janelas |
| SW (políticas temporais) | Deadlines/timeouts/recuperação por módulo |
| COM | Mecanismos de sincronização e transporte |
| SEN/ACT/SEC | Cadências de periféricos e resposta a anomalias |

---

# 6. Estado / Pontos Em Aberto

- **Estado**: Em Desenvolvimento.
- **Pontos em aberto**: matriz de periodicidade/latência/prioridade por mensagem; limites de HEARTBEAT/TIME_SYNC; orçamentos FABRIC vs CAN; disciplina de timestamp de vídeo; apresentação temporal no solo; validação por ensaio.

