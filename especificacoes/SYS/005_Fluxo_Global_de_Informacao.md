# SYS-005 — Fluxo Global de Informação

| Campo             | Valor                      |
|-------------------|----------------------------|
| **Código**        | SYS-005                    |
| **Título**        | Fluxo Global de Informação |
| **Versão**        | 2.0                        |
| **Estado**        | Em Desenvolvimento         |
| **Autor**         | ShegaPT                    |
| **Classificação** | Especificação de Sistema   |

---

# 1. Objetivo

O presente documento define a forma como a informação circula entre os grupos computacionais do sistema AERUS. Estabelecem-se os princípios do fluxo de informação, a distribuição de dados, e a separação entre fluxos de informação, fluxos de controlo e fluxos de autoridade, com concretização nas cinco redes normativas.

Os formatos binários, temporizações e mecanismos de transporte (CAN, TLV, IPC, RS) encontram-se detalhados na série COM; o presente documento fixa o modelo global e as regras invioláveis.

---

# 2. Âmbito

Aplica-se a todos os fluxos: aquisição sensorial, processamento no Master Geral, comando de atuadores, realimentação, segurança, estados, missão, visão e comunicação com o solo.

---

# 3. Descrição Detalhada

## 3.1. Princípios gerais

- Processamento distribuído: a informação é tratada onde é adquirida; transmitem-se resultados, não sinais em bruto.
- Minimização de latência e de redundância desnecessária.
- Paralelização: cada domínio calcula localmente e em paralelo.
- Independência entre domínios e previsibilidade do fluxo.
- Robustez perante falhas por isolamento e por redes segregadas.

## 3.2. Tipos de fluxo

Distinguem-se três tipos, logicamente independentes:

- **Fluxo de Informação**: dados (sensores, cálculos, estados internos, feedback, navegação, missão, vídeo/telemetria de saúde).
- **Fluxo de Controlo**: comandos de funcionamento normal (voo, atuadores, operação, missão). Segue sempre a cadeia MISSÃO → VOO → ATUADOR.
- **Fluxo de Autoridade**: decisões de segurança (pedidos/aceitação de FailSafe/FailSecure, ativação de emergência, inibição de grupos). Pertence ao FailSafe e circula, quando crítico, na CAN-FailSafe dedicada.

## 3.3. As cinco redes (síntese normativa)

| # | Rede | Âmbito | Conteúdo típico |
|---|------|--------|-----------------|
| 1 | CAN-Intra-Grupo (uma por grupo) | Módulos Menores ↔ Master do grupo | TLV de aquisição/local, PWM lógico, diagnóstico |
| 2 | CAN-Principal | Inter-masters (Masters + MG + Router GCV + Comunicação) | Dados normalizados, comandos validados, estados, telemetria |
| 3 | CAN-FailSafe dedicada | FailSafe ↔ todos (via segregada) | Ordens de emergência, inibições, estados de segurança |
| 4 | INTERCONNECT FABRIC | Intra-cluster (4x RP2350) | IPC: SENSOR_DATA, MATH_REQUEST/RESPONSE, NAVIGATION_*, MISSION_*, HEALTH_STATUS, SYSTEM_STATUS, TIME_SYNC, FAULT, HEARTBEAT |
| 5 | RJ45-Privada (RS) | Ponto-a-ponto onde há RF | GCV↔TX 5.8 GHz (vídeo 720p30); MG/GCCOM↔RX 2.4 GHz + TX 868 MHz |

Formato IPC intra-cluster (conceptual, a fechar em COM):

```text
SOURCE | DESTINO | NÚCLEO | TIPO | REQ_ID | TIMESTAMP | COMPRIMENTO | PAYLOAD | CRC
Tipos: SENSOR_DATA, ACTUATOR_DATA, MATH_REQUEST, MATH_RESPONSE,
       NAVIGATION_REQUEST/RESPONSE, MISSION_REQUEST/RESPONSE,
       HEALTH_STATUS, SYSTEM_STATUS, TIME_SYNC, FAULT, HEARTBEAT
```

O protocolo TLV (Tipo-Comprimento-Valor) utiliza-se nas CAN (intra e principal) para extensibilidade e validação; o detalhe consta de COM-002.

## 3.4. Fluxo de aquisição e distribuição sensorial

Todos os sensores ligam-se ao Grupo Sensorial. O Módulo Menor RP2040 executa aquisição, validação, conversão, normalização e cálculos primários; o Master do grupo agrega e publica.

Após processamento, a informação é distribuída, via CAN-Principal, em paralelo para: Controlo de Voo, Fusão, Navegação, Missão (por subscrição) e FailSafe. Cada consumidor calcula de forma independente; não existe dependência entre o cálculo normal e o cálculo de segurança.

Exemplo:

```text
Pitot → RP2040 (filtra, converte em m/s, timestamp)
  → CAN-Intra (TLV) → Master Sensorial
  → CAN-Principal → [Fusão | Navegação | FailSafe] em paralelo
```

A frequência de aquisição (por periférico) é independente da frequência de comunicação entre grupos: o Master pode adquirir a alta cadência, acumular/processar e publicar à cadência da rede (ver SYS-008).

## 3.5. Fluxo de processamento principal e comando

No Master Geral, o processamento normal segue o modelo de serviços IPC:

```text
Fusão/Navegação ─SENSOR_DATA──► consumidores internos
Missão ─MISSION_REQUEST──► Voo (solicitação, nunca ordem)
Voo ─valida envelope──► comando validado ──CAN-Principal──► Master Atuador
Navegação/Missão ─MATH_REQUEST──► Cálculo ─MATH_RESPONSE──► requerente
```

O Grupo Atuador, antes da execução, valida comandos, verifica limites, converte para sinais físicos e gera PWM/GPIO. A realimentação (posição, corrente, estado) é publicada para Voo e FailSafe, o que permite confirmação, monitorização e deteção de anomalias.

## 3.6. Fluxo de segurança e autoridade

O FailSafe executa permanentemente cálculos independentes com dados sensoriais, realimentação e estados do Master Geral. Qualquer domínio pode solicitar emergência; a decisão final é exclusiva do FailSafe (confirma/rejeita, comunica, regista, com intervalo mínimo de reavaliação).

Quando é ativado FailSafe/FailSecure, o FailSafe pode, conforme SEC: inibir o Atuador normal via CAN-FailSafe, ativar controlo de emergência, transferir atuadores críticos e impor manobra. A seleção de ações depende da situação e das regras SEC.

## 3.7. Fluxo de estados e de emergência

Os Masters e o Master Geral trocam estados operacionais (disponibilidade, degradação, perda de comunicação) sem alteração automática de autoridade. A alteração de autoridade só decorre de decisão de segurança explícita.

## 3.8. Fluxo de visão e de comunicação externa

- **Visão**: CÂMARA → MIPI CSI → i.MX (ISP/GPU, NPU futura, codificador) → 720p60 interno + 720p30 → RJ45-RS → placa TX 5.8 GHz → estação terrestre. Saúde e modo reportados pelo Router na CAN-Principal (HEALTH_STATUS). O tráfego de vídeo nunca circula na CAN.
- **Comunicação**: Placa RX 2.4 GHz → RJ45-RS → GCCOM/MG → CAN-Principal como solicitação ao Voo. Telemetria inversa: MG → GCCOM → RJ45-RS → TX 868 MHz → solo. Separação estrita entre comunicação interna (CAN/Fabric) e externa (RF).

## 3.9. Paralelismo e escalabilidade

Os grupos calculam em paralelo e de forma local, o que reduz latência e dependências. O modelo admite novos sensores, atuadores, grupos e missões sem alteração dos princípios.

---

# 4. Exemplos

## Exemplo 1 — Comando de missão com validação

```text
[Missão] "subir para 120 m" ─MISSION_REQUEST─► [Voo]
[Voo] verifica envelope (velocidade, atitude, energia)
  ├─ OK → comando ─CAN-Principal─► [Atuador] → valida limites → PWM
  └─ NOK → rejeita + motivo → [Missão] + evento para [Diagnóstico]
```

## Exemplo 2 — TLV na CAN-Principal

```text
Quadro CAN (extrato lógico):
  TLV #1: T=0x20 L=8 V=lat/lon compactadas (Navegação)
  TLV #2: T=0x31 L=2 V=estado de atuador (Atuador)
  Validação: CRC + gama + timestamp; rejeição silenciosa + contador em caso de erro.
```

## Exemplo 3 — IPC MATH entre núcleos

```text
SOURCE=NAV DEST=CÁLC NÚCLEO=0/1 TIPO=MATH_REQUEST REQ_ID=77 TIMESTAMP=t
PAYLOAD=matriz ... CRC=ok
  ──► cálculo ──► MATH_RESPONSE REQ_ID=77 RESULTADO ... CRC
Timeout → FAULT + estratégia degradada (ver SYS-008/SW).
```

## Exemplo 4 — Fluxo de emergência

```text
[Fusão] deteta incoerência ─solicita─► [FailSafe]
[FailSafe] confirma ─CAN-FailSafe─► inibe Atuador normal,
  impõe picada suave + declara SYSTEM_STATUS=FAILSAFE,
  informa GCCOM (telemetria) e GCV (modo seguro de vídeo).
```

---

# 5. Interfaces Com Outros Documentos

| Documento | Relação |
|-----------|---------|
| SYS-002 | Grupos e autoridade cujos fluxos aqui se concretizam |
| SYS-003 | Módulos/gestores que produzem/consomem estes fluxos |
| SYS-006/007/008 | Estados, modos e tempos que condicionam fluxos |
| COM-001/002/004/008/010 | Arquitetura, TLV, prioridades, CAN, integridade |
| SEC | Regras de emergência e inibição |
| SEN/ACT/MAT/NAV/CTL | Conteúdos transportados |

---

# 6. Estado / Pontos Em Aberto

- **Estado**: Em Desenvolvimento.
- **Pontos em aberto**: débitos e cargas por rede; IDs e dicionário TLV; formato IPC final e política de repetição; débito/pinagem da RJ45-RS; codec do 720p30; prioridades e contenção na CAN-Principal; redundância física de barramentos.

