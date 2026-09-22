# CER — Certificação — Índice

| Campo | Valor |
| ----- | ----- |
| **Domínio** | CER — Certificação |
| **Estado** | Por especificar |
| **Versão** | 0.1 (índice backlog) |

---

# 1. Objectivo

Explicar como provamos que o Aerus é digno de voar: rastreabilidade requisito→especificação→código→teste→evidência, gestão de configuração e dossiers de conformidade. Este índice fixa a intenção; os procedimentos e matrizes serão criados depois.

# 2. Âmbito (previsto, não fechado)

* Matriz de rastreabilidade, critérios de aceitação, gestão documental, evidências de TST/VAL, controlo de versões de hardware/software.
* Interface com todos os domínios, em especial SEC, TST, VAL, OPS.
* Não fecha: normas aplicáveis finais, checklists assinadas, código.

# 3. Relação com os Grupos Computacionais formais

A certificação não executa voo, mas observa todos os grupos:

* **Master Geral, Sensorial, Atuador, FailSafe, Visão GCV, Comunicação e Cálculo (Math Core RP2350#2-C1)** — cada um deverá apresentar requisitos, projecto, testes e evidências próprias, com identificadores de placa/firmware.
* O Math Core, como referência numérica única, terá dossier próprio de verificação numérica (tolerâncias `float`/`double`, comparação referência/local).

# 4. Energia

Sem requisitos próprios de potência além de registar a configuração energética certificada: entradas **3,3 V / 5 V / 12 V** e **PMIC/reguladores** por placa, com sequenciamento documentado como condição de certificação.

# 5. Regra RF=RJ45

A arquitectura certificada incluirá a regra **RF=RJ45** como requisito: nenhum caminho RF directo ao voo; verificação por inspecção de esquemas e testes de corte do modem.

# 6. Redes

Evidência de conformidade das 5 redes (Intra/Principal/FailSafe/FABRIC/RJ45-RS) segundo MAT-018: orçamentos de latência/carga/PLR e prova de «sem vídeo no CAN».

# 7. Estado

**Por especificar.**
