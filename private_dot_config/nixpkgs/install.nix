let
  # This explicitly downloads the 25.11 channel every time
  nixpkgs = builtins.fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-25.11.tar.gz";
  pkgs = import nixpkgs {
    config = import ./config.nix; # Load your existing config
  };
in {
  # Expose your custom package list
  myPackages = pkgs.myPackages;
}
