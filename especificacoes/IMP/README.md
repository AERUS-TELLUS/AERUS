# IMP — Implementos — Índice

| Campo | Valor |
| ----- | ----- |
| **Domínio** | IMP — Implementos (interface com sistemas externos) |
| **Estado** | Por especificar |
| **Versão** | 0.1 (índice backlog) |

---

# 1. Objectivo

Explicar como o Aerus fala com o «mundo lá fora» sem se deixar contaminar por ele: detecção, identificação, capacidades, troca de dados e compatibilidade de implementos (ex. equipamento agrícola, largadores). Documentamos a **interface**, não o implemento em si.

# 2. Âmbito (previsto, não fechado)

* Descoberta, handshake, descrição de capacidades, protocolo de dados, isolamento de falha do implemento.
* Interface com OPS, MAT-020, ENE e SEC.
* Não fecha: protocolos concretos, conectores finais, código.

# 3. Relação com os Grupos Computacionais formais

* **Master Geral (Núcleo de Missão)** — gestão lógica do implemento via FABRIC/CAN-Principal.
* **Grupo Atuador / Sensorial** — quando o implemento precisa de actuação/aquisição dedicada, passa pelos mestres dos grupos, nunca directo ao físico.
* **Grupo Comunicação** — se o implemento for remoto, o acesso faz-se pela via formal (RJ45-RS quando RF).
* **Grupo FailSafe** — pode inibir o implemento em emergência.
* **Math Core** — geometria/temporização de largada sob pedido (com MAT-020).

# 4. Energia

Implementos alimentados por rails dedicadas derivadas de **5 V / 12 V** com protecção e limitação, geridas por **PMIC/interruptores** monitorizados. Nenhum implemento partilha o rail crítico do FailSafe sem isolamento.

# 5. Regra RF=RJ45

Se o implemento comunicar por rádio, fá-lo através da **RJ45-RS** do Grupo Comunicação. Proibido RF directo ao Master ou aos actuadores.

# 6. Redes

CAN-Principal (gestão), CAN-Intra (anexo local), FABRIC (decisão de missão). Sem vídeo no CAN.

# 7. Estado

**Por especificar.**
