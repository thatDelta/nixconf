{
  description = "delta's NixOS configuration - dendritic flake-parts layout";

  inputs = {
    # -- the package set everything is built from --------------------------
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # -- structure ---------------------------------------------------------
    # flake-parts splits a flake into small composable modules.
    # import-tree then auto-imports every .nix file under ./modules, which is
    # why no file in this repo has to be registered anywhere by hand.
    # (Files and directories starting with "_" are skipped by import-tree.)
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";

    # -- home directory management -----------------------------------------
    home-manager = {
      url = "github:nix-community/home-manager";
      # Build home-manager against the same nixpkgs as the system, instead of
      # pulling in a second copy. This is what `follows` means, and leaving it
      # out is a common cause of "why did my closure double in size".
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # -- desktop -----------------------------------------------------------
    # Lets a package be rebuilt with settings baked in; used for noctalia.
    wrapper-modules.url = "github:BirdeeHub/nix-wrapper-modules";

    # The SDDM login screen theme.
    silentSDDM = {
      url = "github:uiriansan/SilentSDDM";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # linuxmobile's package set (the source of the shin setup this borrows from).
    mynixpkgs.url = "github:linuxmobile/mynixpkgs";

    # -- applications ------------------------------------------------------
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    antigravity-nix = {
      url = "github:jacopone/antigravity-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sidra.url = "github:wimpysworld/sidra";
  };

  # Every module under ./modules is imported automatically. Start reading at
  # WALKTHROUGH.md for what lives where.
  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);
}
