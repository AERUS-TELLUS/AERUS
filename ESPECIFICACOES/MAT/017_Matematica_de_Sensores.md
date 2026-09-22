# MAT-017 — Matemática de Sensores

| Campo             | Valor                              |
| ----------------- | ---------------------------------- |
| **Código**        | MAT-017                            |
| **Título**        | Matemática de Sensores             |
| **Versão**        | 0.1 (backlog)                      |
| **Estado**        | Por especificar                    |
| **Autor**         | ShegaPT                            |
| **Classificação** | Especificação Matemática (backlog) |

---

# 1. Objectivo

Reservar os modelos de erro, calibração e compensação de cada sensor (bias, escala, deriva térmica, desalinhamento). Explicará como transformar «leitura bruta» em «medida íntegra» — sem fechar tabelas de calibração.

# 2. Âmbito (previsto, não fechado)

* Modelos de IMU, magnetómetro, barómetro, GNSS, pitot, corrente/tensão.
* Interface com MAT-013/MAT-014 e Grupo Sensorial.
* Não fecha: coeficientes, procedimentos de calibração finais, código.

# 3. Owner

* **Grupo Sensorial** (aquisição/calibração primária) + **Núcleo de Fusão (RP2350#1-C1)**.
* **Grupo de Cálculo (Math Core RP2350#2-C1)** — referência para identificação de parâmetros.

# 4. Dependências

* MAT-001, MAT-004, MAT-009, MAT-013, MAT-014.

# 5. Modelo de execução previsto

Calibração/compensação local e determinística no Grupo Sensorial (CAN-Intra); identificação pesada no Math Core.

# 6. Estado

**Por especificar** — backlog.

# 7. Referências

* CATALOGO_MATEMATICA.md, MAT-018, SEN.
