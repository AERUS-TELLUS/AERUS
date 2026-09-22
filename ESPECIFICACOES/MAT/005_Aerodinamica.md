# MAT-005 — Aerodinâmica

| Campo             | Valor                              |
| ----------------- | ---------------------------------- |
| **Código**        | MAT-005                            |
| **Título**        | Aerodinâmica                       |
| **Versão**        | 0.1 (backlog)                      |
| **Estado**        | Por especificar                    |
| **Autor**         | ShegaPT                            |
| **Classificação** | Especificação Matemática (backlog) |

---

# 1. Objectivo

Reservar a matemática de sustentação, arrasto, momento, pressão dinâmica e polares da aeronave. Explicará como o ar em movimento se transforma em força útil — sem antecipar os coeficientes da aeronave, que só a bancada e o voo fecharão.

# 2. Âmbito (previsto, não fechado)

* Pressão dinâmica, coeficientes CL/CD/CM, relação com Reynolds (MAT-0083) e continuidade (MAT-0005).
* Dependência de MAT-003/MAT-004; consumo por MAT-007/MAT-012/MAT-015.
* Não fecha nesta fase: polares, derivadas de estabilidade, código, ganhos.

# 3. Owner

* **Núcleo de Voo (RP2350#1-C0)** — consumidor de ciclo crítico.
* **Grupo de Cálculo (Math Core RP2350#2-C1)** — referência via `MATH_REQUEST` / `MATH_RESPONSE`.

# 4. Dependências

* MAT-001, MAT-002, MAT-003, MAT-004, MAT-008, MAT-012, MAT-015.

# 5. Modelo de execução previsto

Serviço no Math Core para análise/polar; cópia local redundante apenas para formas fechadas determinísticas do ciclo de voo (a definir em MAT-007/MAT-015).

# 6. Estado

**Por especificar** — backlog.

# 7. Referências

* CATALOGO_MATEMATICA.md, MAT-018.
