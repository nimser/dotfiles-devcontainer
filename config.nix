{
  allowUnfree = true;  # This enables unfree packages globally

  packageOverrides = pkgs: 
    let
      systemType = builtins.getEnv "SYSTEM_TYPE";

      base = with pkgs; [
        tealdeer
        gnumake
        gcc
        fish
        tree
        htop
        nodejs_22
        fd
        ripgrep
        luarocks
      ];
      server = with pkgs; [
        kubectx
        k9s
        fluxcd
      ];
      desktop = with pkgs; [
        sqlite
        gs
        tectonic
        mermaid-cli
        stylua
        appimage-run
        fzf
        tree-sitter
        imagemagick
        lazygit
        discord
        obsidian
        brave
      ];
    in {
      myPackages = pkgs.buildEnv {
        name = "nimser-tools";
        paths = base
          ++ (if systemType == "desktop" then desktop else [])
          ++ (if systemType == "server" then server else []);
      };
    };
}
