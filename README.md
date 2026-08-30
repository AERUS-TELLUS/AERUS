# AERUS - Sistema Multi-Computador para UAS

Sistema computacional distribuído para aeronaves não tripuladas (UAS), composto por 5 unidades computacionais comunicando via CAN FD com o protocolo Bythos.

## Arquitetura

| Computador | Função | Plataforma |
|------------|--------|------------|
| **Raspberry Pi** | Computador de missão | Linux |
| **ESP32-S** | Aquisição de sensores | ESP32 |
| **ESP32-A** | Controlo de voo | ESP32 |
| **ESP32-FS** | Computador de segurança | ESP32 |
| **ESP32-FS_A** | Controlador de emergência | ESP32 |

## Pré-requisitos

- Python 3.8+
- GCC (compilador C/C++) — `sudo apt install build-essential`
- curl (para instalar o direnv)

## Ambiente de Build

As ferramentas de build (CMake, Ninja) estão isoladas numa **venv Python**, tal como se faz com packages Python. Isto significa:

- **Nada é instalado no sistema** — tudo fica dentro de `.venv/`
- **Apaga limpo** — `rm -rf .venv/ .tools/` remove tudo
- **Reprodutível** — qualquer pessoa pode recriar o ambiente com um comando

### Configuração rápida

```bash
# Criar venv + instalar ferramentas + configurar direnv
./setup.sh
```

O `setup.sh` faz:
1. Cria a venv em `.venv/`
2. Instala CMake e Ninja via pip
3. Instala o `direnv` em `.tools/bin/`
4. Configura o hook do direnv no `~/.bashrc`

### Ativação automática (direnv)

O projeto usa [direnv](https://direnv.net/) para ativar/desativar a venv automaticamente:

- **Entras na pasta** → venv ativa automaticamente
- **Saís da pasta** → venv desativa automaticamente

Para configurar pela primeira vez:

```bash
# 1. Executa o setup (instala direnv + configura hook)
./setup.sh

# 2. Reinicia o terminal ou executa
source ~/.bashrc

# 3. Navega até à pasta do projeto
cd /home/shegapt/Secretária/RC/Coding/AERUS-TELLUS/AERUS
# A venv é ativada automaticamente!
```

### Ativação manual (alternativa)

Se preferires ativar manualmente:

```bash
source .venv/bin/activate    # ativar
deactivate                   # desativar
```

### Comandos úteis

| Comando | Descrição |
|---------|-----------|
| `./setup.sh` | Criar/recriar ambiente completo |
| `source .venv/bin/activate` | Ativar venv manualmente |
| `deactivate` | Desativar venv |
| `rm -rf .venv/ .tools/` | Apagar completamente o ambiente |
| `direnv allow` | Permitir o .envrc (após editar) |

### O que está no ambiente

| Ferramenta | Versão | Localização |
|------------|--------|-------------|
| `cmake` | 4.4.x | `.venv/bin/cmake` |
| `ninja` | 1.13.x | `.venv/bin/ninja` |
| `direnv` | 2.34.x | `.tools/bin/direnv` |

### Ficheiros de configuração

| Ficheiro | Descrição |
|----------|-----------|
| `.envrc` | Ativa a venv automaticamente (usado pelo direnv) |
| `build-requirements.txt` | Versões exatas das dependências de build |
| `setup.sh` | Script de configuração do ambiente |

### VS Code

O `.vscode/settings.json` está configurado para apontar para o executável do CMake dentro da venv:

```json
{
    "cmake.sourceDirectory": ".../shared/Bythos/c_core",
    "cmake.cmakePath": ".../.venv/bin/cmake"
}
```

A extensão **CMake Tools** deve detetar o toolkit automaticamente.

### Build do Bythos C Core

```bash
cd shared/Bythos/c_core
cmake -B build -S .
cmake --build build
```

## Estrutura do Repositório

```
AERUS/
├── .venv/                  # Ambiente de build (gitignored)
├── .tools/                 # Ferramentas locais (gitignored)
│   └── bin/direnv          # direnv para ativação automática
├── .envrc                  # Configuração do direnv
├── .gitmodules             # Definição do submodule Bythos
├── setup.sh                # Script de configuração
├── build-requirements.txt  # Versões das dependências
├── CHANGELOG.md            # Histórico de versões
├── README.md               # Documentação principal
├── ARQUITETURA_DO_REPOSITORIO.md  # Arquitetura do repositório
├── LICENSE                 # Licença AGPL-3.0
├── shared/                 # Código partilhado entre computadores
│   └── Bythos/             # Protocolo de comunicação (submodule)
│       ├── c_core/         # Implementação C (CMake)
│       ├── src/            # Implementação Rust (Cargo)
│       └── docs/           # Documentação do protocolo
├── math/                   # Implementações matemáticas (gitignored)
├── especificacoes/         # Especificações técnicas (17 domínios)
├── checklists/             # Checklists de voo (15 ficheiros)
├── hardware/               # Documentação de hardware
│   └── CANBus/             # Documentação CAN Bus
└── docs/                   # Documentação do projeto
    └── logo/               # Logotipos
```

## Licença

AGPL-3.0 — Ver [LICENSE](LICENSE)
