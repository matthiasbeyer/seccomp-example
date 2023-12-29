{
  description = "A very basic flake";
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-23.05";
    unstable-nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
    crane = {
      url = "github:ipetkov/crane/v0.12.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
  };

  outputs = inputs: inputs.flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ]
  (system:
  let
    pkgs = import inputs.nixpkgs {
      inherit system;
      overlays =
        let
          selfOverlay = _: _: {
            inherit (inputs.self.packages."${system}") cloudroots;
          };
        in
        [
          selfOverlay
          (import inputs.rust-overlay)
        ];
    };

    utils = import ./lib/nix/utils.nix { inherit pkgs; };

    fmtRustTarget = pkgs.rust-bin.selectLatestNightlyWith (toolchain: pkgs.rust-bin.fromRustupToolchain { channel = "nightly"; components = [ "rustfmt" ]; });
    fmtCraneLib = (inputs.crane.mkLib pkgs).overrideToolchain fmtRustTarget;
    rustTarget = pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
  in
  {
      devShells.default =
        pkgs.mkShell {
          nativeBuildInputs = [
            rustTarget
            pkgs.libseccomp.out
            pkgs.libseccomp.lib
            pkgs.libseccomp.dev
            pkgs.pkg-config
          ];
        };

  });
}
