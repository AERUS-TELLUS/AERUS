# SEC — Segurança — Índice

| Campo | Valor |
| ----- | ----- |
| **Domínio** | SEC — Segurança |
| **Estado** | Por especificar |
| **Versão** | 0.1 (índice backlog) |

---

# 1. Objectivo

Explicar como o Aerus se protege de si próprio e do exterior: monitorização, FailSafe/FailSecure, redundância, autoridade e recuperação. A segurança não é um modo; é a hierarquia que manda em todos os modos.

# 2. Âmbito (previsto, não fechado)

* Arquitectura de segurança, envelopes, detecção, decisão, redundância de comunicação/alimentação/actuação, interface com MAT-019, SYS e HW.
* Não fecha: limiares certificados, código de decisão, provas.

# 3. Relação com os Grupos Computacionais formais

* **Grupo FailSafe ( + Núcleo de Segurança RP2350#4-C0)** — autoridade máxima; único que pode ordenar pela CAN-FailSafe e inibir os restantes.
* **Master Geral, Sensorial, Atuador, Visão GCV, Comunicação, Cálculo** — todos supervisionados; qualquer um pode *solicitar* emergência, nenhum pode *ordená-la* (decide o FailSafe).
* Regra de comando preservada: Missão→Voo→Atuador; em emergência, FailSafe→actuação de emergência.

# 4. Energia

Via de alimentação do FailSafe independente e mínima garantida, derivada de **3,3 / 5 V** com **PMIC** e supervisão próprios; corte selectivo de cargas não críticas em emergência.

# 5. Regra RF=RJ45

A segurança valida todo o comando vindo do RF após entrada pela **RJ45-RS** (HMAC/SEQ); comando não autenticado nunca chega ao voo. Perda de RF é condição prevista, não excepção.

# 6. Redes

CAN-FailSafe dedicada e sempre folgada (< 30 %); escuta do Principal; FABRIC para saúde do Master; RJ45-RS monitorizada. Sem vídeo no CAN.

# 7. Estado

**Por especificar.**
