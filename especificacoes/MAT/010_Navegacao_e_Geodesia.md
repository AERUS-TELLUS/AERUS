# MAT-010 — Navegação e Geodesia

| Campo             | Valor                              |
| ----------------- | ---------------------------------- |
| **Código**        | MAT-010                            |
| **Título**        | Navegação e Geodesia               |
| **Versão**        | 0.1 (backlog)                      |
| **Estado**        | Por especificar                    |
| **Autor**         | ShegaPT                            |
| **Classificação** | Especificação Matemática (backlog) |

---

# 1. Objectivo

Reservar a matemática de posição, geodesia, waypoints e seguimento de trajectória. Explicará como passamos de «coordenadas» a «caminho a voar» — sem fechar o planeador.

# 2. Âmbito (previsto, não fechado)

* Elipsóide, conversões geodésicas/ECEF/NED, distância/azimute, gestão de waypoints.
* Interface com MAT-004, MAT-007, MAT-014 e GUI/NAV.
* Não fecha: datum final, código, missões concretas.

# 3. Owner

* **Núcleo de Navegação (RP2350#2-C0)**.
* **Grupo de Cálculo (Math Core RP2350#2-C1)** — referência para conversões pesadas.

# 4. Dependências

* MAT-001, MAT-004, MAT-007, MAT-009, MAT-014.

# 5. Modelo de execução previsto

Navegação com primitivas locais determinísticas; Math Core via FABRIC para geodesia pesada. Publicação a outros núcleos via FABRIC; a grupos via CAN-Principal.

# 6. Estado

**Por especificar** — backlog.

# 7. Referências

* CATALOGO_MATEMATICA.md, MAT-018, NAV.
