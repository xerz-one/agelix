{
  description = "Agenix with Lix";

  inputs = {
    sysrepo.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "sysrepo";
    };
    lix-module = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/2.92.0.tar.gz";
      inputs.nixpkgs.follows = "sysrepo";
    };
  };

  outputs =
    {
      self,
      sysrepo,
      agenix,
      ...
    }@inputs:
    let
      forAllSystems = with sysrepo.lib; genAttrs (import agenix.inputs.systems);
    in
    {
      nixosModules = agenix.nixosModules;
      darwinModules = agenix.darwinModules;
      homeManagerModules = agenix.homeManagerModules;

      overlays.default =
        final: prev:
        let
          pkgs = prev.extend inputs.lix-module.overlays.default;
        in
        {
          agenix = prev.callPackage "${inputs.agenix}/pkgs/agenix.nix" { };
        };

      packages = forAllSystems (
        system:
        let
          pkgs = sysrepo.legacyPackages.${system}.extend inputs.lix-module.overlays.default;
        in
        rec {
          agenix = pkgs.callPackage "${inputs.agenix}/pkgs/agenix.nix" { };
          doc = pkgs.callPackage "${inputs.agenix}/pkgs/doc.nix" { inherit self; };
          default = agenix;
        }
      );
    };
}
