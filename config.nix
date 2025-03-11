let
  systemType = builtins.getEnv "SYSTEM_TYPE";
  # Create a new pkgs instance with unfree allowed
  unfree-pkgs = import <nixpkgs> {
    config = {
      allowUnfree = true;
    };
  };

  # Simple Neovim nightly from pre-built Github binaries
  neovim-nightly = unfree-pkgs.stdenv.mkDerivation {
    name = "neovim-nightly";
    src = builtins.fetchTarball { # FIXME: impure, breaks reproductibility
      url = "https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-x86_64.tar.gz";
    };
    installPhase = ''
      mkdir -p $out
      cp -r ./* $out/
    '';
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
    neovim-nightly
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
