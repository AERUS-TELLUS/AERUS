# COM-010 — Integridade

| Campo | Valor |
|---|---|
| **Código** | COM-010 |
| **Título** | Integridade |
| **Versão** | 2.0 |
| **Estado** | Aprovado para implementação |
| **Autor** | ShegaPT |
| **Classificação** | Especificação de Comunicação |

---

# 1. Objectivo

O presente documento define a protecção integral de integridade nas cinco redes: **CAN-CRC + CRC8 + HMAC + SEQ** nas CAN; **CRC FABRIC** no FABRIC; soma de verificação + SEQ de enlace na RJ45-RS; **TrustZone/SHA do RP2350** como raiz de confiança no Master Geral (e em qualquer Master com RP2350).

---

# 2. Princípios

* Defesa em profundidade: cada camada protege contra uma classe de ameaça; falha em qualquer camada implica descarte (com registo e, na FailSafe, reenvio supervisionado).
* Validação sequencial fixa no receptor; zero falsos positivos; sem alocação dinâmica.
* HMAC/SEQ geridos pelo módulo de segurança; CRC8 sempre; CAN-CRC pelo hardware.
* Raiz de confiança em hardware (RP2350) para chaves e arranque.

---

# 3. Camadas nas CAN (1–3)

| Camada | Mecanismo | Tamanho | Protege contra |
|---|---|---|---|
| C1 | CRC nativo CAN-FD | 17 bits | Erros físicos de transmissão |
| C2 | CRC8 TLV (SMBUS 0x07) | 1 B | Corrupção na aplicação |
| C3 | HMAC-SHA256 | 32 B | Falsificação/alteração |
| C4 | CAN-ID + filtragem | 29 bits | Injecção/origem falsa |
| C5 | SEQ anti-repetição | 4 B | Repetição de mensagens capturadas |

Cálculo: C1 sobre ID+carga (hardware MCP2518FD); C2 sobre START…FIELDS; C3 sobre TLV serializado com chave; C4 por filtros hardware+software; C5 por contador crescente com janela 1000.

Sequência no receptor: C1 → C4 → C2 → C3 (se presente; obrigatório em CRITICAL+) → C5 (se presente) → entrega. Tabela de detecção CRC8: 1–2 bits e rajadas ≤8 bits a 100%; rajadas superiores ≈99,6% (complementadas por C1).

Exemplo anti-repetição: atacante reenvia quadro válido (C1–C4 passam) com SEQ=41 quando `último=42` ⇒ rejeitado em C5 com alerta.

---

# 4. CRC FABRIC (rede 4)

CRC-16 sobre cabeçalho+PAYLOAD do quadro IPC (SOURCE…COMPRIMENTO+PAYLOAD). Validação antes de qualquer RPC; falha implica descarte + FAULT + estatística por núcleo. RPC sem CRC válido jamais completa REQ_ID.

Exemplo: quadro MATH_REQUEST de 62 B (COM-002 Anexo A): CRC-16 calculado nos 60 B + 2 B de CRC; erro de 1 bit detectado a 100%.

---

# 5. RJ45-Privada RS (rede 5)

Soma de verificação de trama série + SEQ de enlace por segmento (vídeo e comando/telemetria independentes). Trama RF→CAN só é injectada após validação + filtragem de tipo no router; trama CAN→RF só é encapsulada após validação CAN completa.

---

# 6. TrustZone / SHA do RP2350

| Função | Mecanismo | Aplicação |
|---|---|---|
| Arranque confiável | Arranque assinado do RP2350 | MG e Masters RP2350; periférico não arranca sem imagem válida |
| Chaves HMAC/SEQ | Armazenamento em OTP/memória protegida + TrustZone | Chaves nunca em flash legível; acesso só via API de segurança |
| Aceleração SHA | SHA-256 em hardware | HMAC à cadência CAN sem carga excessiva (ex.: HMAC de 64 B em poucos µs) |
| Reintegração | Validação SHA após falha de 1×RP2350 | RP2350 reintegrado só com 10 s estáveis + imagem validada (COM-006) |
|Quote/attestation | Resumo de firmware por núcleo | Diagnóstico e detecção de adulteração |

Sem TrustZone/SHA, HMAC permanece obrigatório mas com débito policiado; com TrustZone/SHA, HMAC estende-se a todo o tráfego HIGH e superior.

---

# 7. Chaves, ameaças e contadores

Chaves: partilhadas por domínio, rotação pelo módulo de segurança, distribuição fora do CAN. Ameaças: erro físico (C1), corrupção (C2), falsificação/MITM (C3+C4), injecção (C4), repetição/eliminação (C5), negação de serviço (C1+bus-off), adulteração de firmware (TrustZone/SHA), corrupção FABRIC (CRC FABRIC).

Contadores `IntegrityStats`: `can_crc`, `bus_off`, `crc8[origem]`, `hmac[origem]`, `canid_inválido`, `replay`, `seq_janela`, `fabric_crc[núcleo]`, `rf_crc[segmento]`, totais TX/RX/descartados. `discarded` em SC/CR deve ser 0; violação ⇒ alerta.

---

# 8. Nota histórica de migração

> Mecanismos descritos para ESP32/Raspberry Pi/FS_A encontram-se revogados. A raiz de confiança é o RP2350 (TrustZone/SHA) e os pontos de validação são os gestores do COM-003.

---

# 9. Referências

* COM-001, COM-002 (+Anexos), COM-003, COM-004, COM-006, COM-008, COM-009; SEC; ISO 11898-1.
