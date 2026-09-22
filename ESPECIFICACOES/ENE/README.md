# ENE — Energia — Índice

| Campo | Valor |
| ----- | ----- |
| **Domínio** | ENE — Energia |
| **Estado** | Por especificar |
| **Versão** | 0.1 (índice backlog) |

---

# 1. Objectivo

Explicar de onde vem e para onde vai cada watt: baterias, distribuição 3,3/5/12 V, monitorização de corrente/tensão, estimativa de autonomia e política de retorno. Sem energia não há missão; sem gestão, não há regresso.

# 2. Âmbito (previsto, não fechado)

* Barramentos, protecções, medição, SoC/SoH, previsão de autonomia, interface com MAT-016/MAT-011/MAT-006 e com o Grupo FailSafe (corte em emergência).
* Não fecha: químicas, capacidades, limiares, código.

# 3. Relação com os Grupos Computacionais formais

* **Todos os grupos** consomem e reportam: Sensorial, Atuador (maior consumidor), Master Geral, Visão GCV (pico de processamento), Comunicação (modems), FailSafe (consumo mínimo garantido) e Cálculo.
* **Núcleo de Diagnóstico (RP2350#4-C1)** + Núcleo de Missão — decisão energética; **Grupo FailSafe** — acção mínima de sobrevivência.
* **Math Core RP2350#2-C1** — modelos de autonomia sob pedido.

# 4. Energia

Coração do domínio: distribuição **3,3 V (lógica/IO) / 5 V (periféricos, modems) / 12 V (potência, visão, actuação pesada)**. Cada PCB gera os seus rails internos via **reguladores / PMIC** com monitorização, sequenciamento e protecção. A validação incluirá queda/subida de tensão, ripple e transição de carga.

# 5. Regra RF=RJ45

Os modems RF (5.8 GHz TX, 2.4 GHz RX, 868 MHz TX) são alimentados e ligados através do conjunto do Grupo Comunicação/Visão via **RJ45**; a sua energia é orçamentada em ENE mas o seu comando nunca contorna o voo.

# 6. Redes

Telemetria energética via CAN-Principal (1–10 Hz) + Intra local de alta frequência; emergência energética via CAN-FailSafe. Sem vídeo no CAN.

# 7. Estado

**Por especificar.**
