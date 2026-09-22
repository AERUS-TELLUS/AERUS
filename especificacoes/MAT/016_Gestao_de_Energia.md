# MAT-016 — Gestão de Energia

| Campo             | Valor                              |
| ----------------- | ---------------------------------- |
| **Código**        | MAT-016                            |
| **Título**        | Gestão de Energia                  |
| **Versão**        | 0.1 (backlog)                      |
| **Estado**        | Por especificar                    |
| **Autor**         | ShegaPT                            |
| **Classificação** | Especificação Matemática (backlog) |

---

# 1. Objectivo

Reservar a matemática de estado de carga, consumo, autonomia e decisão energética. Explicará «posso continuar ou devo regressar» — sem fechar curvas de bateria.

# 2. Âmbito (previsto, não fechado)

* SoC/SoH, estimativa de autonomia, política de retorno, interface com MAT-006/MAT-011 e ENE.
* Não fecha: modelos de célula, código, limiares certificados.

# 3. Owner

* **Núcleo de Diagnóstico (RP2350#4-C1)** + **Núcleo de Missão**.
* **Grupo de Cálculo (Math Core RP2350#2-C1)** — referência.

# 4. Dependências

* MAT-002 (energia potencial), MAT-006, MAT-011, MAT-020.

# 5. Modelo de execução previsto

Estimadores locais determinísticos para monitores críticos; análise pesada no Math Core. Publicação via CAN-Principal; segurança energética via Grupo FailSafe.

# 6. Estado

**Por especificar** — backlog.

# 7. Referências

* CATALOGO_MATEMATICA.md, MAT-018, ENE.
