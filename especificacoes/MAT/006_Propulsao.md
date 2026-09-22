# MAT-006 — Propulsão

| Campo             | Valor                              |
| ----------------- | ---------------------------------- |
| **Código**        | MAT-006                            |
| **Título**        | Propulsão                          |
| **Versão**        | 0.1 (backlog)                      |
| **Estado**        | Por especificar                    |
| **Autor**         | ShegaPT                            |
| **Classificação** | Especificação Matemática (backlog) |

---

# 1. Objectivo

Reservar a matemática de tracção, potência, consumo e rendimento do conjunto motor/hélice. Explicará como a energia da bateria se transforma em tracção — sem fechar curvas de hélice ou parâmetros do motor.

# 2. Âmbito (previsto, não fechado)

* Tracção/potência, modelo de consumo, interface com MAT-016 (energia) e MAT-011 (desempenho).
* Não fecha: curvas, constantes do motor, código de controlo do actuador.

# 3. Owner

* **Núcleo de Voo (RP2350#1-C0)** + **Grupo Atuador** (execução física).
* **Grupo de Cálculo (Math Core RP2350#2-C1)** — referência.

# 4. Dependências

* MAT-001, MAT-002, MAT-003, MAT-011, MAT-015, MAT-016.

# 5. Modelo de execução previsto

Math Core como serviço de análise; cópias locais determinísticas apenas para limites de envelope no Grupo Atuador e no Núcleo de Voo. Comando sempre Missão→Voo→Atuador, nunca directo.

# 6. Estado

**Por especificar** — backlog.

# 7. Referências

* CATALOGO_MATEMATICA.md, MAT-018, ACT.
