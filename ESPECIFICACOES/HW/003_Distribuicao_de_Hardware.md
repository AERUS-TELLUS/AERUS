# HW-003 — Distribuição de Hardware

| Campo | Valor |
| --- | --- |
| **Código** | HW-003 |
| **Título** | Distribuição de Hardware |
| **Versão** | 2.0 |
| **Estado** | Em Desenvolvimento |
| **Autor** | ShegaPT |
| **Classificação** | Especificação de Hardware |
| **Referência** | docs/Esquemas/Arquitetura-Computacional.md |

---

# 1. Objetivo

O presente documento define os princípios da distribuição física dos elementos computacionais, sensores, atuadores, antenas e cablagem na aeronave.

Explica onde deve viver cada placa da família (COMPUTE-SENSORIAL, COMPUTE-ACTUATOR, COMPUTE-NODE, COMPUTE-FLIGHT-CLUSTER, COMPUTE-VISION-CARRIER e COMM-RF), por que razão a proximidade aos periféricos reduz ruído e cablagem, como preservar a separação entre domínios e que cuidados mecânicos, térmicos e eletromagnéticos condicionam a instalação.

---

# 2. Âmbito

Abrange:

* princípio de distribuição por proximidade e por domínio;
* localização recomendada de cada PCB e de cada antena (5,8 GHz, 2,4 GHz, 868 MHz);
* separação física do domínio FailSafe e do Master Geral;
* cablagem, fichas RJ45-RS, CAN-Principal e alimentação 3,3/5/12 V;
* manutenção, modularidade e expansão.

Não abrange:

* pinos e níveis elétricos (ver HW-004);
* dimensionamento de energia (ver HW-005);
* topologia lógica das redes (ver HW-006);
* periféricos concretos (ver HW-007, SEN, ACT).

---

# 3. Descrição

## 3.1 Princípio de distribuição

A arquitetura não exige que os elementos de um mesmo grupo vivam juntos. Pelo contrário, recomenda-se distribuí-los pela célula sempre que isso reduza ligações longas, evite concentrar funções críticas num ponto único e melhore a relação sinal/ruído.

```text
Antes (concentrado — desaconselhado):

  [Sensores dispersos] ──longos cabos analógicos──► [Baía única com tudo]
       ruído, massa de cobre, ponto único de falha

Depois (distribuído — recomendado):

  [Sensor] ─curto─► [COMPUTE-SENSORIAL local] ─CAN digital─► [Master Geral]
  [Atuador] ─curto─► [COMPUTE-ACTUATOR local] ◄─CAN digital── [Master Geral]
```

A proximidade converte sinais analógicos frágeis em mensagens digitais robustas logo na origem.

## 3.2 Mapa físico de referência (asa fixa convencional)

```text
                          NARIZ
                            ▲
                            │
              ┌─────────────┼──────────────┐
              │ COMPUTE-SENSORIAL_01       │
              │ (Pitot, estática, TAT)     │
              └─────────────┼──────────────┘
                            │
   ┌──────────────────┬─────┴──────┬──────────────────┐
   │ ASA ESQUERDA     │  BAÍA      │ ASA DIREITA      │
   │ SENSORIAL_02     │  CENTRAL   │ SENSORIAL_03     │
   │ (IMU, mag)       │            │ (IMU, mag)       │
   │ ACTUATOR_SUP     │  FLIGHT-   │ ACTUATOR_SUP     │
   │ (aileron)        │  CLUSTER   │ (aileron)        │
   │                  │  (Master   │                  │
   │                  │   Geral)   │                  │
   │                  │            │                  │
   │                  │  VISION-   │                  │
   │                  │  CARRIER   │                  │
   │                  │  (GCV)     │                  │
   └──────────────────┴─────┬──────┴──────────────────┘
                            │
              ┌─────────────┼──────────────┐
              │ SENSORIAL_04 / FAILSAFE    │
              │ (GPS, baro reserva)        │
              │ ACTUATOR_CAuda             │
              │ (profundor, leme, motor)   │
              └─────────────┼──────────────┘
                            ▼
                          CAUDA

Antenas:
  5,8 GHz TX (vídeo) ─ bordo superior, plano de massa livre, afastada de GPS
  2,4 GHz RX         ─ ventre ou lateral, diversidade quando possível
  868 MHz            ─ cauda ou ventre, afastada de eletrónica sensível
```

Este mapa é conceptual. A posição exata depende da célula, do centro de gravidade, da aerodinâmica e do diagrama de radiação.

## 3.3 Onde vive cada PCB

| PCB | Localização recomendada | Justificação |
| --- | --- | --- |
| COMPUTE-SENSORIAL (RP2040) | Junto ao conjunto de sensores que serve (nariz para pressões, asas para IMU/magnetómetro, cauda para baro/GPS auxiliar) | Ligações analógicas e digitais curtas; digitalização precoce |
| COMPUTE-ACTUATOR (RP2040/RP2350) | Junto ao atuador ou ao controlador (servo, ESC) | PWM e potência curtos; retorno (feedback) curto; menos queda de tensão |
| COMPUTE-NODE Master Sensorial (RP2350B) | Baía central ou a meio do feixe CAN-Principal | Agrega sem alongar o barramento; facilita terminação |
| COMPUTE-FLIGHT-CLUSTER (Master Geral) | Baía central, sobre amortecedores de vibração, com arrefecimento e acesso para manutenção | Protege os 8 núcleos; minimiza comprimento médio do CAN-Principal e dos RJ45 para 2,4 GHz/868 MHz |
| COMPUTE-VISION-CARRIER (GCV) | Baía dianteira/central com vista curta para a câmara, ventilação e blindagem | MIPI CSI exige FFC curto (ver HW-004/HW-007); i.MX exige arrefecimento; RJ45 para 5,8 GHz curto |
| COMM-RF 5,8 GHz | Junto à antena de 5,8 GHz, com plano de massa e dissipação | Minimiza perdas coaxiais a 5,8 GHz; RJ45-RS vindo do GCV |
| COMM-RF 2,4 GHz / 868 MHz | Junto às respetivas antenas, separadas entre si e do GPS | Evita dessensibilização; RJ45-RS vindos do Master Geral |
| Nós FailSafe distribuídos (COMPUTE-NODE) | Fisicamente separados da baía central (ex.: cauda), com alimentação e sensores próprios | Sobrevivem a falha localizada na baía central |

## 3.4 Separação física dos domínios

A separação não exige grandes distâncias; exige que uma falha localizada (curto, água, calor, impacto, interferência) não inutilize em simultâneo domínios que devem permanecer independentes.

Critérios a aplicar em cada instalação:

| Domínio | Separar de | Como |
| --- | --- | --- |
| FailSafe/Supervisão | Voo/Missão normal | Posição distinta, alimentação com derivação protegida independente, sensores de reserva próprios, feixe CAN com encaminhamento distinto |
| Master Geral | Potência de propulsão | Compartimento blindado, massa estrela, feixes separados, filtragem |
| GCV (i.MX) | Recetores GPS e 868 MHz | Distância, blindagem, planos de massa contínuos, filtragem da alimentação comutada |
| Rádios TX (5,8 GHz) | GPS e magnetómetros | Distância máxima praticável, orientação de antenas, ensaios de dessensibilização |
| Potência (ESC, motores) | Barramento CAN e sensores analógicos | Feixes entrançados e afastados, toroides quando necessário, massa de potência separada até ponto único |

## 3.5 Cablagem e fichas

* **CAN-Principal (R1):** par trançado com blindagem, terminação de 120 Ω nas extremidades, derivação curta (stub) para cada nó. Topologia em barramento, sem estrela improvisada.
* **RJ45-RS para COMM-RF:** cabo de 8 vias standard com pares dedicados a dados série, alimentação e sinalização de presença; ficha RJ45 com trava; identificação por cor/etiqueta por banda (5,8 GHz, 2,4 GHz, 868 MHz).
* **Alimentação 12/5/3,3 V:** feixe de potência separado do feixe de sinal; bitola por corrente de pico (não média); proteção por derivação.
* **MIPI CSI:** FFC curto, impedância controlada, sem vias desnecessárias, afastado de comutação (ver HW-004; valores por definir).
* **Massa:** topologia em estrela por baía, ponto único de interligação, sem laços entre potência e sinal.

```text
Sensor ──curto──► COMPUTE-SENSORIAL ══CAN digital══► Master Geral
Atuador ─curto──► COMPUTE-ACTUATOR  ══CAN digital══► Master Geral
Câmara ──FFC curto──► GCV ══RJ45──► COMM-RF 5,8 GHz ──► AR
Master Geral ══RJ45──► COMM-RF 2,4 GHz / 868 MHz ──► AR
```

## 3.6 Ambiente mecânico, térmico e EMC

Cada instalação deve verificar: vibração (amortecedores do cluster e do GCV), temperatura (dissipadores do i.MX e dos reguladores, circulação de ar, limites da baía), humidade e poeira (conformal coating e vedação onde aplicável), compatibilidade eletromagnética (blindagem da baía central, filtros, ensaios de emissão/suscetibilidade — estratégia por definir em HW-008).

## 3.7 Manutenção e modularidade

Cada elemento deve poder ser substituído sem desmontar a aeronave: fichas com polarização mecânica, etiquetas com grupo/elemento/versão, pontos de teste acessíveis, fixação anti-vibração com ferramenta simples. A configuração física (que elemento serve que sensor/atuador) é registada na configuração pré-compilação (HW-009).

---

# 4. Exemplos

## Exemplo 1 — Nariz com pressões

```text
Pitot + estática + temperatura ─(tubos curtos + fios curtos)─►
COMPUTE-SENSORIAL_01 (RP2040) no nariz ─(CAN-Principal)─► Master Geral
```

Vantagem: sinais de pressão e temperatura digitalizados a centímetros da tomada; apenas um par trançado digital percorre a fuselagem.

## Exemplo 2 — Asa com servo e IMU

```text
IMU da asa esquerda ─(SPI curto)─► SENSORIAL_02
Servo do aileron esquerdo ─(PWM curto)─► ACTUATOR_ASA_ESQ (RP2040)
Ambos ─(CAN-Principal comum na asa)─► baía central
```

## Exemplo 3 — Separação FailSafe

```text
Baía central: Master Geral + GCV + SENSORIAL principal
Cauda: COMPUTE-NODE FailSafe + GPS/IMU/barómetro de reserva + alimentação protegida
Qualquer incidente na baía central (curto, sobreaquecimento) preserva
a capacidade mínima de supervisão e de atuação de emergência.
```

---

# 5. Interfaces

| Interface física | Percurso | Documento de detalhe |
| --- | --- | --- |
| CAN-Principal | Todos os nós em barramento com stubs curtos | HW-004, HW-006 |
| RJ45-RS 5,8 GHz | GCV → COMM-RF 5,8 GHz | HW-004, HW-006, HW-007 |
| RJ45-RS 2,4 GHz / 868 MHz | Master Geral → COMM-RF respetivas | HW-004, HW-006, HW-007 |
| MIPI CSI FFC | Câmara → COMPUTE-VISION-CARRIER | HW-004, HW-007 |
| Alimentação 12/5/3,3 V | Fonte → distribuição → cada PCB | HW-005 |
| Massas e blindagens | Estrela por baía, ponto único | HW-004, HW-008 |

---

# 6. Pontos em aberto

| # | Ponto em aberto | Resolução |
| --- | --- | --- |
| 1 | Posições definitivas por modelo de aeronave (plantas de baías, centros de gravidade, antenas) | HW-009 + projeto da célula |
| 2 | Suportes anti-vibração do cluster e do GCV (curvas de transmissibilidade) | Ensaio mecânico |
| 3 | Solução térmica da baía central com i.MX + 4 × RP2350 + reguladores (dissipadores, ar, limites) | HW-005 + ensaio térmico |
| 4 | Encaminhamento do CAN-Principal por modelo (comprimentos, stubs, terminações) | HW-006 |
| 5 | Estratégia EMC/EMI completa (blindagem, filtros, ensaios) | HW-008 |
| 6 | Etiquetagem, pontos de teste e tempo médio de substituição por elemento | Documentação de manutenção |

---

# 7. Referências

* HW-001 — Arquitetura de Hardware
* HW-002 — Grupos Computacionais
* HW-004 — Interfaces Elétricas
* HW-005 — Alimentação e Distribuição de Energia
* HW-006 — Interfaces de Comunicação
* HW-007 — Interfaces de Periféricos
* HW-008 — Redundância e Isolamento de Hardware
* HW-009 — Expansibilidade e Configuração de Hardware
