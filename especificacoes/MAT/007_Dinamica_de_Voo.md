# MAT-007 — Dinâmica de Voo

| Campo             | Valor                              |
| ----------------- | ---------------------------------- |
| **Código**        | MAT-007                            |
| **Título**        | Dinâmica de Voo                    |
| **Versão**        | 0.1 (backlog)                      |
| **Estado**        | Por especificar                    |
| **Autor**         | ShegaPT                            |
| **Classificação** | Especificação Matemática (backlog) |

---

# 1. Objectivo

Reservar as equações do movimento translacional da aeronave (velocidade linear, aceleração, forças, vento). Explicará como a aeronave avança no espaço — sem fechar os parâmetros da célula.

# 2. Âmbito (previsto, não fechado)

* Cinemática/dinâmica translacional (MAT-0045/0046/0049/0050/0060 e afins, a confirmar no catálogo).
* Interface com MAT-005, MAT-008, MAT-010, MAT-015.
* Não fecha: matrizes da aeronave, código de integração, passos de simulação.

# 3. Owner

* **Núcleo de Voo (RP2350#1-C0)**.
* **Grupo de Cálculo (Math Core RP2350#2-C1)** — referência e integração pesada sob pedido.

# 4. Dependências

* MAT-001, MAT-002, MAT-005, MAT-008, MAT-010, MAT-014, MAT-015.

# 5. Modelo de execução previsto

Núcleo de Voo com cópias locais determinísticas no ciclo rápido (200 Hz onde aplicável); Math Core para integração/propagação pesada via FABRIC. Comandos ao actuador apenas após validação do Voo.

# 6. Estado

**Por especificar** — backlog.

# 7. Referências

* CATALOGO_MATEMATICA.md, MAT-018.
