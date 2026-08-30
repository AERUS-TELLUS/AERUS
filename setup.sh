#!/bin/bash
# ==============================================================================
# Setup do Ambiente de Build - AERUS
# ==============================================================================
#
# Cria uma venv (.venv/) com as ferramentas de build necessárias.
# Tudo fica isolado — apaga .venv/ e tudo desaparece.
#
# Uso:
#   chmod +x setup.sh
#   ./setup.sh              # criar venv + configurar direnv
#
# Para apagar o ambiente:
#   rm -rf .venv/ .tools/   # apagar tudo
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/.venv"
TOOLS_DIR="$SCRIPT_DIR/.tools"
DIRENV_BIN="$TOOLS_DIR/bin/direnv"
DIRENV_URL="https://github.com/direnv/direnv/releases/download/v2.34.0/direnv.linux-amd64"

echo "=== AERUS - Setup do Ambiente de Build ==="
echo ""

# Verificar se Python 3 está disponível
if ! command -v python3 &> /dev/null; then
    echo "ERRO: python3 não encontrado. Instala o Python 3 primeiro."
    exit 1
fi

echo "Python: $(python3 --version)"

# ──────────────────────────────────────────────────────────────────────────────
# VENV
# ──────────────────────────────────────────────────────────────────────────────

if [ -d "$VENV_DIR" ]; then
    echo ""
    echo "AVISO: Já existe uma venv em .venv/"
    read -p "Queres recriar? (s/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        rm -rf "$VENV_DIR"
        echo "Venv antiga removida."
    else
        echo "A manter venv existente."
        source "$VENV_DIR/bin/activate"
        echo "Venv ativa. CMake: $(cmake --version | head -1)"
    fi
fi

if [ ! -d "$VENV_DIR" ]; then
    echo ""
    echo "A criar venv em .venv/..."
    python3 -m venv "$VENV_DIR"
    source "$VENV_DIR/bin/activate"
    echo "A instalar ferramentas de build..."
    pip install --upgrade pip -q
    pip install cmake ninja -q
fi

# ──────────────────────────────────────────────────────────────────────────────
# DIRENV
# ──────────────────────────────────────────────────────────────────────────────

if [ ! -f "$DIRENV_BIN" ]; then
    echo ""
    echo "A instalar direnv em .tools/bin/..."
    mkdir -p "$TOOLS_DIR/bin"
    curl -sfL "$DIRENV_URL" -o "$DIRENV_BIN"
    chmod +x "$DIRENV_BIN"
    echo "direnv $( "$DIRENV_BIN" --version ) instalado."
else
    echo "direnv já instalado: $( "$DIRENV_BIN" --version )"
fi

# Verificar se o hook já está no .bashrc
BASHRC="$HOME/.bashrc"
DIRENV_HOOK='eval "$(direnv hook bash)"'

if ! grep -qF 'direnv hook bash' "$BASHRC" 2>/dev/null; then
    echo ""
    echo "A adicionar hook do direnv ao ~/.bashrc..."
    echo "" >> "$BASHRC"
    echo "# direnv - ativação automática de ambientes" >> "$BASHRC"
    echo "$DIRENV_HOOK" >> "$BASHRC"
    echo "Hook adicionado. Reinicia o shell ou executa: source ~/.bashrc"
else
    echo "Hook do direnv já existe em ~/.bashrc"
fi

# ──────────────────────────────────────────────────────────────────────────────
# PERMISSÕES .envrc
# ──────────────────────────────────────────────────────────────────────────────

if [ -f "$SCRIPT_DIR/.envrc" ]; then
    direnv allow "$SCRIPT_DIR" 2>/dev/null || true
fi

# ──────────────────────────────────────────────────────────────────────────────
# VERIFICAÇÃO FINAL
# ──────────────────────────────────────────────────────────────────────────────

echo ""
echo "=== Ferramentas instaladas ==="
source "$VENV_DIR/bin/activate"
echo "  CMake:  $(cmake --version | head -1)"
echo "  Ninja:  $(ninja --version)"
echo "  direnv: $( "$DIRENV_BIN" --version )"
echo ""
echo "=== Configuração do VS Code ==="
echo "  cmake.cmakePath: $VENV_DIR/bin/cmake"
echo ""
echo "=== Ativação automática ==="
echo "  O direnv vai ativar a venv automaticamente ao entrares na pasta."
echo "  Para testar: abre uma nova janela de terminal e navega até à pasta."
echo ""
echo "=== Para apagar tudo ==="
echo "  rm -rf .venv/ .tools/"
echo ""
echo "Setup concluído!"
