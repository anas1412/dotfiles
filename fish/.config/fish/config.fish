source /usr/share/cachyos-fish-config/cachyos-config.fish

# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH

# custom aliases
alias anime="curd -rofi"

function ai
    opencode run -m opencode/big-pickle $argv
end


# Added by Antigravity CLI installer
set -gx PATH "/home/blackbox/.local/bin" $PATH

# go
set -Ux GOPATH $HOME/go
set -Ux PATH $PATH $GOPATH/bin

# >>> grok installer >>>
fish_add_path $HOME/.grok/bin
# <<< grok installer <<<

# opencode
fish_add_path /home/blackbox/.opencode/bin
