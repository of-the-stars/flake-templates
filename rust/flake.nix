{
  # TODO: Change description for project
  description = "of-the-star's custom rust development flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    crane = {
      url = "github:ipetkov/crane";
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
      crane,
      rust-overlay,
    }:
    let
      systems = [
        "x86_64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      pkgsFor =
        system:
        import nixpkgs {
          inherit system;
          overlays = [ (import rust-overlay) ];
        };
      packageForSystem =
        system:
        let
          pkgs = (pkgsFor system);

          # Builds the rust components from the toolchain file, or defaults back to the latest nightly build
          rust-toolchain =
            if builtins.pathExists ./rust-toolchain.toml then
              pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml
            else
              pkgs.rust-bin.stable.latest.default.override {
                extensions = [ "rust-src" ];
              };

          # Instantiates custom craneLib using toolchain
          craneLib = (crane.mkLib pkgs).overrideToolchain rust-toolchain;

          src = craneLib.cleanCargoSource ./.;
          pname = craneLib.crateNameFromCargoToml { cargoToml = ./Cargo.toml; }.pname;

          # Common arguments shared between buildPackage and buildDepsOnly
          commonArgs = {
            inherit src;
            strictDeps = true;

            nativeBuildInputs = with pkgs; [
              pkg-config
            ];

            buildInputs = with pkgs; [
              openssl
            ];
          };

          cargoArtifacts = craneLib.buildDepsOnly commonArgs;

          crane-package = craneLib.buildPackage (
            commonArgs
            // {
              inherit cargoArtifacts;
            }
          );
        in
        {
          default = crane-package;
        };
      devShellForSystem =
        system:
        let
          pkgs = pkgsFor system;

          # Builds the rust components from the toolchain file, or defaults back to the latest nightly build
          rust-toolchain =
            if builtins.pathExists ./rust-toolchain.toml then
              pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml
            else
              pkgs.rust-bin.stable.latest.default.override {
                extensions = [ "rust-src" ];
              };
        in
        {
          default = pkgs.mkShell {
            # Inherits buildInputs from crane-package
            inputsFrom = [ (packageForSystem system) ];

            # Additional packages for the dev environment
            packages = with pkgs; [
            ];

            shellHook = "";

            env = {
              # Needed for rust-analyzer
              RUST_SRC_PATH = "${rust-toolchain}/lib/rustlib/src/rust/library";
            };
          };
        };
      formatterForSystem =
        system:
        let
          pkgs = pkgsFor system;
        in
        pkgs.nixfmt-tree;
    in
    {
      # packages = forAllSystems (system: packageForSystem system);
      # devShells = forAllSystems (system: devShellForSystem system);
      # formatter = forAllSystems (system: formatterForSystem system);
    };
}
