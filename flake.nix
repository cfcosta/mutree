{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    {
      nixpkgs,
      flake-utils,
      rust-overlay,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ (import rust-overlay) ];
        };
        inherit (pkgs) makeRustPlatform mkShell rust-bin;
        rust = rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
        rustPlatform = makeRustPlatform {
          rustc = rust;
          cargo = rust;
        };

        RUSTFLAGS =
          {
            "x86_64-linux" = "-C target-feature=+sse,+sse2,+sse3,+ssse3,+sse4.1,+sse4.2,+avx,+avx2";
            "aarch64-darwin" = "-C target-feature=+neon";
          }
          .${system} or "";

        packages.default = rustPlatform.buildRustPackage {
          name = "mutree";
          src = ./.;
          buildFeatures = [
            "blake2"
            "blake3"
            "sha2"
            "sha3"
          ];
          cargoLock.lockFile = ./Cargo.lock;
          env = {
            inherit RUSTFLAGS;
          };
          useNextest = true;
        };
      in
      {
        inherit packages;

        devShells.default = mkShell {
          inherit RUSTFLAGS;

          name = "mutree";

          buildInputs = with pkgs; [
            rust

            cargo-criterion
            cargo-mutants
            cargo-nextest
            cargo-watch
          ];
        };
      }
    );
}
