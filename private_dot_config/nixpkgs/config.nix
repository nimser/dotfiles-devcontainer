{
  allowUnfree = true;  # This enables unfree packages globally

  packageOverrides = pkgs: 
    let
      systemType = builtins.getEnv "SYSTEM_TYPE";

      base = with pkgs; [
        pass
        gcc
        tree
        htop
        luarocks
        luac
      ];
      server = with pkgs; [
        wakeonlan
      ];
      desktop = with pkgs; [
        sqlite
        tectonic
        mermaid-cli
        imagemagick
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
