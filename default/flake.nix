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
          name = "foo"; # TODO: Change package name
          src = ./.;
        in
        {
          devShell = pkgs.mkShell {
            buildInputs = with pkgs; [
              # TODO: Place development dependencies in here
              # package managers, build tools, debuggers, etc

              # for example
              gnumake # this is a build tool, you just add the package name
            ];

            # Run whatever commands you'd like when entering the shell
            shellHook = ''
              echo "Entering nix shell!!";
            '';
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
