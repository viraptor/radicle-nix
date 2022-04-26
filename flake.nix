{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs = { self, nixpkgs, flake-utils, rust-overlay }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs { inherit system overlays; };
      in
      rec {
        packages = {
          radicle-cli = let
              rustPlatform = pkgs.makeRustPlatform {
                rustc = pkgs.rust-bin.stable.latest.default;
                cargo = pkgs.rust-bin.stable.latest.default;
              };
            in
            rustPlatform.buildRustPackage rec {
              pname = "radicle-cli";
              version = "0.5.1";
              nativeBuildInputs = [ pkgs.cmake pkgs.openssl.dev pkgs.pkg-config pkgs.asciidoctor ];
              buildInputs = [ pkgs.openssl ] ++ pkgs.lib.optional pkgs.stdenv.isDarwin [ pkgs.darwin.apple_sdk.frameworks.IOKit pkgs.darwin.apple_sdk.frameworks.AppKit ];
              src = pkgs.fetchFromGitHub {
                owner = "radicle-dev";
                repo = pname;
                rev = "69c1dd451bc9cb58a19efd3d14a92a8fd3eed5a3";
				# rev = "v${version}"; (0.5.1's lock file is broken)
                sha256 = "sha256-P7IEurq2V4LaxfFwUqQefuf04WcFcVajUG+Dh4SNcVo=";
              };
              cargoSha256 = "sha256-lbd3aWvX9XqOvuenSvCVHXEZYTtk0caMwDLNeCh9GmQ=";
              postInstall = ''
                bash ./.github/build-man-page.bash rad.1.adoc
                mkdir -p $out/share/man/man1
                cp rad.1.gz $out/share/man/man1/rad.1.gz
              '';
              doCheck = false; # https://github.com/radicle-dev/radicle-cli/issues/84
            };
        };
        defaultPackage = packages.radicle-cli;
        apps.radicle-cli = flake-utils.lib.mkApp { drv = packages.radicle-cli; };
        defaultApp = apps.radicle-cli;
      }
    );
}
