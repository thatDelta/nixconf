{ self, inputs, ... }: {
  flake.nixosModules.homeManager = { config, pkgs, lib, ... }: {
    imports = [
      inputs.home-manager.nixosModules.home-manager
    ];

    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    
    home-manager.users.delta = {
      # stateVersion and packages are managed per-profile in yume.nix
      programs.fish.enable = true;
      programs.starship.enable = true;
    };
  };
}
