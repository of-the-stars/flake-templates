{
  # TODO: Change description for project
  description = "of-the-star's custom rust development flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    crane = {
      url = "github:ipetkov/crane";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      crane,
      rust-overlay,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ (import rust-overlay) ];
        };

        # Builds the rust components from the toolchain file, or defaults back to the latest nightly build
        rust-toolchain =
          if builtins.pathExists ./rust-toolchain.toml then
            pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml
          else
            pkgs.rust-bin.selectLatestNightlyWith (
              toolchain:
              toolchain.default.override {
                extensions = [ "rust-src" ];
              }
            );

        # Instantiates custom craneLib using toolchain
        craneLib = (crane.mkLib pkgs).overrideToolchain rust-toolchain;

        src = craneLib.cleanCargoSource ./.;
        pname = craneLib.crateNameFromCargoToml { cargoToml = ./Cargo.toml; }.pname;

        # Common arguments shared between buildPackage and buildDepsOnly
        commonArgs = {
          inherit src;
          strictDeps = true;

          buildInputs = with pkgs; [
          ];
        };

        cargoArtifacts = craneLib.buildDepsOnly (commonArgs);

        crane-package = craneLib.buildPackage (
          commonArgs
          // {
            inherit cargoArtifacts;
          }
        );
      in
      {
        devShells.default = pkgs.mkShell {
          # Inherits buildInputs from crane-package
          inputsFrom = [ crane-package ];

          # Additional packages for the dev environment
          packages = with pkgs; [
          ];

          shellHook = "";

          env = {
            # Needed for rust-analyzer
            RUST_SRC_PATH = "${rust-toolchain}/lib/rustlib/src/rust/library";
          };
        };

        packages.default = crane-package;

        formatter = pkgs.nixfmt-tree;
      }
    );
}
