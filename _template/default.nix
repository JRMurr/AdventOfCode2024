{ pkgs ? import ../locked.nix }:
let

  lib = pkgs.lib;

  myLib = import ../myLib { inherit pkgs; };

  part0 = { text, filePath }: "TODO P1";

  part1 = { text, filePath }: "TODO P2";

  solve = filePath:
    let
      text = builtins.readFile filePath;
      attrs = { inherit text filePath; };
    in
    {
      "0" = part0 attrs;
      "1" = part1 attrs;
    };
in
{
  example = solve ./in.example;
  real = solve ./in;
}
