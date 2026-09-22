# MAT-009 — Representação e Estimação de Atitude

| Campo             | Valor                              |
| ----------------- | ---------------------------------- |
| **Código**        | MAT-009                            |
| **Título**        | Representação e Estimação de Atitude |
| **Versão**        | 0.1 (backlog)                      |
| **Estado**        | Por especificar                    |
| **Autor**         | ShegaPT                            |
| **Classificação** | Especificação Matemática (backlog) |

> Nota: o nome do ficheiro histórico refere «Altitude»; o domínio correcto é **Atitude** (orientação: rolamento, picada, guinada). A altitude geométrica/barométrica pertence a MAT-010/MAT-004.

---

# 1. Objectivo

Reservar a matemática de orientação: ângulos de Euler, quaterniões, matrizes de rotação e estimadores de atitude. Explicará como sabemos «para onde aponta o nariz» — sem fechar o estimador final.

# 2. Âmbito (previsto, não fechado)

* Representações, conversões, propagação giroscópica, fusão com acelerómetro/magnetómetro.
* Interface com MAT-013/MAT-014 (sinal e fusão) e MAT-007/MAT-008.
* Não fecha: ganhos, covariâncias, código.

# 3. Owner

* **Núcleo de Fusão (RP2350#1-C1)** — estimação.
* **Grupo de Cálculo (Math Core RP2350#2-C1)** — referência para conversões pesadas e validação.

# 4. Dependências

* MAT-001, MAT-007, MAT-008, MAT-013, MAT-014, MAT-017.

# 5. Modelo de execução previsto

Fusão a alta frequência com primitivas locais determinísticas (magnitude, produtos); Math Core para conversões/validacões pesadas via FABRIC.

# 6. Estado

**Por especificar** — backlog.

# 7. Referências

* CATALOGO_MATEMATICA.md, MAT-018.
