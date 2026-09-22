# ACT — Atuadores — Índice

| Campo | Valor |
| ----- | ----- |
| **Domínio** | ACT — Atuadores |
| **Estado** | Por especificar |
| **Versão** | 0.1 (índice backlog) |

---

# 1. Objectivo

Explicar, de forma didáctica, onde vive a força que move a aeronave: motores, hélices, servos de superfícies, trem de aterragem e actuadores auxiliares. Este índice fixa a intenção do domínio ACT; as especificações detalhadas (curvas, protocolos físicos, PWM, feedback) serão criadas em ficheiros próprios.

Pensemos assim: o voo pensa, o actuador faz. Entre os dois há sempre validação dupla.

# 2. Âmbito (previsto, não fechado)

* Motores e controladores, servos, trem de aterragem, actuadores auxiliares.
* Validação de envelope, conversão comando-lógico → sinal-físico, feedback (corrente, posição, temperatura).
* Interface com MAT-006 (propulsão), MAT-015 (controlo), CTL, ENE e SEC.
* Não fecha nesta fase: modelos, pinos, temporizações finais, código.

# 3. Relação com os Grupos Computacionais formais

* **Grupo Atuador** — dono da execução física: recebe comandos validados via CAN-Principal, verifica o envelope uma segunda vez, gera sinais físicos via CAN-Intra e recolhe feedback.
* **Master Geral (Núcleo de Voo RP2350#1-C0 + Núcleo de Segurança RP2350#4-C0)** — origem dos únicos comandos aceites (regra Missão→Voo→Atuador, nunca directo; ver MAT-018).
* **Grupo FailSafe + actuação de emergência** — via dedicada CAN-FailSafe; em emergência, assume os actuadores críticos com autoridade máxima.
* **Grupo Sensorial** — fornece corrente/tensão/temperatura para supervisão do esforço.
* **Grupo de Cálculo (Math Core RP2350#2-C1)** — serviço de análise (esforço, limites) via MATH_REQUEST; o ciclo rápido usa limites locais determinísticos.
* **Grupo Comunicação / Visão GCV** — apenas supervisão; sem comando directo ao actuador.

# 4. Energia

Placas do Grupo Atuador alimentadas a partir de **3,3 V / 5 V / 12 V** da aeronave (lógica a 3,3/5 V; potência a 12 V ou bateria directa conforme projecto). Rails internas (núcleo, drivers, servo-alimentação) geradas por **reguladores / PMIC** locais com sequenciamento e protecção contra inversão/sobrecorrente. A validação dos limites deve cobrir a gama completa de alimentação.

# 5. Regra RF=RJ45

Os actuadores **nunca** recebem ordens por rádio directamente. Todo o RF entra pela **RJ45-RS** no Grupo Comunicação (comando a 2.4 GHz) → CAN-Principal → Núcleo de Voo → CAN-Principal → Grupo Atuador. Nenhum modem é ligado ao Grupo Atuador.

# 6. Redes

* CAN-Principal (comandos/estados), CAN-Intra (distribuição local), CAN-FailSafe (emergência). **Sem vídeo no CAN.**

# 7. Estado

**Por especificar** — este README é o índice; os documentos ACT-xxx serão criados depois.
