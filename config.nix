
{ pkgs ? import <nixpkgs> {} }:
let
  systemType = builtins.getEnv "SYSTEM_TYPE";

  # remote pagkages 
  github-neovim = builtins.fetchGit {
    url = "https://github.com/neovim/neovim.git";
    ref = "refs/tags/nightly";
  };

  base = with pkgs; [
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
    github-neovim
  ];
  server = with pkgs; [
    kubectl
    kubectx
    k9s
    fluxcd
  ];
  desktop = with pkgs; [
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
      paths = base ++ (if systemType == "server" then server else desktop);
    };
  };
}

#git tree htop luarocks ripgrep fd-find
