# welcome message (fish_greeting equivalent) - must stay ABOVE p10k instant prompt
fastfetch

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

source /usr/share/cachyos-zsh-config/cachyos-config.zsh


# Added by Antigravity CLI installer
export PATH="/home/blackbox/.local/bin:$PATH"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# --- ported from fish config ---
export GOPATH="$HOME/go"
export PATH="$PATH:$GOPATH/bin"

ai() { opencode run -m opencode/big-pickle "$@"; }

mt5() { WINEPREFIX=~/.wine_mt5 wine "$HOME/.wine_mt5/drive_c/Program Files/MetaTrader 5/terminal64.exe" "$@"; }

# grok
export PATH="$HOME/.grok/bin:$PATH"

# opencode
export PATH="$HOME/.opencode/bin:$PATH"

# railway
[ -f "$HOME/.railway/env" ] && source "$HOME/.railway/env"
