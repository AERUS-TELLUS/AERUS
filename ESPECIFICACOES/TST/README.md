# TST — Testes — Índice

| Campo | Valor |
| ----- | ----- |
| **Domínio** | TST — Testes |
| **Estado** | Por especificar |
| **Versão** | 0.1 (índice backlog) |

---

# 1. Objectivo

Explicar como provamos que cada parte funciona antes de voar: unitários, integração, SIL/HIL, solo e voo. Testar cedo é barato; falhar em voo é caro.

# 2. Âmbito (previsto, não fechado)

* Estratégia por grupo e por rede, bancadas, cenários, critérios passa/falha, interface com VAL/CER e com MAT-018 (latência/PLR/carga como critérios).
* Não fecha: casos concretos, scripts, resultados.

# 3. Relação com os Grupos Computacionais formais

* Cada grupo testa-se isolado na sua CAN-Intra e depois integrado na Principal/FailSafe/FABRIC/RJ45-RS.
* **Math Core (RP2350#2-C1)** — teste numérico de referência (tolerâncias, regressão); cada cópia local é testada contra a referência.
* **Visão GCV** — teste de não-interferência (prova de sem-vídeo-no-CAN); **Comunicação** — teste dos 3 RF via RJ45.

# 4. Energia

Bancadas com as tensões **3,3 / 5 / 12 V** e **PMIC** reais; testes de brown-out, ripple e sequenciamento incluídos.

# 5. Regra RF=RJ45

Os testes de RF fazem-se sempre através da **RJ45**; é falha crítica qualquer caminho RF alternativo detectado.

# 6. Redes

Critérios quantitativos por rede vindos de MAT-018 (ex. Principal < 60 %, FailSafe < 30 %, PLR, heartbeat). Sem vídeo no CAN — teste obrigatório.

# 7. Estado

**Por especificar.**
