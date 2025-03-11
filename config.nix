{
  packageOverrides = pkgs: with pkgs; {
    myPackages = pkgs.buildEnv {
      name = "nimser-tools";
      paths = [
        # --- base
        fish
        nodejs_22
        fd
        ripgrep
        # --- Version control
        lazygit
        # -- Kubernetes related
        kubectl
        kubectx
        k9s
        fluxcd
      ];
    };
  };
}
