# GUI — Guiamento — Índice

| Campo | Valor |
| ----- | ----- |
| **Domínio** | GUI — Guiamento |
| **Estado** | Por especificar |
| **Versão** | 0.1 (índice backlog) |

---

# 1. Objectivo

Explicar como transformamos «missão» em «referências que o voo consegue seguir»: trajectória desejada, velocidades, altitudes e janelas de captura. O guiamento sonha o caminho; o controlo concretiza-o.

# 2. Âmbito (previsto, não fechado)

* Geração de referências a partir de waypoints, L1/lógica de seguimento, transições, interface com NAV, MAT-010/MAT-015 e Missão.
* Não fecha: leis finais, ganhos, código.

# 3. Relação com os Grupos Computacionais formais

* **Master Geral (Núcleo de Missão RP2350#3 + Núcleo de Navegação RP2350#2-C0 + Núcleo de Voo RP2350#1-C0)** — o guiamento vive aqui, servido pela FABRIC.
* **Grupo de Cálculo (Math Core RP2350#2-C1)** — geometria de trajectória pesada via MATH_REQUEST; o ciclo usa primitivas locais.
* **Grupo Atuador** — nunca recebe do guiamento directamente; apenas do Voo após validação (Missão→Voo→Atuador).
* **Grupo FailSafe** — pode substituir referências por referências de emergência (regresso/pairar).

# 4. Energia

Lógica do Master a partir de **3,3 V / 5 V** com **PMIC/reguladores** locais; sem potência directa. Menção para garantir determinismo na gama completa.

# 5. Regra RF=RJ45

Referências vindas do solo (nova missão por 2.4 GHz) entram por **RJ45-RS** → Comunicação → Principal → Missão → Guiamento. Nenhum guia por RF directo.

# 6. Redes

FABRIC (Missão/Navegação/Voo) + CAN-Principal (publicação de referências supervisionadas). Sem vídeo no CAN.

# 7. Estado

**Por especificar.**
