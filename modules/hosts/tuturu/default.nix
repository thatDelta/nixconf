{ self, inputs, ... }: {
  flake.nixosConfigurations.tuturu = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.tuturuConfiguration
    ];
  };
}
