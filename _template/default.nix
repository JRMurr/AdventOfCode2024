{ pkgs ? import ../locked.nix }:
let

  lib = pkgs.lib;

  part0 = text: "TODO P1";

  part1 = text: "TODO P2";

  solve = text: {
    "0" = part0 text;
    "1" = part1 text;
  };
in
{
  example = solve (builtins.readFile ./in.example);
  real = solve (builtins.readFile ./in);
}
