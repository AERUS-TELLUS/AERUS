# SYS-009 — Arranque e Encerramento

| Campo             | Valor                    |
|-------------------|--------------------------|
| **Código**        | SYS-009                  |
| **Título**        | Arranque e Encerramento  |
| **Versão**        | 2.0                      |
| **Estado**        | Em Desenvolvimento       |
| **Autor**         | ShegaPT                  |
| **Classificação** | Especificação de Sistema |

---

# 1. Objetivo

O presente documento define a arquitetura geral dos processos de arranque, preparação operacional, encerramento e desativação do sistema AERUS. O arranque e o encerramento são tratados como processos controlados e verificáveis, segundo princípios de operação aeronáutica, com combinação de verificações do operador e do sistema.

---

# 2. Âmbito

Aplica-se à sequência completa de modos (Before_Start a Shutdown), à ordem de energização, ao arranque do cluster, dos grupos, do GCV (com sequenciamento NXP) e da comunicação RF, bem como ao encerramento lógico e ao desligamento físico.

---

# 3. Descrição Detalhada

## 3.1. Princípio geral

A operação inicia-se por verificações em duas categorias: do **operador** (inspeções físicas, visuais e funcionais, configuração de aeronave e missão, condições externas) e do **sistema** (hardware, sensores, atuadores, comunicações, configuração, sincronização temporal, integridade). Nenhuma categoria substitui a outra.

A aplicação de alimentação, por si só, nunca significa aeronave pronta para voo.

## 3.2. Ordem de energização e arranque lógico

Pré-condição: conclusão do checklist `Before_Start` (detalhe em OPS). Após autorização:

1. **Energia**: aplicação de 3.3/5/12 V; arranque monotónico de rails internas por reguladores/PMIC; supervisão de Power-Good por cada PCB.
2. **FailSafe primeiro**: o Grupo FailSafe/Supervisão inicia-se e arma-se (CAN-FailSafe ativa, watchdogs armados). Sem FailSafe operacional não se prossegue.
3. **Masters de Grupo**: Sensorial, Atuador e Comunicação iniciam-se (RP2040 + RP2350), testam CAN-Intra e registam-se na CAN-Principal.
4. **Master Geral**: arranque dos 4x RP2350, teste da FABRIC, sincronização TIME_SYNC, eleição/confirmação da Supervisão do cluster, publicação de SYSTEM_STATUS.
5. **Sincronização temporal**: estabelecimento da base MG↔FailSafe e alinhamento dos restantes (ver SYS-008).
6. **GCV**: sequenciamento conforme NXP (PMIC → rails do SoC → LPDDR → armazenamento → MIPI), arranque do SoC, autoteste de câmara/ISP/codec, arranque do Router RP2350, registo na CAN-Principal, teste da RJ45-RS para a placa TX 5.8 GHz (sem emissão sem autorização).
7. **RF de comando/telemetria**: teste das RJ45-RS para RX 2.4 GHz / TX 868 MHz via Grupo de Comunicação, sem armação de atuadores.
8. **Validação pós-arranque (`After_Start`)**: verificação individual de grupos, comunicações, sincronismo, sensores, atuadores (sem provocação de qualquer ação perigosa), configuração, módulos, estados e integridade. Intervenções do operador quando exigidas (ex.: confirmação de superfícies).

A inicialização só se considera concluída após verificação individual positiva; a mera energização dos grupos é insuficiente. Qualquer condição incompatível é tratada pelas regras aplicáveis (SEC/SYS-006).

## 3.3. Modos intermédios (resumo operacional)

- `Taxi` (opcional): deslocação em solo, quando aplicável; caso contrário, transição direta para `Line_Up`.
- `Line_Up`: posicionamento e verificações finais, calibrações e confirmação de parâmetros.
- `Before_Takeoff`: checklist final de solo; a descolagem depende de conclusão satisfatória.
- `After_Takeoff`: verificação pós-solo (sensores de solo/voo, controlo, navegação, aquisição).
- `In_Flight`: modo principal; execução contínua de missão, controlo, navegação, energia, dados, comunicações e segurança; verificações contínuas por módulo (sem checklist discreta por instante).
- `Before_Landing` → `Descent` → `Approach` → `Landing`: preparação, gestão de descida e periféricos (iluminação, trem, dispositivos), aproximação final com módulos não necessários em espera controlada, deteção de solo por medições consistentes (ultrassónicos, óticos, etc.; nunca por medição isolada quando exigida consistência) e controlo até condição segura de solo.
- `After_Landing` → `Parking` (opcional) → `Securing_Aircraft` → `Shutdown`: estabilização, deslocação final quando aplicável, colocação em condição segura (bloqueio de motores, inibição de atuadores, confirmação de ausência de comandos) e checklist de encerramento (integridade, energia, preservação, conclusão de missão).

Diagrama:

```text
Before_Start → After_Start → Taxi ──┐
                                    ├─► Line_Up → Before_Takeoff
                                    │         (validação Voo)
  ... → After_Takeoff → In_Flight → Before_Landing → Descent
  → Approach → Landing → After_Landing → Parking ──┐
                                                   ├─► Securing_Aircraft → Shutdown
                                                   │         (encerramento lógico
                                                   │          antes do físico)
```

## 3.4. Encerramento lógico e desligamento físico

O encerramento lógico precede sempre o desligamento físico. Após `Shutdown` e checklist do operador, procede-se a: desativação de RF (TX primeiro em modo seguro), paragem do pipeline do GCV, sincronização de logs, desarmação controlada, corte de alimentação e, quando aplicável, desconexão de baterias e armazenamento. A ordem exata consta de OPS.

## 3.5. Interrupção anormal

Qualquer falha no arranque/encerramento impede progressão normal; aplicam-se regras da condição detetada (SEC). A sequência normal nunca prevalece sobre segurança. Exemplo: falha de 1x RP2350 no arranque → permanência em `After_Start`, declaração de degradação, proibição de descolagem até resolução ou autorização degradada conforme SEC/OPS.

## 3.6. Configuração e separação operador/sistema

O processo adapta-se à configuração instalada (ex.: aeronave sem trem não possui requisitos de trem). O operador responde pelo físico/visual/decisão; o AERUS, pelo automático (grupos, redes, integridade). A repartição exata consta de OPS.

---

# 4. Exemplos

## Exemplo 1 — Arranque nominal (extrato de log)

```text
[00] Energia OK (3V3/5V/12V, PG por PCB)
[01] FailSafe ARMADO (CAN-FailSafe ativa)
[02] Sensorial/Atuador/Comunicação registados (CAN-Principal)
[03] MG: FABRIC OK, 8 núcleos, Supervisão confirmada, TIME_SYNC base
[04] GCV: sequência NXP OK, câmara+MIPI OK, 720p60/30 prontos, RJ45-RS testada
[05] RF 2.4/868 testadas (sem armação) → After_Start validado
```

## Exemplo 2 — Falha no arranque

```text
GCV sem MIPI válido → VISAO_SAUDE=FALHA (Router).
Decisão: proibição de missão com dependência de vídeo;
voo sem vídeo permitido apenas se OPS/SEC o autorizarem.
Registo + informação ao operador via GCCOM.
```

## Exemplo 3 — Encerramento seguro

```text
Securing_Aircraft: motores bloqueados, atuadores inibidos, sem comandos.
Shutdown: checklist operador OK → GCV parado → logs sincronizados
→ RF em seguro → corte de energia → baterias desconectadas.
```

---

# 5. Interfaces Com Outros Documentos

| Documento | Relação |
|-----------|---------|
| SYS-006/007/008 | Estados, modos e tempos aqui sequenciados |
| OPS | Checklists e ordem fina de operações |
| SEN/ACT/NAV/CTL | Verificações específicas por domínio |
| SEC/ENE | Segurança e energia no arranque/encerramento |
| HW/COM | PMIC/sequenciamento, redes e mecanismos |

---

# 6. Estado / Pontos Em Aberto

- **Estado**: Em Desenvolvimento.
- **Pontos em aberto**: tempos máximos por etapa; política de tentativas de arranque por grupo; sequência NXP final por PMIC; interlocks físicos de armação; procedimentos de armazenamento; ensaios de arranque degradado (falha de 1x RP2350, falha de GCV, falha de RF).

