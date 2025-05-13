{
  allowUnfree = true;  # This enables unfree packages globally

  packageOverrides = pkgs: 
    let
      systemType = builtins.getEnv "SYSTEM_TYPE";

      base = with pkgs; [
        gcc
        tree
        htop
        luarocks
      ];
      server = with pkgs; [
        kubectx
        k9s
        fluxcd
      ];
      desktop = with pkgs; [
        fcitx5
        fcitx5-gtk
        fcitx5-rime
        fcitx5-configtool
        fcitx5-material-color
        fcitx5-chinese-addons
        sqlite
        tectonic
        mermaid-cli
        imagemagick
        discord
        obsidian
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
