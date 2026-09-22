# NAV-001 — Serviço de Navegação

| Campo             | Valor                      |
| ----------------- | -------------------------- |
| **Código**        | NAV-001                    |
| **Título**        | Serviço de Navegação       |
| **Versão**        | 1.0                        |
| **Estado**        | Em Desenvolvimento         |
| **Autor**         | ShegaPT                    |
| **Classificação** | Especificação de Navegação |

---

# 1. Objetivo

O presente documento define a **Navegação como serviço** do agrupamento computacional principal (**Master Geral**): um fornecedor especializado de posição, velocidade, atitude de referência, erro de seguimento e tempo, consumido pelo Voo, pela Missão e pelo Planeamento, sem que nenhum deles precise de reimplementar geodesia, filtragem ou gestão de sensores de navegação.

A Navegação reside no **Núcleo de Navegação** (RP2350 #2 Core0, 50–100 Hz, bare-metal) e funciona como um servidor cooperante dentro do agrupamento:

* **Consome** o Núcleo de Fusão (estado inercial a 200 Hz) como espinha dorsal de alta taxa.
* **Consome** o Núcleo de Cálculo via **MATH_REQUEST / MATH_RESPONSE** para operações pesadas (transformações geodésicas, matrizes, projeções, verificações).
* **Consome** dados já tratados do Grupo Computacional Sensorial: navegação por satélite (**GNSS**: latitude, longitude, altitude, velocidade solo, tempo), unidade inercial (**IMU** via Fusão), pressão **barométrica** (altitude pressão) e, quando disponível, magnetómetro e velocidade aerodinâmica como apoios.
* **Fornece** soluções completas, sempre com idade, estado e margem de incerteza, via **NAVIGATION_REQUEST / NAVIGATION_RESPONSE** sobre a FABRIC interna.

Navegação não pilota e não delibera missão: estima onde estamos, para onde vamos e com que erro seguimos o plano, para que o Voo valide e a Missão decida.

---

# 2. Âmbito

## 2.1 Dentro do âmbito

* Estimação de posição (latitude, longitude, altitude elipsoidal e ortométrica), velocidade (solo e aerodinâmica quando observável), rumo, trajetória e erro de seguimento.
* Gestão de fontes: GNSS, IMU (via Fusão), barómetro, magnetómetro e referências de tempo, com ponderação, comutação e degradação explícitas.
* Contrato de serviço: tipos de pedido/resposta, cadências (50 Hz nominal, 100 Hz dinâmico), prazos (≤ 8 ms a 50 Hz, ≤ 5 ms a 100 Hz), estados (VÁLIDA/DEGRADADA/ENVELHECIDA/INVÁLIDA) e comportamento em falta.
* Utilização do Núcleo de Cálculo como acelerador matemático (MATH_REQUEST/RESPONSE com prazo e herança de prioridade).
* Interação com Fusão (200 Hz), Voo (200 Hz), Missão (10–50 Hz) e Planeamento (esporádico).

## 2.2 Fora do âmbito

* Fusão inercial detalhada (MAT-014, núcleo de Fusão): a Navegação consome a fusão, não a substitui.
* Leis de controlo e validações de envolvente (CTL-001): a Navegação informa, o Voo decide.
* Gestão de missão e geração de trajetórias (Missão/Planeamento): a Navegação responde a perguntas geométricas, não escolhe waypoints.
* Pipeline sensorial (SEN-001) e propagação de tempo global (SYS-008, SW-0xx): aqui apenas consumidos.
* Visão como fonte de navegação (odometria visual, deteção): futura, via GCV, fora desta versão (apenas prevista como extensão).

---

# 3. Descrição

## 3.1 Ideia fundamental: um servidor de «onde estamos», não um piloto

Sem serviço central, cada núcleo estimaria posição à sua maneira, com geodesia duplicada, inconsistências de datum e divergências subtis que tornariam o seguimento instável. Com serviço central:

* Existe **uma única solução oficial** por instante, com carimbo, idade e incerteza.
* Todos os consumidores partilham a mesma referência (mesmo elipsoide, mesmo datum, mesma origem local).
* A geodesia pesada vive num só lugar (Navegação + Cálculo), testável e auditável.
* A comutação de fontes (com/sem GNSS, com/sem baro) ocorre uma vez, de forma coerente, em vez de N vezes de formas diferentes.

Princípio de dependência:

```text
SENSORES (Grupo Sensorial) ── dados normalizados ──► FUSÃO (200 Hz)
                                                        │ estado inercial
                                                        ▼
GNSS + BARO (via Master Sensorial) ────────────────► NAVEGAÇÃO (50–100 Hz)
                                                        │ + CÁLCULO (MATH)
                                                        ▼
                                              SOLUÇÃO OFICIAL + ERRO
                                                        │
                                        ┌───────────────┼───────────────┐
                                        ▼               ▼               ▼
                                       VOO            MISSÃO        PLANEAMENTO
                                     (valida)        (decide)        (projeta)
```

## 3.2 Fontes e papéis

### 3.2.1 Fusão (IMU + historial): a espinha dorsal

A Fusão a 200 Hz fornece atitude, velocidade incremental, aceleração e respetivas qualidades. Entre soluções GNSS (5–10 Hz) e entre leituras barométricas (50 Hz), é a propagação inercial que mantém a solução viva. A Navegação nunca ignora a Fusão: mesmo sem GNSS, publica solução propagada (degradada, com incerteza crescente) em vez de silêncio.

### 3.2.2 GNSS (posição e velocidade absolutas + tempo)

O recetor de navegação por satélite fornece, tipicamente a 5–10 Hz:

* Latitude, longitude, altitude elipsoidal, velocidade solo (norte/leste/vertical), rumo solo, número de satélites, diluição de precisão (DOP), estado de fixação (sem fixação / 2D / 3D / diferencial quando aplicável) e tempo.
* Pulso por segundo para disciplina temporal (quando encaminhado em HW).

Limitações assumidas: atraso de transporte de dezenas a centenas de ms (carimbado e compensado), vulnerabilidade a ocultação/multicaminho/interferência, cadência baixa para controlo direto. Por isso o GNSS **corrige** a propagação, nunca a substitui ciclo a ciclo.

### 3.2.3 Barómetro (altitude pressão): o altímetro de curto prazo

O sensor barométrico, a 50–100 Hz já filtrado e calibrado, fornece a altitude mais estável a curto prazo e a taxa de subida mais limpa. A Navegação funde altitude pressão (calibrada com referência de solo — QNH/QFE operacionais) com altitude GNSS (absoluta mas ruidosa) para obter altitude oficial e velocidade vertical.

Sem barómetro válido, a altitude passa a GNSS pura (degradada, com aviso). Sem GNSS, a altitude passa a baro + propagação (degradada, com deriva declarada).

### 3.2.4 Apoios: magnetómetro e velocidade aerodinâmica

* Magnetómetro (50–100 Hz): rumo magnético de apoio, útil em arranque e em voo lento; corrigido de inclinação com atitude da Fusão; nunca única fonte de rumo em manobra.
* Pitot/pressão diferencial (50–100 Hz): velocidade aerodinâmica de apoio para estimar vento (vetor solo menos vetor ar) e para validar envolvente; quando congelado ou suspeito, o vento declara-se DESCONHECIDO em vez de errado.

## 3.3 O que a Navegação calcula (catálogo de serviço)

Para cada ciclo (50 ou 100 Hz), a Navegação publica o **pacote de solução oficial**:

1. **Posição geodésica**: latitude, longitude (graus decimais), altitude elipsoidal e altitude ortométrica (metros), com datum e modelo de geoide declarados.
2. **Posição local**: coordenadas no referencial local de missão (origem no ponto de lançamento ou ponto definido, eixos Norte/Leste/Baixo), em metros, para consumo direto do Voo e do Planeamento sem geodesia adicional.
3. **Velocidade**: componentes Norte/Leste/Baixo (m/s), velocidade solo, rumo solo, velocidade vertical, mais estimativa de vento quando observável.
4. **Atitude de referência**: cópia coerente da atitude da Fusão com a mesma época da solução (para que posição e atitude correspondam ao mesmo instante).
5. **Erro de seguimento**: distância lateral e vertical à perna/trajetória ativa, avanço ao longo da perna, tempo estimado de chegada, quando a Missão/Planeamento forneceram perna ativa.
6. **Qualidade**: estado (VÁLIDA/DEGRADADA/ENVELHECIDA/INVÁLIDA), idade por fonte, incertezas (desvios-padrão de horizontal/vertical/velocidade), número de satélites, DOP, motivo de degradação.
7. **Tempo**: época da solução na base temporal comum + correspondência UTC quando disponível.

Tudo com unidades fixas, referenciais fixos e época explícita. Sem época, a solução é inválida por definição.

## 3.4 Como usa o Cálculo (MATH_REQUEST / RESPONSE)

O Núcleo de Navegação não implementa geodesia pesada com as próprias mãos em cada ciclo: delega ao Núcleo de Cálculo as operações custosas, mantendo para si a lógica de estimação, a gestão de fontes e a formatação.

Exemplos de delegação:

* Conversão geodésica ↔ cartesiana terrestre e ↔ local (matrizes de rotação, raios de curvatura, iteração de altitude).
* Projeção de trajetória e cálculo de erro lateral/vertical com interpolação.
* Operações matriciais do estimador (quando o estimador vive repartido entre Navegação e Cálculo).
* Verificação de perna (ponto mais próximo, cruzamento de waypoint, deteção de desvio).

Contrato (detalhe temporal em SW-0xx):

```text
NAVEGAÇÃO precisa de cálculo
  │ MATH_REQUEST(id, operação, operandos, prazo=4 ms, prioridade=ALTA herdada)
  ▼
CÁLCULO executa (FPU/DSP, herança de prioridade, fila com deserção)
  │ MATH_RESPONSE(id, resultado, estado=OK) ou MATH_TIMEOUT
  ▼
NAVEGAÇÃO: se OK → usa; se TIMEOUT → usa via degradada
  (última transformação válida, aproximação plana local ou propagação simples)
  e marca solução como DEGRADADA_POR_CÁLCULO (nunca bloqueia o ciclo).
```

A Navegação dimensiona os seus ciclos para caberem mesmo com um TIMEOUT ocasional: o caminho degradado é testado com a mesma severidade que o caminho feliz.

## 3.5 Modos, cadências e degradação

| Situação | Cadência | Fontes | Estado típico | Consumo pelo Voo |
|----------|----------|--------|---------------|------------------|
| Normal com GNSS + baro | 50 Hz (100 Hz em descolagem/aterrragem e manobra) | Fusão + GNSS + baro + apoios | VÁLIDA | Seguimento pleno. |
| GNSS degradado (poucos satélites, DOP alto) | 50–100 Hz | Fusão + baro + GNSS ponderada baixa | DEGRADADA_GNSS (incerteza cresce) | Manobra conservadora (limites reduzidos pelo Voo). |
| Sem GNSS (ocultação/interferência) | 50 Hz | Fusão + baro + magnetómetro | DEGRADADA_SEM_GNSS (deriva declarada, válida por janela curta) | Espera/contenção; Missão congela avanço; Segurança avalia regresso. |
| Sem baro | 50 Hz | Fusão + GNSS | DEGRADADA_SEM_BARO (vertical ruidosa) | Limita taxa vertical; evita voo próximo do solo. |
| Sem Fusão válida | — | — | INVÁLIDA (Navegação não inventa atitude) | Voo em contenção/FailSafe (ver CTL-001). |
| Cálculo em TIMEOUT | 50–100 Hz | Mesmas, com aproximação | DEGRADADA_POR_CÁLCULO | Usa solução aproximada com margem. |

Regra de envelhecimento: qualquer solução com idade superior a 2 períodos sem atualização é ENVELHECIDA (usável com cautela e margem); após 5 períodos é INVÁLIDA para seguimento agressivo. A Missão nunca recebe solução antiga disfarçada de fresca: a idade viaja sempre com a solução.

## 3.6 Inicialização e alinhamento (o que acontece em solo)

1. **Autoteste**: verifica calibrações, relógios, disponibilidade de Fusão, Cálculo e Master Sensorial.
2. **Alinhamento grosseiro**: atitude inicial por acelerómetros (nivelamento) + rumo por magnetómetro/GNSS em movimento; posição inicial por GNSS ou por ponto introduzido em solo.
3. **Referência barométrica**: regista pressão de solo para altitude relativa; confirma unidades e datum.
4. **Origem local**: fixa origem Norte/Leste/Baixo (tipicamente ponto de lançamento) e comunica-a a Missão/Planeamento para que todos usem a mesma.
5. **Declaração de prontidão**: NAV_PRONTA apenas quando Fusão válida + pelo menos uma fonte absoluta (GNSS ou baro referenciado) + Cálculo responsivo + erro estimado dentro de limiares. Sem prontidão não há descolagem autónoma.

---

# 4. Exemplos ASCII

## 4.1 Pergunta e resposta normais (Missão → Navegação → Voo)

```text
MISSÃO (10 Hz): «qual o erro para a perna 4?»

MISSÃO ── NAVIGATION_REQUEST ──► NAVEGAÇÃO (FABRIC, ALTA):
         { id=201, perna_ativa=4, época_pedida=T }

NAVEGAÇÃO:
  lê FUSÃO (idade 2 ms, VÁLIDA) + GNSS (idade 80 ms) + BARO (idade 8 ms)
  ── MATH_REQUEST ──► CÁLCULO: «projeta posição na perna 4» (prazo 4 ms)
  ◄── MATH_RESPONSE (OK, 1,1 ms)
  compõe SOLUÇÃO_OFICIAL (T, lat/lon/alt, NEB local, vel, erro lateral 12 m
  à direita, erro vertical 3 m acima, incerteza h=1,8 m, estado=VÁLIDA)

NAVEGAÇÃO ── NAVIGATION_RESPONSE ──► MISSÃO + VOO (difusão 50 Hz):
           { id=201, solução, erro, idade, incerteza, estado }

VOO (200 Hz) usa erro + solução (idade < 20 ms) para gerar comando validado.
MISSÃO usa erro para avançar waypoint quando dentro do raio de captura.
```

## 4.2 Pedido com Cálculo em atraso (via degradada, sem bloquear)

```text
NAVEGAÇÃO ── MATH_REQUEST (id=202, prazo 4 ms) ──► CÁLCULO (ocupado)

4 ms expiram sem resposta
  → CÁLCULO emite MATH_TIMEOUT (liberta fila)
  → NAVEGAÇÃO usa aproximação plana local (última matriz válida)
  → SOLUÇÃO marcada DEGRADADA_POR_CÁLCULO, incerteza majorada +0,5 m
  → VOO recebe solução aproximada + aviso → reduz agressividade nesse ciclo
  → DIAGNÓSTICO contabiliza TIMEOUT (alvo: <1% dos pedidos)

No ciclo seguinte, com CÁLCULO livre, a solução volta a VÁLIDA.
Nenhum ciclo de Navegação esperou além do prazo.
```

## 4.3 Perda de GNSS em voo (degradação declarada, não silêncio)

```text
t=0 s: GNSS válido (8 sats, DOP 1,1) → SOLUÇÃO VÁLIDA, 50 Hz
t=12,4 s: sats caem para 4, DOP 3,8 → NAVEGAÇÃO pondera GNSS em baixo
           → estado=DEGRADADA_GNSS, incerteza h sobe 1,8→4,5 m
t=15,0 s: sem fixação há 2 s → estado=DEGRADADA_SEM_GNSS
           → propaga por FUSÃO+BARO, deriva declarada (ex.: 0,8 m/s)
           → VOO limita inclinação a 15°, MISSÃO congela avanço, SEGURANÇA
             inicia contagem para regresso se persistir
t=25,0 s: GNSS recupera (6 sats) → reconverge suavemente (sem salto),
           estado volta a VÁLIDA após validação de 1 s.

Em nenhum instante a NAVEGAÇÃO publicou posição inventada como VÁLIDA.
```

## 4.4 Barómetro contra GNSS em altitude (fusão de altitude)

```text
BARO (50 Hz, estável, resolução 0,1 m, deriva lenta):  120,3 m (rel. solo)
GNSS (5 Hz, absoluto, ruído ±2 m):                    148,0 m (elipsoidal)

NAVEGAÇÃO (via CÁLCULO: elipsoidal→ortométrica com geoide EGM):
  altitude oficial = baro calibrada (curto prazo) + correção GNSS (longo prazo)
  velocidade vertical = derivada filtrada do baro (limpa) + verificação GNSS
  publica: alt_rel=120,3 m, alt_abs=..., vvert=+0,4 m/s, estado=VÁLIDA

Se baro congela (Δ=0) e GNSS varia → declara BARO_SUSPEITO, usa GNSS pura
(DEGRADADA_SEM_BARO) + alerta (ver SEN-001 §4.3). Sem invenção.
```

---

# 5. Interfaces

## 5.1 Mensagens (FABRIC interna, salvo indicação)

| Mensagem | Emissor → Recetor | Cadência | Prioridade | Conteúdo essencial |
|----------|-------------------|----------|------------|-------------------|
| ESTADO_FUSÃO | Fusão → Navegação (+ Voo) | 200 Hz | CRÍTICA | atitude, vel. incremental, aceleração, idade, estado |
| PACOTE_SENSORIAL | Master Sensorial → Navegação (via Fusão + direto para GNSS/baro) | 200/50/5–10 Hz por tipo | ALTA/MÉDIA | GNSS, baro, mag, Pitot normalizados + idade + estado (via CAN-Principal, TLV) |
| MATH_REQUEST | Navegação → Cálculo | Sob pedido (até ~100 Hz em pico) | ALTA (herdada) | id, operação, operandos, prazo |
| MATH_RESPONSE / MATH_TIMEOUT | Cálculo → Navegação | Por pedido | ALTA | id, resultado ou TIMEOUT, tempo gasto |
| NAVIGATION_REQUEST | Voo/Missão/Planeamento → Navegação | 10–100 Hz | ALTA/MÉDIA | id, perna/trajetória de referência, época pedida |
| NAVIGATION_RESPONSE / SOLUÇÃO_OFICIAL | Navegação → Voo + Missão + Planeamento | 50–100 Hz (difusão) + por pedido | ALTA | posição geo + local, velocidade, erro, incerteza, idade, estado |
| NAV_PRONTA / NAV_ESTADO | Navegação → Supervisão + Missão | 10 Hz + evento | ALTA | prontidão, modo, motivo de degradação |
| TIME_SYNC | Supervisão → Todos | 100 Hz | SUPER_CRÍTICA | base temporal comum (consumida para épocas) |

## 5.2 Formatos e referenciais (resumo normativo)

* Geodesia: elipsoide e datum declarados por configuração (ex.: WGS-84), modelo de geoide declarado para altitude ortométrica; nenhum valor sem datum é válido.
* Local: origem fixada na inicialização, eixos Norte/Leste/Baixo em metros; mudança de origem em voo é proibida (nova origem exige reinicialização do serviço com anúncio).
* Unidades: graus decimais, metros, m/s, rad; épocas na base monotónica comum + UTC quando disponível.
* Incertezas: desvios-padrão 1σ por componente (horizontal, vertical, velocidade); nunca apenas «precisão boa/má».

## 5.3 Requisitos temporais (ver SW-0xx para o contrato completo)

* Ciclo nominal 50 Hz (20 ms) com orçamento ≤ 8 ms; ciclo dinâmico 100 Hz (10 ms) com orçamento ≤ 5 ms.
* Pedidos de Voo respondidos preferencialmente dentro do mesmo período de Navegação; pedidos de Missão toleram resposta no período seguinte com idade explícita.
* MATH com prazo de 4 ms para Navegação; TIMEOUT tratado como via degradada, nunca como bloqueio.

---

# 6. Pontos em Aberto

1. **Estimador definitivo**: filtro complementar contra Kalman estendido repartido, estados incluídos (viés de IMU, vento, deriva barométrica), matrizes de covariância e afinação por ensaio real de vibração e manobra.
2. **Gestão de datum/geoide**: elipsoide, datum e modelo de geoide finais, armazenamento embarcado e atualização; origem local por missão e transição entre missões.
3. **Fusão de altitude**: ponderação baro/GNSS, deteção de congelamento de tomada estática, compensação térmica fina e limiares de suspeita.
4. **Estimação de vento**: observabilidade com/sem Pitot, convergência, limites de uso no seguimento e declaração de VENTO_DESCONHECIDO.
5. **Magnetómetro**: calibração dura/macia por célula, posicionamento anti-interferência, ponderação em manobra e deteção de anomalia magnética local.
6. **Robustez GNSS**: máscara de elevação, limiares de DOP/satélites, deteção de salto/multicaminho, comportamento sob interferência intencional e comutação sem salto.
7. **Disciplina temporal pelo pulso do GNSS**: encaminhamento em HW, correção de deriva do relógio do agrupamento e tolerância sem pulso.
8. **Extensão visual futura**: papel do GCV (odometria, marcos, deteção) como fonte auxiliar, interface de covariância e prioridade face ao GNSS; fora desta versão, mas com reserva de identificadores.
9. **Raio de captura e lógica de perna**: distâncias de captura, antecipação de curva, transições entre pernas e comportamento com erro grande (reinterceptar contra abortar).
10. **Prova de carga do Cálculo**: número máximo de MATH_REQUEST por ciclo de Navegação a 100 Hz, tempos por operação (geodésicas, matrizes) e margem para rajadas de Planeamento em simultâneo.

---

# 7. Referências

* SYS-002 — Arquitetura Computacional (domínios e autoridade).
* SYS-005 — Fluxo Global de Informação (quem consome navegação).
* SYS-008 — Gestão Temporal (épocas, sincronização e prazos).
* SW-0xx — Políticas Temporais (cadências, latências e anti-inanição).
* SEN-001 — Cadeia Sensorial (GNSS, IMU, barómetro como entradas tratadas).
* CTL-001 — Lógica de Controlo (Voo como consumidor validador).
* COM-001/008 — Comunicação e CAN-Principal (transporte do sensorial).
* MAT-010 — Navegação e Geodesia (fundamentos matemáticos).
* MAT-014 — Fusão de Sensores (espinha dorsal inercial).
* MAT-017 — Matemática de Sensores (modelos de GNSS/baro/IMU).
* Docs/Esquemas/Arquitetura-Computacional (§ núcleos, IPC e MATH_REQUEST).
