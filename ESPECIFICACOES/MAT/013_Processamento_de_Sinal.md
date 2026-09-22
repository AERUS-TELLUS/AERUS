# MAT-013 — Processamento de Sinal

| Campo             | Valor                              |
| ----------------- | ---------------------------------- |
| **Código**        | MAT-013                            |
| **Título**        | Processamento de Sinal             |
| **Versão**        | 0.1 (backlog)                      |
| **Estado**        | Por especificar                    |
| **Autor**         | ShegaPT                            |
| **Classificação** | Especificação Matemática (backlog) |

---

# 1. Objectivo

Reservar filtragem, calibração, reamostragem e análise espectral dos sensores. Explicará como o «ruído» se transforma em «sinal útil» — sem fechar filtros finais.

# 2. Âmbito (previsto, não fechado)

* FIR/IIR, Kalman preliminar, anti-aliasing, sincronização temporal.
* Interface com MAT-009/MAT-014/MAT-017 e Grupo Sensorial.
* Não fecha: coeficientes, frequências finais, código.

# 3. Owner

* **Núcleo de Fusão (RP2350#1-C1)** + **Grupo Sensorial** (filtragem primária).
* **Grupo de Cálculo (Math Core RP2350#2-C1)** — referência para projecto de filtros.

# 4. Dependências

* MAT-001, MAT-009, MAT-014, MAT-017.

# 5. Modelo de execução previsto

Filtragem primária local e determinística no Grupo Sensorial; fusão no Núcleo de Fusão; projecto/análise pesada no Math Core via FABRIC/CAN-Principal.

# 6. Estado

**Por especificar** — backlog.

# 7. Referências

* CATALOGO_MATEMATICA.md, MAT-018.
