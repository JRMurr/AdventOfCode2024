{ pkgs ? import ../locked.nix }:
let

  lib = pkgs.lib;

  abs = x: if x < 0 then x * -1 else x;

  parseInput = text:
    let
      pairStrs = lib.strings.splitString "\n" text;
      splitPair = str: builtins.trace str
        (
          let
            split = lib.strings.splitString " " str;
            asInts = builtins.map lib.strings.toIntBase10 split;
          in
          {
            left = builtins.head asInts;
            right = builtins.tail asInts;
          }
        );

      pairs = builtins.map splitPair pairStrs;
      left = builtins.map (p: p.left) pairs;
      right = builtins.map (p: p.right) pairs;

      sortLst = lst: lib.lists.sortOn (p: q: p < q) lst;
      sortedLeft = sortLst left;
      sortedRight = sortLst right;

      combined = lib.zipListsWith (l: r: (abs (l - r))) sortedLeft sortedRight;

    in
    lib.lists.foldl' (acc: x: acc + x) 0 combined;


  part0 = text: parseInput text;


  part1 = text: "TODO";


  solve = text: {
    "0" = part0 text;
    "1" = part1 text;
  };

in
{
  example = solve (builtins.readFile ./in.example);
  real = solve (builtins.readFile ./in);
}
