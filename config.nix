let
  systemType = builtins.getEnv "SYSTEM_TYPE";
  # Create a new pkgs instance with unfree allowed
  unfree-pkgs = import <nixpkgs> {
    config = {
      allowUnfree = true;
    };
  };

  base = with unfree-pkgs; [
    tealdeer
    gnumake
    gcc
    netplan
    fish
    tree
    htop
    nodejs_22
    fd
    ripgrep
    luarocks
  ];
  server = with unfree-pkgs; [
    kubectl
    kubectx
    k9s
    fluxcd
  ];
  desktop = with unfree-pkgs; [
    appimage-run
    lazygit
    discord
    obsidian
    brave
  ];
in {
  packageOverrides = pkgs: {
    myPackages = pkgs.buildEnv {
      name = "nimser-tools";
      paths = base ++ (if systemType == "desktop" then desktop else server);
    };
  };
}
