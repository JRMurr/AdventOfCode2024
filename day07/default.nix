{
  pkgs ? import ../locked.nix,
}:
let

  lib = pkgs.lib;

  myLib = import ../myLib { inherit pkgs; };

  parseEquation =
    line:
    let

      splitEq = lib.trivial.pipe line [
        (lib.strings.splitString ":")
        (builtins.map lib.strings.trim)
      ];

      left = lib.strings.toIntBase10 (builtins.head splitEq);

      right = lib.trivial.pipe (lib.lists.last splitEq) [
        (lib.strings.splitString " ")
        (builtins.map lib.strings.toIntBase10)
      ];

    in
    {
      inherit left right;
    };

  part0 =
    { text, filePath }:
    let
      eqs = myLib.parseLines parseEquation text;
    in
    "TODO P1";

  part1 = { text, filePath }: "TODO P2";

  solve =
    filePath:
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
