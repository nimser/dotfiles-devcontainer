> [!Caution]
> **MIRROR NOTICE**
>
> This repository is a filtered mirror of a private source, published for reference only.
> It contains only the paths its allowlist names, so it is not a complete project.
>
> *Standard upgrade paths MIGHT be compromised!*

Dotfiles for workstations and development containers, managed by chezmoi.

px13 is the default workstation. Files captured from its recovered CachyOS,
niri, and Noctalia setup belong in the normal source paths. Older tpad copies
are kept as `*.tpad` references and ignored by chezmoi until that machine is
retired or converged. The checkout does not invent desktop defaults; capture
the reviewed px13 files before expecting chezmoi to manage them.

Run setup on the target machine from this checkout:

```bash
bash setup
```

On a host, this bootstraps the mise CLI, deploys unencrypted configuration,
reports missing native packages, installs mise/Nix packages, then applies
encrypted files, restores stores, and activates services. Have the matching
decryption hardware/key available. On a clean host, the first
run still needs a GitHub token before mise can install its GitHub-backed tools;
provide it without putting it in the repository:

```bash
read -rsp 'GitHub token: ' MISE_GITHUB_TOKEN; export MISE_GITHUB_TOKEN; echo
bash setup
unset MISE_GITHUB_TOKEN
```

Existing installations are reused; a failed required stage stops setup with a
log and a nonzero exit status. Rerun the same command after resolving the
failure. After the first private apply restores the bg store, mise reads the
token through its gopass credential command on later runs.

After recovering a px13 default, capture only the files you have reviewed
from the host into this checkout, then inspect the source diff:

```bash
cd ~/.local/share/chezmoi
chezmoi add --force --source "$PWD" ~/.config/alacritty/alacritty.toml
chezmoi diff
```

Repeat that `chezmoi add` command for the specific niri/Noctalia files you
want to manage. Generated state and caches should stay outside the source.

Containers use the same command but defer decryption until first interactive
login. Bootstrap installs tools and restores bg. `~/.profile` then applies
encrypted files and loads `~/.environment`; containers do use bg secrets.
A success marker at `~/.local/state/chezmoi/secrets-applied` is written only
when the entire encrypted apply succeeds. Failed attempts retry on the next
interactive login, even if `.environment` was already written.

`bash setup --without-secrets` explicitly defers host secrets and activation.
`bash setup --with-secrets` explicitly completes secrets in a container.
An old host's TPM identity cannot provision the new host's TPM; machine-specific
key provisioning remains under `_system`.

Ordinary `chezmoi apply` deploys configuration and runs applicable once/onchange
hooks; it does not install packages. After changing package selections, rerun
setup or wait for the host's weekly `chezmoi-refresh-externals.timer`. That
existing timer now refreshes mise itself, upgrades/installs configured mise
tools, installs the declared Nix package set, updates tldr, and rebuilds bat's
cache. It does not perform a full apply or decrypt secrets. Failures stop the
service and are recorded in its journal. DevPod volume warming stays separate.

Every tool has one installation owner per target. mise owns the user toolchain,
including age, gopass and the age plugins: the deployed identities need
age-plugin-tpm v1 and nixpkgs carries 0.3.0. Nix owns packages whose dependency
closure the distro and mise cannot deliver cleanly, which in a container also
means Chrome and ffmpeg, because no native package stream may be added to a
running container. The distro owns hardware, desktop and browser integration,
and the login fish; containers get fish from mise instead. Nix package selection
comes from the rendered `~/.config/nixpkgs/config.nix`: containers get the
container set, the workstations in the hostname list also get desktop packages,
and every other machine gets the plain host set.

Setup checks the native libraries, executables and services that the deployed
mise configuration implies — libfido2, pcsclite with pcscd, ykman, FUSE 2 for
the Handy AppImage, and keyd where `_system/<hostname>/etc/keyd` exists. Missing
ones stop setup with the pacman or apt command to run; nothing is installed for
you, so an unattended run can never answer a package-manager prompt.

Rclone comes from Nix. Its credential wrapper calls
`~/.nix-profile/bin/rclone` directly. Core restoration downloads to a staging
directory, publishing the store only after a successful transfer and Git check.
Neovim plugin sync remains asynchronous; its log is
`~/.local/state/nvim/lazy-sync.log`.

For file deployment without secrets or run hooks:

```bash
chezmoi apply --exclude=encrypted,scripts
```

Focused source checks: `python3 _utils/test-bootstrap.py` (Python, chezmoi,
Bash, and Fish required). They do not test downloads or hardware decryption.
Test recovery on the current host first; use a fresh VM/snapshot for the clean
workstation test. Container testing must include first login and bg access.
