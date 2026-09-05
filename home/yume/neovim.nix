# =============================================================================
# Neovim + LazyVim
# =============================================================================
#
# LazyVim is a preconfigured Neovim setup: sensible defaults, a plugin manager
# (lazy.nvim), LSP, fuzzy finding, git integration -- without you writing a
# thousand lines of Lua first. It is a good way to learn Neovim, because you
# start from something that works and change one piece at a time.
#
# WHY ~/.config/nvim IS *NOT* MANAGED BY HOME-MANAGER
#   This is the one interesting decision in this file, and it is worth
#   understanding because it applies to any self-updating tool.
#
#   home-manager writes read-only symlinks into /nix/store. LazyVim needs to
#   WRITE to its own config directory -- lazy.nvim keeps lazy-lock.json there
#   to record which plugin versions you have. Point home-manager at
#   ~/.config/nvim and LazyVim breaks on first launch, unable to save its lock
#   file.
#
#   So the split is:
#     - Nix installs neovim and the compilers/tools its plugins need. Those
#       are the parts that are painful to install by hand on NixOS.
#     - LazyVim owns ~/.config/nvim as ordinary editable files, bootstrapped
#       once below.
#
#   You edit your Neovim config the normal way, with Neovim. If you later want
#   it version-controlled, make ~/.config/nvim its own git repo -- keeping it
#   out of this flake is what makes that possible.
# =============================================================================
{ config, pkgs, lib, ... }:
{
  programs.neovim = {
    enable = true;

    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    # Tools LazyVim expects to find on PATH. On another distro these come from
    # the system package manager; here they are attached to neovim itself so
    # they cannot go missing.
    extraPackages = with pkgs; [
      # LazyVim health checks look for these three by name.
      git
      ripgrep      # the search backend for grep and fuzzy find
      fd           # the file finder backend

      lazygit      # the git UI LazyVim opens
      tree-sitter  # syntax parsing

      # Treesitter and some plugins compile native code on install, so a
      # working C toolchain has to be present.
      gcc
      gnumake

      # Most language servers are distributed as npm packages.
      nodejs

      # Lua tooling, since LazyVim itself is configured in Lua.
      lua-language-server
      stylua

      wl-clipboard # lets neovim yank into the system clipboard
      unzip
      curl
    ];
  };

  # --- one-time LazyVim bootstrap -----------------------------------------
  # Clones the LazyVim starter the first time only. If ~/.config/nvim already
  # exists this does nothing, so your own changes are never overwritten.
  #
  # Deliberately cannot fail the rebuild: a broken network on the day you run
  # `nixos-rebuild switch` should not stop your system from switching. If the
  # clone fails you get a warning and can rerun it yourself.
  home.activation.bootstrapLazyVim =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      nvimDir="${config.xdg.configHome}/nvim"

      if [ ! -e "$nvimDir" ]; then
        echo "Setting up LazyVim in $nvimDir"
        if run ${lib.getExe pkgs.git} clone --depth 1 \
             https://github.com/LazyVim/starter "$nvimDir"; then
          # Drop the starter's git history so the directory is yours to
          # version-control (or not) as you like.
          run rm -rf "$nvimDir/.git"
        else
          echo "warning: could not fetch LazyVim starter (offline?)." >&2
          echo "         run this later:  git clone --depth 1 https://github.com/LazyVim/starter $nvimDir" >&2
        fi
      fi
    '';
}
