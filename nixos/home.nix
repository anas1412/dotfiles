# Your dotfiles, declarative. Ported from ~/.zshrc and ~/.config on CachyOS.
{ config, pkgs, ... }:

{
  home.username = "blackbox";
  home.homeDirectory = "/home/blackbox";
  home.stateVersion = "25.05";

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;      # you had zsh-autosuggestions
    syntaxHighlighting.enable = true;  # you had zsh-syntax-highlighting
    historySubstringSearch.enable = true;

    plugins = [{
      name = "powerlevel10k";
      src = pkgs.zsh-powerlevel10k;
      file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
    }];

    # ported straight from your current ~/.zshrc
    initExtra = ''
      fastfetch

      [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

      ai()  { opencode run -m opencode/big-pickle "$@"; }
      mt5() { WINEPREFIX=~/.wine_mt5 wine "$HOME/.wine_mt5/drive_c/Program Files/MetaTrader 5/terminal64.exe" "$@"; }
    '';
  };

  home.sessionVariables = {
    GOPATH = "$HOME/go";
    EDITOR = "micro";
  };
  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/go/bin"
    "$HOME/.opencode/bin"
    "$HOME/.grok/bin"
    "$HOME/.railway/bin"
  ];

  programs.git = {
    enable = true;
    userName  = "anas1412";
    userEmail = "anas.bassoumi@gmail.com";
  };

  programs.kitty.enable = true;
  programs.fastfetch.enable = true;

  # p10k prompt config is 90KB of generated settings - copy it, don't rewrite it
  # home.file.".p10k.zsh".source = ./dotfiles/p10k.zsh;
}
