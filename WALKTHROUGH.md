# nixconf

A NixOS configuration built on the **dendritic** pattern: every `.nix` file
under `modules/` is picked up automatically, so nothing has to be registered by
hand. Read this file first — it is the map.

---

## Everyday commands

```bash
sudo nixos-rebuild switch --flake ~/nixconf#tuturu
```

| What you want | Command |
|---|---|
| Apply changes | `rebuild` (alias for the above) |
| Try changes without making them permanent | `rebuild-test` |
| See what you can roll back to | `generations` |
| Roll back | pick an older entry in the boot menu |
| Update all inputs | `nix flake update` |
| Check it builds before switching | `nix eval .#nixosConfigurations.tuturu.config.system.build.toplevel.drvPath` |

> **The one gotcha that will bite you:** `nix` only sees files that git knows
> about. A brand new file you have not `git add`-ed is **invisible** — you get
> "undefined variable" or "attribute missing" errors that make no sense.
> `git add` first, then rebuild.

---

## The map

```
nixconf/
├── flake.nix              inputs (nixpkgs, home-manager, …) and nothing else
├── WALKTHROUGH.md         you are here
│
├── modules/               ← auto-imported. system side.
│   ├── options.nix        my.username / my.profile
│   ├── parts.nix          which CPU architectures to build for
│   │
│   ├── core/              ALWAYS ON. "the laptop works" layer.
│   │   ├── boot.nix       bootloader, kernel, zram
│   │   ├── locale.nix     timezone, language, console keymap
│   │   ├── network.nix    NetworkManager + wifi password storage
│   │   ├── power.nix      lid switch, suspend, battery
│   │   ├── audio.nix      pipewire
│   │   ├── users.nix      your account
│   │   ├── nix.nix        flakes, caches, garbage collection
│   │   ├── packages.nix   essential CLI tools (git, jq, …)
│   │   ├── fonts.nix      fonts
│   │   └── security.nix   polkit, sudo
│   │
│   ├── features/          OPT-IN capabilities a profile can pick up.
│   │   ├── niri.nix           the compositor
│   │   ├── noctalia.nix       the desktop shell (bar/launcher/notifications)
│   │   ├── noctalia.json      …its settings
│   │   ├── display-manager.nix SDDM login screen + theme
│   │   ├── portals.nix        file pickers, polkit agent, screen share
│   │   └── home-manager.nix   the home-manager ↔ NixOS bridge
│   │
│   ├── profiles/          A COMPLETE DESKTOP, chosen as a unit.
│   │   └── yume.nix       niri + noctalia + shin theming
│   │
│   └── hosts/tuturu/      THIS machine.
│       ├── default.nix        ← where the profile is chosen
│       ├── configuration.nix  hostname, username, host-only packages
│       └── hardware.nix       generated; do not edit
│
└── home/                  ← home-manager side. your home directory.
    └── yume/
        ├── default.nix    the list of parts
        ├── theme.nix      GTK/Qt theme, icons, cursor
        ├── wallpapers.nix seeds ~/Pictures/Wallpapers
        ├── packages.nix   your applications
        ├── shell.nix      fish, starship, atuin
        ├── neovim.nix     neovim + LazyVim
        ├── quickshell.nix noctalia, wrapped with its runtime deps
        └── niri/          compositor config
            ├── default.nix   assembles the parts below into config.kdl
            ├── _settings.nix inputs, outputs, layout, startup
            ├── _binds.nix    ★ every keybind
            ├── _rules.nix    per-app window rules
            └── _to-KDL.nix   Nix → KDL translator (leave alone)
```

Files starting with `_` are **data, not modules** — `import-tree` skips them,
and they are imported explicitly by the `default.nix` beside them.

---

## The four layers

The whole point of the split is that each layer only knows about the one below
it, so you can replace a layer without touching the others.

```
host      "this is tuturu, delta's laptop"   ← picks a profile
  └── profile   "this is the yume desktop"   ← picks features + home config
        ├── features   niri, noctalia, SDDM  ← opt-in capabilities
        └── core       boot, network, power  ← always on
```

**Where does my change go?** Ask "would a completely different desktop still
want this?"

| Change | Goes in |
|---|---|
| Wifi, sleep, sound, sudo | `core/` |
| A new compositor or bar | `features/` |
| Which of those this desktop uses | `profiles/yume.nix` |
| Your apps, theme, keybinds | `home/yume/` |
| Hostname, hardware, this-box-only tools | `hosts/tuturu/` |

---

## What home-manager actually is

NixOS manages the **system**: bootloader, drivers, services, `/etc`. It stops
at your home directory.

home-manager manages **your home** the same declarative way — the dotfiles in
`~/.config`, your per-user packages, your shell, your GTK theme. Instead of
hand-editing `~/.config/niri/config.kdl`, you describe it in Nix and
home-manager writes the file.

**What you get:** dotfiles that are versioned in git, rebuild identically on a
fresh machine, and roll back with the rest of the system.

**What it costs:** the files it writes are **read-only symlinks into
`/nix/store`**. You cannot edit `~/.config/niri/config.kdl` any more. You edit
`home/yume/niri/_binds.nix` and rebuild. That is the trade: you give up
editing-in-place, and in exchange the file in git is always exactly what is
running.

Here it runs *inside* NixOS (as a NixOS module) rather than standalone, which
is why `nixos-rebuild` updates your dotfiles too — there is no second command.

### The escape hatch

Some tools **must** write to their own config directory and break under a
read-only symlink. LazyVim is the example in this repo: `lazy.nvim` writes
`lazy-lock.json` into `~/.config/nvim`. So `home/yume/neovim.nix` deliberately
installs neovim and its toolchain but leaves `~/.config/nvim` as ordinary
editable files.

The general escape hatch is `mkOutOfStoreSymlink`, which points `~/.config/foo`
at a file *in this repo* rather than in the store — editable, live, still in
git, but no rebuild needed to see a change:

```nix
xdg.configFile."foo".source =
  config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixconf/home/yume/foo";
```

Worth using while you are iterating fast on something; switch back to a normal
managed file once it settles.

---

## Switching dotfiles: home-manager vs profile files

You asked whether to switch dotfiles *with home-manager* or with *profile
`.nix` files*. They are not alternatives — they are the two halves, and this
repo uses both:

| | Profile `.nix` (`modules/profiles/`) | home-manager (`home/`) |
|---|---|---|
| Scope | system: which compositor, which login screen | your home: dotfiles, apps, theme |
| Answers | "which desktop is this?" | "what does that desktop look like?" |
| Needs root | yes | no |

A profile is the **switch**; home-manager is **what the switch selects**.
`modules/profiles/yume.nix` is only ~15 lines, and the last one is
`home-manager.users.<you> = import ../../home/yume;` — that single line is the
join.

The alternative you might have had in mind — one home-manager config with
`if profile == "yume" then … else …` branching inside every file — works, but
every file grows a conditional and the two desktops can never be built
side by side. Separate directories mean `home/kai/` can be completely
different, and both stay buildable.

### Adding a second profile

1. `cp -r home/yume home/kai` and edit it
2. `cp modules/profiles/yume.nix modules/profiles/kai.nix`, rename the module
   `profileYume` → `profileKai`, change its feature imports
3. In `modules/hosts/tuturu/default.nix`, uncomment the second line:
   ```nix
   tuturu-kai = mkTuturu self.nixosModules.profileKai;
   ```
4. `git add .` then `sudo nixos-rebuild switch --flake ~/nixconf#tuturu-kai`

Both are normal generations, so the boot menu lets you pick either one, and
`core/` was never touched.

---

## Common tasks

**Add an application** → `home/yume/packages.nix`

**Add a keybind** → `home/yume/niri/_binds.nix`. Names come from:
```bash
niri msg action --help      # what niri can do
noctalia-shell ipc show     # what the bar can do
```

**Change how the bar looks** → `modules/features/noctalia.json`, then rebuild.
See the caveat in `modules/features/noctalia.nix`: the settings panel writes to
`~/.config/noctalia/settings.json` at runtime, so the two can drift. Change it
live to experiment, then copy what you liked back into the JSON.

**Change the theme** → `home/yume/theme.nix`

**Change the wallpaper** → drop an image in `~/Pictures/Wallpapers`, press
`Ctrl+Super+T`. noctalia regenerates the entire colour scheme from it.

---

## Keybinds

`Mod` = Super/Windows key. Full list with comments in
`home/yume/niri/_binds.nix`.

### Apps
| Key | Does |
|---|---|
| `Mod+T` / `Mod+Return` | Terminal |
| `Mod+E` | Files (dolphin) |
| `Mod+B` | Browser |
| `Mod+C` | Editor — currently LazyVim; alternatives listed in `_binds.nix` |

### Shell
| Key | Does |
|---|---|
| `Mod+D` | App launcher |
| `Mod+V` | Clipboard history |
| `Mod+Period` | Emoji picker |
| `Mod+N` / `Mod+Shift+N` | Control centre / notifications |
| `Mod+M` | Media controls |
| `Mod+I` | **Caffeine** (idle inhibitor) |
| `Mod+U` | noctalia settings |
| `Ctrl+Mod+T` | Wallpaper picker |
| `Ctrl+Mod+Shift+D` | Light/dark toggle |

### Windows
| Key | Does |
|---|---|
| `Mod+Q` | Close |
| `Mod+F` / `Mod+Shift+F` | Fullscreen / maximise |
| `Mod+Space` | Float ↔ tile |
| `Mod+Tab` | Overview |
| `Mod+W` | Tabbed column |
| `Mod+H/J/K/L` or arrows | Focus |
| `Mod+Shift+` those | Move window |
| `Mod+R` | Cycle column width |

### Workspaces
| Key | Does |
|---|---|
| `Mod+1`…`9` | Go to workspace |
| `Mod+Shift+1`…`9` | Send window there |
| `Mod+PageUp/Down`, `Mod+scroll` | Previous/next |

### Session & capture
| Key | Does |
|---|---|
| `Ctrl+Alt+L` | Lock |
| `Ctrl+Alt+S` | Sleep |
| `Ctrl+Alt+Delete` | Power menu |
| `Print` / `Mod+Shift+S` | Screenshot screen / region |
| `Mod+Shift+C` | Colour picker |
| `Mod+Shift+Slash` | **Show all keybinds on screen** |

Session keys are on `Ctrl+Alt` rather than end4's `Super+L`, because niri needs
`Mod+L` for column navigation.

---

## Things that will confuse you later

**`stateVersion` is not a version to upgrade.** Both `system.stateVersion` and
`home.stateVersion` pin *defaults* so an upgrade never silently moves your
data. Set once, then leave alone. Your actual NixOS version comes from the
`nixpkgs` input.

**Untracked files are invisible to nix.** See the warning at the top.

**`_`-prefixed files are skipped** by `import-tree`. Naming a real module
`_foo.nix` means it silently never loads.

**Two things must both be true for sleep.** `core/power.nix` decides what a
closed lid does; noctalia's `idle` section decides what happens after N minutes
of no input. They are separate systems.
