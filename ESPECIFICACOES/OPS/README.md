# OPS — Operações — Índice

| Campo | Valor |
| ----- | ----- |
| **Domínio** | OPS — Operações |
| **Estado** | Por especificar |
| **Versão** | 0.1 (índice backlog) |

---

# 1. Objectivo

Explicar como se usa o Aerus no terreno: preparação, verificação, execução da missão, contingências e encerramento. A melhor engenharia falha sem boa operação.

# 2. Âmbito (previsto, não fechado)

* Checklists, perfis de missão, critérios de lançamento/interrupção, papéis da equipa, interface com GUI/NAV/IMP, MAT-020 e CER.
* Não fecha: procedimentos assinados, mapas, código.

# 3. Relação com os Grupos Computacionais formais

* **Master Geral (Missão)** — plano carregado e validado antes do voo.
* **Sensorial/Atuador** — verificações pré-voo via Principal/Intra.
* **FailSafe** — teste de emergência obrigatório antes de cada voo.
* **Visão GCV** — verificação de imagem/telemetria; **Comunicação** — verificação dos 3 enlaces (5.8/2.4/868).
* **Cálculo** — verificação do serviço MATH (pedido de teste e resposta).

# 4. Energia

Verificação dos barramentos **3,3 / 5 / 12 V**, estado dos **PMIC**, carga das baterias e orçamento da missão (ida + regresso + reserva). Nenhuma descolagem sem margem energética.

# 5. Regra RF=RJ45

A equipa verifica modems apenas nas portas **RJ45** do Comunicação/Visão; proibido ligar equipamento RF directo ao bus de voo em campo.

# 6. Redes

Checklists por rede: Intra/Principal/FailSafe (CAN), FABRIC (saúde do Master) e RJ45-RS (RSSI/enlaces). Sem vídeo no CAN — verificado por inspecção de configuração.

# 7. Estado

**Por especificar.**
