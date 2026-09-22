# MAT-015 — Sistemas de Controlo

| Campo             | Valor                              |
| ----------------- | ---------------------------------- |
| **Código**        | MAT-015                            |
| **Título**        | Sistemas de Controlo               |
| **Versão**        | 0.1 (backlog)                      |
| **Estado**        | Por especificar                    |
| **Autor**         | ShegaPT                            |
| **Classificação** | Especificação Matemática (backlog) |

---

# 1. Objectivo

Reservar as leis de controlo (PID, espaço de estados, guiamento lateral/longitudinal) que convertem referências em comandos validados. Explicará como «manter o rumo» sem oscilar — sem fechar ganhos.

# 2. Âmbito (previsto, não fechado)

* Malhas de atitude/velocidade/posição, anti-windup, limites, validação de envelope.
* Interface com MAT-007/MAT-008/MAT-012, NAV/GUI/CTL e Grupo Atuador.
* Não fecha: ganhos, código, ensaios HIL.

# 3. Owner

* **Núcleo de Controlo / Voo (RP2350#1-C0)**.
* **Grupo de Cálculo (Math Core RP2350#2-C1)** — síntese/análise de controladores sob pedido.

# 4. Dependências

* MAT-001, MAT-007, MAT-008, MAT-009, MAT-012, MAT-014.

# 5. Modelo de execução previsto

Leis executadas localmente no Núcleo de Voo a frequência fixa, com primitivas determinísticas; Math Core para projecto e verificação. Regra Missão→Voo→Atuador, nunca directo (ver MAT-018).

# 6. Estado

**Por especificar** — backlog.

# 7. Referências

* CATALOGO_MATEMATICA.md, MAT-018, CTL.
