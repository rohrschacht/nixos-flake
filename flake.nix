{
  description = "Nixos config flake";

  inputs = {
   # nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
   nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
 
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  };

  outputs = { self, nixpkgs, ... }@inputs: {
    nixosConfigurations.default = nixpkgs.lib.nixosSystem {
      specialArgs = {inherit inputs;};
      modules = [
        ./hosts/default/configuration.nix
        inputs.home-manager.nixosModules.default
      ];
    };
    nixosConfigurations.copernicus = nixpkgs.lib.nixosSystem {
      specialArgs = {inherit inputs;};
      modules = [
        ./hosts/copernicus/configuration.nix
        inputs.home-manager.nixosModules.default
        inputs.nixos-hardware.nixosModules.lenovo-thinkpad-t420
      ];
    };
  };
}
