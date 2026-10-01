# =============================================================================
# Shell  --  fish, prompt, history
# =============================================================================
#
# `programs.<name>.enable = true` in home-manager does more than install the
# package: it also writes that program's config file and wires up its shell
# integration. That is why starship and atuin below need no manual
# "add this line to your config" step.
# =============================================================================
{
  # home-manager defaults every program's shell integration ON for every
  # shell it knows how to integrate with -- bash, fish, zsh, nushell -- via
  # one global switch (home.shell.enableShellIntegration). We only use fish,
  # so disable the others explicitly rather than silently generating inert
  # integration files (and, concretely, this nushell default is what broke
  # the build here: fzf gates its nushell integration behind a minimum
  # version our pinned nixpkgs doesn't meet, even though nothing we do
  # touches nushell at all).
  home.shell = {
    enableBashIntegration = false;
    enableNushellIntegration = false;
    enableZshIntegration = false;
  };

  programs.fish = {
    enable = true;

    shellAliases = {
      # NixOS rebuild is a long command you will type constantly.
      rebuild = "sudo nixos-rebuild switch --flake ~/nixconf";
      rebuild-test = "sudo nixos-rebuild test --flake ~/nixconf";

      # List the generations you can roll back to.
      generations = "nixos-rebuild list-generations";
    };
  };

  # A prompt that shows git status, the current directory, and whether you are
  # inside a nix shell.
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
  };

  # Searchable, synced shell history -- Ctrl+R becomes genuinely useful.
  programs.atuin = {
    enable = true;
    enableFishIntegration = true;
    flags = [ "--disable-up-arrow" ];  # keep Up doing normal history
  };

  # Modern replacements that LazyVim and fzf also use under the hood.
  programs.fzf = {
    enable = true;
    enableFishIntegration = true;

    # atuin and fzf both want Ctrl+R by default, and whichever loads last wins
    # -- which is how you end up with a history search that changes depending
    # on the day. atuin keeps Ctrl+R (it is the better history search);
    # fzf keeps Ctrl+T for files and Alt+C for directories.
    historyWidget.command = "";
  };
}
