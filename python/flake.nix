{
  description = "A very basic, yet somehow still opinionated Python flake"; # TODO: Change description for project

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
          name = "foo"; # TODO: Change package name
          src = ./.;
        in
        {
          devShell =
            with pkgs;
            mkShell {
              buildInputs = [
                python3Packages.python
                python3Packages.venvShellHook
              ];
              venvDir = "./.venv";
            };

          package = derivation {
            inherit system name src;

            builder = with pkgs; "${bash}/bin/bash"; # TODO: Add package build step
            args = [
              "-c"
              "echo Building! > $out"
            ];
          };

          formatter = pkgs.nixfmt-tree; # Nix flake formatter. Run `nix fmt` to use
        };
    in
    {
      devShells = (
        iterOverSystems (system: {
          default = (forSystem system).devShell;
        })
      );

      formatter = (iterOverSystems (system: (forSystem system).formatter));

      packages = (
        iterOverSystems (system: {
          default = (forSystem system).package;
        })
      );
    };
}
