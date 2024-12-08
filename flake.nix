{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };

        runDay = pkgs.callPackage ./runDay.nix { };
        initDay = pkgs.callPackage ./initDay.nix { };
      in
      {
        devShells = {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              runDay
              initDay

              just
            ];
          };
        };

        packages = {
          default = pkgs.hello;
        };
      }
    );
}
