{ pkgs ? import <nixpkgs> {} }:

let
  systemType = builtins.getEnv "SYSTEM_TYPE";
  # Import the neovim-nightly-overlay
  neovim-nightly-overlay = builtins.fetchTarball {
    url = "https://github.com/nix-community/neovim-nightly-overlay/archive/master.tar.gz";
  };
  
  # Create a custom pkgs with the overlay applied
  unfree-pkgs = import <nixpkgs> {
    config = {
      allowUnfree = true;
    };
    overlays = [
      (import neovim-nightly-overlay)
    ];
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
    neovim
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
in
{
  # Or if you had a tools derivation like in your error message:
  packageOverrides = pkgs: {
    myPackages = pkgs.buildEnv {
      name = "nimser-tools";
      paths = base ++ (if systemType == "desktop" then desktop else server);
    };
  };
}
