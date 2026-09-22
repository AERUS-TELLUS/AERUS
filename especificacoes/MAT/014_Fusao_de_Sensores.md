# MAT-014 — Fusão de Sensores

| Campo             | Valor                              |
| ----------------- | ---------------------------------- |
| **Código**        | MAT-014                            |
| **Título**        | Fusão de Sensores                  |
| **Versão**        | 0.1 (backlog)                      |
| **Estado**        | Por especificar                    |
| **Autor**         | ShegaPT                            |
| **Classificação** | Especificação Matemática (backlog) |

---

# 1. Objectivo

Reservar a combinação de sensores redundantes e heterogéneos num estado único e íntegro (atitude, velocidade, posição). Explicará como vários sensores imperfeitos produzem uma verdade melhor — sem fechar o filtro final.

# 2. Âmbito (previsto, não fechado)

* Filtros complementares/Kalman, votação, detecção de falha de sensor, integridade.
* Interface com MAT-009/MAT-010/MAT-013/MAT-017.
* Não fecha: matrizes, covariâncias, código.

# 3. Owner

* **Núcleo de Fusão (RP2350#1-C1)**.
* **Grupo de Cálculo (Math Core RP2350#2-C1)** — referência e validação cruzada.

# 4. Dependências

* MAT-001, MAT-009, MAT-010, MAT-013, MAT-017, MAT-019.

# 5. Modelo de execução previsto

Fusão a alta frequência com primitivas locais determinísticas; Math Core para validação e formas pesadas via FABRIC. Publicação via FABRIC ao Voo/Navegação e via CAN-Principal aos restantes grupos.

# 6. Estado

**Por especificar** — backlog.

# 7. Referências

* CATALOGO_MATEMATICA.md, MAT-018.
