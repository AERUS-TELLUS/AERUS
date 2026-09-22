# MAT-004 — Atmosfera e Modelo Atmosférico

| Campo             | Valor                              |
| ----------------- | ---------------------------------- |
| **Código**        | MAT-004                            |
| **Título**        | Atmosfera e Modelo Atmosférico     |
| **Versão**        | 0.1 (backlog)                      |
| **Estado**        | Por especificar                    |
| **Autor**         | ShegaPT                            |
| **Classificação** | Especificação Matemática (backlog) |

---

# 1. Objectivo

Este documento reservará a matemática da atmosfera padrão, do ar como fluido e das correcções de densidade, pressão e temperatura com a altitude. Explicará, de forma didáctica, como passamos de «altitude lida» a «densidade que sustenta a asa».

O conteúdo técnico integral será especificado em versão posterior. Este cabeçalho fixa apenas a intenção, o dono e as fronteiras.

# 2. Âmbito (previsto, não fechado)

* Modelo de atmosfera (tabelas/funções de pressão, temperatura, densidade, viscosidade).
* Correcções de Pitot/estática e ar calibrado versus ar verdadeiro.
* Interface com MAT-003 (Mecânica dos Fluidos), MAT-005 (Aerodinâmica) e MAT-010 (Navegação).
* O que **não** será aqui fechado nesta fase: tabelas numéricas finais, coeficientes da aeronave, código.

# 3. Owner

* **Núcleo de Navegação (RP2350#2-C0)** — consumidor principal (conversão altitude/pressão em estado de navegação).
* **Grupo Computacional de Cálculo (Math Core RP2350#2-C1)** — prestador de referência via `MATH_REQUEST` / `MATH_RESPONSE`.
* Suporte: Grupo Sensorial (pressão/temperatura) e Núcleo de Voo.

# 4. Dependências

* MAT-001 (fundamentos), MAT-002 (física), MAT-003 (fluidos), MAT-017 (matemática de sensores).
* Redes: FABRIC para pedidos intra-agrupamento; CAN-Principal para dados de ar do Grupo Sensorial.
* Documentos de alocação e catálogo matemático.

# 5. Modelo de execução previsto

Referência no Math Core, sob pedido; cópia local redundante apenas para conversões fechadas e determinísticas de ciclo rápido (a definir). Sem vídeo no CAN; sem RF directo (regra RF=RJ45).

# 6. Estado

**Por especificar** — backlog. Nenhuma fórmula é aqui fechada como definitiva.

# 7. Referências

* CATALOGO_MATEMATICA.md, ALOCACAO_MATEMATICA.md, MAT-018 (redes).
