# MAT-019 — Segurança de Voo

| Campo             | Valor                              |
| ----------------- | ---------------------------------- |
| **Código**        | MAT-019                            |
| **Título**        | Segurança de Voo                   |
| **Versão**        | 0.1 (backlog)                      |
| **Estado**        | Por especificar                    |
| **Autor**         | ShegaPT                            |
| **Classificação** | Especificação Matemática (backlog) |

---

# 1. Objectivo

Reservar a matemática de monitorização, envelopes, detecção de anomalia e decisão FailSafe/FailSecure. Explicará «quando devo abandonar a missão para salvar a aeronave» — sem fechar limiares.

# 2. Âmbito (previsto, não fechado)

* Envelopes, votantes, resíduos, limiares, lógica de degradação, interface com SEC e Grupo FailSafe.
* Não fecha: limiares certificados, código de decisão, ensaios.

# 3. Owner

* **Núcleo de Segurança de Voo (RP2350#4-C0)** + **Grupo FailSafe** (autoridade máxima).
* **Grupo de Cálculo (Math Core RP2350#2-C1)** — análise de resíduos sob pedido.

# 4. Dependências

* MAT-001, MAT-007, MAT-009, MAT-014, MAT-015, MAT-016, MAT-018 (PLR/carga/heartbeat).

# 5. Modelo de execução previsto

Monitores locais determinísticos no FailSafe e no Núcleo de Segurança (CAN-FailSafe dedicado, 50 ms); análise pesada no Math Core via FABRIC. Em degradação do Principal, o FailSafe ordena pela via dedicada.

# 6. Estado

**Por especificar** — backlog.

# 7. Referências

* CATALOGO_MATEMATICA.md, MAT-018, SEC.
