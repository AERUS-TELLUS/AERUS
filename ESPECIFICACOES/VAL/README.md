# VAL — Validação — Índice

| Campo | Valor |
| ----- | ----- |
| **Domínio** | VAL — Validação |
| **Estado** | Por especificar |
| **Versão** | 0.1 (índice backlog) |

---

# 1. Objectivo

Explicar como confirmamos que o sistema certo foi construído: conformidadade de requisitos, análise de resultados, aceitação. Se TST pergunta «funciona bem?», VAL pergunta «é isto que foi pedido e é seguro?».

# 2. Âmbito (previsto, não fechado)

* Métodos, critérios de conformidade, análise de resultados de TST/voo, aceitação por grupo e global, interface com CER/SEC/OPS.
* Não fecha: relatórios, assinaturas, thresholds finais.

# 3. Relação com os Grupos Computacionais formais

* Validação por grupo (Sensorial, Atuador, FailSafe, Visão GCV, Comunicação, Master Geral, Cálculo) e por rede (5 redes de MAT-018).
* O **Math Core** fornece as referências numéricas contra as quais se valida cada implementação local.
* A cadeia Missão→Voo→Atuador é validada como propriedade inviolável (teste de intrusão: nenhuma missão comanda actuador directo).

# 4. Energia

Validação da árvore **3,3 / 5 / 12 V + PMIC** por placa: margens, transientes, autonomia medida versus prevista (com ENE e MAT-016).

# 5. Regra RF=RJ45

Critério de validação: todo o tráfego RF inspeccionado atravessa a **RJ45**; evidência por inspecção + teste de corte/injecção.

# 6. Redes

Validação dos orçamentos de MAT-018 e da proibição de vídeo no CAN, com registos de latência/throughput/carga/PLR por rede.

# 7. Estado

**Por especificar.**
