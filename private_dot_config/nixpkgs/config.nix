{
  allowUnfree = true;  # This enables unfree packages globally

  packageOverrides = pkgs: 
    let
      systemType = builtins.getEnv "SYSTEM_TYPE";
      # Evaluation is impure (nix-env / --impure), so we can detect containers
      # directly and keep their closure lean.
      inContainer = builtins.pathExists "/.dockerenv";

      base = with pkgs; [
        socat
        python3
        gcc
        tree
        htop
        luarocks
        lua
      ];
      # Heavy packages that only make sense on real hosts:
      # - brave: personal browser (profile/sync live on the host)
      # - jellyfin-ffmpeg: hw-accel transcode build with a huge GUI closure
      hostOnly = with pkgs; [
        jellyfin-ffmpeg
        brave
        google-chrome
      ];
      # Containers still need Chrome for the browser-tools skill (CDP on :9222)
      # and a slim ffmpeg for occasional media work.
      containerOnly = with pkgs; [
        google-chrome
        ffmpeg-headless
      ];
      server = with pkgs; [
        wakeonlan
      ];
      desktop = with pkgs; [
        sqlite
        tectonic
        mermaid-cli
        imagemagick
        scrcpy
        tmux
        xdotool
        rofi
        xclip
      ];
    in {
      myPackages = pkgs.buildEnv {
        name = "nimser-tools";
        paths = base
          ++ (if inContainer then containerOnly else hostOnly)
          ++ (if systemType == "desktop" then desktop else [])
          ++ (if systemType == "server" then server else []);
      };
    };
}
