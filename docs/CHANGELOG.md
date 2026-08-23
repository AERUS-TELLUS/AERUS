# Changelog

**Projeto:** Aerus

**Autor:** ShegaPT

---

Todas as alterações notáveis neste projeto serão documentadas neste ficheiro.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/).

Versões seguem [Semantic Versioning](https://semver.org/lang/pt-BR/).

---

## [V0.0.5] — Em Desenvolvimento

**Data:** 2026-08-23

**Autor:** ShegaPT

### Adicionado

- `shared/TLV_DEFINITIONS.md` — Protocolo TLV completo v3.0.0 (~700 linhas)
- `shared/CAN_IDS.md` — Tabela de alocação de IDs CAN, 29-bit, 2 buses, tabela de bitrates
- `COM/008_CAN_Bus.md` — Novo (renomeado de 008_UART.md)
- `COM/001` a `COM/010` — Todos os 10 ficheiros COM preenchidos (arquitetura, TLV, gestor de mensagens, prioridades/filas, eventos, timeouts/recuperação, comunicação inter-domínio, CAN Bus físico, sincronização, integridade)
- `MAT/018_Matematica_de_Comunicacoes.md` — Preenchido com matemática CAN FD: latência, PLR, throughput, eficiência fragmentação, capacidade do bus, intervalos heartbeat
- `hardware/CANBus/` — Diretoria completa com 11 ficheiros de documentação CAN Bus (panorama, controladores, transceivers, soluções isoladas, módulos, conectores, cabos, ferramentas, esquemas, BOM)

### Alterado

- `HW/006_Interfaces_de_Comunicacao.md` — Reescrito UART→CAN FD, diagrama 3 camadas, topologia 2 buses, secção interfaces locais adicionada
- `HW/001_Arquitetura_de_Hardware.md` — "UART" → "CAN bus"
- `HW/004_Interfaces_Eletricas.md` — "topologia UART" → "topologia CAN"
- `HW/008_Redundancia_e_Isolamento_de_Hardware.md` — Referência bus segurança adicionada (ESP32-FS ponte ambos buses, ISO1042)
- `SYS/005_Fluxo_Global_de_Informacao.md` — Referências atualizadas para CAN FD + TLV

---

## [V0.0.4] — 2026-08-21

**Data:** 2026-08-21

**Autor:** ShegaPT

### Adicionado

- `.gitignore` — Regras iniciais de ignore
- `.github/workflows/sync-fork.yml` — Workflow para sincronizar fork com organização
- `especificacoes/MAT/001_Fundamentos_Matematicos.md`
- `especificacoes/MAT/002_Fisica_e_Mecanica.md`
- `especificacoes/MAT/003_Mecanica_dos_Fluidos.md`
- `especificacoes/MAT/014_Fusao_de_Sensores.md`
- `especificacoes/MAT/015_Sistemas_de_Controlo.md`
- `especificacoes/MAT/016_Gestao_de_Energia.md`
- `especificacoes/MAT/017_Matematica_de_Sensores.md`
- `especificacoes/MAT/018_Matematica_de_Comunicacoes.md`
- `especificacoes/MAT/019_Seguranca_de_Voo.md`
- `especificacoes/MAT/020_Balistica_e_Missoes_Especificas.md`
- `especificacoes/MAT/021_Modelos_Experimentais_e_Nao_Operacionais.md`

### Renomeado

- `especificacoes/MAT/001_Catalogo_Matematico.md` → `004_Atmosfera_e_Modelo_Atmosferico.md`
- `especificacoes/MAT/002_Indice_Matematico.md` → `005_Aerodinamica.md`
- `especificacoes/MAT/003_Alocacao_Matematica.md` → `006_Propulsao.md`
- `especificacoes/MAT/004_Arquitetura_Matematica.md` → `007_Dinamica_de_Voo.md`
- `especificacoes/MAT/005_Cadeias_Matematicas.md` → `008_Dinamica_de_Corpo_Rigido.md`
- `especificacoes/MAT/006_Fusao_Sensorial.md` → `009_Representacao_e_Estimacao_de_Altitude.md`
- `especificacoes/MAT/007_Navegacao.md` → `010_Navegacao_e_Geodesia.md`
- `especificacoes/MAT/008_Guiamento.md` → `011_Desempenho_da_Aeronave.md`
- `especificacoes/MAT/009_Controlo.md` → `012_Estabilidade_da_Aeronave.md`
- `especificacoes/MAT/010_Seguranca_Matematica.md` → `013_Processamento_de_Sinal.md`

### Alterado

- `.github/workflows/sync-fork.yml` — Atualizações do workflow
- `.gitignore` — Atualização das regras de ignore

---

## [V0.0.3] — 2026-08-11

**Data:** 2026-08-11

**Autor:** ShegaPT

### Adicionado

- `docs/logo/high-resolution-color-logo.png`
- `docs/logo/high-resolution-logo-grayscale.png`

### Alterado

- `especificacoes/HW/001_Arquitetura_de_Hardware.md`
- `especificacoes/HW/002_Grupos_Computacionais.md`
- `especificacoes/HW/003_Distribuicao_de_Hardware.md`
- `especificacoes/HW/004_Interfaces_Eletricas.md`
- `especificacoes/HW/005_Alimentacao_e_Distribuicao_de_Energia.md`
- `especificacoes/HW/006_Interfaces_de_Comunicacao.md`
- `especificacoes/HW/007_Interfaces_de_Perifericos.md`
- `especificacoes/HW/008_Redundancia_e_Isolamento_de_Hardware.md`
- `especificacoes/HW/009_Expansibilidade_e_Configuracao_de_Hardware.md`
- `especificacoes/SYS/002_Arquitetura_Computacional.md`
- `especificacoes/SYS/003_Arquitetura_Software.md`
- `especificacoes/SYS/004_Arquitetura_Hardware.md`
- `especificacoes/SYS/005_Fluxo_Global_de_Informacao.md`
- `especificacoes/SYS/006_Gestao_de_Estados.md`
- `especificacoes/SYS/007_Modos_de_Funcionamento.md`
- `especificacoes/SYS/008_Gestao_Temporal.md`
- `especificacoes/SYS/009_Arranque_e_Encerramento.md`

---

## [V0.0.2] — 2026-08-10

**Data:** 2026-08-10

**Autor:** ShegaPT

### Adicionado

- `especificacoes/HW/001_Arquitetura_de_Hardware.md`
- `especificacoes/HW/002_Grupos_Computacionais.md`
- `especificacoes/HW/003_Distribuicao_de_Hardware.md`
- `especificacoes/HW/004_Interfaces_Eletricas.md`
- `especificacoes/HW/005_Alimentacao_e_Distribuicao_de_Energia.md`
- `especificacoes/HW/006_Interfaces_de_Comunicacao.md`
- `especificacoes/HW/007_Interfaces_de_Perifericos.md`
- `especificacoes/HW/008_Redundancia_e_Isolamento_de_Hardware.md`
- `especificacoes/HW/009_Expansibilidade_e_Configuracao_de_Hardware.md`
- `especificacoes/SW/0xx-Politicas_Temporais.md`

### Alterado

- `especificacoes/SYS/008_Gestao_Temporal.md`
- `especificacoes/SYS/009_Arranque_e_Encerramento.md`

---

## [V0.0.1] — 2026-08-07

**Data:** 2026-08-07

**Autor:** ShegaPT

### Adicionado

- Commit inicial — repositório criado
- `README.md`
- `ARQUITETURA_DO_REPOSITORIO.md`
- `checklists/001-Before_Start.md` a `checklists/015-Shutdown.md` (15 checklists)
- `especificacoes/COM/001_Arquitetura_de_Comunicacao.md` a `010_Integridade.md` (10 ficheiros)
- `especificacoes/MAT/001_Catalogo_Matematico.md` a `010_Seguranca_Matematica.md` (10 ficheiros)
- `especificacoes/SYS/001_Visao_Geral.md` a `009_Arranque_e_Encerramento.md` (9 ficheiros)

### Alterado

- `especificacoes/SYS/001_Visao_Geral.md`
- `especificacoes/SYS/002_Arquitetura_Computacional.md`
- `especificacoes/SYS/003_Arquitetura_Software.md`
- `especificacoes/SYS/004_Arquitetura_Hardware.md`
- `especificacoes/SYS/005_Fluxo_Global_de_Informacao.md`
- `especificacoes/SYS/006_Gestao_de_Estados.md`
- `especificacoes/SYS/007_Modos_de_Funcionamento.md`
