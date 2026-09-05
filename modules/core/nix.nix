# =============================================================================
# Nix itself  --  flakes, caches, garbage collection
# =============================================================================
{
  flake.nixosModules.coreNix = {

    nix.settings = {
      # Flakes and the `nix` command are still technically "experimental".
      # This whole repo is a flake, so they are non-negotiable here.
      experimental-features = [ "nix-command" "flakes" ];

      # A binary cache means downloading a prebuilt package instead of
      # compiling it yourself. The public key proves the download is genuine;
      # without a matching key nix refuses to trust the cache.
      extra-substituters = [ "https://cache.numtide.com" ];
      extra-trusted-public-keys = [
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      ];

      # Deduplicate identical files in the nix store. Reclaims a surprising
      # amount of disk over time.
      auto-optimise-store = true;
    };

    # Old generations are what you roll back TO, so keep a month of them --
    # but not forever, or the store grows without limit.
    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };

    # Some packages (chrome, and most fonts worth having) are not free
    # software. Without this they refuse to build.
    nixpkgs.config.allowUnfree = true;
  };
}
