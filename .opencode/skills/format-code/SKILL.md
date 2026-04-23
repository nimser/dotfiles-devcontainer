---
name: format-code
description: Format files in this chezmoi dotfiles repo using dprint (CLI) and conform.nvim (neovim). Covers fish, shell, json, toml, yaml, markdown, dockerfile.
---

## Formatting rules

This repo uses **dprint** as the single CLI formatter, with the **Exec plugin** wrapping `fish_indent` and `shfmt` for file types dprint has no native plugin for.

### Config files

- **Repo**: `.dprint.jsonc` at repo root
- **Global fallback**: `~/.config/dprint/.dprint.jsonc` (used when no local config found)

Both configs are kept in sync. When you change formatting rules, update both chezmoi sources:

- Repo: `.dprint.jsonc`
- Global: `private_dot_config/dprint/dot_dprint.jsonc`

Then run `chezmoi apply --force ~/.config/dprint/.dprint.jsonc`.

### CLI command

```bash
dprint fmt
```

For a single file:

```bash
dprint fmt <path>
```

Verify without modifying:

```bash
dprint check
```

### Template files

| Pattern             | Formatted? | Notes                                                              |
| ------------------- | ---------- | ------------------------------------------------------------------ |
| `*.sh.tmpl`         | Yes        | shfmt handles `{{ }}` syntax fine                                  |
| `*.toml.tmpl`       | Yes        | dprint toml plugin handles `{{ }}` syntax                          |
| `*.yaml.tmpl`       | Yes        | dprint yaml plugin handles `{{ }}` syntax                          |
| `modify_*.json`     | **No**     | Pure Go templates that output JSON — JSON parser chokes on `{{ }}` |
| `modify_*` (no ext) | No         | Pure Go templates, no formatter exists                             |

### What formats what

| File type                  | Formatter (via dprint Exec or native)          |
| -------------------------- | ---------------------------------------------- |
| `.fish`                    | `fish_indent` (ships with fish)                |
| `.sh`, `.bash`, `.sh.tmpl` | `shfmt -i 2 -ci -bn`                           |
| `.json`, `.jsonc`          | dprint wasm plugin (`trailingCommas: "never"`) |
| `.toml`                    | dprint wasm plugin                             |
| `.yaml`, `.yml`            | dprint pretty_yaml plugin                      |
| `.md`                      | dprint wasm plugin                             |
| `Dockerfile`               | dprint wasm plugin                             |

### Neovim (conform.nvim)

`private_dot_config/nvim/lua/plugins/conform.lua` mirrors the CLI exactly. Same formatters, same args. Format on save works per-filetype.

The fallback logic in conform checks for a local `.dprint.jsonc` first, then falls back to `~/.config/dprint/.dprint.jsonc`. This means neovim formats files correctly in any project.

### Mise-managed tools

All formatters are installed via mise:

- **Global config template**: `private_dot_config/mise/config.toml.tmpl`
- **Repo activation**: `mise.toml` at repo root (ensures shims work when dprint runs exec commands)

Never install formatters directly — update the chezmoi template instead.

### When to format

- Before committing changes to any `.fish`, `.sh`, `.json`, `.toml`, `.yaml`, `.md`, or `Dockerfile`
- After editing any file that dprint covers
- Run `dprint check` to verify without modifying
