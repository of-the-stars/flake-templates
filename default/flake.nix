{
  description = "A very basic, yet somehow still opinionated flake for dev environments and packaging"; # TODO: Change description for project

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs =
    {
      self,
      nixpkgs,
    }:
    let
      systems = [
        "x86_64-linux"
      ];
      iterOverSystems = nixpkgs.lib.genAttrs systems;
      forSystem =
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          pname = "foo"; # TODO: Change package name
          src = ./.;
        in
        {
          devShell = pkgs.mkShell {
            buildInputs = with pkgs; [
            ];
          };

          package = pkgs.stdenv.mkDerivation {
            inherit
              src
              pname
              ;
          };

          formatter = pkgs.nixfmt-tree; # Nix flake formatter. Run `nix fmt` to use
        };
    in
    {
      formatter = iterOverSystems (system: (forSystem system).formatter);

      devShells = iterOverSystems (system: {
        default = (forSystem system).devShell;
      });

      packages = iterOverSystems (system: {
        default = (forSystem system).package;
      });
    };
}
