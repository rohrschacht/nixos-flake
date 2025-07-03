{
  description = "Nixos config flake";

  inputs = {
   # nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
   nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
   nixpkgs-pinned.url = "github:nixos/nixpkgs/6c64dabd3aa85e0c02ef1cdcb6e1213de64baee3";
 
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
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
    nixosConfigurations.curie = nixpkgs.lib.nixosSystem {
      specialArgs = {inherit inputs;};
      modules = [
        ./hosts/curie/configuration.nix
        inputs.home-manager.nixosModules.default
        inputs.nixos-hardware.nixosModules.lenovo-thinkpad-t14
      ];
    };
    nixosConfigurations.galileo = nixpkgs.lib.nixosSystem {
      specialArgs = {inherit inputs;};
      modules = [
        ./hosts/galileo/configuration.nix
        inputs.home-manager.nixosModules.default
        inputs.nixos-hardware.nixosModules.framework-13th-gen-intel
      ];
    };
  };
}
